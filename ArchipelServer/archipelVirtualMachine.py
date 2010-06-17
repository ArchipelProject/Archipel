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

try:
    import libvirt
except ImportError:
    pass


VIR_DOMAIN_NOSTATE	            = 0
VIR_DOMAIN_RUNNING	            = 1
VIR_DOMAIN_BLOCKED	            = 2
VIR_DOMAIN_PAUSED	            = 3
VIR_DOMAIN_SHUTDOWN	            = 4
VIR_DOMAIN_SHUTOFF	            = 5
VIR_DOMAIN_CRASHED	            = 6

NS_ARCHIPEL_STATUS_RUNNING      = "Running"
NS_ARCHIPEL_STATUS_PAUSED       = "Paused"
NS_ARCHIPEL_STATUS_SHUTDOWNED   = "Off"
NS_ARCHIPEL_STATUS_ERROR        = "Error"
NS_ARCHIPEL_STATUS_NOT_DEFINED  = "Not defined"

NS_ARCHIPEL_VM_CONTROL          = "archipel:vm:control"
NS_ARCHIPEL_VM_DEFINITION       = "archipel:vm:definition"
NS_ARCHIPEL_VM_DEPENDENCE       = "archipel:vm:dependence"

NS_ARCHIPEL_VM_DEPENDENCE_TYPE_LIBVIRT_STATE    = "NS_ARCHIPEL_VM_DEPENDENCE_TYPE_LIBVIRT_STATE";
NS_ARCHIPEL_VM_DEPENDENCE_TYPE_UNIX_CMD         = "NS_ARCHIPEL_VM_DEPENDENCE_TYPE_UNIX_CMD";

class TNArchipelVirtualMachineRunningState:
    
    def __init__(self, vm, check_type=NS_ARCHIPEL_VM_DEPENDENCE_TYPE_LIBVIRT_STATE, command=None, result=VIR_DOMAIN_RUNNING):
        self.vm = vm
        self.check_type = check_type
        self.command = command
        self.result = result
    
    def process_check(self):
        if self.check_type == NS_ARCHIPEL_VM_DEPENDENCE_TYPE_LIBVIRT_STATE:
            if self.vm.info()[0] == self.result:
                return True
        
        if self.check_type == NS_ARCHIPEL_VM_DEPENDENCE_TYPE_UNIX_CMD:
            if command.getoutput(self.command) == self.result:
                return True
        
        return False
        



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
        
        self.vm_disk_base_path  = self.configuration.get("VIRTUALMACHINE", "vm_base_path") + "/"
        self.vm_own_folder      = self.vm_disk_base_path + str(self.jid.getNode())
        
        self.libvirt_connection = None
        self.register_actions_to_perform_on_auth("connect_libvirt", None)
        
        default_avatar = self.configuration.get("VIRTUALMACHINE", "vm_default_avatar")
        # whooo... this technic is dirty. was I drunk ? TODO! FIXME!
        self.register_actions_to_perform_on_auth("set_vcard_entity_type", {"entity_type": "virtualmachine", "avatar_file": default_avatar})
        self.hypervisor = hypervisor
        self.definition = None;
        if not os.path.isdir(self.vm_own_folder):
            os.mkdir(self.vm_own_folder)
            
        self.register_for_messages()
    
    
    def register_for_messages(self):
        """
        this method register for user messages
        """
        registrar_items = [
                            {  "commands" : ["start", "create", "boot", "play", "run"], 
                                "parameters": [],
                                "method": self.message_create,
                                "description": "I'll start" },
                            
                            {  "commands" : ["shutdown", "stop"], 
                                "parameters": [],
                                "method": self.message_shutdown,
                                "description": "I'll shutdown" },
                                
                            {  "commands" : ["destroy"], 
                                "parameters": [],
                                "method": self.message_destroy,
                                "description": "I'll destroy myself" },
                                
                            {  "commands" : ["pause", "suspend"], 
                                "parameters": [],
                                "method": self.message_suspend,
                                "description": "I'll suspend" },
                            
                            {  "commands" : ["resume", "unpause"], 
                                "parameters": [],
                                "method": self.message_resume,
                                "description": "I'll resume" },
                            
                            {  "commands" : ["info", "how are you"], 
                                "parameters": [],
                                "method": self.message_info,
                                "description": "I'll give info about me" },
                            
                            {  "commands" : ["vnc", "display"], 
                                "parameters": [],
                                "method": self.message_vncdisplay,
                                "description": "I'll show my VNC port" },
                                
                            {  "commands" : ["desc", "xml"], 
                                "parameters": [],
                                "method": self.message_xmldesc,
                                "description": "I'll show my description" },
                        ]
        self.add_message_registrar_items(registrar_items)
        
    
    
    def register_handler(self):
        """
        this method registers the events handlers.
        it is invoked by super class __xmpp_connect() method
        """
        self.xmppclient.RegisterHandler('iq', self.__process_iq_archipel_control, ns=NS_ARCHIPEL_VM_CONTROL)
        self.xmppclient.RegisterHandler('iq', self.__process_iq_archipel_definition, typ=NS_ARCHIPEL_VM_DEFINITION)
        
        TNArchipelBasicXMPPClient.register_handler(self)
    
    
    def disconnect(self):
        """
        Close the connections to libvirt and XMPP server. it overrides the super class 
        method in order to connect also from libvirt
        """
        self.xmppclient.disconnect()
        
        if self.libvirt_connection:
            self.libvirt_connection.close() 
    
    
    def remove_own_folder(self):
        """
        remove the folder of the virtual with all its contents
        """
        os.system("rm -rf " + self.vm_own_folder)
    
    
    def connect_libvirt(self):
        """
        Initialize the connection to the libvirt first, and
        then to the domain by looking the uuid used as JID Node

        exit on any error.
        """

        self.push_change("virtualmachine", "initialized")

        self.domain = None
        self.libvirt_connection = None

        self.uuid = self.jid.getNode()
        self.libvirt_connection = libvirt.open(None)
        if self.libvirt_connection == None:
            log.error("unable to connect hypervisor")
            sys.exit(0) 
        log.info("connected to hypervisor using libvirt")

        try:
            self.domain = self.libvirt_connection.lookupByUUIDString(self.uuid)
            log.info("sucessfully connect to domain uuid {0}".format(self.uuid))

            if self.domain:
                self.definition = xmpp.simplexml.NodeBuilder(data=str(self.domain.XMLDesc(0))).getDom()

            # register for libvirt handlers            
            self.libvirt_connection.domainEventRegister(self.on_domain_event,None)

            dominfo = self.domain.info()
            log.info("virtual machine state is %d" %  dominfo[0])
            if dominfo[0] == VIR_DOMAIN_RUNNING:
                self.change_presence("", NS_ARCHIPEL_STATUS_RUNNING)
            elif dominfo[0] == VIR_DOMAIN_PAUSED:
                self.change_presence("away", NS_ARCHIPEL_STATUS_PAUSED)
            elif dominfo[0] == VIR_DOMAIN_SHUTOFF or dominfo[0] == VIR_DOMAIN_SHUTDOWN:
                self.change_presence("xa", NS_ARCHIPEL_STATUS_SHUTDOWNED)
        except libvirt.libvirtError as ex:
            if ex.get_error_code() == 42:
                log.info("Exception raised #{0} : {1}".format(ex.get_error_code(), ex))
                self.domain = None
                self.change_presence("xa", NS_ARCHIPEL_STATUS_NOT_DEFINED)
            else:
                log.error("Exception raised #{0} : {1}".format(ex.get_error_code(), ex))
                self.change_presence("dnd", NS_ARCHIPEL_STATUS_ERROR)
        except Exception as ex:
            log.error("unexpected exception : " + str(ex))
            sys.exit(0)
    

    def on_domain_event(self, conn, dom, event, detail, opaque):
        if dom.UUID() == self.domain.UUID():
            log.info("libvirt event received: %d with detail %s" % (event, detail))
            
            try:
                if event == libvirt.VIR_DOMAIN_EVENT_STARTED:
                    self.change_presence("", NS_ARCHIPEL_STATUS_RUNNING)
                    self.push_change("virtualmachine:control", "created")
                elif event == libvirt.VIR_DOMAIN_EVENT_SUSPENDED:
                    self.change_presence("away", NS_ARCHIPEL_STATUS_PAUSED)
                    self.push_change("virtualmachine:control", "suspended")
                elif event == libvirt.VIR_DOMAIN_EVENT_RESUMED:
                    self.change_presence("", NS_ARCHIPEL_STATUS_RUNNING)
                    self.push_change("virtualmachine:control", "resumed")
                elif event == libvirt.VIR_DOMAIN_EVENT_STOPPED:
                    self.change_presence("xa", NS_ARCHIPEL_STATUS_SHUTDOWNED)
                    self.push_change("virtualmachine:control", "shutdowned")
                elif event == libvirt.VIR_DOMAIN_EVENT_UNDEFINED:
                    self.change_presence("xa", NS_ARCHIPEL_STATUS_NOT_DEFINED)
                    self.push_change("virtualmachine:definition", "undefined")
                elif event == libvirt.VIR_DOMAIN_EVENT_DEFINED:
                    self.change_presence("xa", NS_ARCHIPEL_STATUS_SHUTDOWNED)
                    self.push_change("virtualmachine:definition", "defined")
            except Exception as ex:
                log.error("Unable to push state change : %s" % str(ex))
    

    
    
    ######################################################################################################
    ### Libvirt bindings
    ###################################################################################################### 
    
    # iq control
    
    def create(self):
        self.domain.create()
        log.info("virtual machine created")
        return str(self.domain.ID())
    
    
    def iq_create(self, iq):
        """
        Create a domain using libvirt connection

        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ

        @rtype: xmpp.Protocol.Iq
        @return: a ready to send IQ containing the result of the action
        """

        reply = None
        try:
            domid = self.create()
            reply = iq.buildReply("result")
            payload = xmpp.Node("domain", attrs={"id": domid})
            reply.setQueryPayload([payload])
        except Exception as ex:
            reply = build_error_iq(self, ex, iq)
        return reply

    
    
    def message_create(self, msg):
        try:
            self.create()
            return "I'm starting"
        except Exception as ex:
            return build_error_message(self, ex)
    
    
    
    def shutdown(self):
        self.domain.shutdown()
        log.info("virtual machine shutdowned")
    
    
    def iq_shutdown(self, iq):
        """
        Shutdown a domain using libvirt connection
        
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ
        
        @rtype: xmpp.Protocol.Iq
        @return: a ready to send IQ containing the result of the action
        """
        
        reply = None
        try:
            self.shutdown()
            reply = iq.buildReply("result")
        except Exception as ex:
            reply = build_error_iq(self, ex, iq)
        return reply
    
    
    def message_shutdown(self, msg):
        try:
            self.shutdown()
            return "I'm shutdowning"
        except Exception as ex:
            return build_error_message(self, ex)
    
    
    
    def destroy(self):
        self.domain.destroy()
    
    
    def iq_destroy(self, iq):
        """
        Destroy a domain using libvirt connection

        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ

        @rtype: xmpp.Protocol.Iq
        @return: a ready to send IQ containing the result of the action
        """

        reply = None
        try:
            self.destroy()
            reply = iq.buildReply("result")
            log.info("virtual machine destroyed")
        except Exception as ex:
            reply = build_error_iq(self, ex, iq)
        return reply
    
    
    def message_destroy(self, msg):
        try:
            self.destroy()
            return "I've destroyed myself"
        except Exception as ex:
            return build_error_message(self, ex)
    
    
    
    def reboot(self):
        self.domain.reboot(0) # flags not used in libvirt but required.
        log.info("virtual machine rebooted")
    
    
    def iq_reboot(self, iq):
        """
        Reboot a domain using libvirt connection
        
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ
        
        @rtype: xmpp.Protocol.Iq
        @return: a ready to send IQ containing the result of the action
        """
        
        reply = None
        try:
            self.reboot()
            reply = iq.buildReply("result")
        except Exception as ex:
            reply = build_error_iq(self, ex, iq)
        return reply
    
    
    def message_reboot(self, msg):
        try:
            self.reboot()
            return "I try to reboot"
        except Exception as ex:
            return build_error_message(self, ex)
    
    
    
    def suspend(self):
        self.domain.suspend()
        log.info("virtual machine suspended")
    
    
    def iq_suspend(self, iq):
        """
        Suspend (pause) a domain using libvirt connection
        
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ
        
        @rtype: xmpp.Protocol.Iq
        @return: a ready to send IQ containing the result of the action
        """
        reply = None
        try:
            self.suspend()
            reply = iq.buildReply("result")
        except Exception as ex:
            reply = build_error_iq(self, ex, iq)
        return reply
    
    
    def message_suspend(self, msg):
        try:
            self.suspend()
            return "I'm suspended"
        except Exception as ex:
            return build_error_message(self, ex)
    
    
    
    def resume(self):
        self.domain.resume()
        log.info("virtual machine resumed")
    

    def iq_resume(self, iq):
        """
        Resume (unpause) a domain using libvirt connection
        
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ
        
        @rtype: xmpp.Protocol.Iq
        @return: a ready to send IQ containing the result of the action
        """
        
        reply = None
        try:
            self.resume()
            reply = iq.buildReply("result")
        except Exception as ex:
            reply = build_error_iq(self, ex, iq)
        return reply
    
    
    def message_resume(self, msg):
        try:
            self.resume()
            return "I'm resumed"
        except Exception as ex:
            return build_error_message(self, ex)
    
    
    
    def info(self):
        dominfo = self.domain.info()
        return {"state": dominfo[0], "maxMem": dominfo[1], "memory": dominfo[2], "nrVirtCpu": dominfo[3], "cpuTime": dominfo[4], "hypervisor": self.hypervisor.jid}
    
    
    def iq_info(self, iq):
        """
        Return an IQ containing the info of the domain using libvirt connection
        
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ
        
        @rtype: xmpp.Protocol.Iq
        @return: a ready to send IQ containing the result of the action
        """
        
        reply = None
        try:
            reply = iq.buildReply("result")
            if self.domain:
                infos = self.info()
                response = xmpp.Node(tag="info", attrs=infos)
                reply.setQueryPayload([response])
                log.debug("virtual machine info sent")
            else:
                reply = iq.buildReply('ignore')  
        except Exception as ex:
            reply = build_error_iq(self, ex, iq)
        return reply
    
    
    def message_info(self, msg):
        try:
            i = self.info()
            return "I'm in state %s, I use %d Ko of memory. I've got %d CPU(s) and I've consumed %dsecond of my hypervisor (%s)" % (i["state"], i["memory"], i["nrVirtCpu"], i["cpuTime"], i["hypervisor"])
        except Exception as ex:
            return build_error_message(self, ex)
    
    
    
    def vncdisplay(self):
        xmldesc = self.domain.XMLDesc(0)
        xmldescnode = xmpp.simplexml.NodeBuilder(data=xmldesc).getDom()
        return xmldescnode.getTag(name="devices").getTag(name="graphics").getAttr("port")
        
    
    
    def iq_vncdisplay(self, iq):
        """
        get the VNC display used in the virtual machine.
        
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ
        
        @rtype: xmpp.Protocol.Iq
        @return: a ready to send IQ containing the result of the action
        """
        reply = iq.buildReply("result")
        try:
            if not self.domain:
                return iq.buildReply('ignore')
            port = self.vncdisplay()
            payload = xmpp.Node("vncdisplay", attrs={"port": str(port), "host": self.ipaddr})
            reply.setQueryPayload([payload])
        except Exception as ex:
            reply = build_error_iq(self, ex, iq)
        return reply
    
    
    def message_vncdisplay(self, msg):
        try:
            port = self.vncdisplay()
            return "you can connect to my screen at %s:%s" % (self.ipaddr, port)
        except Exception as ex:
            return build_error_message(self, ex)
    
    
    
    def xmldesc(self):
        xmldesc = self.domain.XMLDesc(0)
        return xmpp.simplexml.NodeBuilder(data=xmldesc).getDom()
    
        
    def iq_xmldesc(self, iq):
        """
        get the XML Desc of the virtual machine.
        
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ
        
        @rtype: xmpp.Protocol.Iq
        @return: a ready to send IQ containing the result of the action
        """
        reply = iq.buildReply("result")
        try:
            if not self.domain:
                return iq.buildReply('ignore')
            xmldescnode = self.xmldesc()
            reply.setQueryPayload([xmldescnode])
        except Exception as ex:
            reply = build_error_iq(self, ex, iq)
        return reply
    
    
    def message_xmldesc(self, msg):
        return str(self.xmldesc())
    
    
    
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
       
       reply = None
       
       try :
           domain_node = iq.getTag("query").getTag("domain")
           
           domain_uuid = domain_node.getTag("uuid").getData()
           if domain_uuid != self.jid.getNode():
               raise Exception('IncorrectUUID', "given UUID {0} doesn't match JID {1}".format(domain_uuid, self.jid.getNode()))
           
           reply = iq.buildReply("result")
           
           # the dirty replace below is to avoid having this xmlns wrote by xmpp.Node automatically.
           # I've sepnd two hours, trying to remove it, I'm done.
           definitionXML = str(domain_node).replace('xmlns="http://www.gajim.org/xmlns/undeclared" ', '')
           self.libvirt_connection.defineXML(definitionXML)
           self.definition = domain_node
           log.info("virtual machine XML is defined")
           if not self.domain:
               self.connect_libvirt()
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
        
        reply = None
        try:
            reply = iq.buildReply("result")
            self.domain.undefine()
            log.info("virtual machine is undefined")
            self.definition = None;
        except Exception as ex:
            reply = build_error_iq(self, ex, iq)
        return reply
    
    
    
    # iq dependencies
    def dep_define(self, iq):
        reply = None;
        try:
            raise Exception("Not implemented")
        except Exception as ex:
            reply = build_error_iq(self, ex, iq)
        return reply
    
    
    def dep_add(self, iq):
        reply = None;
        try:
            raise Exception("Not implemented")
        except Exception as ex:
            reply = build_error_iq(self, ex, iq)
        return reply
        
    def dep_remove(self, iq):
        reply = None;
        try:
            raise Exception("Not implemented")
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
            - destroy
            - reboot
            - suspend
            - resume
        
        @type conn: xmpp.Dispatcher
        @param conn: ths instance of the current connection that send the message
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ
        """
        
        action = iq.getTag("query").getAttr("action")
        
        log.debug("Control IQ received from %s with type %s" % (iq.getFrom(), action))
        
        if action == "info":
            reply = self.iq_info(iq)
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed
            
        if action == "create":
            reply = self.iq_create(iq)
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed
            
        if action == "shutdown":
            reply = self.iq_shutdown(iq)
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed

        if action == "destroy":
            reply = self.iq_destroy(iq)
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed
            
        if action == "reboot":
            reply = self.iq_reboot(iq)
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed
            
        if action == "suspend":
            reply = self.iq_suspend(iq)
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed
            
        if action == "resume":
            reply = self.iq_resume(iq)
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed
            
        if action == "vncdisplay":
            reply = self.iq_vncdisplay(iq)
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed
            
        if action == "xmldesc":
            reply = self.iq_xmldesc(iq)
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed
            
    

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
        
        action = iq.getTag("query").getAttr("action")
        log.debug("Definition IQ received from %s with type %s" % (iq.getFrom(), action))
        
        if action == "define":
            reply = self.define(iq)
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed
        
        if action == "undefine":
            reply = self.undefine(iq)
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed        
    
    
    def __process_iq_archipel_dependence(self, conn, iq):
        """
        Invoked when new archipel:dependence IQ is received.
        
        it understands IQ of type:
            - add
            - remove
            - define
            
        @type conn: xmpp.Dispatcher
        @param conn: ths instance of the current connection that send the message
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ
        """
        action = iq.getTag("query").getAttr("action")
        log.debug("Dependence IQ received from %s with type %s" % (iq.getFrom(), action))
        
        if action == "add":
            reply = self.dep_add(iq)
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed
            
        if action == "remove":
            reply = self.dep_remove(iq)
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed
            
        if action == "define":
            reply = self.dep_define(iq)
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed
    
