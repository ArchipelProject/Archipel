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
from utils import *
from trinitybasic import *


class TrinityVM(TrinityBase):
    """
    this class represent an Virtual Machine, XMPP Capable.
    this class need to already have 
    """

    ######################################################################################################
    ###  Super methods overrided
    ######################################################################################################
    
    def register_handler(self):
        """
        this method registers the events handlers.
        it is invoked by super class __xmpp_connect() method
        """
        self.xmppclient.RegisterHandler('iq', self.__process_iq_trinity_control, ns="trinity:vm:control")
        self.xmppclient.RegisterHandler('iq', self.__process_iq_trinity_definition, ns="trinity:vm:definition")
        #self.xmppclient.RegisterHandler('message', self.__process_message)

        TrinityBase.register_handler(self)
    
    
    def connect(self):
        """
        Connects to XMPP server and libvirt. it overrides the super class
        method in order to connect also from libvirt
        """
        self.__connect_libvirt()
        self._connect_xmpp()
        self._auth_xmpp()
    
   
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
    
    def __connect_libvirt(self):
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
        except libvirt.libvirtError as ex:
            log(self, LOG_LEVEL_ERROR, "Exception raised #{0} : {1}".format(ex.get_error_code(), ex))
            return
        except:
            log(self, LOG_LEVEL_ERROR, "unexpected exception")
            sys.exit(0)
        log(self, LOG_LEVEL_DEBUG, "domain infos : ".format(self.domain.info()))
    
    
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
            log(self, LOG_LEVEL_INFO, "virtual machine info sent")
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
                self.__connect_libvirt()
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
        
        if not self.is_jid_subscribed(xmpp.JID(iq.getFrom())):
            return
            #reply = iq.buildReply('error')
            #response = xmpp.Node(tag="subscription-required")
            #reply.setQueryPayload([response])
            #raise xmpp.protocol.NodeProcessed
        
        if iq.getType() == "info":
            reply = self.__info(iq)
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed
        
        if iq.getType() == "create":
            reply = self.__create(iq)
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed
        
        if iq.getType() == "shutdown":
            reply = self.__shutdown(iq)
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed
        
        if iq.getType() == "reboot":
            reply = self.__reboot(iq)
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed
        
        if iq.getType() == "suspend":
            reply = self.__suspend(iq)
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed
            
        if iq.getType() == "resume":
            reply = self.__resume(iq)
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

        if iq.getType() == "define":
            reply = self.__define(iq)
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed
        
        if iq.getType() == "undefine":
            reply = self.__undefine(iq)
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed
    
