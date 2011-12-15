# -*- coding: utf-8 -*-
#
# network.py
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
import os
import xmpp

from archipelcore.archipelPlugin import TNArchipelPlugin
from archipelcore.utils import build_error_iq, build_error_message

from archipel.archipelLibvirtEntity import ARCHIPEL_NS_LIBVIRT_GENERIC_ERROR


ARCHIPEL_NS_HYPERVISOR_NETWORK              = "archipel:hypervisor:network"
ARCHIPEL_ERROR_CODE_NETWORKS_DEFINE         = -7001
ARCHIPEL_ERROR_CODE_NETWORKS_UNDEFINE       = -7002
ARCHIPEL_ERROR_CODE_NETWORKS_CREATE         = -7003
ARCHIPEL_ERROR_CODE_NETWORKS_DESTROY        = -7004
ARCHIPEL_ERROR_CODE_NETWORKS_GET            = -7005
ARCHIPEL_ERROR_CODE_NETWORKS_BRIDGES        = -7006
ARCHIPEL_ERROR_CODE_NETWORKS_GETNAMES       = -7007
ARCHIPEL_ERROR_CODE_NETWORKS_GETNICS        = -7008
ARCHIPEL_ERROR_CODE_NETWORKS_GETNWFILTERS   = -7009


class TNHypervisorNetworks (TNArchipelPlugin):

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
        self.folder_nwfilters = self.configuration.get("NETWORKS", "libvirt_nw_filters_path")
        if not os.path.exists(self.folder_nwfilters):
            self.folder_nwfilters = None
            self.entity.log.warning("NETWORK: unable to find network filter folder at path %s. agent will not offer any network filter")

        # permissions
        if self.entity.__class__.__name__ == "TNArchipelVirtualMachine":
            self.entity.permission_center.create_permission("network_getnames", "Authorizes user to get the existing network names", False)
            self.entity.permission_center.create_permission("network_bridges", "Authorizes user to get existing bridges", False)
        elif self.entity.__class__.__name__ == "TNArchipelHypervisor":
            self.entity.permission_center.create_permission("network_define", "Authorizes user to define a network", False)
            self.entity.permission_center.create_permission("network_undefine", "Authorizes user to undefine a network", False)
            self.entity.permission_center.create_permission("network_create", "Authorizes user to create (start) a network", False)
            self.entity.permission_center.create_permission("network_destroy", "Authorizes user to destroy (stop) a network", False)
            self.entity.permission_center.create_permission("network_get", "Authorizes user to get all networks informations", False)
            self.entity.permission_center.create_permission("network_getnames", "Authorizes user to get the existing network names", False)
            self.entity.permission_center.create_permission("network_bridges", "Authorizes user to get existing bridges", False)
            self.entity.permission_center.create_permission("network_getnics", "Authorizes user to get existing network interfaces", False)
            self.entity.permission_center.create_permission("network_getnwfilters", "Authorizes user to get existing libvirt network filters", False)
            registrar_items = [
                                {   "commands" : ["list networks"],
                                    "parameters": [],
                                    "method": self.message_get,
                                    "permissions": ["network_get"],
                                    "description": "List all networks" },
                                {   "commands" : ["create network", "start network"],
                                    "parameters": [{"name": "identifier", "description": "The identifer of the network, UUID or name"}],
                                    "method": self.message_create,
                                    "permissions": ["network_create"],
                                    "description": "Start the given network" },
                                {   "commands" : ["destroy network", "stop network"],
                                    "parameters": [{"name": "identifier", "description": "The identifer of the network, UUID or name"}],
                                    "method": self.message_destroy,
                                    "permissions": ["network_destroy"],
                                    "description": "Stop the given network" },
                                {   "commands" : ["nics", "network cards"],
                                    "parameters": [],
                                    "method": self.message_getnics,
                                    "permissions": ["network_getnics"],
                                    "description": "Get the list of all my network interfaces" }
                                ]

            self.entity.add_message_registrar_items(registrar_items)


    ### Plugin implementation

    def register_handlers(self):
        """
        This method will be called by the plugin user when it will be
        necessary to register module for listening to stanza.
        """
        if self.entity.__class__.__name__ == "TNArchipelVirtualMachine":
            self.entity.xmppclient.RegisterHandler('iq', self.process_iq_for_virtualmachine, ns=ARCHIPEL_NS_HYPERVISOR_NETWORK)
        elif self.entity.__class__.__name__ == "TNArchipelHypervisor":
            self.entity.xmppclient.RegisterHandler('iq', self.process_iq_for_hypervisor, ns=ARCHIPEL_NS_HYPERVISOR_NETWORK)

    def unregister_handlers(self):
        """
        Unregister the handlers.
        """
        if self.entity.__class__.__name__ == "TNArchipelVirtualMachine":
            self.entity.xmppclient.UnregisterHandler('iq', self.process_iq_for_virtualmachine, ns=ARCHIPEL_NS_HYPERVISOR_NETWORK)
        elif self.entity.__class__.__name__ == "TNArchipelHypervisor":
            self.entity.xmppclient.UnregisterHandler('iq', self.process_iq_for_hypervisor, ns=ARCHIPEL_NS_HYPERVISOR_NETWORK)

    @staticmethod
    def plugin_info():
        """
        Return informations about the plugin.
        @rtype: dict
        @return: dictionary contaning plugin informations
        """
        plugin_friendly_name           = "Hypervisor Networks"
        plugin_identifier              = "hypervisor_network"
        plugin_configuration_section   = "NETWORKS"
        plugin_configuration_tokens    = ["libvirt_nw_filters_path"]
        return {    "common-name"               : plugin_friendly_name,
                    "identifier"                : plugin_identifier,
                    "configuration-section"     : plugin_configuration_section,
                    "configuration-tokens"      : plugin_configuration_tokens }

    ### Utilities

    def get_network_with_identifier(self, identifier):
        """
        Return a libvirtNetwork according to the identifier, which can be the name or the UUID
        @type identifier: String
        @param identifier: the name or the UUID of the network
        @rtype: libvirtNetwork
        @return: the network object with given identifier
        """
        try:
            try:
                libvirt_network = self.entity.libvirt_connection.networkLookupByName(identifier)
            except:
                libvirt_network = self.entity.libvirt_connection.networkLookupByUUIDString(identifier)
            return libvirt_network
        except Exception as ex:
            self.entity.log.error("NETWORK: Unable to find a network with identifier %s: %s" % (identifier, str(ex)))
            raise Exception("Unable to find a network with identifier %s" % identifier)


    ### libvirt controls

    def get(self, active=True, inactive=True):
        """
        Get the list of networks.
        @type active: bool
        @param active: if True, will return active network
        @type inactive: bool
        @param inactive: if True, will return not active network
        @rtype: dict
        @return: a list containing networtks
        """
        ret = {}
        if active:
            ret["active"] = self.entity.libvirt_connection.listNetworks()
        if inactive:
            ret["inactive"] = self.entity.libvirt_connection.listDefinedNetworks()
        return ret

    def create(self, identifier):
        """
        Create (start) the network with given identifier.
        @type identifier: string
        @param identifier: the identifer of the network to create. It can be its name or UUID
        """
        libvirt_network = self.get_network_with_identifier(identifier)
        libvirt_network.create()
        self.entity.log.info("NETWORK: Virtual network %s created." % identifier)
        self.entity.push_change("network", "created")

    def destroy(self, identifier):
        """
        destroy (stop) the network with given identifier
        @type identifier: string
        @param identifier: the identifer of the network to destroy. It can be its name or UUID
        """
        libvirt_network = self.get_network_with_identifier(identifier)
        libvirt_network.destroy()
        self.entity.log.info("NETWORK: virtual network %s destroyed" % identifier)
        self.entity.push_change("network", "destroyed")

    def define(self, definition):
        """
        define the network
        @type definition: string
        @param definition: the XML definition to use
        """
        self.entity.libvirt_connection.networkDefineXML(str(definition))
        self.entity.log.info("NETWORK: Virtual network XML is defined.")
        self.entity.push_change("network", "defined")

    def undefine(self, identifier):
        """
        Undefine the network with given identifier.
        @type identifier: string
        @param identifier: the identifer of the network to destroy. It can be its name or UUID
        """
        libvirt_network = self.get_network_with_identifier(identifier)
        libvirt_network.undefine()
        self.entity.log.info("NETWORK: Virtual network %s is undefined." % identifier)
        self.entity.push_change("network", "undefined")

    def getnics(self):
        """
        Return the list of all network interfaces.
        @rtype: list
        @return: list containing network cards names
        """
        f = open('/proc/net/dev', 'r')
        content = f.read()
        f.close()
        splitted = content.split('\n')[2:-1]
        return map(lambda x: x.split(":")[0].replace(" ", ""), splitted)

    def getnwfilters(self):
        """
        Return the list of all libvirt network filters.
        @rtype: list
        @return: list containing network cards names
        """
        ret = []
        if not self.folder_nwfilters:
            return ret
        for nwfilter in os.listdir(self.folder_nwfilters):
            ret.append(os.path.splitext(nwfilter)[0])
        return ret

    def setAutostart(self, identifier, shouldAutostart):
        """
        Set the network to start with the host
        @type network_identifier: string
        @param identifier: the UUID or the name of the network
        @type identifier: boolean
        @param shouldAutostart: set if autostart should be set
        @rtype: integer
        @return: the result of the libvirt call
        """
        libvirt_network = self.get_network_with_identifier(identifier)
        return libvirt_network.setAutostart(shouldAutostart)

    def getAutostart(self, identifier):
        """
        Set the network to start with the host
        @type identifier: string
        @param identifier: the UUID or the name of the network
        @rtype: Boolean
        @return: True is network is in autostart mode
        """
        libvirt_network = self.get_network_with_identifier(identifier)
        return libvirt_network.autostart()


    ### XMPP Processing

    def process_iq_for_hypervisor(self, conn, iq):
        """
        This method is invoked when a ARCHIPEL_NS_HYPERVISOR_NETWORK IQ is received.
        It understands IQ of type:
            - define
            - undefine
            - create
            - destroy
            - get
            - bridges
            - getnames
            - getnics
        @type conn: xmpp.Dispatcher
        @param conn: ths instance of the current connection that send the stanza
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ
        """
        reply = None
        action = self.entity.check_acp(conn, iq)
        self.entity.check_perm(conn, iq, action, -1, prefix="network_")
        if action == "define":
            reply = self.iq_define(iq)
        elif action == "undefine":
            reply = self.iq_undefine(iq)
        elif action == "create":
            reply = self.iq_create(iq)
        elif action == "destroy":
            reply = self.iq_destroy(iq)
        elif action == "get":
            reply = self.iq_get(iq)
        elif action == "bridges":
            reply = self.iq_bridges(iq)
        elif action == "getnames":
            reply = self.iq_get_names(iq)
        elif action == "getnics":
            reply = self.iq_get_nics(iq)
        if reply:
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed

    def process_iq_for_virtualmachine(self, conn, iq):
        """
        This method is invoked when a ARCHIPEL_NS_HYPERVISOR_NETWORK IQ is received.
        It understands IQ of type:
            - bridges
            - getnames
            - getnics
            - getnwfilters
        @type conn: xmpp.Dispatcher
        @param conn: ths instance of the current connection that send the stanza
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ
        """
        reply = None
        action = self.entity.check_acp(conn, iq)
        self.entity.check_perm(conn, iq, action, -1, prefix="network_")
        if action == "getnames":
            reply = self.iq_get_names(iq)
        elif action == "bridges":
            reply = self.iq_bridges(iq)
        elif action == "getnics":
            reply = self.iq_get_nics(iq)
        elif action == "getnwfilters":
            reply = self.iq_get_nwfilters(iq)
        if reply:
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed

    def iq_define(self, iq):
        """
        Define a virtual network in the libvirt according to the XML data
        network passed in argument.
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ
        @rtype: xmpp.Protocol.Iq
        @return: a ready to send IQ containing the result of the action
        """
        try:
            reply           = iq.buildReply("result")
            network_node    = iq.getTag("query").getTag("archipel").getTag("network")
            self.define(network_node)
            if iq.getTag("query").getTag("archipel").getAttr("autostart") == "1":
                self.setAutostart(network_node.getTag("uuid").getData(), True)
        except libvirt.libvirtError as ex:
            reply = build_error_iq(self, ex, iq, ex.get_error_code(), ns=ARCHIPEL_NS_LIBVIRT_GENERIC_ERROR)
        except Exception as ex:
            reply = build_error_iq(self, ex, iq, ARCHIPEL_ERROR_CODE_NETWORKS_DEFINE)
        return reply

    def iq_undefine(self, iq):
        """
        Undefine a virtual network in the libvirt according to name passed in argument.
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ
        @rtype: xmpp.Protocol.Iq
        @return: a ready to send IQ containing the result of the action
        """
        try:
            reply = iq.buildReply("result")
            network_uuid = iq.getTag("query").getTag("archipel").getAttr("uuid")
            self.undefine(network_uuid)
        except libvirt.libvirtError as ex:
            reply = build_error_iq(self, ex, iq, ex.get_error_code(), ns=ARCHIPEL_NS_LIBVIRT_GENERIC_ERROR)
        except Exception as ex:
            reply = build_error_iq(self, ex, iq, ARCHIPEL_ERROR_CODE_NETWORKS_UNDEFINE)
        return reply

    def iq_create(self, iq):
        """
        Create a network using libvirt connection.
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ
        @rtype: xmpp.Protocol.Iq
        @return: a ready to send IQ containing the result of the action
        """
        try:
            network_uuid = iq.getTag("query").getTag("archipel").getAttr("uuid")
            self.create(network_uuid)
            reply = iq.buildReply("result")
            self.entity.shout("network", "Network %s has been started by %s." % (network_uuid, iq.getFrom()))
        except libvirt.libvirtError as ex:
            reply = build_error_iq(self, ex, iq, ex.get_error_code(), ns=ARCHIPEL_NS_LIBVIRT_GENERIC_ERROR)
        except Exception as ex:
            reply = build_error_iq(self, ex, iq, ARCHIPEL_ERROR_CODE_NETWORKS_CREATE)
        return reply

    def message_create(self, msg):
        """
        Handle the creation request message.
        @type msg: xmpp.Protocol.Message
        @param msg: the received message
        @rtype: xmpp.Protocol.Message
        @return: a ready to send Message containing the result of the action
        """
        try:
            tokens = msg.getBody().split()
            if not len(tokens) == 3:
                return "I'm sorry, you use a wrong format. You can type 'help' to get help."
            identifier = tokens[-1:][0]
            self.create(identifier)
            return "Starting network %s" % identifier
        except Exception as ex:
            return build_error_message(self, ex, msg)

    def iq_destroy(self, iq):
        """
        Destroy a network using libvirt connection.
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ
        @rtype: xmpp.Protocol.Iq
        @return: a ready to send IQ containing the result of the action
        """
        try:
            network_uuid = iq.getTag("query").getTag("archipel").getAttr("uuid")
            self.destroy(network_uuid)
            reply = iq.buildReply("result")
            self.entity.shout("network", "Network %s has been shutdowned by %s." % (network_uuid, iq.getFrom()))
        except libvirt.libvirtError as ex:
            reply = build_error_iq(self, ex, iq, ex.get_error_code(), ns=ARCHIPEL_NS_LIBVIRT_GENERIC_ERROR)
        except Exception as ex:
            reply = build_error_iq(self, ex, iq, ARCHIPEL_ERROR_CODE_NETWORKS_DESTROY)
        return reply

    def message_destroy(self, msg):
        """
        Handle the destroying request message.
        @type msg: xmpp.Protocol.Message
        @param msg: the message containing the request
        @rtype: string
        @return: the answer
        """
        try:
            tokens = msg.getBody().split()
            if not len(tokens) == 3:
                return "I'm sorry, you use a wrong format. You can type 'help' to get help."
            identifier = tokens[-1:][0]
            self.destroy(identifier)
            return "Destroying network %s" % identifier
        except Exception as ex:
            return build_error_message(self, ex, msg)

    def iq_get(self, iq):
        """
        List all virtual networks.
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ
        @rtype: xmpp.Protocol.Iq
        @return: a ready to send IQ containing the result of the action
        """
        try:
            reply                   = iq.buildReply("result")
            active_networks_nodes   = []
            inactive_networks_nodes = []
            networks                = self.get()
            for network_name in networks["active"]:
                network = self.entity.libvirt_connection.networkLookupByName(network_name)
                desc = network.XMLDesc(0)
                n = xmpp.simplexml.NodeBuilder(data=desc).getDom()
                n.setAttr("autostart", self.getAutostart(network_name))
                active_networks_nodes.append(n)
            for network_name in networks["inactive"]:
                network = self.entity.libvirt_connection.networkLookupByName(network_name)
                desc = network.XMLDesc(0)
                n = xmpp.simplexml.NodeBuilder(data=desc).getDom()
                n.setAttr("autostart", self.getAutostart(network_name))
                inactive_networks_nodes.append(n)
            active_networks_root_node   = xmpp.Node(tag="activedNetworks", payload=active_networks_nodes)
            inactive_networks_root_node = xmpp.Node(tag="unactivedNetworks", payload=inactive_networks_nodes)
            reply.setQueryPayload([active_networks_root_node, inactive_networks_root_node])
        except libvirt.libvirtError as ex:
            reply = build_error_iq(self, ex, iq, ex.get_error_code(), ns=ARCHIPEL_NS_LIBVIRT_GENERIC_ERROR)
        except Exception as ex:
            reply = build_error_iq(self, ex, iq, ARCHIPEL_ERROR_CODE_NETWORKS_GET)
        return reply

    def message_get(self, msg):
        """
        Create the message response to list network.
        @type msg: xmpp.Protocol.Message
        @param msg: the message containing the request
        @rtype: string
        @return: the answer
        """
        try:
            networks = self.get()
            ret = "Sure. Here are my current active networks:\n"
            for net in networks["active"]:
                ret += "    - %s\n" % net
            ret += "\n and my unactive network:\n"
            for net in networks["inactive"]:
                ret += "    - %s\n" % net
            return ret
        except Exception as ex:
            return build_error_message(self, ex, msg)

    def iq_get_names(self, iq):
        """
        List all virtual network names.
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ
        @rtype: xmpp.Protocol.Iq
        @return: a ready to send IQ containing the result of the action
        """
        try:
            reply = iq.buildReply("result")
            active_networks_nodes = []
            actives_networks_names = self.get(inactive=False)["active"]
            for network_name in actives_networks_names:
                network = xmpp.Node(tag="network", attrs={"name": network_name})
                active_networks_nodes.append(network)
            reply.setQueryPayload(active_networks_nodes)
        except libvirt.libvirtError as ex:
            reply = build_error_iq(self, ex, iq, ex.get_error_code(), ns=ARCHIPEL_NS_LIBVIRT_GENERIC_ERROR)
        except Exception as ex:
            reply = build_error_iq(self, ex, iq, ARCHIPEL_ERROR_CODE_NETWORKS_GETNAMES)
        return reply

    def iq_bridges(self, iq):
        """
        List all bridge names.
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ
        @rtype: xmpp.Protocol.Iq
        @return: a ready to send IQ containing the result of the action
        """
        try:
            reply = iq.buildReply("result")
            output = commands.getoutput("brctl show | grep -v -E '^[[:space:]]'")
            lines = output.split("\n")[1:]
            bridges_names = []
            for line in lines:
                bridge_name = line.split()[0]
                bridge_node = xmpp.Node(tag="bridge", attrs={"name": bridge_name})
                bridges_names.append(bridge_node)
            reply.setQueryPayload(bridges_names)
        except Exception as ex:
            reply = build_error_iq(self, ex, iq, ARCHIPEL_ERROR_CODE_NETWORKS_BRIDGES)
        return reply

    def iq_get_nics(self, iq):
        """
        List all existing networks cards on the hypervisor.
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ
        @rtype: xmpp.Protocol.Iq
        @return: a ready to send IQ containing the result of the action
        """
        try:
            reply = iq.buildReply("result")
            nodes = []
            for n in self.getnics():
                nodes.append(xmpp.Node("nic", attrs={"name": n}))
            reply.setQueryPayload(nodes)
        except Exception as ex:
            reply = build_error_iq(self, ex, iq, ARCHIPEL_ERROR_CODE_NETWORKS_GETNICS)
        return reply

    def message_getnics(self, msg):
        """
        Get all the nics of the hypervisor.
        @type msg: xmpp.Protocol.Message
        @param msg: the message containing the request
        @rtype: string
        @return: the answer
        """
        try:
            nics = self.getnics()
            ret = "Sure. Here are my current available network interfaces:\n"
            for n in nics:
                ret += "    - %s\n" % n
            return ret
        except Exception as ex:
            return build_error_message(self, ex, msg)

    def iq_get_nwfilters(self, iq):
        """
        List all existing libvirt network filters.
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ
        @rtype: xmpp.Protocol.Iq
        @return: a ready to send IQ containing the result of the action
        """
        try:
            reply = iq.buildReply("result")
            nodes = []
            for nwfilter in self.getnwfilters():
                nodes.append(xmpp.Node("filter", attrs={"name": nwfilter}))
            reply.setQueryPayload(nodes)
        except Exception as ex:
            reply = build_error_iq(self, ex, iq, ARCHIPEL_ERROR_CODE_NETWORKS_GETNWFILTERS)
        return reply
