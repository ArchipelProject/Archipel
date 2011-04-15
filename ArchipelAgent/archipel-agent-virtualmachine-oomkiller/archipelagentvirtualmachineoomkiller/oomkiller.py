# -*- coding: utf-8 -*-
#
# oomkiller.py
#
# Copyright (C) 2010 Antoine Mercadal <antoine.mercadal@inframonde.eu>
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
import sqlite3
import xmpp

from archipelcore.archipelPlugin import TNArchipelPlugin
from archipelcore.utils import build_error_iq


ARCHIPEL_NS_OOM_KILLER = "archipel:vm:oom"


class TNOOMKiller (TNArchipelPlugin):

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
        self.entity.register_hook("HOOK_VM_INITIALIZE", method=self.vm_initialized)
        self.entity.register_hook("HOOK_VM_CREATE", method=self.vm_create)
        self.entity.register_hook("HOOK_VM_TERMINATE", method=self.vm_terminate)
        self.database = sqlite3.connect(self.configuration.get("OOMKILLER", "database"), check_same_thread=False)
        self.database.execute("create table if not exists oomkiller (uuid text unique, adjust int)")
        self.database.commit()
        self.cursor = self.database.cursor()
        self.entity.log.info("module oom killer initialized")
        # permissions
        self.entity.permission_center.create_permission("oom_getadjust", "Authorizes user to get OOM values", False)
        self.entity.permission_center.create_permission("oom_setadjust", "Authorizes user to set OOM values", False)

    ### Module implementation

    def register_handlers(self):
        """
        This method will be called by the plugin user when it will be
        necessary to register module for listening to stanza.
        """
        self.entity.xmppclient.RegisterHandler('iq', self.process_iq, ns=ARCHIPEL_NS_OOM_KILLER)

    def unregister_handlers(self):
        """
        Unregister the handlers.
        """
        self.entity.xmppclient.UnregisterHandler('iq', self.process_iq, ns=ARCHIPEL_NS_OOM_KILLER)

    @staticmethod
    def plugin_info():
        """
        Return informations about the plugin.
        @rtype: dict
        @return: dictionary contaning plugin informations
        """
        plugin_friendly_name           = "Virtual Machine OOM Killer"
        plugin_identifier              = "oomkiller"
        plugin_configuration_section   = "OOMKILLER"
        plugin_configuration_tokens    = ["database"]
        return {    "common-name"               : plugin_friendly_name,
                    "identifier"                : plugin_identifier,
                    "configuration-section"     : plugin_configuration_section,
                    "configuration-tokens"      : plugin_configuration_tokens }


    ### Hooks

    def vm_create(self, origin, user_info, parameters):
        """
        Handle create HOOK_VM_CREATE.
        @type origin: L{TNArchipelEntity}
        @param origin: the origin of the hook
        @type user_info: object
        @param user_info: random user info
        @type parameters: object
        @param parameters: runtim argument
        """
        oom_info = self.get_oom_info()
        self.entity.log.info("OOM value retrieved %s" % str(oom_info))
        self.set_oom_info(oom_info["adjust"], oom_info["score"])
        self.entity.log.info("OOM value for vm with uuid %s have been restored." % self.entity.uuid)

    def vm_terminate(self, origin, user_info, parameters):
        """
        Handle create HOOK_VM_TERMINATE.
        @type origin: L{TNArchipelEntity}
        @param origin: the origin of the hook
        @type user_info: object
        @param user_info: random user info
        @type parameters: object
        @param parameters: runtim argument
        """
        self.cursor.execute("DELETE FROM oomkiller WHERE uuid=?", (self.entity.uuid, ))
        self.database.commit()
        self.cursor.close()
        self.database.close()
        self.entity.log.info("OOM information for vm with uuid %s has been removed." % self.entity.uuid)

    def vm_initialized(self, origin, user_info, parameters):
        """
        Handle create HOOK_VM_INITIALIZE.
        @type origin: L{TNArchipelEntity}
        @param origin: the origin of the hook
        @type user_info: object
        @param user_info: random user info
        @type parameters: object
        @param parameters: runtim argument
        """
        oom_info = self.get_oom_info()
        self.set_oom_info(oom_info["adjust"], oom_info["score"])
        self.entity.log.info("OOM information for vm with uuid %s have been removed." % self.entity.uuid)


    ### OOM information management

    def get_oom_info(self):
        """
        Get the OOM info from database.
        @rtype: dict
        @return: dict contaning OOM status
        """
        adj_value = 0
        score_value = 0
        self.cursor.execute("SELECT adjust FROM oomkiller WHERE uuid=?", (self.entity.uuid, ))
        for values in self.cursor:
            adj_value = values[0]
            score_value = 0
        return {"adjust": adj_value, "score": score_value}

    def set_oom_info(self, adjust, score):
        """
        Set the OOM info both on file if exists and on database.
        @type adjust: int
        @param adjust: the value of adjust
        @type score: int
        @param score: the value of the score
        """
        try:
            pid = int(commands.getoutput("ps -ef | grep kvm | grep %s | grep -v grep" % self.entity.uuid).split()[1])
            f = open("/proc/%d/oom_adj" % pid, "w")
            f.write(str(adjust))
            f.close()
        except Exception as ex:
            self.entity.log.warning("No valid PID. storing value only on database: " + str(ex))
        try:
            self.cursor.execute("INSERT INTO oomkiller VALUES (?, ?)", (self.entity.uuid, int(adjust), ))
        except:
            self.cursor.execute("UPDATE oomkiller SET adjust=? WHERE uuid=?", (int(adjust), self.entity.uuid, ))
        self.database.commit()


    ### XMPP handlers

    def process_iq(self, conn, iq):
        """
        This method is invoked when a ARCHIPEL_NS_OOM_KILLER IQ is received.
        It understands IQ of type:
            - do-something
        @type conn: xmpp.Dispatcher
        @param conn: ths instance of the current connection that send the stanza
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ
        """
        reply = None
        action = self.entity.check_acp(conn, iq)
        self.entity.check_perm(conn, iq, action, -1, prefix="oom_")
        if action == "getadjust":
            reply = self.iq_oom_get_adjust(iq)
        elif action == "setadjust":
            reply = self.iq_oom_set_adjust(iq)
        if reply:
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed

    def iq_oom_get_adjust(self, iq):
        """
        Return the value of the oom_adjust of the virtual machine.
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ
        @rtype: xmpp.Protocol.Iq
        @return: a ready to send IQ containing the result of the action
        """
        try:
            reply = iq.buildReply("result")
            oom_info = self.get_oom_info()
            adj_node = xmpp.Node(tag="oom", attrs={"adjust": oom_info["adjust"], "score": oom_info["score"]})
            reply.setQueryPayload([adj_node])
        except Exception as ex:
            reply = build_error_iq(self, ex, iq)
        return reply


    def iq_oom_set_adjust(self, iq):
        """
        Set the adjust value of oom killer from -16:15 plus special -17 value that disable oom killer for the process
        the lower the value his the higher the likelihood of killing the process.
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ
        @rtype: xmpp.Protocol.Iq
        @return: a ready to send IQ containing the result of the action
        """
        try:
            reply = iq.buildReply("result")
            value = iq.getTag("query").getTag("archipel").getAttr("adjust")
            self.set_oom_info(value, 0)
            self.entity.push_change("oom", "adjusted")
        except Exception as ex:
            reply = build_error_iq(self, ex, iq)
        return reply