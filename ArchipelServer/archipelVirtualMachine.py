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
from threading import Timer, Thread
from libvirtEventLoop import *
import libvirt

ARCHIPEL_ERROR_CODE_VM_CREATE       = -1001
ARCHIPEL_ERROR_CODE_VM_SUSPEND      = -1002
ARCHIPEL_ERROR_CODE_VM_RESUME       = -1003
ARCHIPEL_ERROR_CODE_VM_DESTROY      = -1004
ARCHIPEL_ERROR_CODE_VM_SHUTDOWN     = -1005
ARCHIPEL_ERROR_CODE_VM_REBOOT       = -1006
ARCHIPEL_ERROR_CODE_VM_DEFINE       = -1007
ARCHIPEL_ERROR_CODE_VM_UNDEFINE     = -1008
ARCHIPEL_ERROR_CODE_VM_INFO         = -1009
ARCHIPEL_ERROR_CODE_VM_VNC          = -1010
ARCHIPEL_ERROR_CODE_VM_XMLDESC      = -1011
ARCHIPEL_ERROR_CODE_VM_LOCKED       = -1012
ARCHIPEL_ERROR_CODE_VM_MIGRATE      = -1013
ARCHIPEL_ERROR_CODE_VM_IS_MIGRATING = -1014


class TNArchipelVirtualMachine(TNArchipelBasicXMPPClient):
    """
    this class represent an Virtual Machine, XMPP Capable.
    this class need to already have 
    """
    
    def __init__(self, jid, password, hypervisor, configuration, name):
        """
        contructor of the class
        """
        TNArchipelBasicXMPPClient.__init__(self, jid, password, configuration, name)
        
        self.hypervisor                 = hypervisor
        self.libvirt_connection         = libvirt.open(self.configuration.get("GLOBAL", "libvirt_uri"))
        self.domain                     = None
        self.definition                 = None
        self.uuid                       = self.jid.getNode()
        self.vm_disk_base_path          = self.configuration.get("VIRTUALMACHINE", "vm_base_path") + "/"
        self.folder                     = self.vm_disk_base_path + self.uuid
        self.locked                     = False
        self.lock_timer                 = None
        self.maximum_lock_time          = self.configuration.getint("VIRTUALMACHINE", "maximum_lock_time")
        self.is_migrating               = False
        self.is_migrated                = False
        self.migration_destination_jid  = None
        self.libvirt_event_callback_id  = None
        
        if not os.path.isdir(self.folder):
            os.mkdir(self.folder)
        
        default_avatar = self.configuration.get("VIRTUALMACHINE", "vm_default_avatar")
        self.register_actions_to_perform_on_auth("connect_domain", None)
        self.register_actions_to_perform_on_auth("set_vcard", {"entity_type": "virtualmachine", "avatar_file": default_avatar})
        
        self.register_for_messages()
    
    
    def lock(self):
        log.info("acquiring lock")
        self.locked = True;
        self.lock_timer = Timer(self.maximum_lock_time, self.unlock)
        self.lock_timer.start()
    
    
    def unlock(self):
        log.info("releasing lock")
        self.locked = False;
        if self.lock_timer:
            self.lock_timer.cancel()
    
    
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
        self.xmppclient.RegisterHandler('iq', self.__process_iq_archipel_control, ns=ARCHIPEL_NS_VM_CONTROL)
        self.xmppclient.RegisterHandler('iq', self.__process_iq_archipel_definition, ns=ARCHIPEL_NS_VM_DEFINITION)
        
        TNArchipelBasicXMPPClient.register_handler(self)
    
    
    def remove_folder(self):
        """
        remove the folder of the virtual with all its contents
        """
        os.system("rm -rf " + self.folder)
    
    
    def set_presence_according_to_libvirt_info(self):
        try:
            self.push_change("virtualmachine:definition", "defined", excludedgroups=['vitualmachines'])
            
            dominfo = self.domain.info()
            log.info("virtual machine state is %d" %  dominfo[0])
            if dominfo[0] == libvirt.VIR_DOMAIN_RUNNING:
                self.change_presence("", ARCHIPEL_XMPP_SHOW_RUNNING)
            elif dominfo[0] == libvirt.VIR_DOMAIN_PAUSED:
                self.change_presence("away", ARCHIPEL_XMPP_SHOW_PAUSED)
            elif dominfo[0] == libvirt.VIR_DOMAIN_SHUTOFF or dominfo[0] == libvirt.VIR_DOMAIN_SHUTDOWN:
                self.change_presence("xa", ARCHIPEL_XMPP_SHOW_SHUTDOWNED)
        except libvirt.libvirtError as ex:
            if ex.get_error_code() == 42:
                log.info("Exception raised #{0} : {1}".format(ex.get_error_code(), ex))
                self.domain = None
                self.change_presence("xa", ARCHIPEL_XMPP_SHOW_NOT_DEFINED)
        
    
    
    def connect_domain(self):
        """
        Initialize the connection to the libvirt first, and
        then to the domain by looking the uuid used as JID Node
        
        exit on any error.
        """
        try:
            self.domain     = self.libvirt_connection.lookupByUUIDString(self.uuid)
            self.definition = xmpp.simplexml.NodeBuilder(data=str(self.domain.XMLDesc(0))).getDom()
            log.info("sucessfully connect to domain uuid {0}".format(self.uuid))
            self.libvirt_event_callback_id = self.libvirt_connection.domainEventRegisterAny(self.domain, libvirt.VIR_DOMAIN_EVENT_ID_LIFECYCLE, self.on_domain_event, None)
             
            self.set_presence_according_to_libvirt_info()
        except Exception as ex:
            log.error("can't connect to libvirt : " + str(ex))
            self.change_presence("xa", ARCHIPEL_XMPP_SHOW_NOT_DEFINED)
            
    
    
    def on_domain_event(self, conn, dom, event, detail, opaque):
        log.info("libvirt event received: %d with detail %s" % (event, detail))
        
        if self.is_migrating and not self.is_migrated and event == libvirt.VIR_DOMAIN_EVENT_STOPPED and detail == libvirt.VIR_DOMAIN_EVENT_STOPPED_MIGRATED:
            #self.migrate_step3()
            return
        
        if self.is_migrating or self.is_migrated:
            return
        
        try:
            if event == libvirt.VIR_DOMAIN_EVENT_STARTED:
                if detail == libvirt.VIR_DOMAIN_EVENT_STARTED_MIGRATED:
                    self.set_presence_according_to_libvirt_info()
                else:
                    self.change_presence("", ARCHIPEL_XMPP_SHOW_RUNNING)
                    self.push_change("virtualmachine:control", "created", excludedgroups=['vitualmachines'])
            
            elif event == libvirt.VIR_DOMAIN_EVENT_SUSPENDED:
                if not detail == libvirt.VIR_DOMAIN_EVENT_SUSPENDED_MIGRATED:
                    self.change_presence("away", ARCHIPEL_XMPP_SHOW_PAUSED)
                    self.push_change("virtualmachine:control", "suspended", excludedgroups=['vitualmachines'])
                
            elif event == libvirt.VIR_DOMAIN_EVENT_RESUMED:
                if detail == libvirt.VIR_DOMAIN_EVENT_RESUMED_UNPAUSED:
                    self.change_presence("", ARCHIPEL_XMPP_SHOW_RUNNING)
                    self.push_change("virtualmachine:control", "resumed", excludedgroups=['vitualmachines'])
                elif detail == libvirt.VIR_DOMAIN_EVENT_RESUMED_MIGRATED:
                    self.set_presence_according_to_libvirt_info()
                
            elif event == libvirt.VIR_DOMAIN_EVENT_STOPPED:
                if not detail == libvirt.VIR_DOMAIN_EVENT_STOPPED_MIGRATED:
                    self.change_presence("xa", ARCHIPEL_XMPP_SHOW_SHUTDOWNED)
                    self.push_change("virtualmachine:control", "shutdowned", excludedgroups=['vitualmachines'])
            
            elif event == libvirt.VIR_DOMAIN_EVENT_UNDEFINED:
                self.change_presence("xa", ARCHIPEL_XMPP_SHOW_NOT_DEFINED)
                self.push_change("virtualmachine:definition", "undefined", excludedgroups=['vitualmachines'])
            
            elif event == libvirt.VIR_DOMAIN_EVENT_DEFINED:
                self.change_presence("xa", ARCHIPEL_XMPP_SHOW_SHUTDOWNED)
                self.push_change("virtualmachine:definition", "defined", excludedgroups=['vitualmachines'])
            
        except Exception as ex:
            log.error("%s: Unable to change state %d:%d : %s" % (self.jid.getStripped(), event, detail, str(ex)))
        finally:
            self.unlock()
    
    
    def disconnect(self):
        """
        overides the disconnect function
        """
        log.info("%s is disconnecting from everything" % self.jid)
        
        if not self.libvirt_event_callback_id is None:
            self.libvirt_connection.domainEventDeregisterAny(self.libvirt_event_callback_id)
            self.libvirt_event_callback_id = None;
        
        if self.libvirt_connection:
            self.libvirt_connection.close()
            self.libvirt_connection = None
        
        TNArchipelBasicXMPPClient.disconnect(self)
    
    
    
    ######################################################################################################
    ### Process IQ
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
        
        try:
            action = iq.getTag("query").getTag("archipel").getAttr("action")
            log.info("IQ RECEIVED: from: %s, type: %s, namespace: %s, action: %s" % (iq.getFrom(), iq.getType(), iq.getQueryNS(), action))
        except Exception as ex:
            reply = build_error_iq(self, ex, iq, ARCHIPEL_NS_ERROR_QUERY_NOT_WELL_FORMED)
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed
        
        if not self.libvirt_connection:
            reply = build_error_iq(self, "Virtual is migrating. You cannot do anything", iq, ARCHIPEL_ERROR_CODE_VM_IS_MIGRATING)
            conn.send(reply)
            return;
            
        if self.is_migrating:
            raise xmpp.protocol.NodeProcessed
            
        if action == "info":
            reply = self.iq_info(iq)
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed
            
        elif action == "create":
            reply = self.iq_create(iq)
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed
            
        elif action == "shutdown":
            reply = self.iq_shutdown(iq)
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed
            
        elif action == "destroy":
            reply = self.iq_destroy(iq)
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed
            
        elif action == "reboot":
            reply = self.iq_reboot(iq)
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed
            
        elif action == "suspend":
            reply = self.iq_suspend(iq)
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed
            
        elif action == "resume":
            reply = self.iq_resume(iq)
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed
            
        elif action == "vncdisplay":
            reply = self.iq_vncdisplay(iq)
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed
            
        elif action == "xmldesc":
            reply = self.iq_xmldesc(iq)
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed
            
        elif action == "migrate":
            reply = self.iq_migrate(iq)
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
        try:
            action = iq.getTag("query").getTag("archipel").getAttr("action")
            log.info("IQ RECEIVED: from: %s, type: %s, namespace: %s, action: %s" % (iq.getFrom(), iq.getType(), iq.getQueryNS(), action))
        except Exception as ex:
            reply = build_error_iq(self, ex, iq, ARCHIPEL_NS_ERROR_QUERY_NOT_WELL_FORMED)
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed
        
        if not self.libvirt_connection:
            reply = build_error_iq(self, "Virtual is migrating. You cannot do anything", iq, ARCHIPEL_ERROR_CODE_VM_IS_MIGRATING)
            conn.send(reply)
            return;
                
        if action == "define":
            reply = self.iq_define(iq)
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed
            
        elif action == "undefine":
            reply = self.iq_undefine(iq)
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed
    
    
    
    ######################################################################################################
    ### libvirt controls
    ######################################################################################################
    
    def create(self):
        self.lock()
        self.domain.create()
        log.info("virtual machine created")
        return str(self.domain.ID())
    

    def shutdown(self):
        self.lock()
        self.domain.shutdown()
        log.info("virtual machine shutdowned")
    
    
    def destroy(self):
        self.lock()
        self.domain.destroy()
        log.info("virtual machine destroyed")
    
    
    def reboot(self):
        self.lock()
        self.domain.reboot(0) # flags not used in libvirt but required.
        log.info("virtual machine rebooted")
    
    
    def suspend(self):
        self.lock()
        self.domain.suspend()
        log.info("virtual machine suspended")
    
    
    def resume(self):
        self.lock()
        self.domain.resume()
        log.info("virtual machine resumed")
    
    
    def info(self):
        dominfo = self.domain.info()
        log.debug("virtual machine info sent")
        return {"state": dominfo[0], "maxMem": dominfo[1], "memory": dominfo[2], "nrVirtCpu": dominfo[3], "cpuTime": dominfo[4], "hypervisor": self.hypervisor.jid}
    
    
    def vncdisplay(self):
        xmldesc = self.domain.XMLDesc(0)
        xmldescnode = xmpp.simplexml.NodeBuilder(data=xmldesc).getDom()
        return xmldescnode.getTag(name="devices").getTag(name="graphics").getAttr("port")
    
    
    def xmldesc(self):
        xmldesc = self.domain.XMLDesc(0)
        return xmpp.simplexml.NodeBuilder(data=xmldesc).getDom()
    
    
    def define(self, xmldesc):
        
        if not xmldesc.getTag('description'): xmldesc.addChild(name='description')
        xmldesc.getTag('description').setPayload("%s::::%s::::%s" % (self.jid.getStripped(), self.password, self.name))
        
        definitionXML = str(xmldesc).replace('xmlns="http://www.gajim.org/xmlns/undeclared" ', '')
        self.libvirt_connection.defineXML(definitionXML)
        
        if not self.domain:
            self.connect_domain()
        self.definition = xmldesc
        return xmldesc
    
    
    def undefine(self):
        self.domain.undefine()
        self.definition = None;
    
    
    def clone(self, info):
        """
        clone a vm from another
        info is a dict that contains following keys
            - definition : the xml object containing the libvirt definition
            - path : the vm path to clone (will clone * in it)
            - baseuuid : the base uuid of cloned vm, in order to replace it
        """
        xml         = info["definition"]
        path        = info["path"]
        baseuuid    = info["baseuuid"]
        xmlstring   = str(xml)
        xmlstring   = xmlstring.replace(baseuuid, self.uuid)
        newxml      = xmpp.simplexml.NodeBuilder(data=xmlstring).getDom()
        
        log.info("starting to clone virtual machine %s from %s" % (self.uuid, baseuuid))
        self.change_presence(presence_show="dnd", presence_status="Cloning...")
        log.info("copying base virtual repository")
        os.system("cp -a %s/* %s" % (path, self.folder))
        log.info("defining the cloned virtual machine")
        self.define(newxml)
    
    
    def migrate_step1(self, destination_jid):
        """
        migrate a virtual machine from this host to another
        This step check is virtual machine can be migrated.
        Then ask for the destination_jid hypervisor what is his 
        libvirt uri
        """
        
        if self.is_migrating:
            raise Exception('Virtual machine is already migrating')
        
        if not self.definition:
            raise Exception('Virtual machine must be defined')
            
        if not self.domain.info()[0] == libvirt.VIR_DOMAIN_RUNNING:
            raise Exception('Virtual machine must be running')
            
        if self.hypervisor.jid.getStripped() == destination_jid.getStripped():
            raise Exception('Virtual machine is already running on %s' % destination_jid.getStripped())
        
        self.is_migrating               = True
        self.is_migrated                = False
        self.migration_destination_jid  = destination_jid
        
        self.lock()
        self.change_presence(presence_show=self.xmppstatusshow, presence_status="Migrating...")
        
        self.xmppclient.UnregisterHandler(name='presence', handler=self.process_presence_unsubscribe, typ="unsubscribe")
        self.xmppclient.UnregisterHandler(name='presence', handler=self.process_presence_subscribe, typ="subscribe")
        self.xmppclient.UnregisterHandler(name='iq', handler=self.__process_iq_archipel_definition, ns=ARCHIPEL_NS_VM_DEFINITION)
        self.xmppclient.UnregisterHandler(name='iq', handler=self.__process_iq_archipel_control, ns=ARCHIPEL_NS_VM_DEFINITION)
        
        iq = xmpp.Iq(typ="get", queryNS="archipel:hypervisor:control", to=self.migration_destination_jid)
        iq.getTag("query").addChild(name="archipel", attrs={"action": "uri"})
        resp = self.xmppclient.SendAndCallForResponse(iq, self.migrate_step2)
    
    
    def migrate_step2(self, conn, resp):
        """
        once received the remote hypervisor URI, start libvirt migration migration
        """
        flags = libvirt.VIR_MIGRATE_PEER2PEER | libvirt.VIR_MIGRATE_PERSIST_DEST | libvirt.VIR_MIGRATE_LIVE# | libvirt.VIR_MIGRATE_UNDEFINE_SOURCE
        
        try:
            remote_hypervisor_uri   = resp.getTag("query").getTag("uri").getCDATA().replace("qemu://", "qemu+ssh://")
        except:
            log.warn("hypervisor %s hasn't gave its URI. aborting migration" % resp.getFrom())
            return
        
        self.domain.migrateToURI(remote_hypervisor_uri, flags, None, 0)
        # note that the next step is performed when libvirt event VIR_DOMAIN_EVENT_STOPPED_MIGRATED is received
    
    
    # def migrate_step3(self):
    #     """
    #     Once the virtual machine is migrated, ask the remote hypervisor to alloc a new XMPP container
    #     for the virtual machine
    #     """
    #     self.domain         = None;
    #     self.is_migrated    = True;
    #     
    #     log.info("starting to ask to %s to alloc new XMPP VM" % self.migration_destination_jid)
    #     iq = xmpp.Iq(typ="get", queryNS="archipel:hypervisor:control", to=self.migration_destination_jid)
    #     iq.getTag("query").addChild(name="archipel", attrs={
    #         "action": "allocmigrated",
    #         "jid": self.jid,
    #         "name": self.name,
    #         "password": self.password})
    #     
    #     self.xmppclient.SendAndCallForResponse(iq, self.migrate_step4)
    # 
    # 
    # def migrate_step4(self, conn, resp):
    #     """
    #     finally ask local hypervisor to soflty remove XMPP virtual machine.
    #     This will be this hypervisor that will perform virtual machine XMPP disconnect
    #     DO NOT DO IT FROM THIS METHOD OR THREADS WILL DIE!
    #     """
    #     log.info("alloc done to %s: %s" % (self.migration_destination_jid, resp))
    #     
    #     iq = xmpp.Iq(typ="get", queryNS="archipel:hypervisor:control", to=self.hypervisor.jid)
    #     iq.getTag("query").addChild(name="archipel", attrs={
    #         "action": "freemigrated", 
    #         "jid": self.jid})
    #     
    #     resp = self.xmppclient.send(iq)
    
    
    
    ######################################################################################################
    ### XMPP Controls
    ###################################################################################################### 
    
    # iq control
    
    def iq_migrate(self, iq):
        try:
            hyp_jid = xmpp.JID(iq.getTag("query").getTag("archipel").getAttr("hypervisorjid"))
            self.migrate_step1(hyp_jid)
            reply =  iq.buildReply("result");
        except Exception as ex:
            reply = build_error_iq(self, ex, iq, ARCHIPEL_ERROR_CODE_VM_MIGRATE)
        return reply
    
    
        
    def iq_create(self, iq):
        """
        Create a domain using libvirt connection
        
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ
        
        @rtype: xmpp.Protocol.Iq
        @return: a ready to send IQ containing the result of the action
        """
        if self.locked:
            log.error("Virtual machine is locked, can't do anything")
            return build_error_iq(self, Exception("Virtual machine is locked, can't do anything"), iq, ARCHIPEL_ERROR_CODE_VM_LOCKED)
        
        try:
            domid = self.create()
            reply = iq.buildReply("result")
            payload = xmpp.Node("domain", attrs={"id": domid})
            reply.setQueryPayload([payload])
        except libvirt.libvirtError as ex:
            self.unlock()
            reply = build_error_iq(self, ex, iq, ex.get_error_code(), ns=ARCHIPEL_NS_LIBVIRT_GENERIC_ERROR)
        except Exception as ex:
            self.unlock()
            reply = build_error_iq(self, ex, iq, ARCHIPEL_ERROR_CODE_VM_CREATE)
        return reply
    
    
    def message_create(self, msg):
        """
        handle message creation order
        """
        try:
            self.create()
            return "I'm starting"
        except Exception as ex:
            return build_error_message(self, ex)
    
    

    def iq_shutdown(self, iq):
        """
        Shutdown a domain using libvirt connection
        
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ
        
        @rtype: xmpp.Protocol.Iq
        @return: a ready to send IQ containing the result of the action
        """
        if self.locked:
            log.error("Virtual machine is locked, can't do anything")
            return build_error_iq(self, Exception("Virtual machine is locked, can't do anything"), iq, ARCHIPEL_ERROR_CODE_VM_LOCKED)
        
        try:
            self.shutdown()
            reply = iq.buildReply("result")
        except libvirt.libvirtError as ex:
            self.unlock()
            reply = build_error_iq(self, ex, iq, ex.get_error_code(), ns=ARCHIPEL_NS_LIBVIRT_GENERIC_ERROR)
        except Exception as ex:
            self.unlock()
            reply = build_error_iq(self, ex, iq, ARCHIPEL_ERROR_CODE_VM_SHUTDOWN)
        return reply
    
    
    def message_shutdown(self, msg):
        """
        handle message shutdown order
        """
        try:
            self.shutdown()
            return "I'm shutdowning"
        except Exception as ex:
            return build_error_message(self, ex)
    
    
    
    def iq_destroy(self, iq):
        """
        Destroy a domain using libvirt connection
        
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ
        @rtype: xmpp.Protocol.Iq
        @return: a ready to send IQ containing the result of the action
        """
        if self.locked:
            log.error("Virtual machine is locked, can't do anything")
            return build_error_iq(self, Exception("Virtual machine is locked, can't do anything"), iq, ARCHIPEL_ERROR_CODE_VM_LOCKED)
        
        try:
            self.destroy()
            reply = iq.buildReply("result")
        except libvirt.libvirtError as ex:
            self.unlock()
            reply = build_error_iq(self, ex, iq, ex.get_error_code(), ns=ARCHIPEL_NS_LIBVIRT_GENERIC_ERROR)
        except Exception as ex:
            self.unlock()
            reply = build_error_iq(self, ex, iq, ARCHIPEL_ERROR_CODE_VM_DESTROY)
        return reply
    
    
    def message_destroy(self, msg):
        """
        handle message destroy order
        """
        try:
            self.destroy()
            return "I've destroyed myself"
        except Exception as ex:
            return build_error_message(self, ex)
    
    
    
    def iq_reboot(self, iq):
        """
        Reboot a domain using libvirt connection
        
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ
        
        @rtype: xmpp.Protocol.Iq
        @return: a ready to send IQ containing the result of the action
        """
        
        if self.locked:
            log.error("Virtual machine is locked, can't do anything")
            return build_error_iq(self, Exception("Virtual machine is locked, can't do anything"), iq, ARCHIPEL_ERROR_CODE_VM_LOCKED)
        
        try:
            self.reboot()
            reply = iq.buildReply("result")
        except libvirt.libvirtError as ex:
            self.unlock()
            reply = build_error_iq(self, ex, iq, ex.get_error_code())
        except Exception as ex:
            self.unlock()
            reply = build_error_iq(self, ex, iq, ARCHIPEL_ERROR_CODE_VM_REBOOT)
        return reply
    
    
    def message_reboot(self, msg):
        """
        handle message reboot order
        """
        try:
            self.reboot()
            return "I try to reboot"
        except Exception as ex:
            return build_error_message(self, ex)
    
    
    
    def iq_suspend(self, iq):
        """
        Suspend (pause) a domain using libvirt connection
        
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ
        
        @rtype: xmpp.Protocol.Iq
        @return: a ready to send IQ containing the result of the action
        """
        if self.locked:
            log.error("Virtual machine is locked, can't do anything")
            return build_error_iq(self, Exception("Virtual machine is locked, can't do anything"), iq, ARCHIPEL_ERROR_CODE_VM_LOCKED)
        
        try:
            self.suspend()
            reply = iq.buildReply("result")
        except libvirt.libvirtError as ex:
            self.unlock()
            reply = build_error_iq(self, ex, iq, ex.get_error_code(), ns=ARCHIPEL_NS_LIBVIRT_GENERIC_ERROR)
        except Exception as ex:
            self.unlock()
            reply = build_error_iq(self, ex, iq, ARCHIPEL_ERROR_CODE_VM_SUSPEND)
        return reply
    
    
    def message_suspend(self, msg):
        """
        handle message suspend order
        """
        try:
            self.suspend()
            return "I'm suspended"
        except Exception as ex:
            return build_error_message(self, ex)
    
    
    
    def iq_resume(self, iq):
        """
        Resume (unpause) a domain using libvirt connection
        
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ
        
        @rtype: xmpp.Protocol.Iq
        @return: a ready to send IQ containing the result of the action
        """
        if self.locked:
            log.error("Virtual machine is locked, can't do anything")
            return build_error_iq(self, Exception("Virtual machine is locked, can't do anything"), iq, ARCHIPEL_ERROR_CODE_VM_LOCKED)
        
        try:    
            self.resume()
            reply = iq.buildReply("result")
        except libvirt.libvirtError as ex:
            self.unlock()
            reply = build_error_iq(self, ex, iq, ex.get_error_code(), ns=ARCHIPEL_NS_LIBVIRT_GENERIC_ERROR)
        except Exception as ex:
            self.unlock()
            reply = build_error_iq(self, ex, iq, ARCHIPEL_ERROR_CODE_VM_RESUME)
        return reply
    
    
    def message_resume(self, msg):
        """
        handle message resume order
        """
        try:
            self.resume()
            return "I'm resumed"
        except Exception as ex:
            return build_error_message(self, ex)
    
    
    
    def iq_info(self, iq):
        """
        Return an IQ containing the info of the domain using libvirt connection
        
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ
        @rtype: xmpp.Protocol.Iq
        @return: a ready to send IQ containing the result of the action
        """
        try:
            if not self.domain:
                return iq.buildReply("ignore")
            
            reply = iq.buildReply("result")
            infos = self.info()
            response = xmpp.Node(tag="info", attrs=infos)
            reply.setQueryPayload([response])
        except libvirt.libvirtError as ex:
            if ex.get_error_code() == libvirt.VIR_ERR_NO_DOMAIN:
                return iq.buildReply("result")
            else:
                reply = build_error_iq(self, ex, iq, ex.get_error_code(), ns=ARCHIPEL_NS_LIBVIRT_GENERIC_ERROR)
        except Exception as ex:
            reply = build_error_iq(self, ex, iq, ARCHIPEL_ERROR_CODE_VM_INFO)
        return reply
    
    
    def message_info(self, msg):
        """
        handle message info order
        """
        try:
            i = self.info()
            return "I'm in state %s, I use %d Ko of memory. I've got %d CPU(s) and I've consumed %dsecond of my hypervisor (%s)" % (i["state"], i["memory"], i["nrVirtCpu"], i["cpuTime"], i["hypervisor"])
        except Exception as ex:
            return build_error_message(self, ex)
    
    
    
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
        except libvirt.libvirtError as ex:
            reply = build_error_iq(self, ex, iq, ex.get_error_code(), ns=ARCHIPEL_NS_LIBVIRT_GENERIC_ERROR)
        except Exception as ex:
            reply = build_error_iq(self, ex, iq, ARCHIPEL_ERROR_CODE_VM_VNC)
        return reply
    
    
    def message_vncdisplay(self, msg):
        """
        handle message vnc display order
        """
        try:
            port = self.vncdisplay()
            return "you can connect to my screen at %s:%s" % (self.ipaddr, port)
        except Exception as ex:
            return build_error_message(self, ex)
    
    
       
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
        except libvirt.libvirtError as ex:
            reply = build_error_iq(self, ex, iq, ex.get_error_code(), ns=ARCHIPEL_NS_LIBVIRT_GENERIC_ERROR)
        except Exception as ex:
            reply = build_error_iq(self, ex, iq, ARCHIPEL_ERROR_CODE_VM_XMLDESC)
        return reply
    
    
    def message_xmldesc(self, msg):
        """
        handle message xmldesc order
        """
        return str(self.xmldesc())
    
    
    
    
    
    # iq definition
     
    def iq_define(self, iq):
        """
        Define a virtual machine in the libvirt according to the XML data
        domain passed in argument
        
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ
        
        @rtype: xmpp.Protocol.Iq
        @return: a ready to send IQ containing the result of the action
        """
        reply = iq.buildReply("result")
       
        try :
            domain_node = iq.getTag("query").getTag("archipel").getTag("domain")
            domain_uuid = domain_node.getTag("uuid").getData()
            
            if domain_uuid != self.jid.getNode():
                raise Exception('IncorrectUUID', "given UUID {0} doesn't match JID {1}".format(domain_uuid, self.jid.getNode()))
            
            self.define(domain_node)
            log.info("virtual machine XML is defined")
        except libvirt.libvirtError as ex:
            reply = build_error_iq(self, ex, iq, ex.get_error_code(), ns=ARCHIPEL_NS_LIBVIRT_GENERIC_ERROR)
        except Exception as ex:
            reply = build_error_iq(self, ex, iq, ARCHIPEL_ERROR_CODE_VM_DEFINE)
        return reply
    
    
    def iq_undefine(self, iq):
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
            self.undefine()
            log.info("virtual machine is undefined")
        except libvirt.libvirtError as ex:
            reply = build_error_iq(self, ex, iq, ex.get_error_code(), ns=ARCHIPEL_NS_LIBVIRT_GENERIC_ERROR)
        except Exception as ex:
            reply = build_error_iq(self, ex, iq, ARCHIPEL_ERROR_CODE_VM_DESTROY)
        return reply
    
    
    
