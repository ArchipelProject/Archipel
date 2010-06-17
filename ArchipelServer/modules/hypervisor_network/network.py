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
from utils import *
import commands
import xmpp
import os
import archipel

try:
    import libvirt
except ImportError:
    pass



class TNHypervisorNetworks:
    
    def __init__(self, entity):
        self.entity = entity
        self.libvirt_connection = libvirt.open(None)
        if self.libvirt_connection == None:
            log.error( "unable to connect libvirt")
            sys.exit(0) 
        log.info( "connected to  libvirt")
    
    
    def process_iq_for_hypervisor(self, conn, iq):
        action = iq.getTag("query").getTag("archipel").getAttr("action")
        log.debug( "Network IQ received from %s with type %s" % (iq.getFrom(), action))
        
        if action == "define":
            reply = self.__module_network_define_network(iq)
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed
        
        if action == "undefine":
            reply = self.__module_network_undefine_network(iq)
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed
        
        if action == "create":
            reply = self.__module_network_create(iq)
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed
        
        if action == "destroy":
            reply = self.__module_network_destroy(iq)
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed
        
        if action == "list":
            reply = self.__module_network_list(iq)
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed
            
        if action == "bridges":
            reply = self.__module_network_bridges(iq)
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed
        
    
    
    def process_iq_for_virtualmachine(self, conn, iq):
        action = iq.getTag("query").getTag("archipel").getAttr("action")
        log.debug("Network IQ received from %s with type %s" % (iq.getFrom(), action))
        
        if action == "list":
            reply = self.__module_network_name_list(iq)
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed

        if action == "bridges":
            reply = self.__module_network_bridges(iq)
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed
    

    def __module_network_define_network(self, iq):
        """
        Define a virtual network in the libvirt according to the XML data
        network passed in argument
        
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ
        
        @rtype: xmpp.Protocol.Iq
        @return: a ready to send IQ containing the result of the action
        """
        try:
            network_node = iq.getTag("query").getTag("archipel").getTag("network")
            
            reply = iq.buildReply("result")
            self.libvirt_connection.networkDefineXML(str(network_node))
            log.info( "virtual network XML is defined")
            self.entity.push_change("network", "defined")
        except Exception as ex:
            reply = build_error_iq(self, ex, iq)
        return reply
    

    def __module_network_undefine_network(self, iq):
        """
        undefine a virtual network in the libvirt according to name passed in argument
        
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ
        
        @rtype: xmpp.Protocol.Iq
        @return: a ready to send IQ containing the result of the action
        """
        reply = None
        try:
            network_uuid = iq.getTag("query").getTag("archipel").getAttr("uuid")
            libvirt_network = self.libvirt_connection.networkLookupByUUIDString(network_uuid)
            libvirt_network.undefine()
            reply = iq.buildReply("result")
            log.info( "virtual network XML is undefined")
            self.entity.push_change("network", "undefined")
        except Exception as ex:
            reply = build_error_iq(self, ex, iq)
        return reply
    

    def __module_network_create(self, iq):
        """
        Create a network using libvirt connection
        
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ
        
        @rtype: xmpp.Protocol.Iq
        @return: a ready to send IQ containing the result of the action
        """
        reply = None
        try:
            network_uuid = iq.getTag("query").getTag("archipel").getAttr("uuid")
            libvirt_network = self.libvirt_connection.networkLookupByUUIDString(network_uuid)
            libvirt_network.create()
            reply = iq.buildReply("result")
            log.info( "virtual network created")
            self.entity.push_change("network", "created")
            self.entity.shout("disk", "Network %s has been started by %s." % (network_uuid, iq.getFrom()))
        except Exception as ex:
            reply = build_error_iq(self, ex, iq)
        return reply
    

    def __module_network_destroy(self, iq):
        """
        Destroy a network using libvirt connection
        
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ
        
        @rtype: xmpp.Protocol.Iq
        @return: a ready to send IQ containing the result of the action
        """
        reply = None
        try:
            network_uuid = iq.getTag("query").getTag("archipel").getAttr("uuid")
            libvirt_network = self.libvirt_connection.networkLookupByUUIDString(network_uuid)
            libvirt_network.destroy()
            reply = iq.buildReply("result")
            log.info( "virtual network destroyed")
            self.entity.push_change("network", "destroyed")
            self.entity.shout("disk", "Network %s has been shutdwned by %s." % (network_uuid, iq.getFrom()))
        except Exception as ex:
            reply = build_error_iq(self, ex, iq)
        return reply
    

    def __module_network_list(self, iq):
        """
        list all virtual networks
        
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ
        
        @rtype: xmpp.Protocol.Iq
        @return: a ready to send IQ containing the result of the action
        """
        try:
            reply = iq.buildReply("result")
            active_networks_nodes = [] 
            not_active_networks_nodes = [] #xmpp.Node(tag="unactivedNetworks")
        
            actives_networks_names = self.libvirt_connection.listNetworks()
            not_active_networks_names = self.libvirt_connection.listDefinedNetworks()
        
        
            for network_name in actives_networks_names:
                network = self.libvirt_connection.networkLookupByName(network_name)
                desc = network.XMLDesc(0)
                n = xmpp.simplexml.NodeBuilder(data=desc).getDom()
                active_networks_nodes.append(n)
        
            for network_name in not_active_networks_names:
                network = self.libvirt_connection.networkLookupByName(network_name)
                desc = network.XMLDesc(0)
                n = xmpp.simplexml.NodeBuilder(data=desc).getDom()
                not_active_networks_nodes.append(n)
            active_networks_root_node = xmpp.Node(tag="activedNetworks", payload=active_networks_nodes)
            not_active_networks_root_node = xmpp.Node(tag="unactivedNetworks", payload=not_active_networks_nodes)
            reply.setQueryPayload([active_networks_root_node, not_active_networks_root_node])
        except Exception as ex:
            reply = build_error_iq(self, ex, iq)
        return reply
    

    def __module_network_name_list(self, iq):
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
            actives_networks_names = self.libvirt_connection.listNetworks()
            for network_name in actives_networks_names:
                network = xmpp.Node(tag="network", attrs={"name": network_name})
                active_networks_nodes.append(network)
            reply.setQueryPayload(active_networks_nodes)
        except Exception as ex:
            reply = build_error_iq(self, ex, iq)
        return reply
    

    def __module_network_bridges(self, iq):
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
                bridge_name = line.split()[0];
                bridge_node = xmpp.Node(tag="bridge", attrs={"name": bridge_name})
                bridges_names.append(bridge_node)
            reply.setQueryPayload(bridges_names)
        except Exception as ex:
            reply = build_error_iq(self, ex, iq)
        return reply
    
