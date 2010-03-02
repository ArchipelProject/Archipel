"""
Contains TrinityVM, the XMPP capable controller

This module contain the class TrinityVM that represents a virtual machine
linked to a libvirt domain and allowing other XMPP entities to control it using IQ.

The TrinityVM is able to register to any kind of XMPP compliant Server. These 
Server SHOULD allow in-band registration, or you have to manually register VM before 
launching them.

Also the JID of the virtual machine MUST be the UUID use in the libvirt domain, or it will
fail.
"""
import xmpp
import libvirt
import sys
import socket
import os
import commands
from utils import *
from trinitybasic import *

VIR_DOMAIN_NOSTATE	                        =	0;
VIR_DOMAIN_RUNNING	                        =	1;
VIR_DOMAIN_BLOCKED	                        =	2;
VIR_DOMAIN_PAUSED	                        =	3;
VIR_DOMAIN_SHUTDOWN	                        =	4;
VIR_DOMAIN_SHUTOFF	                        =	5;
VIR_DOMAIN_CRASHED	                        =	6;

NS_ARCHIPEL_VM_CONTROL      = "trinity:vm:control"
NS_ARCHIPEL_VM_DEFINITION   = "trinity:vm:definition"
NS_ARCHIPEL_VM_DISK         = "trinity:vm:disk"

class TrinityVM(TrinityBase):
    """
    this class represent an Virtual Machine, XMPP Capable.
    this class need to already have 
    """

    ######################################################################################################
    ###  Super methods overrided
    ######################################################################################################
    
    def __init__(self, jid, password):
        TrinityBase.__init__(self, jid, password)
        self.libvirt_connection = None;
        self.register_actions_to_perform_on_auth("set_vcard_entity_type", "virtualmachine")
        self.register_actions_to_perform_on_auth("connect_libvirt", None)
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(('google.com', 0));
        ipaddr, other = s.getsockname();
        self.vm_disk_base_path = "/vm/drives/" #### TODO: add config
        
        if not os.path.isdir(self.vm_disk_base_path + jid):
            os.mkdir(self.vm_disk_base_path + jid);
                
        self.ipaddr = ipaddr;
    
    
    def register_handler(self):
        """
        this method registers the events handlers.
        it is invoked by super class __xmpp_connect() method
        """
        self.xmppclient.RegisterHandler('iq', self.__process_iq_trinity_control, typ=NS_ARCHIPEL_VM_CONTROL)
        self.xmppclient.RegisterHandler('iq', self.__process_iq_trinity_definition, typ=NS_ARCHIPEL_VM_DEFINITION)
        self.xmppclient.RegisterHandler('iq', self.__process_iq_trinity_disk, typ=NS_ARCHIPEL_VM_DISK)
        #self.xmppclient.RegisterHandler('message', self.__process_message)

        TrinityBase.register_handler(self)
    
    
    # def connect(self):
    #     """
    #     Connects to XMPP server and libvirt. it overrides the super class
    #     method in order to connect also from libvirt
    #     """
    #     self.__connect_libvirt()
    #     self._connect_xmpp()
    #     self._auth_xmpp()
    
   
    def disconnect(self):
        """
        Close the connections to libvirt and XMPP server. it overrides the super class 
        method in order to connect also from libvirt
        """
        self.xmppclient.disconnect()
        if self.libvirt_connection:
            self.libvirt_connection.close() 
    
    
       
    ######################################################################################################
    ### Libvirt bindings
    ###################################################################################################### 
    
    def connect_libvirt(self):
        """
        Initialize the connection to the libvirt first, and
        then to the domain by looking the uuid used as JID Node
        
        exit on any error.
        """
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
            log(self, LOG_LEVEL_ERROR, "Exception raised #{0} : {1}".format(ex.get_error_code(), ex))
            self.change_presence("dnd", "shutdown");
            return
        except:
            log(self, LOG_LEVEL_ERROR, "unexpected exception")
            sys.exit(0)
    
    
    def __create(self, iq):
        """
        Create a domain using libvirt connection
        
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ
        
        @rtype: xmpp.Protocol.Iq
        @return: a ready to send IQ containing the result of the action
        """
        reply = None
        try:
            self.domain.create()
            reply = iq.buildReply('success')
            payload = xmpp.Node("domain", attrs={"id": str(self.domain.ID())})
            reply.setQueryPayload([payload])
            log(self, LOG_LEVEL_INFO, "virtual machine created")
            self.change_presence("", "Running");
        except libvirt.libvirtError as ex:
            log(self, LOG_LEVEL_ERROR, "exception raised is : {0}".format(ex))
            reply = iq.buildReply('error')
            payload = xmpp.Node("error", attrs={"code": str(ex.get_error_code())})
            payload.addData(str(ex))
            reply.setQueryPayload([payload])
        return reply
    
    
    def __shutdown(self, iq):
        """
        Shutdown a domain using libvirt connection
        
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ
        
        @rtype: xmpp.Protocol.Iq
        @return: a ready to send IQ containing the result of the action
        """
        reply = None
        try:
            self.domain.shutdown()
            reply = iq.buildReply('success')
            log(self, LOG_LEVEL_INFO, "virtual machine shutdowned")
            self.change_presence("xa", "shutdown");
        except libvirt.libvirtError as ex:
            log(self, LOG_LEVEL_ERROR, "exception raised is : {0}".format(ex))
            reply = iq.buildReply('error')
            payload = xmpp.Node("error", attrs={"code": str(ex.get_error_code())})
            payload.addData(str(ex))
            reply.setQueryPayload([payload])
        return reply
    
    
    def __reboot(self, iq):
        """
        Reboot a domain using libvirt connection
        
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ
        
        @rtype: xmpp.Protocol.Iq
        @return: a ready to send IQ containing the result of the action
        """
        reply = None
        try:
            self.domain.reboot(0) # flags not used in libvirt but required.
            reply = iq.buildReply('success')
            log(self, LOG_LEVEL_INFO, "virtual machine rebooted")
        except libvirt.libvirtError as ex:
            log(self, LOG_LEVEL_ERROR, "exception raised is : {0}".format(ex))
            reply = iq.buildReply('error')
            payload = xmpp.Node("error", attrs={"code": str(ex.get_error_code())})
            payload.addData(str(ex))
            reply.setQueryPayload([payload])
        return reply
    
    
    def __suspend(self, iq):
        """
        Suspend (pause) a domain using libvirt connection
        
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ
        
        @rtype: xmpp.Protocol.Iq
        @return: a ready to send IQ containing the result of the action
        """
        reply = None
        try:
            self.domain.suspend()
            reply = iq.buildReply('success')
            log(self, LOG_LEVEL_INFO, "virtual machine suspended")
            self.change_presence("away", "paused");
        except libvirt.libvirtError as ex:
            log(self, LOG_LEVEL_ERROR, "exception raised is : {0}".format(ex))
            reply = iq.buildReply('error')
            payload = xmpp.Node("error", attrs={"code": str(ex.get_error_code())})
            payload.addData(str(ex))
            reply.setQueryPayload([payload])
        return reply
    
   
    def __resume(self, iq):
        """
        Resume (unpause) a domain using libvirt connection
        
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ

        @rtype: xmpp.Protocol.Iq
        @return: a ready to send IQ containing the result of the action
        """
        reply = None
        try:
            self.domain.resume()
            reply = iq.buildReply('success')
            log(self, LOG_LEVEL_INFO, "virtual machine resumed")
            self.change_presence("", "running");
        except libvirt.libvirtError as ex:
            log(self, LOG_LEVEL_ERROR, "exception raised is : {0}".format(ex))
            reply = iq.buildReply('error')
            payload = xmpp.Node("error", attrs={"code": str(ex.get_error_code())})
            payload.addData(str(ex))
            reply.setQueryPayload([payload])
        return reply
    
    
    def __info(self, iq):
        """
        Return an IQ containing the info of the domain using libvirt connection
        
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ

        @rtype: xmpp.Protocol.Iq
        @return: a ready to send IQ containing the result of the action
        """
        reply = None
        try:
            reply = iq.buildReply('success')
            dominfo = self.domain.info()
            response = xmpp.Node(tag="info", attrs={
                "state": dominfo[0],
                "maxMem": dominfo[1],
                "memory": dominfo[2],
                "nrVirtCpu": dominfo[3],
                "cpuTime": dominfo[4]
            })
            reply.setQueryPayload([response])
            log(self, LOG_LEVEL_DEBUG, "virtual machine info sent")
        except libvirt.libvirtError as ex:
            log(self, LOG_LEVEL_ERROR, "exception raised is : {0}".format(ex))
            reply = iq.buildReply('error')
            payload = xmpp.Node("error", attrs={"code": str(ex.get_error_code())})
            payload.addData(str(ex))
            reply.setQueryPayload([payload])
                
        except Exception as ex:
            log(self, LOG_LEVEL_ERROR, "exception raised is : {0}".format(ex))
            reply = iq.buildReply('error')
            reply.setQueryPayload([str(ex)])
        return reply
    
    
    def __define(self, iq):
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
            print "self.jid.getNode() : " + str(self.jid.getNode());
            domain_node = xmpp.simplexml.XML2Node(str(iq.getQueryPayload()[0]));
            domain_uuid = domain_node.getTag("uuid").getData()
            if domain_uuid != self.jid.getNode():
                log(self, LOG_LEVEL_ERROR, "given UUID {0} doesn't match JID {1}".format(domain_uuid, self.jid.getNode()))
                reply = iq.buildReply('error')
                return reply
        except Exception as ex:
            log(self, LOG_LEVEL_ERROR, "exception raised is : {0}".format(ex))
            reply = iq.buildReply('error')
            reply.setQueryPayload([str(ex)])
            return reply 
            
        try:
            reply = iq.buildReply('success')
            self.libvirt_connection.defineXML(str(iq.getQueryPayload()[0]))
            log(self, LOG_LEVEL_INFO, "virtual machine XML is defined")
            if not self.domain:
                self.connect_libvirt()
        except libvirt.libvirtError as ex:
            log(self, LOG_LEVEL_ERROR, "exception raised is : {0}".format(ex))
            reply = iq.buildReply('error')
            payload = xmpp.Node("error", attrs={"code": str(ex.get_error_code())})
            payload.addData(str(ex))
            reply.setQueryPayload([payload])
        return reply
    
    
    def __undefine(self, iq):
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
            reply = iq.buildReply('success')
            self.domain.undefine()
            log(self, LOG_LEVEL_INFO, "virtual machine is undefined")
        except libvirt.libvirtError as ex:
            log(self, LOG_LEVEL_ERROR, "exception raised is : {0}".format(ex))
            reply = iq.buildReply('error')
            payload = xmpp.Node("error", attrs={"code": str(ex.get_error_code())})
            payload.addData(str(ex))
            reply.setQueryPayload([payload])
        return reply
    
    
    def __vncdisplay(self, iq):
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
        except libvirt.libvirtError as ex:
            log(self, LOG_LEVEL_ERROR, "exception raised is : {0}".format(ex))
            reply = iq.buildReply('error')
            payload = xmpp.Node("error", attrs={"code": str(ex.get_error_code())})
            payload.addData(str(ex))
            reply.setQueryPayload([payload])
        except Exception as ex:
            log(self, LOG_LEVEL_ERROR, "exception raised is : {0}".format(ex))
            reply = iq.buildReply('error')
            reply.setQueryPayload([str(ex)])
        return reply
    
    
    def __xml_description(self, iq):
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
        except libvirt.libvirtError as ex:
            log(self, LOG_LEVEL_ERROR, "exception raised is : {0}".format(ex))
            reply = iq.buildReply('error')
            payload = xmpp.Node("error", attrs={"code": str(ex.get_error_code())})
            payload.addData(str(ex))
            reply.setQueryPayload([payload])
        except Exception as ex:
            log(self, LOG_LEVEL_ERROR, "exception raised is : {0}".format(ex))
            reply = iq.buildReply('error')
            reply.setQueryPayload([str(ex)])
        return reply
    
    
    def __disk_create(self, iq):
        """
        Create a disk in QCOW2 format

        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ

        @rtype: xmpp.Protocol.Iq
        @return: a ready to send IQ containing the result of the action
        """
        try:
            path = self.vm_disk_base_path + str(self.jid);
            if not os.path.isdir(path):
                os.mkdir(path);
            
            query_node = iq.getTag("query");
            disk_name = query_node.getTag("name").getData()
            disk_size = query_node.getTag("size").getData()
            disk_unit = query_node.getTag("unit").getData()
        
            os.system("qemu-img create -f qcow2 " + path + "/" + disk_name + ".qcow2" + " " + disk_size + disk_unit);
        
            reply = iq.buildReply('success')
            log(self, LOG_LEVEL_INFO, " disk created")
        except Exception as ex:
            log(self, LOG_LEVEL_ERROR, "exception raised is : {0}".format(ex))
            reply = iq.buildReply('error')
            payload = xmpp.Node("error", attrs={})
            payload.addData(str(ex))
            reply.setQueryPayload([payload])
        return reply
    
    def __disk_delete(self, iq):
        """
        delete a virtual hard drive

        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ

        @rtype: xmpp.Protocol.Iq
        @return: a ready to send IQ containing the result of the action
        """
        try:
            path = self.vm_disk_base_path + str(self.jid);
        
            query_node = iq.getTag("query");
            disk_name = query_node.getTag("name").getData();
        
            os.system("rm -rf " + disk_name);
    
            reply = iq.buildReply('success')
            log(self, LOG_LEVEL_INFO, " disk deleted")
        except Exception as ex:
            log(self, LOG_LEVEL_ERROR, "exception raised is : {0}".format(ex))
            reply = iq.buildReply('error')
            payload = xmpp.Node("error", attrs={})
            payload.addData(str(ex))
            reply.setQueryPayload([payload])
        return reply
    
    def __disk_get(self, iq):
        """
        Get the virtual hatd drives of the virtual machine

        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ

        @rtype: xmpp.Protocol.Iq
        @return: a ready to send IQ containing the result of the action
        """
        try:
            path = self.vm_disk_base_path + str(self.jid);
            disks = commands.getoutput("ls " + path).split()
            nodes = []
            
            for disk in disks:
                diskinfo = commands.getoutput("qemu-img info " + path + "/" + disk).split("\n");
                node = xmpp.Node(tag="disk", attrs={
                    "name": disk,
                    "path": path + "/" + disk,
                    "format": diskinfo[1].split(": ")[1],
                    "virtualSize": diskinfo[2].split(": ")[1],
                    "diskSize": diskinfo[3].split(": ")[1],
                })
                nodes.append(node);
        
            reply = iq.buildReply('success')
            reply.setQueryPayload(nodes);
            log(self, LOG_LEVEL_INFO, "info about disks sent")
            
        except Exception as ex:
            log(self, LOG_LEVEL_ERROR, "exception raised is : {0}".format(ex))
            reply = iq.buildReply('error')
            payload = xmpp.Node("error", attrs={})
            payload.addData(str(ex))
            reply.setQueryPayload([payload])
        return reply
        
    def __networkstats(self, iq):
        """
        get statistics about network uses of the VM.

        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ

        @rtype: xmpp.Protocol.Iq
        @return: a ready to send IQ containing the result of the action
        """
        try:
            target_nodes = iq.getQueryPayload();
            nodes = [];
            
            for target in target_nodes:
                stats = self.domain.interfaceStats(target.getData());
                node = xmpp.Node(tag="stats", attrs={
                    "interface":    target.getData(),
                    "rx_bytes":     stats[0],
                    "rx_packets":   stats[1],
                    "rx_errs":      stats[2],
                    "rx_drops":     stats[3],
                    "tx_bytes":     stats[4],
                    "tx_packets":   stats[5],
                    "tx_errs":      stats[6],
                    "tx_drops":     stats[7]
                })
                nodes.append(node);
            
            reply = iq.buildReply('success')
            reply.setQueryPayload(nodes);
            log(self, LOG_LEVEL_INFO, "info about network sent");
            
        except Exception as ex:
            log(self, LOG_LEVEL_ERROR, "exception raised is : {0}".format(ex))
            reply = iq.buildReply('error')
            payload = xmpp.Node("error", attrs={})
            payload.addData(str(ex))
            reply.setQueryPayload([payload])
        return reply
      
    ######################################################################################################
    ### XMPP Processing
    ######################################################################################################
       
    def __process_message(self, conn, msg):
        """
        Handler for incoming message. this method is not implemented.
        
        @type conn: xmpp.Dispatcher
        @param conn: ths instance of the current connection that send the message
        @type msg: xmpp.Protocol.Message
        @param msg: the received message 
        """
        log(self, LOG_LEVEL_DEBUG, "message received : {0}".format(msg))        
    

    def __process_iq_trinity_control(self, conn, iq):
        """
        Invoked when new trinity:vm:control IQ is received. 
        
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
        log(self, LOG_LEVEL_DEBUG, "Control IQ received from {0} with type {1}".format(iq.getFrom(), iq.getType()))
        
        #if not self.is_jid_subscribed(xmpp.JID(iq.getFrom())):
        #    return
            #reply = iq.buildReply('error')
            #response = xmpp.Node(tag="subscription-required")
            #reply.setQueryPayload([response])
            #raise xmpp.protocol.NodeProcessed
        
        
        iqType = iq.getTag("query").getAttr("type");
        
        if iqType == "info":
            reply = self.__info(iq)
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed
        
        if iqType == "create":
            reply = self.__create(iq)
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed
        
        if iqType == "shutdown":
            reply = self.__shutdown(iq)
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed
        
        if iqType == "reboot":
            reply = self.__reboot(iq)
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed
        
        if iqType == "suspend":
            reply = self.__suspend(iq)
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed
            
        if iqType == "resume":
            reply = self.__resume(iq)
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed

        if iqType == "vncdisplay":
            reply = self.__vncdisplay(iq)
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed

        if iqType == "xmldesc":
            reply = self.__xml_description(iq)
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed
            
        if iqType == "networkstats":
            reply = self.__networkstats(iq)
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed
    
            
    def __process_iq_trinity_definition(self, conn, iq):
        """
        Invoked when new trinity:define IQ is received.
        
        it understands IQ of type:
            - define (the domain xml must be sent as payload of IQ, and the uuid *MUST*, be the same as the JID of the client)
            - undefine (undefine a virtual machine domain)
        
        @type conn: xmpp.Dispatcher
        @param conn: ths instance of the current connection that send the message
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ
        """
        log(self, LOG_LEVEL_DEBUG, "Definition IQ received from {0} with type {1}".format(iq.getFrom(), iq.getType()))
        
        iqType = iq.getTag("query").getAttr("type");
        
        if iqType == "define":
            reply = self.__define(iq)
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed
        
        if iqType == "undefine":
            reply = self.__undefine(iq)
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed        
    

    def __process_iq_trinity_disk(self, conn, iq):
        """
        Invoked when new NS_ARCHIPEL_VM_DISK IQ is received.

        it understands IQ of type:
        - create
        - delete
        - get

        @type conn: xmpp.Dispatcher
        @param conn: ths instance of the current connection that send the message
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ
        """
        log(self, LOG_LEVEL_DEBUG, "Disk IQ received from {0} with type {1}".format(iq.getFrom(), iq.getType()))

        iqType = iq.getTag("query").getAttr("type");
        
        if iqType == "create":
            reply = self.__disk_create(iq)
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed

        if iqType == "delete":
            reply = self.__disk_delete(iq)
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed

        if iqType == "get":
            reply = self.__disk_get(iq)
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed
    
    
