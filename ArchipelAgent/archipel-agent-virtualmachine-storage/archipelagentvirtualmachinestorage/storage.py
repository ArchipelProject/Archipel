# -*- coding: utf-8 -*-
#
# storage.py
#
# Copyright (C) 2010 Antoine Mercadal <antoine.mercadal@inframonde.eu>
# Copyright, 2011 - Franck Villaume <franck.villaume@trivialdev.com>
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

import magic
import os
import subprocess
import xmpp

from archipelcore.archipelPlugin import TNArchipelPlugin
from archipel.archipelVirtualMachine import ARCHIPEL_ERROR_CODE_VM_MIGRATING
from archipelcore.utils import build_error_iq


ARCHIPEL_NS_VM_DISK                     = "archipel:vm:disk"
ARCHIPEL_ERROR_CODE_DRIVES_CREATE       = -3001
ARCHIPEL_ERROR_CODE_DRIVES_DELETE       = -3002
ARCHIPEL_ERROR_CODE_DRIVES_GET          = -3003
ARCHIPEL_ERROR_CODE_DRIVES_GETISO       = -3004
ARCHIPEL_ERROR_CODE_DRIVES_CONVERT      = -3005
ARCHIPEL_ERROR_CODE_DRIVES_RENAME       = -3006
ARCHIPEL_ERROR_CODE_DRIVES_GETGOLDEN    = -3007


class TNStorageManagement (TNArchipelPlugin):
    """
    Plugin that manages the storage volumes for virtual machines.
    """

    def __init__(self, configuration, entity, entry_point_group):
        """
        Initialize the plugin.
        @type configuration: Configuration object
        @param configuration: the configuration
        @type entity: L{TNArchipelEntity}
        @param entity: the entity that owns the plugin
        @type entry_point_group: string
        @param entry_point_group: the group name of plugin entry_point
        """
        TNArchipelPlugin.__init__(self, configuration=configuration, entity=entity, entry_point_group=entry_point_group)
        self.shared_isos_folder = self.configuration.get("STORAGE", "iso_base_path") + "/"
        self.golden_drives_dir = self.configuration.get("STORAGE", "golden_drives_dir")
        if self.configuration.has_option("STORAGE", "qemu_img_bin_path"):
            self.qemu_img_bin = self.configuration.get("STORAGE", "qemu_img_bin_path")
        else:
            self.qemu_img_bin = "qemu-img"
        if not os.path.exists(self.qemu_img_bin):
            raise Exception("qemu-img is not found at path %s. You may need to install it" % self.qemu_img_bin)
        if not os.path.exists(self.shared_isos_folder):
            os.makedirs(self.shared_isos_folder)
        if not os.path.exists(self.golden_drives_dir):
            os.makedirs(self.golden_drives_dir)
        self.magicObject = magic.Magic()
        # permissions
        self.entity.permission_center.create_permission("drives_create", "Authorizes user to get create a drive", False)
        self.entity.permission_center.create_permission("drives_delete", "Authorizes user to delete a drive", False)
        self.entity.permission_center.create_permission("drives_get", "Authorizes user to get all drives", False)
        self.entity.permission_center.create_permission("drives_getiso", "Authorizes user to get existing ISO images", False)
        self.entity.permission_center.create_permission("drives_convert", "Authorizes user to convert a drive", False)
        self.entity.permission_center.create_permission("drives_rename", "Authorizes user to rename a drive", False)


    ### Plugin interface

    def register_handlers(self):
        """
        This method will be called by the plugin user when it will be
        necessary to register module for listening to stanza.
        """
        self.entity.xmppclient.RegisterHandler('iq', self.process_iq, ns=ARCHIPEL_NS_VM_DISK)

    def unregister_handlers(self):
        """
        Unregister the handlers.
        """
        self.entity.xmppclient.UnregisterHandler('iq', self.process_iq, ns=ARCHIPEL_NS_VM_DISK)

    @staticmethod
    def plugin_info():
        """
        Return informations about the plugin.
        @rtype: dict
        @return: dictionary contaning plugin informations
        """
        plugin_friendly_name           = "Virtual Machine Storage"
        plugin_identifier              = "storage"
        plugin_configuration_section   = "STORAGE"
        plugin_configuration_tokens    = ["iso_base_path", "use_metadata_preallocation", "golden_drives_dir"]

        return {    "common-name"               : plugin_friendly_name,
                    "identifier"                : plugin_identifier,
                    "configuration-section"     : plugin_configuration_section,
                    "configuration-tokens"      : plugin_configuration_tokens }


    ### Utilities

    def _is_file_a_drive(self, path):
        """
        check if given drive is a valid virtual drive
        @type path: string
        @param path: the path of the file to check
        """
        return self._is_file_a_cow(path) \
        or self._is_file_a_qcow(path) \
        or self._is_file_a_qcow2(path) \
        or self._is_file_a_raw(path) \
        or self._is_file_a_vmdk(path) \
        or self._is_file_an_iso(path)

    def _is_file_a_cow(self, path):
        """
        check if given drive is a valid COW file
        @type path: string
        @param path: the path of the file to check
        """
        m = magic.Magic()
        output = m.from_file(path).lower()
        return "user-mode linux cow file" in output

    def _is_file_a_qcow(self, path):
        """
        check if given drive is a valid QCOW file
        @type path: string
        @param path: the path of the file to check
        """
        output = self.magicObject.from_file(path).lower()
        return "format: qcow , version: 1" in output or "qemu qcow image (v1)" in output

    def _is_file_a_qcow2(self, path):
        """
        check if given drive is a valid QCOW2 file
        @type path: string
        @param path: the path of the file to check
        """
        output = self.magicObject.from_file(path).lower()
        return "format: qcow , version: 2" in output or "qemu qcow image (v2)" in output

    def _is_file_a_raw(self, path):
        """
        check if given drive is a valid RAW drive
        @type path: string
        @param path: the path of the file to check
        """
        output = self.magicObject.from_file(path).lower()
        return output == "data" or "x86 boot sector" in output or "filesystem data" in output

    def _is_file_a_vmdk(self, path):
        """
        check if given drive is a valid VMDK
        @type path: string
        @param path: the path of the file to check
        """
        output = self.magicObject.from_file(path).lower()
        return "vmware" in output

    def _is_file_an_iso(self, path):
        """
        check if given drive is a valid ISO
        @type path: string
        @param path: the path of the file to check
        """
        output = self.magicObject.from_file(path).lower()
        return "iso 9660" in output


    ### XMPP Processing

    def process_iq(self, conn, iq):
        """
        Invoked when new ARCHIPEL_NS_VM_DISK IQ is received.
        It understands IQ of type:
            - create
            - delete
            - get
            - getiso
            - convert
            - rename
            - getgolden
        @type conn: xmpp.Dispatcher
        @param conn: ths instance of the current connection that send the message
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ
        """
        reply = None
        action = self.entity.check_acp(conn, iq)
        self.entity.check_perm(conn, iq, action, -1, prefix="drives_")
        if self.entity.is_migrating and (not action in ("get", "getiso")):
            reply = build_error_iq(self, "Virtual machine is migrating. Can't perform any drives operation.", iq, ARCHIPEL_ERROR_CODE_VM_MIGRATING)
        elif action == "create":
            reply = self.iq_create(iq)
        elif action == "delete":
            reply = self.iq_delete(iq)
        elif action == "get":
            reply = self.iq_get(iq)
        elif action == "getiso":
            reply = self.iq_getiso(iq)
        elif action == "convert":
            reply = self.iq_convert(iq)
        elif action == "rename":
            reply = self.iq_rename(iq)
        elif action == "getgolden":
            reply = self.iq_getgolden(iq)

        if reply:
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed

    def iq_create(self, iq):
        """
        Create a disk in given format.
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ
        @rtype: xmpp.Protocol.Iq
        @return: a ready to send IQ containing the result of the action
        """
        try:
            query_node  = iq.getTag("query")
            disk_name   = query_node.getTag("archipel").getAttr("name").replace(" ", "_").replace("/", "_").replace("..", "_")
            disk_size   = query_node.getTag("archipel").getAttr("size")
            disk_unit   = query_node.getTag("archipel").getAttr("unit")
            format      = query_node.getTag("archipel").getAttr("format")
            prealloc    = query_node.getTag("archipel").getAttr("preallocation")
            golden      = query_node.getTag("archipel").getAttr("golden")
            disk_path   = os.path.join(self.entity.folder, "%s.%s" % (disk_name, format))
            if disk_unit == "M" and (float(disk_size) >= 1000000000):
                raise Exception("too big", "You may be able to do it manually, but I won't try.")
            elif disk_unit == "G" and (float(disk_size) >= 10000):
                raise Exception("too big", "You may be able to do it manually, but I won't try.")
            if os.path.exists(disk_path):
                raise Exception("The disk with name %s already exists." % disk_name)

            if prealloc and prealloc == "metadata" and format == "qcow2" and self.entity.configuration.getboolean("STORAGE", "use_metadata_preallocation"):
                self.entity.log.info("Creating a QCOW2 file with preallocated metadata.")
                ret = subprocess.call([self.qemu_img_bin, "create", "-f", format, "-o", "preallocation=metadata", disk_path, "%s%s" % (disk_size, disk_unit)])
            elif golden and format == "qcow2":
                self.entity.log.info("Creating a differencing QCOW2 file with backing file.")
                if not os.path.exists(os.path.join(self.golden_drives_dir, golden)):
                    raise Exception("The requested golden image %s has not been found in the golden folder. Cannot create drive")
                else:
                    ret = subprocess.call([self.qemu_img_bin, "create", "-f", format, "-b", "%s/%s" % (self.golden_drives_dir, golden), disk_path, "%s%s" % (disk_size, disk_unit)])
            else:
                ret = subprocess.call([self.qemu_img_bin, "create", "-f", format, disk_path, "%s%s" % (disk_size, disk_unit)])
            if not ret == 0:
                raise Exception("DriveError", "Unable to create drive. Error code is " + str(ret))
            reply = iq.buildReply("result")
            self.entity.log.info("disk created")
            self.entity.shout("disk", "I've just created a new hard drive named %s with size of %s%s." % (disk_name, disk_size, disk_unit))
            self.entity.push_change("disk", "created")
        except Exception as ex:
            reply = build_error_iq(self, ex, iq, ARCHIPEL_ERROR_CODE_DRIVES_CREATE)
        return reply

    def iq_convert(self, iq):
        """
        Convert a disk from a format to another.
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ
        @rtype: xmpp.Protocol.Iq
        @return: a ready to send IQ containing the result of the action
        """
        try:
            old_status  = self.entity.xmppstatus
            old_show    = self.entity.xmppstatusshow
            query_node  = iq.getTag("query")
            path        = query_node.getTag("archipel").getAttr("path")
            format      = query_node.getTag("archipel").getAttr("format")
            disk_path   = path.replace(path.split(".")[-1], "") + format
            if os.path.exists(disk_path):
                raise Exception("The disk with same name and extension already exists.")
            self.entity.change_presence(presence_show="dnd", presence_status="Converting a disk...")
            ret = subprocess.call([self.qemu_img_bin, "convert", path, "-O", format, disk_path])
            if not ret == 0:
                raise Exception("DriveError", "Unable to convert drive. Error code is " + str(ret))
            os.unlink(path)
            for drive in self.entity.definition.getTag("devices").getTags("disk"):
                if drive.getTag("source"):
                    if drive.getTag("source").getAttr("file") == path:
                        if drive.getTag("driver"):
                            drive.getTag("driver").setAttr("type", format)
                        if drive.getTag("source"):
                            drive.getTag("source").setAttr("file", disk_path)
                        self.entity.define(self.entity.definition)
                        break
            self.entity.change_presence(presence_show=old_show, presence_status=old_status)
            reply = iq.buildReply("result")
            self.entity.log.info("Disk as been converted from %s to %s" % (path, disk_path))
            self.entity.shout("disk", "I've just converted hard drive %s into format %s." % (path, format))
            self.entity.push_change("disk", "converted")
        except Exception as ex:
            self.entity.change_presence(presence_show=old_show, presence_status=old_status)
            reply = build_error_iq(self, ex, iq, ARCHIPEL_ERROR_CODE_DRIVES_CONVERT)
        return reply

    def iq_rename(self, iq):
        """
        Rename a disk.
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ
        @rtype: xmpp.Protocol.Iq
        @return: a ready to send IQ containing the result of the action
        """
        try:
            query_node = iq.getTag("query")
            path = query_node.getTag("archipel").getAttr("path")
            newname = query_node.getTag("archipel").getAttr("newname").replace(" ", "_").replace("/", "_").replace("..", "_")
            extension = path.split(".")[-1]
            newpath = os.path.join(self.entity.folder, "%s.%s" % (newname, extension))
            if os.path.exists(newpath):
                raise Exception("The disk with name %s already exists." % newname)
            os.rename(path, newpath)
            reply = iq.buildReply("result")
            self.entity.log.info("Renamed hard drive %s into  %s" % (path, newname))
            self.entity.shout("disk", "I've just renamed hard drive %s into  %s." % (path, newname))
            self.entity.push_change("disk", "renamed")
        except Exception as ex:
            reply = build_error_iq(self, ex, iq, ARCHIPEL_ERROR_CODE_DRIVES_RENAME)
        return reply

    def iq_delete(self, iq):
        """
        Delete a virtual hard drive.
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ
        @rtype: xmpp.Protocol.Iq
        @return: a ready to send IQ containing the result of the action
        """
        try:
            query_node          = iq.getTag("query")
            disk_name           = query_node.getTag("archipel").getAttr("name")
            secure_disk_name    = disk_name.split("/")[-1]
            secure_disk_path    = os.path.join(self.entity.folder, secure_disk_name)
            old_status          = self.entity.xmppstatus
            old_show            = self.entity.xmppstatusshow
            self.entity.change_presence(presence_show="dnd", presence_status="Deleting a drive...")
            os.unlink(secure_disk_path)
            disk_nodes = []
            if self.entity.definition:
                devices_node = self.entity.definition.getTag('devices')
                disk_nodes = devices_node.getTags('disk', attrs={'type': 'file'})
            if query_node.getTag("archipel").getAttr("undefine") == "yes":
                have_undefined_at_least_on_disk = False
                for disk_node in disk_nodes:
                    path = disk_node.getTag('source').getAttr('file')
                    if path == secure_disk_path:
                        devices_node.delChild(disk_node)
                        have_undefined_at_least_on_disk = True
                if have_undefined_at_least_on_disk:
                    xml = str(self.entity.definition).replace('xmlns="http://www.gajim.org/xmlns/undeclared" ', '')
                    self.entity.libvirt_connection.defineXML(xml)
                    self.entity.push_change("virtualmachine:definition", "defined")
            self.entity.change_presence(presence_show=old_show, presence_status=old_status)
            reply = iq.buildReply("result")
            self.entity.log.info("disk %s deleted" % secure_disk_path)
            self.entity.push_change("disk", "deleted")
            self.entity.shout("disk", "I've just deleted the hard drive named %s." % (disk_name))
        except Exception as ex:
            reply = build_error_iq(self, ex, iq, ARCHIPEL_ERROR_CODE_DRIVES_DELETE)
        return reply

    def iq_get(self, iq):
        """
        Get the virtual hard drives of the virtual machine.
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ
        @rtype: xmpp.Protocol.Iq
        @return: a ready to send IQ containing the result of the action
        """
        try:
            disks = os.listdir(self.entity.folder)
            nodes = []
            for disk in disks:
                if self._is_file_a_drive(os.path.join(self.entity.folder, disk)):
                    diskPath = os.path.join(self.entity.folder, disk)
                    diskSize = os.path.getsize(diskPath)
                    diskInfo = subprocess.Popen([self.qemu_img_bin, "info", diskPath], stdout=subprocess.PIPE).communicate()[0].split("\n")
                    currentAttributes = {
                        "name": os.path.basename(os.path.splitext(disk)[0]),
                        "path": diskPath,
                        "format": diskInfo[1].split(": ")[1],
                        "virtualSize": diskInfo[2].split(" ")[3].replace("(", ""),
                        "diskSize": diskSize
                    }
                    if len(diskInfo) == 7:
                        currentAttributes["backingFile"] = os.path.basename(diskInfo[5].split()[2])
                    node = xmpp.Node(tag="disk", attrs=currentAttributes)
                    nodes.append(node)
            reply = iq.buildReply("result")
            reply.setQueryPayload(nodes)
            self.entity.log.info("Info about disks sent.")
        except Exception as ex:
            reply = build_error_iq(self, ex, iq, ARCHIPEL_ERROR_CODE_DRIVES_GET)
        return reply

    def iq_getiso(self, iq):
        """
        Get the virtual cdrom ISO of the virtual machine.
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ
        @rtype: xmpp.Protocol.Iq
        @return: a ready to send IQ containing the result of the action
        """
        try:
            nodes = []
            isos = os.listdir(self.entity.folder)
            for iso in isos:
                if self._is_file_an_iso(os.path.join(self.entity.folder, iso)):
                    node = xmpp.Node(tag="iso", attrs={"name": iso, "path": os.path.join(self.entity.folder, iso)})
                    nodes.append(node)
            sharedisos = os.listdir(self.shared_isos_folder)
            for iso in sharedisos:
                if self._is_file_an_iso(os.path.join(self.shared_isos_folder, iso)):
                    node = xmpp.Node(tag="iso", attrs={"name": iso, "path": os.path.join(self.shared_isos_folder, iso)})
                    nodes.append(node)
            reply = iq.buildReply("result")
            reply.setQueryPayload(nodes)
            self.entity.log.info("Info about iso sent.")
        except Exception as ex:
            reply = build_error_iq(self, ex, iq, ARCHIPEL_ERROR_CODE_DRIVES_GETISO)
        return reply

    def iq_getgolden(self, iq):
        """
        Get the list of golden qcow2 images
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ
        @rtype: xmpp.Protocol.Iq
        @return: a ready to send IQ containing the result of the action
        """
        try:
            nodes = []
            goldens = os.listdir(self.golden_drives_dir)
            for golden in goldens:
                if self._is_file_a_qcow(os.path.join(self.golden_drives_dir, golden)) \
                or self._is_file_a_qcow2(os.path.join(self.golden_drives_dir, golden)):
                    node = xmpp.Node(tag="golden", attrs={"name": golden, "path": os.path.join(self.golden_drives_dir, golden)})
                    nodes.append(node)
            reply = iq.buildReply("result")
            reply.setQueryPayload(nodes)
            self.entity.log.info("Info about golden sent.")
        except Exception as ex:
            reply = build_error_iq(self, ex, iq, ARCHIPEL_ERROR_CODE_DRIVES_GETGOLDEN)
        return reply
