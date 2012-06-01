# -*- coding: utf-8 -*-
#
# appliancedecompresser.py
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

import os
import shutil
import tarfile
import tempfile
import xmpp
from gzip import GzipFile as gz
from threading import Thread

from archipel.archipelLibvirtEntity import generate_mac_adress

class TNApplianceDecompresser (Thread):

    def __init__(self, working_dir, disk_exts, xvm2_package_path, entity, finish_callback, error_callback, package_uuid, requester):
        """
        Initialize a TNApplianceDecompresser.
        @type working_dir: string
        @param working_dir: the base dir where TNApplianceDecompresser will works
        @type disk_exts: array
        @param disk_exts: contains all the extensions that should be considered as a disks with the initial dot (ie: .gz)
        @type xvm2_package_path: string
        @param xvm2_package_path: path of the xvm2 file
        @type entity: L{TNArchipelVirtualMachine}
        @param entity: the virtual machine
        @type finish_callback: function
        @param finish_callback: called when decompression is done sucessfully
        @type error_callback: function
        @param error_callback: called when decompression has failed
        @type package_uuid: string
        @param package_uuid: UUID of the package
        @type requester: xmpp.Protocol.JID
        @param requester: the JID of the requester
        """
        self.working_dir        = working_dir
        self.disk_extensions    = disk_exts
        self.xvm2_package_path  = xvm2_package_path
        self.entity             = entity
        self.finish_callback    = finish_callback
        self.error_callback     = error_callback
        self.package_uuid       = package_uuid
        self.requester          = requester
        self.install_path       = entity.folder
        self.description_file   = None
        self.disk_files         = {}
        self.snapshots_desc     = []
        Thread.__init__(self)

    def run(self):
        """
        Run the thread.
        """
        try:
            self.entity.log.info("TNApplianceDecompresser: unpacking to %s" % self.working_dir)
            try:
                self.entity.log.info("TNApplianceDecompresser: unpacking to %s" % self.working_dir)
                self.unpack()
            except Exception as ex:
                raise Exception("TNApplianceDecompresser: cannot unpack because unpack() has returned exception: %s" % str(ex))
            try:
                self.entity.log.info("TNApplianceDecompresser: defining UUID in description file as %s" % self.entity.uuid)
                self.update_description()
            except Exception as ex:
                raise Exception("TNApplianceDecompresser: cannot update description because update_description() has returned exception: %s" % str(ex))
            try:
                self.entity.log.info("TNApplianceDecompresser: installing package in %s" % self.install_path)
                self.install()
            except Exception as ex:
                raise Exception("TNApplianceDecompresser: cannot update install because install returned exception %s" % str(ex))
            self.entity.log.info("TNApplianceDecompresser: cleaning working directory %s " % self.working_dir)
            self.clean()
            self.entity.log.info("TNApplianceDecompresser: Defining the virtual machine")
            self.entity.define(self.description_node)
            # This doesn;t work. we have to wait libvirt to handle snapshot recovering.
            # anyway, everything is ready, snapshots desc are stored in xvm2 packages, XML desc
            # are stored into self.snapshots_desc.
            # self.entity.log.info("Recovering any snapshots")
            # self.recover_snapshots()
            self.finish_callback()
        except Exception as ex:
            try:
                self.clean()
            except:
                pass
            self.error_callback(ex)
            self.entity.log.error(str(ex))

    def unpack(self):
        """
        Unpack the given xvm2 package.
        @rtype: boolean
        @return: True in case of success
        """
        self.package_path   = self.xvm2_package_path
        self.temp_path      = tempfile.mkdtemp(dir=self.working_dir)
        self.extract_path   = os.path.join(self.temp_path, "export")
        package             = tarfile.open(name=self.package_path)
        package.extractall(path=self.extract_path)
        for aFile in os.listdir(self.extract_path):
            full_path = os.path.join(self.extract_path, aFile)
            self.entity.log.debug("TNApplianceDecompresser: parsing file %s" % full_path)
            if os.path.splitext(full_path)[-1] == ".gz":
                self.entity.log.info("Found one gziped disk: %s" % full_path)
                i = open(full_path, 'rb')
                o = open(full_path.replace(".gz", ""), 'w')
                self._gunzip(i, o)
                i.close()
                o.close()
                self.entity.log.info("File unziped at: %s" % full_path.replace(".gz", ""))
                self.disk_files[aFile.replace(".gz", "")] = full_path.replace(".gz", "")
            if os.path.splitext(full_path)[-1] in self.disk_extensions:
                self.entity.log.debug("Found one disk: %s" % full_path)
                self.disk_files[aFile] = full_path
            if aFile == "description.xml":
                self.entity.log.debug("Found description.xml file: %s" % full_path)
                o = open(full_path, 'r')
                self.description_file = o.read()
                o.close()
            # if aFile.find("snapshot-") > -1:
            #     self.entity.log.debug("found snapshot file : %s" % full_path)
            #     o = open(full_path, 'r')
            #     snapXML = o.read()
            #     o.close()
            #     self.snapshots_desc.append(snapXML)
        return True

    def update_description(self):
        """
        Define the uuid to write in the description file.
        @raise Exception: Exception if description file is empty
        @return: True in case of success
        """
        if not self.description_file:
            raise Exception("Description file is empty.")
        desc_string = self.description_file
        xml_desc = xmpp.simplexml.NodeBuilder(data=desc_string).getDom()
        name_node = xml_desc.getTag("name")
        uuid_node = xml_desc.getTag("uuid")
        if xml_desc.getTag("devices"):
            disk_nodes = xml_desc.getTag("devices").getTags("disk")
            for disk in disk_nodes:
                source = disk.getTag("source")
                if source:
                    source_file = os.path.basename(source.getAttr("file")).replace(".gz", "")
                    source.setAttr("file", os.path.join(self.entity.folder, source_file))

        if xml_desc.getTag("devices"):
            nics_nodes = xml_desc.getTag("devices").getTags("interface")
            for nic in nics_nodes:
                mac = nic.getTag("mac")
                if mac:
                    mac.setAttr("address", generate_mac_adress())
                else:
                    nic.addChild(name="mac", attrs={"address" : generate_mac_adress()})
        name_node.setData(self.entity.uuid)
        uuid_node.setData(self.entity.uuid)
        self.description_node = xml_desc
        return True

    def recover_snapshots(self):
        """
        Recover any snapshots.
        """
        for snap in self.snapshots_desc:
            try:
                snap_node = xmpp.simplexml.NodeBuilder(data=snap).getDom()
                #snap_node.getTag("name").setData(str(uuid.uuid1()))
                snap_node.getTag("domain").getTag("uuid").setData(self.entity.uuid)
                snap_str = str(snap_node).replace('xmlns="http://www.gajim.org/xmlns/undeclared" ', '')
                self.entity.domain.snapshotCreateXML(snap_str, 0)
            except Exception as ex:
                self.entity.log.error("TNApplianceDecompresser: can't recover snapshot: %s", str(ex))

    def install(self):
        """
        Install a untared and uuid defined package.
        @return: True in case of success
        """
        if not self.description_file:
            raise Exception("description file is empty")
        for key, path in self.disk_files.items():
            self.entity.log.debug("TNApplianceDecompresser: moving %s to %s" % (path, self.install_path))
            try:
                shutil.move(path, self.install_path)
            except:
                os.remove(self.install_path + "/" + key)
                shutil.move(path, self.install_path)
        f = open(self.install_path + "/current.package", "w")
        f.write(self.package_uuid)
        f.close()
        return True

    def _gunzip(self, fileobjin, fileobjout):
        """
        Returns NamedTemporaryFile with unzipped content of fileobj.
        @type fileobjin: File
        @param fileobjin: file containing the archive
        @type fileobjout: File
        @param fileobjout: file where to put the unziped file
        """
        source = gz(fileobj=fileobjin, mode='rb')
        target = fileobjout
        try:
            while 1:
                data=source.read(65536)
                if data and len(data):
                    target.write(data)
                else:
                    target.flush()
                    break
        except Exception:
            target.close()
            raise
        else:
            return target

    def clean(self):
        """
        Clean the tempory path.
        """
        shutil.rmtree(self.temp_path)