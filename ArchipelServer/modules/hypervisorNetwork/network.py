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
import archipel
import commands
import xmpp
import os
import libvirt

NS_ARCHIPEL_HYPERVISOR_NETWORK = "trinity:hypervisor:network"


######################################################################################################
### Registring of the stanza
######################################################################################################

def __module_init__network_management(self):
    self.libvirt_networks = [];
    self.register_actions_to_perform_on_auth("__module_network_connect_network", None)


def __module_register_stanza__network_management(self):
    self.xmppclient.RegisterHandler('iq', self.__process_iq_trinity_network, typ=NS_ARCHIPEL_HYPERVISOR_NETWORK)



# def __module_network_connect_network(self):
#     networks_names = self.libvirt_connection.listNetworks();
#     for network_name in networks_names:
#         self.libvirt_networks.append(self.libvirt_connection.networkLookupByName(network_name));



def __process_iq_trinity_network_for_hypervisor(self, conn, iq):
    log(self, LOG_LEVEL_INFO, "received network iq");
    
    iqType = iq.getTag("query").getAttr("type");
    
    if iqType == "define":
        reply = self.__module_network_define_network(iq)
        conn.send(reply)
        raise xmpp.protocol.NodeProcessed
        
    if iqType == "undefine":
        reply = self.__module_network_undefine_network(iq)
        conn.send(reply)
        raise xmpp.protocol.NodeProcessed
        
    if iqType == "create":
        reply = self.__module_network_create(iq)
        conn.send(reply)
        raise xmpp.protocol.NodeProcessed
    
    if iqType == "destroy":
        reply = self.__module_network_destroy(iq)
        conn.send(reply)
        raise xmpp.protocol.NodeProcessed
    
    if iqType == "list":
        reply = self.__module_network_list(iq)
        conn.send(reply)
        raise xmpp.protocol.NodeProcessed


def __process_iq_trinity_network_for_virtualmachine(self, conn, iq):
    log(self, LOG_LEVEL_INFO, "received network iq");
    
    iqType = iq.getTag("query").getAttr("type");
    
    if iqType == "list":
        reply = self.__module_network_list(iq)
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
    reply = None
    try:
        network_node = iq.getTag("query").getTag("network");
        
        reply = iq.buildReply('success')
        self.libvirt_connection.networkDefineXML(str(network_node))
        log(self, LOG_LEVEL_INFO, "virtual network XML is defined")
        
    except libvirt.libvirtError as ex:
        log(self, LOG_LEVEL_ERROR, "exception raised is : {0}".format(ex))
        reply = iq.buildReply('error')
        payload = xmpp.Node("error", attrs={"code": str(ex.get_error_code())})
        payload.addData(str(ex))
        reply.setQueryPayload([payload])
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
        network_uuid = iq.getTag("query").getData();
        libvirt_network = self.libvirt_connection.networkLookupByUUIDString(network_uuid)
        libvirt_network.undefine();
        reply = iq.buildReply('success')
        log(self, LOG_LEVEL_INFO, "virtual network XML is undefined")
    except libvirt.libvirtError as ex:
        log(self, LOG_LEVEL_ERROR, "exception raised is : {0}".format(ex))
        reply = iq.buildReply('error')
        payload = xmpp.Node("error", attrs={"code": str(ex.get_error_code())})
        payload.addData(str(ex))
        reply.setQueryPayload([payload])
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
        network_uuid = iq.getTag("query").getData();
        libvirt_network = self.libvirt_connection.networkLookupByUUIDString(network_uuid)
        libvirt_network.create()
        reply = iq.buildReply('success')
        log(self, LOG_LEVEL_INFO, "virtual network created")
    except libvirt.libvirtError as ex:
        log(self, LOG_LEVEL_ERROR, "exception raised is : {0}".format(ex))
        reply = iq.buildReply('error')
        payload = xmpp.Node("error", attrs={"code": str(ex.get_error_code())})
        payload.addData(str(ex))
        reply.setQueryPayload([payload])
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
        network_uuid = iq.getTag("query").getData();
        libvirt_network = self.libvirt_connection.networkLookupByUUIDString(network_uuid)
        libvirt_network.destroy()
        reply = iq.buildReply('success')
        log(self, LOG_LEVEL_INFO, "virtual network destroyed")
    except libvirt.libvirtError as ex:
        log(self, LOG_LEVEL_ERROR, "exception raised is : {0}".format(ex))
        reply = iq.buildReply('error')
        payload = xmpp.Node("error", attrs={"code": str(ex.get_error_code())})
        payload.addData(str(ex))
        reply.setQueryPayload([payload])
    return reply


def __module_network_list(self, iq):
    """
    list all virtual networks
    
    @type iq: xmpp.Protocol.Iq
    @param iq: the received IQ
    
    @rtype: xmpp.Protocol.Iq
    @return: a ready to send IQ containing the result of the action
    """
    reply = iq.buildReply('success')
    active_networks_nodes = []; 
    not_active_networks_nodes = []; #xmpp.Node(tag="unactivedNetworks");
    
    actives_networks_names = self.libvirt_connection.listNetworks();
    not_active_networks_names = self.libvirt_connection.listDefinedNetworks();
    
    
    for network_name in actives_networks_names:
        network = self.libvirt_connection.networkLookupByName(network_name);
        desc = network.XMLDesc(0);
        n = xmpp.simplexml.NodeBuilder(data=desc).getDom();
        active_networks_nodes.append(n)
        
    for network_name in not_active_networks_names:
        network = self.libvirt_connection.networkLookupByName(network_name);
        desc = network.XMLDesc(0);
        n = xmpp.simplexml.NodeBuilder(data=desc).getDom();
        not_active_networks_nodes.append(n)
    
    active_networks_root_node = xmpp.Node(tag="activedNetworks", payload=active_networks_nodes);
    not_active_networks_root_node = xmpp.Node(tag="unactivedNetworks", payload=not_active_networks_nodes);
    
    reply.setQueryPayload([active_networks_root_node, not_active_networks_root_node])
    return reply;
        
    


def __module_network_name_list(self, iq):
    """
    list all virtual networks name

    @type iq: xmpp.Protocol.Iq
    @param iq: the received IQ

    @rtype: xmpp.Protocol.Iq
    @return: a ready to send IQ containing the result of the action
    """
    reply = iq.buildReply('success')
    active_networks_nodes = []; 

    actives_networks_names = self.libvirt_connection.listNetworks();

    for network_name in actives_networks_names:
        network = xmpp.Node(tag="network", attrs={"name": network_name})
        active_networks_nodes.append(network)

    reply.setQueryPayload(active_networks_nodes)
    return reply;





setattr(archipel.TNArchipelHypervisor, "__module_init__network_management", __module_init__network_management)
setattr(archipel.TNArchipelHypervisor, "__module_register_stanza__network_management", __module_register_stanza__network_management)
# setattr(archipel.TNArchipelHypervisor, "__module_network_connect_network", __module_network_connect_network)
setattr(archipel.TNArchipelHypervisor, "__process_iq_trinity_network", __process_iq_trinity_network_for_hypervisor)
setattr(archipel.TNArchipelHypervisor, "__module_network_define_network", __module_network_define_network)
setattr(archipel.TNArchipelHypervisor, "__module_network_undefine_network", __module_network_undefine_network)
setattr(archipel.TNArchipelHypervisor, "__module_network_create", __module_network_create)
setattr(archipel.TNArchipelHypervisor, "__module_network_destroy", __module_network_destroy)
setattr(archipel.TNArchipelHypervisor, "__module_network_list", __module_network_list)


setattr(archipel.TNArchipelVirtualMachine, "__module_register_stanza__network_management", __module_register_stanza__network_management);
setattr(archipel.TNArchipelVirtualMachine, "__process_iq_trinity_network", __process_iq_trinity_network_for_virtualmachine)
setattr(archipel.TNArchipelVirtualMachine, "__module_network_list", __module_network_name_list)