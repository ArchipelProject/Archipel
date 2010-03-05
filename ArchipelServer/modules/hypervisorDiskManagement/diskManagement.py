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

NS_ARCHIPEL_VM_DISK = "trinity:vm:disk"


######################################################################################################
### Registring of the stanza
######################################################################################################

def __module_register_stanza__disk_management(self):
    self.xmppclient.RegisterHandler('iq', self.__process_iq_trinity_disk, typ=NS_ARCHIPEL_VM_DISK)

######################################################################################################
### Disk definition
######################################################################################################

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
        
    if iqType == "getiso":
        reply = self.__isos_get(iq)
        conn.send(reply)
        raise xmpp.protocol.NodeProcessed


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
        disks = commands.getoutput("ls " + path + " | grep qcow2").split()
        nodes = []
        
        for disk in disks:
            diskinfo = commands.getoutput("qemu-img info " + path + "/" + disk).split("\n");
            node = xmpp.Node(tag="disk", attrs={ "name": disk,
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


def __isos_get(self, iq):
    """
    Get the virtual cdrom ISO of the virtual machine
    
    @type iq: xmpp.Protocol.Iq
    @param iq: the received IQ
    
    @rtype: xmpp.Protocol.Iq
    @return: a ready to send IQ containing the result of the action
    """
    try:
        path = self.vm_disk_base_path + str(self.jid);
        nodes = []
        
        isos = commands.getoutput("ls " + path + " | grep iso").split()
        for iso in isos:
            node = xmpp.Node(tag="iso", attrs={"name": iso, "path": path + "/" + iso })
            nodes.append(node);
        
        print "ls " + self.shared_isos_folder + " | grep iso";
        sharedisos = commands.getoutput("ls " + self.shared_isos_folder + " | grep iso").split() 
        for iso in sharedisos:
            print "ISOOSOOS;"
            node = xmpp.Node(tag="iso", attrs={"name": iso, "path": self.shared_isos_folder + "/" + iso })
            nodes.append(node);
        
        reply = iq.buildReply('success')
        reply.setQueryPayload(nodes);
        log(self, LOG_LEVEL_INFO, "info about iso sent")
        
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
            node = xmpp.Node(tag="stats", attrs={ "interface":    target.getData(),
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


setattr(archipel.TNArchipelVirtualMachine, "__module_register_stanza__disk_management", __module_register_stanza__disk_management)
setattr(archipel.TNArchipelVirtualMachine, "__process_iq_trinity_disk", __process_iq_trinity_disk)
setattr(archipel.TNArchipelVirtualMachine, "__disk_create", __disk_create)
setattr(archipel.TNArchipelVirtualMachine, "__disk_delete", __disk_delete)
setattr(archipel.TNArchipelVirtualMachine, "__disk_get", __disk_get)
setattr(archipel.TNArchipelVirtualMachine, "__isos_get", __isos_get)
setattr(archipel.TNArchipelVirtualMachine, "__networkstats", __networkstats)

