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
import libvirt

ARCHIPEL_ERROR_CODE_NETWORKS_DEFINE     = -7001
ARCHIPEL_ERROR_CODE_NETWORKS_UNDEFINE   = -7002
ARCHIPEL_ERROR_CODE_NETWORKS_CREATE     = -7003
ARCHIPEL_ERROR_CODE_NETWORKS_DESTROY    = -7004
ARCHIPEL_ERROR_CODE_NETWORKS_GET        = -7005
ARCHIPEL_ERROR_CODE_NETWORKS_BRIDGES    = -7006
ARCHIPEL_ERROR_CODE_NETWORKS_GETNAMES   = -7007

class TNHypervisorNetworks:
    
    def __init__(self, entity):
        self.entity = entity
        self.libvirt_connection = libvirt.open(self.entity.configuration.get("GLOBAL", "libvirt_uri"))
        if self.libvirt_connection == None:
            log.error( "unable to connect libvirt")
            sys.exit(0) 
        log.info( "connected to  libvirt")
    
    
    def process_iq_for_hypervisor(self, conn, iq):
        """
        this method is invoked when a NS_ARCHIPEL_HYPERVISOR_NETWORK IQ is received.
        
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
        try:
            action = iq.getTag("query").getTag("archipel").getAttr("action")
            log.info( "IQ RECEIVED: from: %s, type: %s, namespace: %s, action: %s" % (iq.getFrom(), iq.getType(), iq.getQueryNS(), action))
        except Exception as ex:
            reply = build_error_iq(self, ex, iq, NS_ARCHIPEL_ERROR_QUERY_NOT_WELL_FORMED)
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed
        
        if action == "define":
            reply = self.__define(iq)
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed
        
        elif action == "undefine":
            reply = self.__undefine(iq)
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed
        
        elif action == "create":
            reply = self.__create(iq)
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed
        
        elif action == "destroy":
            reply = self.__destroy(iq)
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed
        
        elif action == "get":
            reply = self.__get(iq)
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed
            
        elif action == "bridges":
            reply = self.__bridges(iq)
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed
        
        elif action == "getnames":
            reply = self.__get_names(iq)
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed
    
    
    def process_iq_for_virtualmachine(self, conn, iq):
        """
        this method is invoked when a NS_ARCHIPEL_HYPERVISOR_NETWORK IQ is received.
        
        it understands IQ of type:
            - bridges
            - getnames
        
        @type conn: xmpp.Dispatcher
        @param conn: ths instance of the current connection that send the stanza
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ
        """
        try:
            action = iq.getTag("query").getTag("archipel").getAttr("action")
            log.info( "IQ RECEIVED: from: %s, type: %s, namespace: %s, action: %s" % (iq.getFrom(), iq.getType(), iq.getQueryNS(), action))
        except Exception as ex:
            reply = build_error_iq(self, ex, iq, NS_ARCHIPEL_ERROR_QUERY_NOT_WELL_FORMED)
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed
        
        if action == "getnames":
            reply = self.__get_names(iq)
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed

        elif action == "bridges":
            reply = self.__bridges(iq)
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed
    

    def __define(self, iq):
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
        except libvirt.libvirtError as ex:
            reply = build_error_iq(self, ex, iq, ex.get_error_code(), ns=NS_LIBVIRT_GENERIC_ERROR)
        except Exception as ex:
            reply = build_error_iq(self, ex, iq, ARCHIPEL_ERROR_CODE_NETWORKS_DEFINE)
        return reply
    

    def __undefine(self, iq):
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
        except libvirt.libvirtError as ex:
            reply = build_error_iq(self, ex, iq, ex.get_error_code(), ns=NS_LIBVIRT_GENERIC_ERROR)
        except Exception as ex:
            reply = build_error_iq(self, ex, iq, ARCHIPEL_ERROR_CODE_NETWORKS_UNDEFINE)
        return reply
    

    def __create(self, iq):
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
            self.entity.shout("network", "Network %s has been started by %s." % (network_uuid, iq.getFrom()))
        except libvirt.libvirtError as ex:
            reply = build_error_iq(self, ex, iq, ex.get_error_code(), ns=NS_LIBVIRT_GENERIC_ERROR)
        except Exception as ex:
            reply = build_error_iq(self, ex, iq, ARCHIPEL_ERROR_CODE_NETWORKS_CREATE)
        return reply
    

    def __destroy(self, iq):
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
            self.entity.shout("network", "Network %s has been shutdwned by %s." % (network_uuid, iq.getFrom()))
        except libvirt.libvirtError as ex:
            reply = build_error_iq(self, ex, iq, ex.get_error_code(), ns=NS_LIBVIRT_GENERIC_ERROR)
        except Exception as ex:
            reply = build_error_iq(self, ex, iq, ARCHIPEL_ERROR_CODE_NETWORKS_DESTROY)
        return reply
    

    def __get(self, iq):
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
        except libvirt.libvirtError as ex:
            reply = build_error_iq(self, ex, iq, ex.get_error_code(), ns=NS_LIBVIRT_GENERIC_ERROR)
        except Exception as ex:
            reply = build_error_iq(self, ex, iq, ARCHIPEL_ERROR_CODE_NETWORKS_GET)
        return reply
    

    def __get_names(self, iq):
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
        except libvirt.libvirtError as ex:
            reply = build_error_iq(self, ex, iq, ex.get_error_code(), ns=NS_LIBVIRT_GENERIC_ERROR)
        except Exception as ex:
            reply = build_error_iq(self, ex, iq, ARCHIPEL_ERROR_CODE_NETWORKS_GETNAMES)
        return reply
    

    def __bridges(self, iq):
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
        except libvirt.libvirtError as ex:
            reply = build_error_iq(self, ex, iq, ex.get_error_code(), ns=NS_LIBVIRT_GENERIC_ERROR)
        except Exception as ex:
            reply = build_error_iq(self, ex, iq, ARCHIPEL_ERROR_CODE_NETWORKS_BRIDGES)
        return reply
    
