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
import xmpp
import archipel
import commands
import os, sys

class TNMediaManagement:
    
    def __init__(self, shared_isos_folder, entity):
        self.entity = entity;
        self.shared_isos_folder =  shared_isos_folder


    def process_iq(self, conn, iq):
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
            query_node = iq.getTag("query");
            disk_name = query_node.getTag("name").getData()
            disk_size = query_node.getTag("size").getData()
            disk_unit = query_node.getTag("unit").getData()
        
            ret = os.system("qemu-img create -f qcow2 " + self.entity.vm_own_folder + "/" + disk_name + ".qcow2" + " " + disk_size + disk_unit);
            if not ret == 0:
                raise Exception("DriveError", "Unable to create drive. Error code is " + ret);
         
            reply = iq.buildReply('success')
            log(self, LOG_LEVEL_INFO, " disk created")
            self.push_change("disk", "created")
        except Exception as ex:
            reply = build_error_iq(self, ex, iq)
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
            query_node = iq.getTag("query");
            disk_name = query_node.getTag("name").getData();
        
            os.system("rm -rf " + disk_name);
        
            reply = iq.buildReply('success')
            log(self, LOG_LEVEL_INFO, " disk deleted")
            self.push_change("disk", "deleted")
        except Exception as ex:
            reply = build_error_iq(self, ex, iq)
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
            disks = commands.getoutput("ls " + self.entity.vm_own_folder).split()
            nodes = []
        
            for disk in disks:
                file_cmd_output = commands.getoutput("file " + self.entity.vm_own_folder + "/" + disk).lower();
                if (file_cmd_output.find("format: qcow") > -1) or (file_cmd_output.find("boot sector;") > -1):
                    diskinfo = commands.getoutput("qemu-img info " + self.entity.vm_own_folder + "/" + disk).split("\n");
                    node = xmpp.Node(tag="disk", attrs={ "name": disk,
                        "path": self.entity.vm_own_folder + "/" + disk,
                        "format": diskinfo[1].split(": ")[1],
                        "virtualSize": diskinfo[2].split(": ")[1],
                        "diskSize": diskinfo[3].split(": ")[1],
                    })
                    nodes.append(node);
        
            reply = iq.buildReply('success')
            reply.setQueryPayload(nodes);
            log(self, LOG_LEVEL_INFO, "info about disks sent")
        
        except Exception as ex:
            reply = build_error_iq(self, ex, iq)
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
            nodes = []
        
            isos = commands.getoutput("ls " + self.entity.vm_own_folder).split()
            for iso in isos:
                if commands.getoutput("file " + self.entity.vm_own_folder + "/" + iso).lower().find("iso 9660") > -1:
                    node = xmpp.Node(tag="iso", attrs={"name": iso, "path": self.entity.vm_own_folder + "/" + iso })
                    nodes.append(node);
        
            sharedisos = commands.getoutput("ls " + self.shared_isos_folder).split() 
            for iso in sharedisos:
                if commands.getoutput("file " + self.shared_isos_folder + "/" + iso).lower().find("iso 9660") > -1:
                    node = xmpp.Node(tag="iso", attrs={"name": iso, "path": self.shared_isos_folder + "/" + iso })
                    nodes.append(node);
        
            reply = iq.buildReply('success')
            reply.setQueryPayload(nodes);
            log(self, LOG_LEVEL_INFO, "info about iso sent")
        
        except Exception as ex:
            reply = build_error_iq(self, ex, iq)
        return reply    


    # def __networkstats(self, iq):
    #     """
    #     get statistics about network uses of the VM.
    # 
    #     @type iq: xmpp.Protocol.Iq
    #     @param iq: the received IQ
    # 
    #     @rtype: xmpp.Protocol.Iq
    #     @return: a ready to send IQ containing the result of the action
    #     """
    #     try:
    #         target_nodes = iq.getQueryPayload();
    #         nodes = [];
    #     
    #         for target in target_nodes:
    #             stats = self.domain.interfaceStats(target.getData());
    #             node = xmpp.Node(tag="stats", attrs={ "interface":    target.getData(),
    #                 "rx_bytes":     stats[0],
    #                 "rx_packets":   stats[1],
    #                 "rx_errs":      stats[2],
    #                 "rx_drops":     stats[3],
    #                 "tx_bytes":     stats[4],
    #                 "tx_packets":   stats[5],
    #                 "tx_errs":      stats[6],
    #                 "tx_drops":     stats[7]
    #             })
    #             nodes.append(node);
    #     
    #         reply = iq.buildReply('success')
    #         reply.setQueryPayload(nodes);
    #         log(self, LOG_LEVEL_INFO, "info about network sent");
    #     
    #     except Exception as ex:
    #         reply = build_error_iq(self, ex, iq)
    #     return reply



