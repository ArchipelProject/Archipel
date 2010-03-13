# 
# archipelHypervisor.py
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
Contains TNArchipelVirtualMachines, the entities uses for hypervisor

This provides the possibility to instanciate TNArchipelVirtualMachines
"""
import xmpp
import libvirt
import sys
import socket
import sqlite3
import datetime
import commands
import time
from threading import Thread
from utils import *
from archipelBasicXMPPClient import *
from archipelVirtualMachine import *

GROUP_VM = "virtualmachines"
GROUP_HYPERVISOR = "hypervisors"

NS_ARCHIPEL_HYPERVISOR_CONTROL = "archipel:hypervisor:control"


class TNThreadedVirtualMachine(Thread):
    """
    this class is used to run L{ArchipelVirtualMachine} main loop
    in a thread.
    """
    def __init__(self, jid, password, hypervisor, configuration):
        """
        the contructor of the class
        @type jid: string
        @param jid: the jid of the L{ArchipelVirtualMachine} 
        @type password: string
        @param password: the password associated to the JID
        """
        self.jid = jid
        self.password = password
        self.xmppvm = TNArchipelVirtualMachine(self.jid, self.password, hypervisor, configuration)
        Thread.__init__(self)
    
    
    def get_instance(self):
        """
        this method return the current L{ArchipelVirtualMachine} instance
        @rtype: ArchipelVirtualMachine
        @return: the L{ArchipelVirtualMachine} instance
        """
        return self.xmppvm
    
    
    def run(self):
        """
        overiddes sur super class method. do the L{ArchipelVirtualMachine} main loop
        """
        try:
            self.xmppvm.connect()
        except Exception as ex:
            log(self, LOG_LEVEL_ERROR, "vm has been stopped execption :" + str(ex))
    
  


   
class TNArchipelHypervisor(TNArchipelBasicXMPPClient):
    """
    this class represent an Hypervisor XMPP Capable. This is an XMPP client
    that allows to alloc threaded instance of XMPP Virtual Machine, destroy already
    active XMPP VM, and remember which have been created.
    """       
    
    ######################################################################################################
    ###  Super methods overrided
    ######################################################################################################
    
    def __init__(self, jid, password, configuration, database_file="./database.db"):
        """
        this is the constructor of the class.
        
        @type jid: string
        @param jid: the jid of the hypervisor
        @type password: string
        @param password: the password associated to the JID
        @type database_file: string
        @param database_file: the sqlite3 file to store existing VM for persistance
        """
        TNArchipelBasicXMPPClient.__init__(self, jid, password, configuration)
        self.virtualmachines = {};
        self.xmppserveraddr = jid.split("/")[0].split("@")[1];
        log(self, LOG_LEVEL_INFO, "server address defined as {0}".format(self.xmppserveraddr))
        self.database_file = database_file;
        self.__manage_persistance()
        
        self.libvirt_connection = libvirt.open(None)
        if self.libvirt_connection == None:
            log(self, LOG_LEVEL_ERROR, "unable to connect libvirt")
            sys.exit(0) 
        log(self, LOG_LEVEL_INFO, "connected to  libvirt")
        self.register_actions_to_perform_on_auth("set_vcard_entity_type", "hypervisor")
        
    
    
    def register_handler(self):
        """
        this method overrides the defaut register_handler of the super class.
        """
        self.xmppclient.RegisterHandler('iq', self.__process_iq_archipel_control, typ=NS_ARCHIPEL_HYPERVISOR_CONTROL)
        TNArchipelBasicXMPPClient.register_handler(self)
    
 
    def __manage_persistance(self):
        """
        if the database_file parameter contain a valid populated sqlite3 database,
        this method will recreate all the old L{TNArchipelVirtualMachine}. if not, it will create a 
        blank database file.
        """
        log(self, LOG_LEVEL_INFO, "opening database file {0}".format(self.database_file))
        self.database = sqlite3.connect(self.database_file)
        
        log(self, LOG_LEVEL_INFO, "populating database if not exists")
        try:
            self.database.execute("create table virtualmachines (jid text, password text, creation_date date, comment text)")
            log(self, LOG_LEVEL_INFO, "database schema created.")
        except Exception as ex:
            log(self, LOG_LEVEL_INFO, "tables seems to be already here. recovering.")
            c = self.database.cursor();
            c.execute("select * from virtualmachines")
            for vm in c:
                jid, password, date, comment = vm
                vm = self.__create_threaded_vm(jid, password)
                self.virtualmachines[jid.split("@")[0]] = vm
    
        
    def __create_threaded_vm(self, jid, password):
        """
        this method creates a threaded L{TNArchipelVirtualMachine}, start it and return the Thread instance
        @type jid: string
        @param jid: the JID of the L{TNArchipelVirtualMachine}
        @type password: string
        @param password: the password associated to the JID
        @rtype: L{TNThreadedVirtualMachine}
        @return: a L{TNThreadedVirtualMachine} instance of the virtual machine
        """
        vm = TNThreadedVirtualMachine(jid, password, self, self.configuration); #envoyer un bon mot de passe.
        vm.daemon = True
        vm.start()
        return vm    
    
    
    def disconnect(self):
        """
        this method overrides the super class method in order to 
        disconnect all active threads
        """
        for uuid in self.virtualmachines:
            self.virtualmachines[uuid].get_instance().set_loop_status(LOOP_OFF)
        TNArchipelBasicXMPPClient.disconnect(self)
    
    
    ######################################################################################################
    ###  Hypervisor controls
    ######################################################################################################
    
    def __alloc_xmppvirtualmachine(self, iq):
        """
        this method creates a threaded L{TNArchipelVirtualMachine} with UUID given 
        as paylood in IQ and register the hypervisor and the iq sender in 
        the VM's roster
        @type iq: xmpp.Protocol.Iq
        @param iq: the sender request IQ
        @rtype: xmpp.Protocol.Iq
        @return: a ready-to-send IQ containing the results
        """
        reply = None
        
        query = iq.getQueryChildren();
        
        domain_uuid = None;
        nickname = None;
        for node in query:
            if node.getName() == "jid":
                domain_uuid = query[0].getCDATA();
            if node.getName() == "nickname":
                nickname = query[1].getCDATA();
        
        
        if not domain_uuid:
            log(self, LOG_LEVEL_ERROR, "IQ malformed missing UUID")
            reply = iq.buildReply('error')
            reply.setQueryPayload(["missing UUID"])
            return reply
            
        vm_password = "password" #temp method
        vm_jid = "{0}@{1}".format(domain_uuid, self.xmppserveraddr)
        
        log(self, LOG_LEVEL_INFO, "adding the xmpp vm ({0}) to my roster".format(vm_jid))
        self.add_jid(vm_jid, [GROUP_VM])
        
        vm = self.__create_threaded_vm(vm_jid, vm_password)
        log(self, LOG_LEVEL_INFO, "XMPP VM thread started")
        
        log(self, LOG_LEVEL_INFO, "adding the requesting controller ({0}) to the VM's roster".format(iq.getFrom()))
        vm.get_instance().register_actions_to_perform_on_auth("add_jid", iq.getFrom().getStripped())
        
        log(self, LOG_LEVEL_INFO, "registering the new VM in hypervisor's memory")
        self.database.execute("insert into virtualmachines values(?,?,?,?)", (vm_jid,vm_password, datetime.datetime.now(), 'no comment'))
        self.database.commit()
        self.virtualmachines[domain_uuid] = vm
        
        reply = iq.buildReply('success')
        payload = xmpp.Node("virtualmachine", attrs={"jid": vm_jid})
        reply.setQueryPayload([payload])
        log(self, LOG_LEVEL_INFO, "XMPP Virtual Machine instance sucessfully initialized")
        return reply
    
             
    def __free_xmppvirtualmachine(self, iq):
        """
        this method destroy a threaded L{TNArchipelVirtualMachine} with UUID given 
        as paylood in IQ and remove it from the hypervisor roster
        
        @type iq: xmpp.Protocol.Iq
        @param iq: the sender request IQ
        @rtype: xmpp.Protocol.Iq
        @return: a ready-to-send IQ containing the results
        """
        reply = None
        
        vm_jid = str(iq.getQueryPayload()[0])
        domain_uuid = vm_jid.split("@")[0];
        
        try:
            vm = self.virtualmachines[domain_uuid];
        except KeyError as ex:
            log(self, LOG_LEVEL_ERROR, "Key Error exception raised no key {0}".format(ex))
            reply = iq.buildReply('error')
            reply.setQueryPayload(["Key {0} not found".format(ex)])
            return reply
        
        if (vm.get_instance().domain):
            if (vm.get_instance().domain.info()[0] == 1 or vm.get_instance().domain.info()[0] == 2 or vm.get_instance().domain.info()[0] == 3):
                vm.get_instance().domain.destroy()
            vm.get_instance().domain.undefine()
        
        log(self, LOG_LEVEL_INFO, "removing the xmpp vm ({0}) from my roster".format(vm_jid))
        self.remove_jid(vm_jid)
        
        log(self, LOG_LEVEL_INFO, "removing the vm drive directory")
        vm.get_instance().remove_own_folder();
        
        log(self, LOG_LEVEL_INFO, "unregistering the VM from hypervisor's database")
        self.database.execute("delete from virtualmachines where jid='{0}'".format(vm_jid))
        self.database.commit()
        
        del self.virtualmachines[domain_uuid]
        
        log(self, LOG_LEVEL_INFO, "unregistering vm from jabber server ".format(vm_jid))
        vm.get_instance()._inband_unregistration()
        
        reply = iq.buildReply('success')
        reply.setQueryPayload([xmpp.Node(tag="virtualmachine", attrs={"jid": vm_jid})]);
        
        log(self, LOG_LEVEL_INFO, "XMPP Virtual Machine instance sucessfully destroyed")
        return reply
    
   
    def __send_roster_virtualmachine(self, iq):
        """
        send the hypervisor roster content
        
        @type iq: xmpp.Protocol.Iq
        @param iq: the sender request IQ
        @rtype: xmpp.Protocol.Iq
        @return: a ready-to-send IQ containing the results
        """
        # TODO : add some ACL here later
        reply = iq.buildReply('success')
        nodes = []
        for item in self.roster.getItems():
            n = xmpp.Node("item")
            n.addData(item)
            nodes.append(n)
        reply.setQueryPayload(nodes)
        return reply
    
    
    ######################################################################################################
    ### XMPP Processing
    ######################################################################################################
    
    def __process_iq_archipel_control(self, conn, iq):
        """
        this method is invoked when a NS_ARCHIPEL_HYPERVISOR_CONTROL IQ is received.
        
        it understands IQ of type:
            - alloc
            - free
        
        @type conn: xmpp.Dispatcher
        @param conn: ths instance of the current connection that send the stanza
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ
        """
        log(self, LOG_LEVEL_DEBUG, "iq received from {0} with type {1}".format(iq.getFrom(), iq.getType()))
        
        iqType = iq.getTag("query").getAttr("type");
        
        if iqType == "alloc":
            reply = self.__alloc_xmppvirtualmachine(iq)
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed
        
        if iqType == "free":
            reply = self.__free_xmppvirtualmachine(iq)
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed
        
        if iqType == "rostervm":
            reply = self.__send_roster_virtualmachine(iq)
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed

  



            