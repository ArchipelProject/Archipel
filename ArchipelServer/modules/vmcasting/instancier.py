# 
# instancier.py
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


import xmpp
import packager
from utils import *
import archipel
import sqlite3
import os


ARCHIPEL_APPLIANCES_INSTALLED = 1

class TNArchipelPackageInstancier:
    
    def __init__(self, database_path, temp_directory, disks_extensions, entity):
        self.entity = entity;
        self.disks_extensions = disks_extensions.split(";")
        self.temp_directory = temp_directory;
        self.database_connection = sqlite3.connect(database_path, check_same_thread = False)
        self.cursor = self.database_connection.cursor();
    
    def process_iq(self, conn, iq):
        """
        process incoming IQ of type NS_ARCHIPEL_HYPERVISOR_VMCASTING.
        it understands IQ of type:
            - install
            - getinstalledappliances
        
        @type conn: xmpp.Dispatcher
        @param conn: ths instance of the current connection that send the stanza
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ
        """
        iqType = iq.getTag("query").getAttr("type");
        
        log(self, LOG_LEVEL_DEBUG, "VMCasting IQ received from {0} with type {1} / {2}".format(iq.getFrom(), iq.getType(), iqType))
        
        if iqType == "install":
            reply = self.__install(iq)
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed
            
        if iqType == "getinstalledappliances":
            reply = self.__get_installed_appliances(iq)
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed
    
    
    def __get_installed_appliances(self, iq):
        """
        get all installed appliances
        
        @type iq: xmpp.Protocol.Iq
        @param iq: the sender request IQ
        @rtype: xmpp.Protocol.Iq
        @return: a ready-to-send IQ containing the results
        """
        try:
            uuid = iq.getTag("query").getAttr("uuid");
            nodes = [];
            reply = iq.buildReply("success");
            self.cursor.execute("SELECT save_path, name, description, uuid FROM vmcastappliances WHERE status=%d" % (ARCHIPEL_APPLIANCES_INSTALLED));
            for values in self.cursor:
                path = values[0]
                name = values[1]
                description = values[2]
                uuid = values[3]
                node = xmpp.Node(tag="appliance", attrs={"path": path, "name": name, "description": description, "uuid": uuid})
                nodes.append(node)
            reply.setQueryPayload(nodes)
        except Exception as ex:
            reply = build_error_iq(self, ex, iq)
        return reply
    
    
    def __install(self, iq):
        """
        instanciate a new virtualmachine from an installed appliance
        @type iq: xmpp.Protocol.Iq
        @param iq: the sender request IQ
        @rtype: xmpp.Protocol.Iq
        @return: a ready-to-send IQ containing the results
        """
        try:
            uuid = iq.getTag("query").getTag("uuid").getCDATA();
            
            self.cursor.execute("SELECT * FROM vmcastappliances WHERE uuid=\"%s\"" % (uuid));
            for values in self.cursor:
                name, description, url, uuid, status, source, save_path = values;
            
            log(self, LOG_LEVEL_DEBUG, "Supported extensions : %s " % str(self.disks_extensions));
            log(self, LOG_LEVEL_INFO, "will install appliance with uuid %s at path %s"  % (uuid, save_path));
            appliance_packager = packager.TNArchipelPackage(self.temp_directory, self.disks_extensions, save_path, self.entity.uuid, self.entity.vm_own_folder, self.entity.define);
            
            appliance_packager.start();
            
            reply = iq.buildReply('success');
        except Exception as ex:
            reply = build_error_iq(self, ex, iq)
            
        return reply
