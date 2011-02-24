#!/usr/bin/python
# archipelModuleHypervisorTest.py
# 
# Copyright (C) 2010 Antoine Mercadal <antoine.mercadal@inframonde.eu>
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


# we need to import the package containing the class to surclass
from archipelcore.utils import *
from archipel.archipelPlugin import TNArchipelPlugin
import commands
import xmpp
import os
import archipel
import libvirt

ARCHIPEL_NS_HYPERVISOR_NETWORK          = "archipel:hypervisor:network"
ARCHIPEL_ERROR_CODE_NETWORKS_DEFINE     = -7001
ARCHIPEL_ERROR_CODE_NETWORKS_UNDEFINE   = -7002
ARCHIPEL_ERROR_CODE_NETWORKS_CREATE     = -7003
ARCHIPEL_ERROR_CODE_NETWORKS_DESTROY    = -7004
ARCHIPEL_ERROR_CODE_NETWORKS_GET        = -7005
ARCHIPEL_ERROR_CODE_NETWORKS_BRIDGES    = -7006
ARCHIPEL_ERROR_CODE_NETWORKS_GETNAMES   = -7007

class TNHypervisorNetworks (TNArchipelPlugin):
    
    def __init__(self, configuration, entity, entry_point_group):
        """
        initialize the module
        @type entity TNArchipelEntity
        @param entity the module entity
        """
        TNArchipelPlugin.__init__(self, configuration=configuration, entity=entity, entry_point_group=entry_point_group)
        
        # permissions
        if self.entity.__class__.__name__ == "TNArchipelVirtualMachine":
            self.entity.permission_center.create_permission("network_getnames", "Authorizes user to get the existing network names", False)
            self.entity.permission_center.create_permission("network_bridges",  "Authorizes user to get existing bridges", False)
        elif self.entity.__class__.__name__ == "TNArchipelHypervisor":
            self.entity.permission_center.create_permission("network_define",   "Authorizes user to define a network", False)
            self.entity.permission_center.create_permission("network_undefine", "Authorizes user to undefine a network", False)
            self.entity.permission_center.create_permission("network_create",   "Authorizes user to create (start) a network", False)
            self.entity.permission_center.create_permission("network_destroy",  "Authorizes user to destroy (stop) a network", False)
            self.entity.permission_center.create_permission("network_get",      "Authorizes user to get all networks informations", False)
            self.entity.permission_center.create_permission("network_getnames", "Authorizes user to get the existing network names", False)
            self.entity.permission_center.create_permission("network_bridges",  "Authorizes user to get existing bridges", False)
            
            registrar_items = [
                                {   "commands" : ["list networks"], 
                                    "parameters": {}, 
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
                                    "description": "Stop the given network" }
                                ]
        
            self.entity.add_message_registrar_items(registrar_items)
    
    
    ### Module implementation
    
    def register_for_stanza(self):
        """
        this method will be called by the plugin user when it will be
        necessary to register module for listening to stanza
        """
        if self.entity.__class__.__name__ == "TNArchipelVirtualMachine":
            self.entity.xmppclient.RegisterHandler('iq', self.process_iq_for_virtualmachine, ns=ARCHIPEL_NS_HYPERVISOR_NETWORK)
        elif self.entity.__class__.__name__ == "TNArchipelHypervisor":
            self.entity.xmppclient.RegisterHandler('iq', self.process_iq_for_hypervisor, ns=ARCHIPEL_NS_HYPERVISOR_NETWORK)    
    
    
    @staticmethod
    def plugin_info():
        """
        return inforations about the plugin
        """
        plugin_friendly_name           = "Hypervisor Networks"
        plugin_identifier              = "hypervisor_network"
        plugin_configuration_section   = None
        plugin_configuration_tokens    = None

        return {    "common-name"               : plugin_friendly_name, 
                    "identifier"                : plugin_identifier,
                    "configuration-section"     : plugin_configuration_section,
                    "configuration-tokens"      : plugin_configuration_tokens }
    
    
    ### libvirt controls
    
    def get(self, active=True, inactive=True):
        """
        get the list of the networks
        
        @type active bool
        @param active: if True, will return active network
        @type inactive bool
        @param inactive: if True, will return not active network
        
        @rtype: dict
        @return a list containing networtks
        """
        ret = {}
        if active:      ret["active"]   = self.entity.libvirt_connection.listNetworks()
        if inactive:    ret["inactive"] = self.entity.libvirt_connection.listDefinedNetworks()
        return ret
    
    
    def create(self, identifier):
        """
        create (start) the network with given identifier
        
        @type identifier string
        @param identifier: the identifer of the network to create. It can be its name or UUID
        """
        try:
            libvirt_network = self.entity.libvirt_connection.networkLookupByUUIDString(identifier)
        except:
            libvirt_network = self.entity.libvirt_connection.networkLookupByName(identifier)
        libvirt_network.create()
        self.entity.log.info("virtual network %s created" % identifier)
        self.entity.push_change("network", "created", excludedgroups=[ARCHIPEL_XMPP_GROUP_VM, ARCHIPEL_XMPP_GROUP_HYPERVISOR])
    
    
    def destroy(self, identifier):
        """
        destroy (stop) the network with given identifier
        
        @type identifier string
        @param identifier: the identifer of the network to destroy. It can be its name or UUID
        """
        try:
            libvirt_network = self.entity.libvirt_connection.networkLookupByUUIDString(identifier)
        except:
            libvirt_network = self.entity.libvirt_connection.networkLookupByName(identifier)
        libvirt_network.destroy()
        self.entity.log.info("virtual network %s destroyed" % identifier)
        self.entity.push_change("network", "destroyed", excludedgroups=[ARCHIPEL_XMPP_GROUP_VM, ARCHIPEL_XMPP_GROUP_HYPERVISOR])
    
    
    def define(self, definition):
        """
        define the network
        
        @type definition string
        @param definition: the XML definition to use
        """
        self.entity.libvirt_connection.networkDefineXML(str(definition))
        self.entity.log.info("virtual network XML is defined")
        self.entity.push_change("network", "defined", excludedgroups=[ARCHIPEL_XMPP_GROUP_VM, ARCHIPEL_XMPP_GROUP_HYPERVISOR])
    
    
    def undefine(self, identifier):
        """
        undefine the network with given identifier
        
        @type identifier string
        @param identifier: the identifer of the network to destroy. It can be its name or UUID
        """
        try:
            libvirt_network = self.entity.libvirt_connection.networkLookupByUUIDString(identifier)
        except:
            libvirt_network = self.entity.libvirt_connection.networkLookupByName(identifier)
        libvirt_network.undefine()
        self.entity.log.info("virtual network %s is undefined" % identifier)
        self.entity.push_change("network", "undefined", excludedgroups=[ARCHIPEL_XMPP_GROUP_VM, ARCHIPEL_XMPP_GROUP_HYPERVISOR])
        
    
    
    
    ### XMPP Processing
    
    def process_iq_for_hypervisor(self, conn, iq):
        """
        this method is invoked when a ARCHIPEL_NS_HYPERVISOR_NETWORK IQ is received.
        
        it understands IQ of type:
            - define
            - undefine
            - create
            - destroy
            - get
            - bridges
            - getnames
        
        @type conn: xmpp.Dispatcher
        @param conn: ths instance of the current connection that send the stanza
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ
        """
        action = self.entity.check_acp(conn, iq)        
        self.entity.check_perm(conn, iq, action, -1, prefix="network_")
        
        if action == "define":      reply = self.iq_define(iq)
        elif action == "undefine":  reply = self.iq_undefine(iq)
        elif action == "create":    reply = self.iq_create(iq)
        elif action == "destroy":   reply = self.iq_destroy(iq)
        elif action == "get":       reply = self.iq_get(iq)
        elif action == "bridges":   reply = self.iq_bridges(iq)
        elif action == "getnames":  reply = self.iq_get_names(iq)
        
        if reply:
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed
    
    
    def process_iq_for_virtualmachine(self, conn, iq):
        """
        this method is invoked when a ARCHIPEL_NS_HYPERVISOR_NETWORK IQ is received.
        
        it understands IQ of type:
            - bridges
            - getnames
        
        @type conn: xmpp.Dispatcher
        @param conn: ths instance of the current connection that send the stanza
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ
        """
        action = self.entity.check_acp(conn, iq)
        self.entity.check_perm(conn, iq, action, -1, prefix="network_")
        if action == "getnames":
            reply = self.iq_get_names(iq)
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed
        
        elif action == "bridges":
            reply = self.iq_bridges(iq)
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed
    
    
    
    def iq_define(self, iq):
        """
        Define a virtual network in the libvirt according to the XML data
        network passed in argument
        
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ
        
        @rtype: xmpp.Protocol.Iq
        @return: a ready to send IQ containing the result of the action
        """
        try:
            reply           = iq.buildReply("result")
            network_node    = iq.getTag("query").getTag("archipel").getTag("network")            
            self.define(network_node)
        except libvirt.libvirtError as ex:
            reply = build_error_iq(self, ex, iq, ex.get_error_code(), ns=ARCHIPEL_NS_LIBVIRT_GENERIC_ERROR)
        except Exception as ex:
            reply = build_error_iq(self, ex, iq, ARCHIPEL_ERROR_CODE_NETWORKS_DEFINE)
        return reply
    
    
    
    def iq_undefine(self, iq):
        """
        undefine a virtual network in the libvirt according to name passed in argument
        
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
        Create a network using libvirt connection
        
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ
        
        @rtype: xmpp.Protocol.Iq
        @return: a ready to send IQ containing the result of the action
        """
        try:
            network_uuid = iq.getTag("query").getTag("archipel").getAttr("uuid")
            self.create(network_uuid)
            reply = iq.buildReply("result")
            self.entity.shout("network", "Network %s has been started by %s." % (network_uuid, iq.getFrom()), excludedgroups=[ARCHIPEL_XMPP_GROUP_VM, ARCHIPEL_XMPP_GROUP_HYPERVISOR])
        except libvirt.libvirtError as ex:
            reply = build_error_iq(self, ex, iq, ex.get_error_code(), ns=ARCHIPEL_NS_LIBVIRT_GENERIC_ERROR)
        except Exception as ex:
            reply = build_error_iq(self, ex, iq, ARCHIPEL_ERROR_CODE_NETWORKS_CREATE)
        return reply
    
    
    def message_create(self, msg):
        """
        handle the creation request message
        """
        try:
            tokens = msg.getBody().split()
            if not len(tokens) == 3: return "I'm sorry, you use a wrong format. You can type 'help' to get help"
            identifier = tokens[-1:][0]
            self.create(identifier);
            return "Starting network %s" % identifier
        except Exception as ex:
            return build_error_message(self, ex)
    
    
    
    def iq_destroy(self, iq):
        """
        Destroy a network using libvirt connection
        
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ
        
        @rtype: xmpp.Protocol.Iq
        @return: a ready to send IQ containing the result of the action
        """
        try:
            network_uuid = iq.getTag("query").getTag("archipel").getAttr("uuid")
            self.destroy(network_uuid)
            reply = iq.buildReply("result")
            self.entity.shout("network", "Network %s has been shutdwned by %s." % (network_uuid, iq.getFrom()), excludedgroups=[ARCHIPEL_XMPP_GROUP_VM, ARCHIPEL_XMPP_GROUP_HYPERVISOR])
        except libvirt.libvirtError as ex:
            reply = build_error_iq(self, ex, iq, ex.get_error_code(), ns=ARCHIPEL_NS_LIBVIRT_GENERIC_ERROR)
        except Exception as ex:
            reply = build_error_iq(self, ex, iq, ARCHIPEL_ERROR_CODE_NETWORKS_DESTROY)
        return reply
    
    
    def message_destroy(self, msg):
        """
        handle the destroying request message
        """
        try:
            tokens = msg.getBody().split()
            if not len(tokens) == 3: return "I'm sorry, you use a wrong format. You can type 'help' to get help"
            identifier = tokens[-1:][0]
            self.destroy(identifier);
            return "Destroying network %s" % identifier
        except Exception as ex:
            return build_error_message(self, ex)
    
    
    
    def iq_get(self, iq):
        """
        list all virtual networks
        
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
                active_networks_nodes.append(n)
            
            for network_name in networks["inactive"]:
                network = self.entity.libvirt_connection.networkLookupByName(network_name)
                desc = network.XMLDesc(0)
                n = xmpp.simplexml.NodeBuilder(data=desc).getDom()
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
        create the message response to list network
        """
        try:
            networks = self.get()
            ret = "Sure. Here are my current active networks:\n"
            for net in networks["active"]: ret += "    - %s\n" % net
            ret += "\n and my unactive network:\n"
            for net in networks["inactive"]: ret += "    - %s\n" % net
            return ret
        except Exception as ex:
            return build_error_message(self, ex)
        
    
    
    
    def iq_get_names(self, iq):
        """
        list all virtual networks name
        
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
        list all virtual networks name
        
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
        except libvirt.libvirtError as ex:
            reply = build_error_iq(self, ex, iq, ex.get_error_code(), ns=ARCHIPEL_NS_LIBVIRT_GENERIC_ERROR)
        except Exception as ex:
            reply = build_error_iq(self, ex, iq, ARCHIPEL_ERROR_CODE_NETWORKS_BRIDGES)
        return reply
    
