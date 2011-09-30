# -*- coding: utf-8 -*-
#
# health.py
#
# Copyright (C) 2010 Antoine Mercadal <antoine.mercadal@inframonde.eu>
# Copyright, 2011 - Franck Villaume <franck.villaume@trivialdev.com>
# This file is part of ArchipelProject
# http://archipelproject.org
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

import commands
import libvirt
import xmpp
import json

from archipelcore.archipelPlugin import TNArchipelPlugin
from archipelcore.utils import build_error_iq, build_error_message
from archipelStatsCollector import TNThreadedHealthCollector


ARCHIPEL_NS_HYPERVISOR_HEALTH       = "archipel:hypervisor:health"
ARCHIPEL_ERROR_CODE_HEALTH_HISTORY  = -8001
ARCHIPEL_ERROR_CODE_HEALTH_INFO     = -8002
ARCHIPEL_ERROR_CODE_HEALTH_LOG      = -8003


class TNHypervisorHealth (TNArchipelPlugin):

    def __init__(self, configuration, entity, entry_point_group):
        """
        Initialize the plugin.
        @type configuration: Configuration object
        @param configuration: the configuration
        @type entity: L{TNArchipelEntity}
        @param entity: the entity that owns the plugin
        @type entry_point_group: string
        @param entry_point_group: the group name of plugin entry_point
        """
        TNArchipelPlugin.__init__(self, configuration=configuration, entity=entity, entry_point_group=entry_point_group)
        db_file                 = self.configuration.get("HEALTH", "health_database_path")
        collection_interval     = self.configuration.getint("HEALTH", "health_collection_interval")
        max_rows_before_purge   = self.configuration.getint("HEALTH", "max_rows_before_purge")
        max_cached_rows         = self.configuration.getint("HEALTH", "max_cached_rows")
        log_file                = self.configuration.get("LOGGING", "logging_file_path")
        self.collector = TNThreadedHealthCollector(db_file,collection_interval, max_rows_before_purge, max_cached_rows)
        self.logfile = log_file

        # permissions
        self.entity.permission_center.create_permission("health_history", "Authorizes user to get the health history", False)
        self.entity.permission_center.create_permission("health_info", "Authorizes user to get entity information", False)
        self.entity.permission_center.create_permission("health_logs", "Authorizes user to get entity logs", False)
        registrar_items = [
                            {   "commands" : ["health"],
                                "parameters": [{"name": "limit", "description": "Max number of returned entries. Equals 1 if ommited"}],
                                "method": self.message_health_info,
                                "permissions": ["health_info"],
                                "description": "Get my last health information" },
                            {   "commands" : ["logs"],
                                "parameters": [{"name": "limit", "description": "Max number of returned entries. Equals 1 if ommited"}],
                                "method": self.message_get_logs,
                                "permissions": ["health_logs"],
                                "description": "Get my last logs information" }
                            ]
        self.entity.add_message_registrar_items(registrar_items)

        self.entity.register_hook("HOOK_ARCHIPELENTITY_XMPP_AUTHENTICATED", method=self.start_collector)


    ### Plugin interface

    def register_handlers(self):
        """
        This method will be called by the plugin user when it will be
        necessary to register module for listening to stanza.
        """
        self.entity.xmppclient.RegisterHandler('iq', self.process_iq, ns=ARCHIPEL_NS_HYPERVISOR_HEALTH)

    def unregister_handlers(self):
        """
        Unregister the handlers.
        """
        self.entity.xmppclient.UnregisterHandler('iq', self.process_iq, ns=ARCHIPEL_NS_HYPERVISOR_HEALTH)

    @staticmethod
    def plugin_info():
        """
        Return informations about the plugin.
        @rtype: dict
        @return: dictionary contaning plugin informations
        """
        plugin_friendly_name           = "Hypervisor Health"
        plugin_identifier              = "hypervisor_health"
        plugin_configuration_section   = "HEALTH"
        plugin_configuration_tokens    = [  "health_database_path",
                                            "health_collection_interval",
                                            "max_rows_before_purge",
                                            "max_cached_rows"]
        return {    "common-name"               : plugin_friendly_name,
                    "identifier"                : plugin_identifier,
                    "configuration-section"     : plugin_configuration_section,
                    "configuration-tokens"      : plugin_configuration_tokens }


    ### HOOK

    def start_collector(self, origin=None, user_info=None, parameters=None):
        """
        Start the collector
        @type origin: L{TNArchipelEntity}
        @param origin: the origin of the hook
        @type user_info: object
        @param user_info: random user info
        @type parameters: object
        @param parameters: runtime argument
        """
        self.collector.start()


    ### XMPP Processing

    def process_iq(self, conn, iq):
        """
        This method is invoked when a ARCHIPEL_NS_HYPERVISOR_HEALTH IQ is received.
        It understands IQ of type:
            - history
            - info
            - logs
        @type conn: xmpp.Dispatcher
        @param conn: ths instance of the current connection that send the stanza
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ
        """
        reply = None
        action = self.entity.check_acp(conn, iq)
        self.entity.check_perm(conn, iq, action, -1, prefix="health_")
        if action == "history":
            reply = self.iq_health_info_history(iq)
        elif action == "info":
            reply = self.iq_health_info(iq)
        elif action == "logs":
            reply = self.iq_get_logs(iq)
        if reply:
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed

    def iq_health_info_history(self, iq):
        """
        Get a range of old stat history according to the limit parameters in iq node.
        @type iq: xmpp.Protocol.Iq
        @param iq: the sender request IQ
        @rtype: xmpp.Protocol.Iq
        @return: a ready-to-send IQ containing the results
        """
        try:
            reply = iq.buildReply("result")
            self.entity.log.debug("Converting stats into XML node.")
            limit = int(iq.getTag("query").getTag("archipel").getAttr("limit"))
            nodes = []
            stats = self.collector.get_collected_stats(limit)
            number_of_rows = limit
            if number_of_rows > len(stats["memory"]):
                number_of_rows = len(stats["memory"])
            for i in range(number_of_rows):
                statNode = xmpp.Node("stat")
                statNode.addChild("memory", attrs=stats["memory"][i])
                statNode.addChild("cpu", attrs=stats["cpu"][i])
                statNode.addChild("disk")
                statNode.addChild("load", attrs=stats["load"][i])
                network_node = statNode.addChild("networks")
                for nic, delta in json.loads(stats["network"][i]["records"]).items():
                    network_node.addChild("network", attrs={"name": nic, "delta": delta})
                nodes.append(statNode)
            reply.setQueryPayload(nodes)
        except Exception as ex:
            reply = build_error_iq(self, ex, iq, ARCHIPEL_ERROR_CODE_HEALTH_HISTORY)
        return reply

    def iq_health_info(self, iq):
        """
        Send information about the hypervisor health info.
        @type iq: xmpp.Protocol.Iq
        @param iq: the sender request IQ
        @rtype: xmpp.Protocol.Iq
        @return: a ready-to-send IQ containing the results
        """
        try:
            reply = iq.buildReply("result")
            nodes = []
            stats = self.collector.get_collected_stats(1)
            if not stats:
                reply = build_error_iq(self, "Unable to get stats. See hypervisor log.", iq)
            else:
                try:
                    mem_free_node = xmpp.Node("memory", attrs=stats["memory"][0])
                    nodes.append(mem_free_node)
                except Exception as ex:
                    raise Exception("Unable to append memory stats node.", ex)
                try:
                    cpu_node = xmpp.Node("cpu", attrs=stats["cpu"][0])
                    nodes.append(cpu_node)
                except Exception as ex:
                    raise Exception("Unable to append cpu stats node.", ex)
                try:
                    disk_free_node = xmpp.Node("disk", attrs=stats["totaldisk"])
                    for s in stats["disk"]:
                        disk_free_node.addChild("partition", attrs=s)
                    nodes.append(disk_free_node)
                except Exception as ex:
                    raise Exception("Unable to append disk stats node.", ex)
                try:
                    network_node = xmpp.Node("networks")
                    for nic, delta in json.loads(stats["network"][0]["records"]).items():
                        network_node.addChild("network", attrs={"name": nic, "delta": delta})
                    nodes.append(network_node)
                except Exception as ex:
                    raise Exception("Unable to append network stats node.", ex)
                try:
                    load_node = xmpp.Node("load", attrs=stats["load"][0])
                    nodes.append(load_node)
                except Exception as ex:
                    raise Exception("Unable to append load avergae stats node.", ex)
                try:
                    uptime_node = xmpp.Node("uptime", attrs=stats["uptime"])
                    nodes.append(uptime_node)
                except Exception as ex:
                    raise Exception("Unable to append uptime stats node:", ex)
                try:
                    uname_node = xmpp.Node("uname", attrs=stats["uname"])
                    nodes.append(uname_node)
                except Exception as ex:
                    raise Exception("Unable to append uname node.", ex)
                try:
                    libvirtversion_node = xmpp.Node("libvirt", attrs=self.entity.libvirt_version())
                    nodes.append(libvirtversion_node)
                except Exception as ex:
                    raise Exception("Unable to append libvirtversion_node node.", ex)
                try:
                    driverversion_node = xmpp.Node("driver", attrs=self.entity.driver_version())
                    nodes.append(driverversion_node)
                except Exception as ex:
                    raise Exception("Unable to append driverversion_node node.", ex)
                reply.setQueryPayload(nodes)
        except Exception as ex:
            reply = build_error_iq(self, ex, iq, ARCHIPEL_ERROR_CODE_HEALTH_INFO)
        return reply

    def message_health_info(self, msg):
        """
        Handle the health info request message.
        @type msg: xmmp.Protocol.Message
        @param msg: the message
        @rtype: string
        @return: the answer
        """
        try:
            tokens = msg.getBody().split()
            if len(tokens) == 1 :   limit = 1
            elif len(tokens) == 2 : limit = int(tokens[1])
            else: return "I'm sorry, you use a wrong format. You can type 'help' to get help."
            stats = self.collector.get_collected_stats(limit)
            return str(stats)
        except Exception as ex:
            return build_error_message(self, ex, msg)

    def iq_get_logs(self, iq):
        """
        Read the hypervisor's log file.
        @type iq: xmpp.Protocol.Iq
        @param iq: the sender request IQ
        @rtype: xmpp.Protocol.Iq
        @return: a ready-to-send IQ containing the results
        """
        try:
            reply = iq.buildReply("result")
            limit = int(iq.getTag("query").getTag("archipel").getAttr("limit"))
            output = commands.getoutput("tail -n %d %s" % (limit, self.logfile))
            nodes = []
            for line in output.split("\n"):
                try:
                    infos = line.split("::")
                    log_node = xmpp.Node("log", attrs={"level": infos[0], "date": infos[1], "file": "", "method": ""})
                    log_node.setData(line)
                    nodes.append(log_node)
                except Exception as ex:
                    pass
            reply.setQueryPayload(nodes)
        except Exception as ex:
            print str(ex)
            reply = build_error_iq(self, ex, iq, ARCHIPEL_ERROR_CODE_HEALTH_LOG)
        return reply

    def message_get_logs(self, msg):
        """
        Handle the log info request message.
        @type msg: xmpp.Protocol.Iq
        @param msg: the sender request IQ
        @rtype: xmpp.Protocol.Iq
        @return: a ready-to-send IQ containing the results
        """
        try:
            tokens = msg.getBody().split()
            if len(tokens) == 1 :   limit = 1
            elif len(tokens) == 2 : limit = int(tokens[1])
            else: return "I'm sorry, you use a wrong format. You can type 'help' to get help."
            output = commands.getoutput("tail -n %d %s" % (limit, self.logfile))
            return output
        except Exception as ex:
            return build_error_message(self, ex, msg)