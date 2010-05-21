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
import appliancedecompresser
import appliancecompresser
from utils import *
import archipel
import sqlite3
import os


ARCHIPEL_APPLIANCES_INSTALLED = 1

class TNVMApplianceManager:
    
    def __init__(self, database_path, temp_directory, disks_extensions, hypervisor_repo_path, entity):
        self.entity = entity
        self.disks_extensions = disks_extensions.split(";")
        self.temp_directory = temp_directory
        self.database_connection = sqlite3.connect(database_path, check_same_thread = False)
        self.cursor = self.database_connection.cursor()
        self.is_installing = False
        self.installing_media_uuid = None
        self.is_installed = False
        self.hypervisor_repo_path = hypervisor_repo_path
    
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
        iqType = iq.getTag("query").getAttr("type")
        
        log(self, LOG_LEVEL_DEBUG, "VMCasting IQ received from {0} with type {1} / {2}".format(iq.getFrom(), iq.getType(), iqType))
        
        if iqType == "install":
            reply = self.__install(iq)
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed
            
        if iqType == "getinstalledappliances":
            reply = self.__get_installed_appliances(iq)
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed
            
        if iqType == "dettach":
            reply = self.__dettach(iq)
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed
        
        if iqType == "package":
            reply = self.__package(iq)
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
            uuid = iq.getTag("query").getAttr("uuid")
            nodes = []
            reply = iq.buildReply("success")
            self.cursor.execute("SELECT save_path, name, description, uuid FROM vmcastappliances WHERE status=%d" % (ARCHIPEL_APPLIANCES_INSTALLED))
            for values in self.cursor:
                path = values[0]
                name = values[1]
                description = values[2]
                uuid = values[3]
                
                status = "none"
                
                if self.is_installing and (self.installing_media_uuid == uuid):
                    status = "installing"
                else:
                    try:
                        f = open(self.entity.vm_own_folder + "/current.package", "r")
                        puuid = f.read()
                        f.close()
                        if puuid == uuid:
                            status = "installed"
                            self.is_installed = True
                    except:
                        pass

                node = xmpp.Node(tag="appliance", attrs={"path": path, "name": name, "description": description, "uuid": uuid, "status": status})
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
            if self.is_installing:
                raise Exception("Virtual machine is already installing a package")
            
            if (self.is_installed):
                raise Exception("You must dettach from already attached template")
            
            uuid = iq.getTag("query").getTag("uuid").getCDATA()
            requester = iq.getFrom()
            
            self.cursor.execute("SELECT * FROM vmcastappliances WHERE uuid=\"%s\"" % (uuid))
            for values in self.cursor:
                name, description, url, uuid, status, source, save_path = values
            
            log(self, LOG_LEVEL_DEBUG, "Supported extensions : %s " % str(self.disks_extensions))
            log(self, LOG_LEVEL_INFO, "will install appliance with uuid %s at path %s"  % (uuid, save_path))
            appliance_packager = appliancedecompresser.TNApplianceDecompresser(self.temp_directory, self.disks_extensions, save_path, self.entity.uuid, self.entity.vm_own_folder, self.entity.define, self.finish_installing, uuid, requester)
            
            self.old_status  = self.entity.xmppstatus
            self.old_show    = self.entity.xmppstatusshow
            self.entity.change_presence(presence_show="dnd", presence_status="Installing from appliance...")
            
            self.is_installing = True
            self.installing_media_uuid = uuid
            appliance_packager.start()
            
            self.entity.push_change("vmcasting", "applianceinstalling")
            
            reply = iq.buildReply('success')
        except Exception as ex:
            reply = build_error_iq(self, ex, iq)
            
        return reply

    def __dettach(self, iq):
        """
        detach an installed appliance from a virtualmachine 
        @type iq: xmpp.Protocol.Iq
        @param iq: the sender request IQ
        @rtype: xmpp.Protocol.Iq
        @return: a ready-to-send IQ containing the results
        """
        try:
            if self.is_installing:
                raise Exception("Virtual machine is already installing a package")

            package_file_path = self.entity.vm_own_folder + "/current.package"
            os.unlink(package_file_path)
            self.is_installed = False
            self.entity.push_change("vmcasting", "appliancedettached")
            
            reply = iq.buildReply('success')
        except Exception as ex:
            reply = build_error_iq(self, ex, iq)

        return reply
        
    def __package(self, iq):
        """
        package the current virtual machine
        @type iq: xmpp.Protocol.Iq
        @param iq: the sender request IQ
        @rtype: xmpp.Protocol.Iq
        @return: a ready-to-send IQ containing the results
        """
        try:
            if self.is_installing:
                raise Exception("Virtual machine is already installing a package")
            
            if not self.entity.definition:
                raise Exception("Virtual machine is not defined")
            
            disk_nodes      = self.entity.definition.getTag('devices').getTags('disk', attrs={'type': 'file'})
            package_name    = iq.getTag("query").getAttr("name")
            paths           = []
            
            if os.path.exists(self.hypervisor_repo_path + "/" + package_name + ".xvm2"):
                log(self, LOG_LEVEL_ERROR, self.hypervisor_repo_path + "/" + package_name + ".xvm2 already exists. aborting")
                raise Exception("Appliance with name %s is already in hypervisor repository" % package_name)
            
            self.old_status  = self.entity.xmppstatus
            self.old_show    = self.entity.xmppstatusshow
            self.entity.change_presence(presence_show="dnd", presence_status="Packaging myself...")
            
            for disk_node in disk_nodes:
                path = disk_node.getTag('source').getAttr('file')
                paths.append(path)
            
            compressor = appliancecompresser.TNApplianceCompresser(package_name, paths, self.entity.definition, "/tmp", "/tmp", self.entity.vm_own_folder, self.hypervisor_repo_path, self.finish_packaging)
            
            self.is_installing = True
            self.entity.push_change("vmcasting", "packaging")
            compressor.start()
            reply = iq.buildReply('success')
        except Exception as ex:
            reply = build_error_iq(self, ex, iq)

        return reply

    def finish_installing(self):
        self.is_installed = True
        self.is_installing = False
        self.installing_media_uuid = None
        self.entity.change_presence(presence_show=self.old_show, presence_status=self.old_status)
        self.entity.push_change("vmcasting", "applianceinstalled")
        self.entity.change_status("Off")
        self.entity.shout("appliance", "I've terminated to install from applicance.")
        
        
    def finish_packaging(self):
        self.is_installing = False
        self.entity.push_change("vmcasting", "packaged")
        self.entity.hypervisor.module_vmcasting.parse_own_repo(loop=False);
        self.entity.change_presence(presence_show=self.old_show, presence_status=self.old_status)
            
        