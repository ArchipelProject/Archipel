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
import archipelWebSocket

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
ARCHIPEL_ERROR_CODE_VM_AUTOSTART    = -1015
ARCHIPEL_ERROR_CODE_VM_MEMORY       = -1016
ARCHIPEL_ERROR_CODE_VM_NETWORKINFO  = -1017


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
        self.migration_destination_jid  = None
        self.libvirt_event_callback_id  = None
        
        if not os.path.isdir(self.folder):
            os.mkdir(self.folder)
        
        default_avatar = self.configuration.get("VIRTUALMACHINE", "vm_default_avatar")
        self.register_actions_to_perform_on_auth("connect_domain", None)
        self.register_actions_to_perform_on_auth("set_vcard", {"entity_type": "virtualmachine", "avatar_file": default_avatar})
        
        self.register_for_messages()
    
    
    def lock(self):
        self.log.info("acquiring lock")
        self.locked = True;
        self.lock_timer = Timer(self.maximum_lock_time, self.unlock)
        self.lock_timer.start()
    
    
    def unlock(self):
        self.log.info("releasing lock")
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
                            
                            {  "commands" : ["info", "how are you", "and you"], 
                                "parameters": [],
                                "method": self.message_info,
                                "description": "I'll give info about me" },
                            
                            {  "commands" : ["vnc", "screen"], 
                                "parameters": [],
                                "method": self.message_vncdisplay,
                                "description": "I'll show my VNC port" },
                                
                            {  "commands" : ["desc", "xml"], 
                                "parameters": [],
                                "method": self.message_xmldesc,
                                "description": "I'll show my description" },
                            
                            {  "commands" : ["net", "stat"], 
                                "parameters": [],
                                "method": self.message_networkinfo,
                                "description": "I'll show my network stats" },
                            
                            {  "commands" : ["fuck", "asshole", "jerk", "stupid", "suck"],
                                "ignore": True,
                                "parameters": [],
                                "method": self.message_insult,
                                "description": "" },
                            
                            {  "commands" : ["hello", "hey", "hi", "good morning", "yo"], 
                                "ignore": True,
                                "parameters": [],
                                "method": self.message_hello,
                                "description": "I'll show my network stats" },
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
            self.log.info("virtual machine state is %d" %  dominfo[0])
            if dominfo[0] == libvirt.VIR_DOMAIN_RUNNING:
                self.change_presence("", ARCHIPEL_XMPP_SHOW_RUNNING)
                self.create_novnc_proxy()
            elif dominfo[0] == libvirt.VIR_DOMAIN_PAUSED:
                self.change_presence("away", ARCHIPEL_XMPP_SHOW_PAUSED)
            elif dominfo[0] == libvirt.VIR_DOMAIN_SHUTOFF or dominfo[0] == libvirt.VIR_DOMAIN_SHUTDOWN:
                self.change_presence("xa", ARCHIPEL_XMPP_SHOW_SHUTDOWNED)
        except libvirt.libvirtError as ex:
            if ex.get_error_code() == 42:
                self.log.info("Exception raised #{0} : {1}".format(ex.get_error_code(), ex))
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
            self.log.info("sucessfully connect to domain uuid {0}".format(self.uuid))
            self.libvirt_event_callback_id = self.libvirt_connection.domainEventRegisterAny(self.domain, libvirt.VIR_DOMAIN_EVENT_ID_LIFECYCLE, self.on_domain_event, None)
             
            self.set_presence_according_to_libvirt_info()
        except Exception as ex:
            self.log.error("can't connect to libvirt : " + str(ex))
            self.change_presence("xa", ARCHIPEL_XMPP_SHOW_NOT_DEFINED)
            
    
    
    def on_domain_event(self, conn, dom, event, detail, opaque):
        self.log.info("libvirt event received: %d with detail %s" % (event, detail))
        
        if self.is_migrating:
            return
        
        try:
            if event == libvirt.VIR_DOMAIN_EVENT_STARTED  and not detail == libvirt.VIR_DOMAIN_EVENT_STARTED_MIGRATED:
                self.change_presence("", ARCHIPEL_XMPP_SHOW_RUNNING)
                self.push_change("virtualmachine:control", "created", excludedgroups=['vitualmachines'])
                self.create_novnc_proxy()
            
            elif event == libvirt.VIR_DOMAIN_EVENT_SUSPENDED and not detail == libvirt.VIR_DOMAIN_EVENT_SUSPENDED_MIGRATED:
                self.change_presence("away", ARCHIPEL_XMPP_SHOW_PAUSED)
                self.push_change("virtualmachine:control", "suspended", excludedgroups=['vitualmachines'])
                
            elif event == libvirt.VIR_DOMAIN_EVENT_RESUMED and not detail == libvirt.VIR_DOMAIN_EVENT_RESUMED_MIGRATED:
                self.change_presence("", ARCHIPEL_XMPP_SHOW_RUNNING)
                self.push_change("virtualmachine:control", "resumed", excludedgroups=['vitualmachines'])
                
            elif event == libvirt.VIR_DOMAIN_EVENT_STOPPED and not detail == libvirt.VIR_DOMAIN_EVENT_STOPPED_MIGRATED:
                self.change_presence("xa", ARCHIPEL_XMPP_SHOW_SHUTDOWNED)
                self.push_change("virtualmachine:control", "shutdowned", excludedgroups=['vitualmachines'])
            
            elif event == libvirt.VIR_DOMAIN_CRASHED:
                self.change_presence("xa", ARCHIPEL_XMPP_SHOW_CRASHED)
                self.push_change("virtualmachine:control", "crashed", excludedgroups=['vitualmachines'])
                
            elif event == libvirt.VIR_DOMAIN_SHUTOFF:
                self.change_presence("xa", ARCHIPEL_XMPP_SHOW_SHUTOFF)
                self.push_change("virtualmachine:control", "shutoff", excludedgroups=['vitualmachines'])
            
            elif event == libvirt.VIR_DOMAIN_EVENT_UNDEFINED:
                self.change_presence("xa", ARCHIPEL_XMPP_SHOW_NOT_DEFINED)
                self.push_change("virtualmachine:definition", "undefined", excludedgroups=['vitualmachines'])
            
            elif event == libvirt.VIR_DOMAIN_EVENT_DEFINED:
                self.change_presence("xa", ARCHIPEL_XMPP_SHOW_SHUTDOWNED)
                self.push_change("virtualmachine:definition", "defined", excludedgroups=['vitualmachines'])

            
        except Exception as ex:
            self.log.error("%s: Unable to change state %d:%d : %s" % (self.jid.getStripped(), event, detail, str(ex)))
        finally:
            self.unlock()
    
    
    def disconnect(self):
        """
        overides the disconnect function
        """
        self.log.info("%s is disconnecting from everything" % self.jid)
        
        if not self.libvirt_event_callback_id is None:
            self.libvirt_connection.domainEventDeregisterAny(self.libvirt_event_callback_id)
            self.libvirt_event_callback_id = None;
        
        if self.libvirt_connection:
            self.libvirt_connection.close()
            self.libvirt_connection = None
        
        TNArchipelBasicXMPPClient.disconnect(self)
    
    
    def create_novnc_proxy(self):
        """
        create a noVNC proxy on port vmpport + 1000 (so noVNC proxy is 6900 for VNC port 5900 etc)
        """
        current_vnc_port        = self.vncdisplay()["direct"]
        novnc_proxy_port        = self.vncdisplay()["proxy"]
        log.info("NOVNC: current proxy port is %d" % novnc_proxy_port)
        
        self.novnc_proxy = archipelWebSocket.TNArchipelWebSocket("127.0.0.1", current_vnc_port, "0.0.0.0", novnc_proxy_port);
        self.novnc_proxy.start()
    
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
            self.log.info("IQ RECEIVED: from: %s, type: %s, namespace: %s, action: %s" % (iq.getFrom(), iq.getType(), iq.getQueryNS(), action))
        except Exception as ex:
            reply = build_error_iq(self, ex, iq, ARCHIPEL_NS_ERROR_QUERY_NOT_WELL_FORMED)
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed
        
        if not self.libvirt_connection:
            raise xmpp.protocol.NodeProcessed
            
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
        
        elif action == "autostart":
            reply = self.iq_autostart(iq);
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed
        
        elif action == "memory":
            reply = self.iq_memory(iq);
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed
            
        elif action == "setvcpus":
            reply = self.iq_setvcpus(iq);
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed
            
        elif action == "networkinfo":
            reply = self.iq_networkinfo(iq);
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed        
        
        # elif action == "setpincpus":
        #     reply = self.iq_setcpuspin(iq);
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
        try:
            action = iq.getTag("query").getTag("archipel").getAttr("action")
            self.log.info("IQ RECEIVED: from: %s, type: %s, namespace: %s, action: %s" % (iq.getFrom(), iq.getType(), iq.getQueryNS(), action))
        except Exception as ex:
            reply = build_error_iq(self, ex, iq, ARCHIPEL_NS_ERROR_QUERY_NOT_WELL_FORMED)
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed
        
        if self.is_migrating:
            reply = build_error_iq(self, "virtual machine is migrating. Can't do anything", iq, ARCHIPEL_ERROR_CODE_VM_IS_MIGRATING)
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed
        
        
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
        self.log.info("virtual machine created")
        return str(self.domain.ID())
    

    def shutdown(self):
        self.lock()
        self.domain.shutdown()
        self.log.info("virtual machine shutdowned")
    
    
    def destroy(self):
        self.lock()
        self.domain.destroy()
        self.log.info("virtual machine destroyed")
    
    
    def reboot(self):
        self.lock()
        self.domain.reboot(0) # flags not used in libvirt but required.
        self.log.info("virtual machine rebooted")
    
    
    def suspend(self):
        self.lock()
        self.domain.suspend()
        self.log.info("virtual machine suspended")
    
    
    def resume(self):
        self.lock()
        self.domain.resume()
        self.log.info("virtual machine resumed")
    
    
    def info(self):
        dominfo     = self.domain.info()
        autostart   = self.domain.autostart()
        return {
            "state": dominfo[0], 
            "maxMem": dominfo[1], 
            "memory": dominfo[2], 
            "nrVirtCpu": dominfo[3], 
            "cpuTime": dominfo[4], 
            "hypervisor": self.hypervisor.jid, 
            "autostart": str(autostart)}
        
    
    
    def network_info(self):
        desc = xmpp.simplexml.NodeBuilder(data=self.domain.XMLDesc(0)).getDom()
        interfaces_nodes = desc.getTag("devices").getTags("interface")
        
        netstats = []
        for nic in interfaces_nodes:
            name    = nic.getTag("alias").getAttr("name");
            target  = nic.getTag("target").getAttr("dev"); 
            stats   = self.domain.interfaceStats(target);
            netstats.append({
                "name": name,
                "rx_bytes": stats[0],
                "rx_packets": stats[1],
                "rx_errs": stats[2],
                "rx_drop": stats[3],
                "tx_bytes": stats[4],
                "tx_packets": stats[5],
                "tx_errs": stats[6],
                "tx_drop": stats[7]
            })
        
        return netstats;
    
    
    def setMemory(self, value):
        value = long(value)
        if value < 10 :
            value = 10;
        self.domain.setMemory(value)
        t = Timer(1.0, self.memoryTimer, kwargs={"requestedMemory": value})
        t.start()
    
    
    def memoryTimer(self, requestedMemory, retry=3):
        if requestedMemory / self.info()["memory"] in (0, 1):
            self.push_change("virtualmachine:control", "memory", excludedgroups=['vitualmachines'])
        elif retry > 0:
            t = Timer(1.0, self.memoryTimer, kwargs={"requestedMemory": requestedMemory, "retry": (retry - 1)})
            t.start()
        else:
            self.push_change("virtualmachine:control", "memory", excludedgroups=['vitualmachines'])
    
    
    def setVCPUs(self, value):
        self.lock()
        if value > self.domain.maxVcpus():
            raise Exception("Maximum vCPU is %d" % self.domain.maxVcpus())
        self.domain.setVcpus(int(value))
        self.unlock()
        
    # def setCPUsPin(self, vcpu, cpumap):
    #     self.lock()
    #     self.domain.pinVcpu(int(value)); # no no non
    #     self.unlock()
    
    
    def setAutostart(self, flag):
        self.domain.setAutostart(flag)
    
    
    def vncdisplay(self):
        xmldesc = self.domain.XMLDesc(0)
        xmldescnode = xmpp.simplexml.NodeBuilder(data=xmldesc).getDom()
        directport = int(xmldescnode.getTag(name="devices").getTag(name="graphics").getAttr("port"))
        proxyport = directport + 1000
        return {"direct": directport, "proxy": proxyport}
    
    
    def xmldesc(self):
        xmldesc = self.domain.XMLDesc(0)
        descnode = xmpp.simplexml.NodeBuilder(data=xmldesc).getDom();
        descnode.delChild("description")
        return descnode
    
    
    def define(self, xmldesc):
        
        if not xmldesc.getTag('description'): 
            xmldesc.addChild(name='description')
        else:
            xmldesc.delChild("description")
            xmldesc.addChild(name='description')
        
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
    
    
    def undefine_and_disconnect(self):
        self.undefine()
        self.disconnect()
    
    
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
        
        self.log.info("starting to clone virtual machine %s from %s" % (self.uuid, baseuuid))
        self.change_presence(presence_show="dnd", presence_status="Cloning...")
        self.log.info("copying base virtual repository")
        os.system("cp -a %s/* %s" % (path, self.folder))
        self.log.info("defining the cloned virtual machine")
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
        self.migration_destination_jid  = destination_jid
        
        self.lock()
        self.change_presence(presence_show=self.xmppstatusshow, presence_status="Migrating...")
        
        self.xmppclient.UnregisterHandler(name='presence', handler=self.process_presence_unsubscribe, typ="unsubscribe")
        self.xmppclient.UnregisterHandler(name='presence', handler=self.process_presence_subscribe, typ="subscribe")
        self.xmppclient.UnregisterHandler(name='iq', handler=self.__process_iq_archipel_definition, ns=ARCHIPEL_NS_VM_DEFINITION)
        self.xmppclient.UnregisterHandler(name='iq', handler=self.__process_iq_archipel_control, ns=ARCHIPEL_NS_VM_DEFINITION)
        
        iq = xmpp.Iq(typ="get", queryNS="archipel:hypervisor:control", to=self.migration_destination_jid)
        iq.getTag("query").addChild(name="archipel", attrs={"action": "uri"})
        self.xmppclient.SendAndCallForResponse(iq, self.migrate_step2)
    
    
    def migrate_step2(self, conn, resp):
        """
        once received the remote hypervisor URI, start libvirt migration migration
        """
        ## DO NOT UNDEFINE DOMAIN HERE. the hypervisor is in charge of this. If undefined here, can't free XMPP client
        flags = libvirt.VIR_MIGRATE_PEER2PEER | libvirt.VIR_MIGRATE_PERSIST_DEST | libvirt.VIR_MIGRATE_LIVE# | libvirt.VIR_MIGRATE_UNDEFINE_SOURCE
        
        try:
            remote_hypervisor_uri   = resp.getTag("query").getTag("uri").getCDATA() #.replace("qemu://", "qemu+ssh://")
        except:
            self.log.warn("hypervisor %s hasn't gave its URI. aborting migration" % resp.getFrom())
            return
        
        try:
            self.domain.migrateToURI(remote_hypervisor_uri, flags, None, 0)
        except Exception as ex:
            self.unlock()
            self.is_migrating = False;
            self.migration_destination_jid = None;
            
            self.xmppclient.RegisterHandler(name='presence', handler=self.process_presence_unsubscribe, typ="unsubscribe")
            self.xmppclient.RegisterHandler(name='presence', handler=self.process_presence_subscribe, typ="subscribe")
            self.xmppclient.RegisterHandler(name='iq', handler=self.__process_iq_archipel_definition, ns=ARCHIPEL_NS_VM_DEFINITION)
            self.xmppclient.RegisterHandler(name='iq', handler=self.__process_iq_archipel_control, ns=ARCHIPEL_NS_VM_DEFINITION)
            self.change_presence(presence_show=self.xmppstatusshow, presence_status="Can't migrate.")
            self.shout("migration", "I can't migrate to %s because exception has been raised: %s" % (remote_hypervisor_uri, str(ex)))
            self.log.error("can't migrate because of : %s" % str(ex))
    
    
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
            self.log.error("Virtual machine is locked, can't do anything")
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
            self.log.error("Virtual machine is locked, can't do anything")
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
            self.log.error("Virtual machine is locked, can't do anything")
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
            self.log.error("Virtual machine is locked, can't do anything")
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
            self.log.error("Virtual machine is locked, can't do anything")
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
            self.log.error("Virtual machine is locked, can't do anything")
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
            ports = self.vncdisplay()
            payload = xmpp.Node("vncdisplay", attrs={"port": str(ports["direct"]), "proxy": str(ports["proxy"]), "host": self.ipaddr})
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
            ports = self.vncdisplay()
            return "you can connect to my screen at %s:%s" % (self.ipaddr, ports["direct"])
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
            self.log.info("virtual machine XML is defined")
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
        try:
            reply = iq.buildReply("result")
            self.undefine()
            self.log.info("virtual machine is undefined")
        except libvirt.libvirtError as ex:
            reply = build_error_iq(self, ex, iq, ex.get_error_code(), ns=ARCHIPEL_NS_LIBVIRT_GENERIC_ERROR)
        except Exception as ex:
            reply = build_error_iq(self, ex, iq, ARCHIPEL_ERROR_CODE_VM_DESTROY)
        return reply
    
    
    
    def iq_autostart(self, iq):
        """
        set if machine should start with host.
        
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ
        
        @rtype: xmpp.Protocol.Iq
        @return: a ready to send IQ containing the result of the action
        """
        try:
            reply = iq.buildReply("result")
            autostart = int(iq.getTag("query").getTag("archipel").getAttr("value"))
            self.setAutostart(autostart)
            self.log.info("virtual autostart is set to %d" % autostart)
        except libvirt.libvirtError as ex:
            reply = build_error_iq(self, ex, iq, ex.get_error_code(), ns=ARCHIPEL_NS_LIBVIRT_GENERIC_ERROR)
        except Exception as ex:
            reply = build_error_iq(self, ex, iq, ARCHIPEL_ERROR_CODE_VM_AUTOSTART)
        return reply
    
    
    def iq_memory(self, iq):
        """
        balloon memory .
        
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ
        
        @rtype: xmpp.Protocol.Iq
        @return: a ready to send IQ containing the result of the action
        """
        try:
            reply = iq.buildReply("result")
            memory = long(iq.getTag("query").getTag("archipel").getAttr("value"))
            self.setMemory(memory)
            self.log.info("virtual machine memory is set to %d" % memory)
        except libvirt.libvirtError as ex:
            reply = build_error_iq(self, ex, iq, ex.get_error_code(), ns=ARCHIPEL_NS_LIBVIRT_GENERIC_ERROR)
        except Exception as ex:
            reply = build_error_iq(self, ex, iq, ARCHIPEL_ERROR_CODE_VM_MEMORY)
        return reply
    
    
    def iq_setvcpus(self, iq):
        """
        set number of virtual cpus
        
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ
        
        @rtype: xmpp.Protocol.Iq
        @return: a ready to send IQ containing the result of the action
        """
        try:
            reply = iq.buildReply("result")
            cpus = int(iq.getTag("query").getTag("archipel").getAttr("value"))
            self.setVCPUs(cpus)
            self.log.info("virtual machine number of cpus is set to %d" % cpus)
            self.push_change("virtualmachine:control", "nvcpu", excludedgroups=['vitualmachines'])
            self.push_change("virtualmachine:definition", "nvcpu", excludedgroups=['vitualmachines'])
        except libvirt.libvirtError as ex:
            reply = build_error_iq(self, ex, iq, ex.get_error_code(), ns=ARCHIPEL_NS_LIBVIRT_GENERIC_ERROR)
        except Exception as ex:
            reply = build_error_iq(self, ex, iq, ARCHIPEL_ERROR_CODE_VM_MEMORY)
        return reply
    
    
    
    def iq_networkinfo(self, iq):
        """
        return info about network
        
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ
        
        @rtype: xmpp.Protocol.Iq
        @return: a ready to send IQ containing the result of the action
        """
        try:
            if not self.domain:
                return iq.buildReply("ignore")
            
            reply = iq.buildReply("result")
            infos = self.network_info()
            stats = []
            for info in infos:
                stats.append(xmpp.Node(tag="network", attrs=info))
            reply.setQueryPayload(stats)
        except libvirt.libvirtError as ex:
            if ex.get_error_code() == libvirt.VIR_ERR_NO_DOMAIN:
                return iq.buildReply("result")
            else:
                reply = build_error_iq(self, ex, iq, ex.get_error_code(), ns=ARCHIPEL_NS_LIBVIRT_GENERIC_ERROR)
        except Exception as ex:
            reply = build_error_iq(self, ex, iq, ARCHIPEL_ERROR_CODE_VM_NETWORKINFO)
        return reply
        
    
    
    def message_networkinfo(self, msg):
        try:
            s = self.network_info()
            resp = "My network info are :\n"
            for i in s:
                resp = resp + "%s : rx_bytes:%s rx_packets:%s rx_errs:%d rx_drop:%s / tx_bytes:%s tx_packets:%s tx_errs:%d tx_drop:%s" % (i["name"], i["rx_bytes"], i["rx_packets"], i["rx_errs"], i["rx_drop"], i["tx_bytes"], i["tx_packets"], i["tx_errs"], i["tx_drop"])
            return resp
        except Exception as ex:
            return build_error_message(self, ex)
        
    
    
    
    def message_insult(self, msg):
        return "Please, don't be so rude with me, I try to do my best everyday for you."
    
    
    def message_hello(self, msg):
        return "Hello %s! How are you today ?"% (msg.getFrom().getNode())
        
    
    
    # def iq_setcpuspin(self, iq):
    #     """
    #     set number of virtual cpus
    #     
    #     @type iq: xmpp.Protocol.Iq
    #     @param iq: the received IQ
    #     
    #     @rtype: xmpp.Protocol.Iq
    #     @return: a ready to send IQ containing the result of the action
    #     """
    #     try:
    #         reply = iq.buildReply("result")
    #         cpus = int(iq.getTag("query").getTag("archipel").getAttr("value"))
    #         self.setVCPUs(cpus)
    #         self.log.info("virtual machine number of cpus is set to %d" % cpus)
    #         self.push_change("virtualmachine:control", "nvcpu", excludedgroups=['vitualmachines'])
    #     except libvirt.libvirtError as ex:
    #         reply = build_error_iq(self, ex, iq, ex.get_error_code(), ns=ARCHIPEL_NS_LIBVIRT_GENERIC_ERROR)
    #     except Exception as ex:
    #         reply = build_error_iq(self, ex, iq, ARCHIPEL_ERROR_CODE_VM_MEMORY)
    #     return reply
    # 
