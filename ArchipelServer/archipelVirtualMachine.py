# 
# archipelVirtualMachine.py
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



"""
Contains ArchipelVirtualMachine, the XMPP capable controller

This module contain the class ArchipelVirtualMachine that represents a virtual machine
linked to a libvirt domain and allowing other XMPP entities to control it using IQ.

The ArchipelVirtualMachine is able to register to any kind of XMPP compliant Server. These 
Server SHOULD allow in-band registration, or you have to manually register VM before 
launching them.

Also the JID of the virtual machine MUST be the UUID use in the libvirt domain, or it will
fail.
"""
import xmpp
import sys
import socket
import os
import commands
from utils import *
from archipelBasicXMPPClient import *

NS_ARCHIPEL_WITH_LIBVIRT_MODULE = True
try:
    import libvirt
except ImportError:
    NS_ARCHIPEL_WITH_LIBVIRT_MODULE = False


VIR_DOMAIN_NOSTATE	                        =	0;
VIR_DOMAIN_RUNNING	                        =	1;
VIR_DOMAIN_BLOCKED	                        =	2;
VIR_DOMAIN_PAUSED	                        =	3;
VIR_DOMAIN_SHUTDOWN	                        =	4;
VIR_DOMAIN_SHUTOFF	                        =	5;
VIR_DOMAIN_CRASHED	                        =	6;

NS_ARCHIPEL_VM_CONTROL      = "archipel:vm:control"
NS_ARCHIPEL_VM_DEFINITION   = "archipel:vm:definition"

class TNArchipelVirtualMachine(TNArchipelBasicXMPPClient):
    """
    this class represent an Virtual Machine, XMPP Capable.
    this class need to already have 
    """
    
    ######################################################################################################
    ###  Super methods overrided
    ######################################################################################################
    
    def __init__(self, jid, password, hypervisor, configuration):
        TNArchipelBasicXMPPClient.__init__(self, jid, password, configuration)
        
        self.vm_disk_base_path  = self.configuration.get("VIRTUALMACHINE", "disk_base_path") + "/"
        self.vm_own_folder      = self.vm_disk_base_path + str(self.jid.getNode());
        
        if NS_ARCHIPEL_WITH_LIBVIRT_MODULE:
            self.libvirt_connection = None;
            self.register_actions_to_perform_on_auth("connect_libvirt", None)
        
        default_avatar = self.configuration.get("VIRTUALMACHINE", "vm_default_avatar")
        self.register_actions_to_perform_on_auth("set_vcard_entity_type", {"entity_type": "virtualmachine", "avatar_file": default_avatar})
        self.hypervisor = hypervisor;
        
        if not os.path.isdir(self.vm_own_folder):
            os.mkdir(self.vm_own_folder);
    
    
    def register_handler(self):
        """
        this method registers the events handlers.
        it is invoked by super class __xmpp_connect() method
        """
        self.xmppclient.RegisterHandler('iq', self.__process_iq_archipel_control, typ=NS_ARCHIPEL_VM_CONTROL)
        self.xmppclient.RegisterHandler('iq', self.__process_iq_archipel_definition, typ=NS_ARCHIPEL_VM_DEFINITION)
        #self.xmppclient.RegisterHandler('iq', self.__process_iq_archipel_disk, typ=NS_ARCHIPEL_VM_DISK)
        
        TNArchipelBasicXMPPClient.register_handler(self)
    
    
    def disconnect(self):
        """
        Close the connections to libvirt and XMPP server. it overrides the super class 
        method in order to connect also from libvirt
        """
        self.xmppclient.disconnect()
        
        if NS_ARCHIPEL_WITH_LIBVIRT_MODULE:
            if self.libvirt_connection:
                self.libvirt_connection.close() 
    
    
    def remove_own_folder(self):
        """
        remove the folder of the virtual with all its contents
        """
        os.system("rm -rf " + self.vm_own_folder);
    
    
    
    ######################################################################################################
    ### Libvirt bindings
    ###################################################################################################### 
    
    # iq control
    
    def connect_libvirt(self):
        """
        Initialize the connection to the libvirt first, and
        then to the domain by looking the uuid used as JID Node
        
        exit on any error.
        """
        if not NS_ARCHIPEL_WITH_LIBVIRT_MODULE:
            return
        self.push_change("virtualmachine", "initialized");
        
        self.domain = None;
        self.libvirt_connection = None;
        
        self.uuid = self.jid.getNode()
        self.libvirt_connection = libvirt.open(None)
        if self.libvirt_connection == None:
            log(self, LOG_LEVEL_ERROR, "unable to connect hypervisor")
            sys.exit(0) 
        log(self, LOG_LEVEL_INFO, "connected to hypervisor using libvirt")
        
        try:
            self.domain = self.libvirt_connection.lookupByUUIDString(self.uuid)
            log(self, LOG_LEVEL_INFO, "sucessfully connect to domain uuid {0}".format(self.uuid))
            
            dominfo = self.domain.info()
            if dominfo[0] == VIR_DOMAIN_RUNNING:
                self.change_presence("", "shutdown");
            elif dominfo[0] == VIR_DOMAIN_PAUSED:
                self.change_presence("away", "shutdown");
            elif dominfo[0] == VIR_DOMAIN_SHUTOFF or dominfo[0] == VIR_DOMAIN_SHUTDOWN:
                self.change_presence("xa", "shutdown");
            
        except libvirt.libvirtError as ex:
            if ex.get_error_code() == 42:
                log(self, LOG_LEVEL_INFO, "Exception raised #{0} : {1}".format(ex.get_error_code(), ex))
                self.change_presence("dnd", "shutdown");
            else:
                log(self, LOG_LEVEL_ERROR, "Exception raised #{0} : {1}".format(ex.get_error_code(), ex))
        except Exception as ex:
            log(self, LOG_LEVEL_ERROR, "unexpected exception")
            sys.exit(0)
    
    
    def create(self, iq):
        """
        Create a domain using libvirt connection
        
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ
        
        @rtype: xmpp.Protocol.Iq
        @return: a ready to send IQ containing the result of the action
        """
        if not NS_ARCHIPEL_WITH_LIBVIRT_MODULE:
            return
        
        reply = None
        try:
            self.domain.create()
            reply = iq.buildReply('success')
            payload = xmpp.Node("domain", attrs={"id": str(self.domain.ID())})
            reply.setQueryPayload([payload])
            log(self, LOG_LEVEL_INFO, "virtual machine created")
            self.change_presence("", "Running");
            self.push_change("virtualmachine", "created")
        except Exception as ex:
            reply = build_error_iq(self, ex, iq)
        return reply
    
    
    def shutdown(self, iq):
        """
        Shutdown a domain using libvirt connection
        
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ
        
        @rtype: xmpp.Protocol.Iq
        @return: a ready to send IQ containing the result of the action
        """
        if not NS_ARCHIPEL_WITH_LIBVIRT_MODULE:
            return
        
        reply = None
        try:
            self.domain.shutdown()
            reply = iq.buildReply('success')
            log(self, LOG_LEVEL_INFO, "virtual machine shutdowned")
            self.change_presence("xa", "shutdown");
            self.push_change("virtualmachine", "shutdowned")
        except Exception as ex:
            reply = build_error_iq(self, ex, iq)
        return reply
    
    
    def reboot(self, iq):
        """
        Reboot a domain using libvirt connection
        
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ
        
        @rtype: xmpp.Protocol.Iq
        @return: a ready to send IQ containing the result of the action
        """
        if not NS_ARCHIPEL_WITH_LIBVIRT_MODULE:
            return
        
        reply = None
        try:
            self.domain.reboot(0) # flags not used in libvirt but required.
            reply = iq.buildReply('success')
            log(self, LOG_LEVEL_INFO, "virtual machine rebooted")
            self.push_change("virtualmachine", "rebooted")
        except Exception as ex:
            reply = build_error_iq(self, ex, iq)
        return reply
    
    
    def suspend(self, iq):
        """
        Suspend (pause) a domain using libvirt connection
        
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ
        
        @rtype: xmpp.Protocol.Iq
        @return: a ready to send IQ containing the result of the action
        """
        if not NS_ARCHIPEL_WITH_LIBVIRT_MODULE:
            return
        
        reply = None
        try:
            self.domain.suspend()
            reply = iq.buildReply('success')
            log(self, LOG_LEVEL_INFO, "virtual machine suspended")
            self.change_presence("away", "paused");
            self.push_change("virtualmachine", "suspended")
        except Exception as ex:
            reply = build_error_iq(self, ex, iq)
        return reply
    
    
    def resume(self, iq):
        """
        Resume (unpause) a domain using libvirt connection
        
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ
        
        @rtype: xmpp.Protocol.Iq
        @return: a ready to send IQ containing the result of the action
        """
        if not NS_ARCHIPEL_WITH_LIBVIRT_MODULE:
            return
        
        reply = None
        try:
            self.domain.resume()
            reply = iq.buildReply('success')
            log(self, LOG_LEVEL_INFO, "virtual machine resumed")
            self.change_presence("", "running");
            self.push_change("virtualmachine", "resumed")
        except Exception as ex:
            reply = build_error_iq(self, ex, iq)
        return reply
    
    
    def info(self, iq):
        """
        Return an IQ containing the info of the domain using libvirt connection
        
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ
        
        @rtype: xmpp.Protocol.Iq
        @return: a ready to send IQ containing the result of the action
        """
        if not NS_ARCHIPEL_WITH_LIBVIRT_MODULE:
            return
        
        reply = None
        try:
            reply = iq.buildReply('success')
            if self.domain:
                dominfo = self.domain.info()
                response = xmpp.Node(tag="info", attrs={"state": dominfo[0], "maxMem": dominfo[1], "memory": dominfo[2], "nrVirtCpu": dominfo[3], "cpuTime": dominfo[4], "hypervisor": self.hypervisor.jid})
                reply.setQueryPayload([response])
                log(self, LOG_LEVEL_DEBUG, "virtual machine info sent")
            else:
                reply = iq.buildReply('error')  
        except Exception as ex:
            reply = build_error_iq(self, ex, iq)
        return reply
    
    
    def vncdisplay(self, iq):
        """
        get the VNC display used in the virtual machine.
        
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ
        
        @rtype: xmpp.Protocol.Iq
        @return: a ready to send IQ containing the result of the action
        """
        reply = None
        try:
            reply = iq.buildReply('success')                
            xmldesc = self.domain.XMLDesc(0);
            xmldescnode = xmpp.simplexml.NodeBuilder(data=xmldesc).getDom();
            graphicnode = xmldescnode.getTag(name="devices").getTag(name="graphics");
            payload = xmpp.Node("vncdisplay", attrs={"port": str(graphicnode.getAttr("port")), "host": self.ipaddr})
            reply.setQueryPayload([payload])
        except Exception as ex:
            reply = build_error_iq(self, ex, iq)
        return reply
    
    
    def xml_description(self, iq):
        """
        get the XML Desc of the virtual machine.
        
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ
        
        @rtype: xmpp.Protocol.Iq
        @return: a ready to send IQ containing the result of the action
        """
        reply = None
        try:
            reply = iq.buildReply('success')
            xmldesc = self.domain.XMLDesc(0);
            xmldescnode = xmpp.simplexml.NodeBuilder(data=xmldesc).getDom();
            reply.setQueryPayload([xmldescnode])
        except Exception as ex:
            reply = build_error_iq(self, ex, iq)
        return reply
    
    
    
    # iq definition
    
    def define(self, iq):
       """
       Define a virtual machine in the libvirt according to the XML data
       domain passed in argument
       
       @type iq: xmpp.Protocol.Iq
       @param iq: the received IQ
       
       @rtype: xmpp.Protocol.Iq
       @return: a ready to send IQ containing the result of the action
       """
       if not NS_ARCHIPEL_WITH_LIBVIRT_MODULE:
           return
       
       reply = None
       
       try :
           domain_node = iq.getTag("query").getTag("domain");
           
           domain_uuid = domain_node.getTag("uuid").getData()
           if domain_uuid != self.jid.getNode():
               raise Exception('IncorrectUUID', "given UUID {0} doesn't match JID {1}".format(domain_uuid, self.jid.getNode()))
           
           reply = iq.buildReply('success')
           
           # the dirty replace below is to avoid having this xmlns wrote by xmpp.Node automatically.
           # I've sepnd two hours, trying to remove it, I'm done.
           self.libvirt_connection.defineXML(str(domain_node).replace('xmlns="http://www.gajim.org/xmlns/undeclared" ', ''))
           log(self, LOG_LEVEL_INFO, "virtual machine XML is defined")
           if not self.domain:
               self.connect_libvirt()
           self.push_change("virtualmachine:definition", "defined")
       except Exception as ex:
           reply = build_error_iq(self, ex, iq)
       return reply
    
    
    def undefine(self, iq):
        """
        Undefine a virtual machine in the libvirt according to the XML data
        domain passed in argument
        
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ
        
        @rtype: xmpp.Protocol.Iq
        @return: a ready to send IQ containing the result of the action
        """
        if not NS_ARCHIPEL_WITH_LIBVIRT_MODULE:
            return
        
        reply = None
        try:
            reply = iq.buildReply('success')
            self.domain.undefine()
            log(self, LOG_LEVEL_INFO, "virtual machine is undefined")
            self.push_change("virtualmachine:definition", "undefined")
        except Exception as ex:
            reply = build_error_iq(self, ex, iq)
        return reply
    
    
    
    ######################################################################################################
    ### XMPP Processing
    ######################################################################################################
    
    def __process_iq_archipel_control(self, conn, iq):
        """
        Invoked when new archipel:vm:control IQ is received. 
        
        it understands IQ of type:
            - info
            - create
            - shutdown
            - reboot
            - suspend
            - resume
        
        @type conn: xmpp.Dispatcher
        @param conn: ths instance of the current connection that send the message
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ
        """
        if not NS_ARCHIPEL_WITH_LIBVIRT_MODULE:
            return
        
        
        log(self, LOG_LEVEL_DEBUG, "Control IQ received from {0} with type {1}".format(iq.getFrom(), iq.getType()))
        
        iqType = iq.getTag("query").getAttr("type");
        
        if iqType == "info":
            reply = self.info(iq)
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed
            
        if iqType == "create":
            reply = self.create(iq)
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed
            
        if iqType == "shutdown":
            reply = self.shutdown(iq)
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed
            
        if iqType == "reboot":
            reply = self.reboot(iq)
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed
            
        if iqType == "suspend":
            reply = self.suspend(iq)
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed
            
        if iqType == "resume":
            reply = self.resume(iq)
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed
            
        if iqType == "vncdisplay":
            reply = self.vncdisplay(iq)
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed
            
        if iqType == "xmldesc":
            reply = self.xml_description(iq)
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed
            
        # if iqType == "networkstats":
        #     reply = self.__networkstats(iq)
        #     conn.send(reply)
        #     raise xmpp.protocol.NodeProcessed
    
    
    def __process_iq_archipel_definition(self, conn, iq):
        """
        Invoked when new archipel:define IQ is received.
        
        it understands IQ of type:
            - define (the domain xml must be sent as payload of IQ, and the uuid *MUST*, be the same as the JID of the client)
            - undefine (undefine a virtual machine domain)
        
        @type conn: xmpp.Dispatcher
        @param conn: ths instance of the current connection that send the message
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ
        """
        
        if not NS_ARCHIPEL_WITH_LIBVIRT_MODULE:
            return
        
        log(self, LOG_LEVEL_DEBUG, "Definition IQ received from {0} with type {1}".format(iq.getFrom(), iq.getType()))
        
        iqType = iq.getTag("query").getAttr("type");
        
        if iqType == "define":
            reply = self.define(iq)
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed
        
        if iqType == "undefine":
            reply = self.undefine(iq)
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed        
    
    

