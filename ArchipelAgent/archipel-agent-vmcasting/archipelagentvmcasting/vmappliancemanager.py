# -*- coding: utf-8 -*-
#
# vmappliancemanager.py
#
# Copyright (C) 2010 Antoine Mercadal <antoine.mercadal@inframonde.eu>
# This file is part of ArchipelProject
# http://archipelproject.org
#
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

import os
import sqlite3
import xmpp

from archipelcore.archipelPlugin import TNArchipelPlugin
from archipel.archipelVirtualMachine import ARCHIPEL_ERROR_CODE_VM_MIGRATING
from archipelcore.utils import build_error_iq

import appliancecompresser
import appliancedecompresser

ARCHIPEL_NS_VIRTUALMACHINE_VMCASTING        = "archipel:virtualmachine:vmcasting"
ARCHIPEL_APPLIANCES_INSTALLED               = 1
ARCHIPEL_ERROR_CODE_VMAPPLIANCES_INSTALL    = -4001
ARCHIPEL_ERROR_CODE_VMAPPLIANCES_GET        = -4002
ARCHIPEL_ERROR_CODE_VMAPPLIANCES_DETACH     = -4003
ARCHIPEL_ERROR_CODE_VMAPPLIANCES_PACKAGE    = -4004


class TNVMApplianceManager (TNArchipelPlugin):

    def __init__(self, configuration, entity, entry_point_group):
        """
        Initialize the class.
        @type configuration: Configuration object
        @param configuration: the configuration
        @type entity: L{TNArchipelEntity}
        @param entity: the entity that owns the plugin
        @type entry_point_group: string
        @param entry_point_group: the group name of plugin entry_point
        """
        TNArchipelPlugin.__init__(self, configuration=configuration, entity=entity, entry_point_group=entry_point_group)
        ## create directories if neede
        if not os.path.exists(self.configuration.get("VMCASTING", "repository_path")):
            os.makedirs(self.configuration.get("VMCASTING", "repository_path"))
        if not os.path.exists(self.configuration.get("VMCASTING", "temp_path")):
            os.makedirs(self.configuration.get("VMCASTING", "temp_path"))
        if not os.path.exists(self.configuration.get("VMCASTING", "own_vmcast_path")):
            os.makedirs(self.configuration.get("VMCASTING", "own_vmcast_path"))
        self.disks_extensions       =  self.configuration.get("VMCASTING", "disks_extensions").split(";")
        self.temp_directory         = self.configuration.get("VMCASTING", "temp_path")
        self.hypervisor_repo_path   = self.configuration.get("VMCASTING", "own_vmcast_path")
        self.is_installing          = False
        self.installing_media_uuid  = None
        self.is_installed           = False
        self.database_connection = sqlite3.connect(self.configuration.get("VMCASTING", "vmcasting_database_path"), check_same_thread = False)
        self.cursor = self.database_connection.cursor()
        # permissions
        self.entity.permission_center.create_permission("appliance_get", "Authorizes user to get installed appliances", False)
        self.entity.permission_center.create_permission("appliance_attach", "Authorizes user attach appliance to virtual machine", False)
        self.entity.permission_center.create_permission("appliance_detach", "Authorizes user to detach appliance_detach from virtual machine", False)
        self.entity.permission_center.create_permission("appliance_package", "Authorizes user to package new appliance from virtual machine", False)


    ### Plugin interface

    def register_for_stanza(self):
        """
        This method will be called by the plugin user when it will be
        necessary to register module for listening to stanza.
        """
        self.entity.xmppclient.RegisterHandler('iq', self.process_iq, ns=ARCHIPEL_NS_VIRTUALMACHINE_VMCASTING)

    @staticmethod
    def plugin_info():
        """
        Return informations about the plugin.
        @rtype: dict
        @return: dictionary contaning plugin informations
        """
        plugin_friendly_name           = "Virtual Machine Appliances"
        plugin_identifier              = "virtualmachine_appliance"
        plugin_configuration_section   = "VMCASTING"
        plugin_configuration_tokens    = [  "repository_path",
                                            "temp_path",
                                            "own_vmcast_path",
                                            "disks_extensions",
                                            "repository_path",
                                            "vmcasting_database_path"]
        return {    "common-name"               : plugin_friendly_name,
                    "identifier"                : plugin_identifier,
                    "configuration-section"     : plugin_configuration_section,
                    "configuration-tokens"      : plugin_configuration_tokens }


    ### Callbacks

    def finish_installing(self):
        """
        Used as callback for TNApplianceDecompresser.
        """
        self.is_installed = True
        self.is_installing = False
        self.installing_media_uuid = None
        self.entity.change_presence(presence_show=self.old_show, presence_status=self.old_status)
        self.entity.push_change("vmcasting", "applianceinstalled")
        self.entity.change_status("Off")
        self.entity.shout("appliance", "I've terminated to install from applicance.")

    def error_installing(self, exception):
        """
        Used as callback for TNApplianceDecompresser.
        """
        self.is_installed = False
        self.is_installing = False
        self.installing_media_uuid = None
        self.entity.change_presence(presence_show=self.old_show, presence_status=self.old_status)
        self.entity.push_change("vmcasting", "applianceerror")
        self.entity.change_status("Cannot install appliance")
        self.entity.shout("appliance", "Cannot install appliance: %s" % str(exception))

    def finish_packaging(self):
        """
        Used as callback for TNApplianceCompresser.
        """
        self.is_installing = False
        self.entity.push_change("vmcasting", "packaged")
        hypervisor_vmcast_plugin = self.entity.hypervisor.get_plugin("hypervisor_vmcasts")
        hypervisor_vmcast_plugin.parse_own_repo(loop=False)
        self.entity.change_presence(presence_show=self.old_show, presence_status=self.old_status)


    ### XMPP Processing

    def process_iq(self, conn, iq):
        """
        Process incoming IQ of type ARCHIPEL_NS_HYPERVISOR_VMCASTING.
        It understands IQ of type:
            - get
            - attach
            - detach
            - package
        @type conn: xmpp.Dispatcher
        @param conn: ths instance of the current connection that send the stanza
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ
        """
        reply = None
        action = self.entity.check_acp(conn, iq)
        self.entity.check_perm(conn, iq, action, -1, prefix="appliance_")
        if self.entity.is_migrating and (not action in ("get")):
            reply = build_error_iq(self, "Virtual machine is migrating. Can't perform any snapshoting operation.", iq, ARCHIPEL_ERROR_CODE_VM_MIGRATING)
        elif action == "get":
            reply = self.iq_get(iq)
        elif action == "attach":
            reply = self.iq_attach(iq)
        elif action == "detach":
            reply = self.iq_detach(iq)
        elif action == "package":
            reply = self.iq_package(iq)
        if reply:
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed

    def iq_get(self, iq):
        """
        Get all installed appliances.
        @type iq: xmpp.Protocol.Iq
        @param iq: the sender request IQ
        @rtype: xmpp.Protocol.Iq
        @return: a ready-to-send IQ containing the results
        """
        try:
            #uuid = iq.getTag("query").getTag("archipel").getAttr("uuid")
            nodes = []
            reply = iq.buildReply("result")
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
                        f = open(self.entity.folder + "/current.package", "r")
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
            reply = build_error_iq(self, ex, iq, ARCHIPEL_ERROR_CODE_VMAPPLIANCES_GET)
        return reply

    def iq_attach(self, iq):
        """
        Instanciate a new virtualmachine from an installed appliance.
        @type iq: xmpp.Protocol.Iq
        @param iq: the sender request IQ
        @rtype: xmpp.Protocol.Iq
        @return: a ready-to-send IQ containing the results
        """
        reply = iq.buildReply("result")
        try:
            if self.is_installing:
                raise Exception("Virtual machine is already installing a package.")
            if (self.is_installed):
                raise Exception("You must detach from already attached template.")
            uuid = iq.getTag("query").getTag("archipel").getAttr("uuid")
            requester = iq.getFrom()
            self.cursor.execute("SELECT * FROM vmcastappliances WHERE uuid=\"%s\"" % (uuid))
            for values in self.cursor:
                name, description, url, uuid, status, source, save_path = values
            self.entity.log.debug("Supported extensions : %s " % str(self.disks_extensions))
            self.entity.log.info("will install appliance with uuid %s at path %s"  % (uuid, save_path))
            appliance_packager = appliancedecompresser.TNApplianceDecompresser(self.temp_directory, self.disks_extensions, save_path, self.entity, self.finish_installing, self.error_installing, uuid, requester)
            self.old_status  = self.entity.xmppstatus
            self.old_show    = self.entity.xmppstatusshow
            self.entity.change_presence(presence_show="dnd", presence_status="Installing from appliance...")
            self.is_installing = True
            self.installing_media_uuid = uuid
            appliance_packager.start()
            self.entity.push_change("vmcasting", "applianceinstalling")
        except Exception as ex:
            reply = build_error_iq(self, ex, iq, ARCHIPEL_ERROR_CODE_VMAPPLIANCES_INSTALL)
        return reply

    def iq_detach(self, iq):
        """
        Detach an installed appliance from a virtualmachine.
        @type iq: xmpp.Protocol.Iq
        @param iq: the sender request IQ
        @rtype: xmpp.Protocol.Iq
        @return: a ready-to-send IQ containing the results
        """
        reply = iq.buildReply("result")
        try:
            if self.is_installing:
                raise Exception("Virtual machine is already installing a package.")
            package_file_path = self.entity.folder + "/current.package"
            os.unlink(package_file_path)
            self.is_installed = False
            self.entity.push_change("vmcasting", "appliancedetached")
        except Exception as ex:
            reply = build_error_iq(self, ex, iq, ARCHIPEL_ERROR_CODE_VMAPPLIANCES_DETACH)
        return reply

    def iq_package(self, iq):
        """
        Package the current virtual machine.
        @type iq: xmpp.Protocol.Iq
        @param iq: the sender request IQ
        @rtype: xmpp.Protocol.Iq
        @return: a ready-to-send IQ containing the results
        """
        reply = iq.buildReply("result")
        try:
            if self.is_installing:
                raise Exception("Virtual machine is already installing a package.")
            if not self.entity.definition:
                raise Exception("Virtual machine is not defined.")
            disk_nodes      = self.entity.definition.getTag('devices').getTags('disk', attrs={'type': 'file'})
            package_name    = iq.getTag("query").getTag("archipel").getAttr("name")
            paths           = []
            if os.path.exists(self.hypervisor_repo_path + "/" + package_name + ".xvm2"):
                self.entity.log.error(self.hypervisor_repo_path + "/" + package_name + ".xvm2 already exists. Aborting.")
                raise Exception("Appliance with name %s is already in hypervisor repository." % package_name)
            self.old_status  = self.entity.xmppstatus
            self.old_show    = self.entity.xmppstatusshow
            self.entity.change_presence(presence_show="dnd", presence_status="Packaging myself...")
            for disk_node in disk_nodes:
                path = disk_node.getTag('source').getAttr('file')
                paths.append(path)
            snapshots = []
            if self.entity.domain.hasCurrentSnapshot(0):
                snapshot_names = self.entity.domain.snapshotListNames(0)
                for snapshot_name in snapshot_names:
                    snapshotObject = self.entity.domain.snapshotLookupByName(snapshot_name, 0)
                    desc = snapshotObject.getXMLDesc(0)
                    snapshots.append(desc)
            working_dir = self.entity.configuration.get("VMCASTING", "temp_path")
            ## create directories if needed
            if not os.path.exists(working_dir):
                os.makedirs(working_dir)
            compressor = appliancecompresser.TNApplianceCompresser(package_name, paths, self.entity.definition, snapshots, working_dir, self.entity.folder, self.hypervisor_repo_path, self.finish_packaging, self.entity)
            self.is_installing = True
            self.entity.push_change("vmcasting", "packaging")
            compressor.start()
        except Exception as ex:
            reply = build_error_iq(self, ex, iq, ARCHIPEL_ERROR_CODE_VMAPPLIANCES_PACKAGE)
        return reply