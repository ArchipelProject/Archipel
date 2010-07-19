# 
# packager.py
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

import os, sys
import tempfile
import tarfile
from gzip import GzipFile as gz
from utils import *
from threading import Thread
from xml.dom import minidom
import xmpp
import shutil
import uuid
import random

class TNApplianceDecompresser(Thread):
    
    def __init__(self, working_dir, disk_exts, xvm2_package_path, entity, finish_callback, package_uuid, requester):
        """
        initialize a TNApplianceDecompresser
        
        @type working_dir: string
        @param working_dir: the base dir where TNApplianceDecompresser will works
        @type disk_exts: array
        @param disk_exts: contains all the extensions that should be considered as a disks with the initial dot (ie: .gz)
        """
        self.working_dir        = working_dir
        self.disk_extensions    = disk_exts
        self.xvm2_package_path  = xvm2_package_path
        self.entity             = entity
        self.finish_callback    = finish_callback
        self.package_uuid       = package_uuid
        self.requester          = requester
        self.install_path       = entity.folder
        
        self.description_file   = None
        self.disk_files         = {}
        self.snapshots_desc     = []
        
        Thread.__init__(self)
    
    
    def run(self):
        log.info("unpacking to %s" % self.working_dir)
        self.unpack()
        
        log.info("defining UUID in description file as %s" % self.entity.uuid)
        self.update_description()
        
        log.info("installing package in %s" % self.install_path)
        self.install()
        
        log.info("cleaning...")
        self.clean()
        
        log.info("Defining the virtual machine")
        self.entity.define(self.description_node)
        
        # This doesn;t work. we have to wait libvirt to handle snapshot recovering.
        # anyway, everything is ready, snapshots desc are stored in xvm2 packages, XML desc
        # are stored into self.snapshots_desc.
        # log.info("Recovering any snapshots")
        # self.recover_snapshots()
        
        self.finish_callback()
        
    
    def unpack(self):
        """
        unpack the given xvm2 package
        @type self.xvm2_package_path: string
        @param self.xvm2_package_path: The path to the package
        """
        self.package_path   = self.xvm2_package_path
        self.temp_path      = tempfile.mkdtemp(dir=self.working_dir)
        self.extract_path   = os.path.join(self.temp_path, "export")
        package             = tarfile.open(name=self.package_path)
        
        package.extractall(path=self.extract_path)
        
        try:
            for aFile in os.listdir(self.extract_path):
                full_path = os.path.join(self.extract_path, aFile)
                log.debug("parsing file %s" % full_path)
                
                if os.path.splitext(full_path)[-1] == ".gz":
                    log.info("found one gziped disk : %s" % full_path)
                    i = open(full_path, 'rb')
                    o = open(full_path.replace(".gz", ""), 'w')
                    self._gunzip(i, o)
                    i.close()
                    o.close()
                    log.info("file unziped at : %s" % full_path.replace(".gz", ""))
                    self.disk_files[aFile.replace(".gz", "")] = full_path.replace(".gz", "")
                    
                if os.path.splitext(full_path)[-1] in self.disk_extensions:
                    log.debug("found one disk : %s" % full_path)
                    self.disk_files[aFile] = full_path
                    
                if aFile == "description.xml":
                    log.debug("found description.xml file : %s" % full_path)
                    o = open(full_path, 'r')
                    self.description_file = o.read()
                    o.close()
                    
                if aFile.find("snapshot-") > -1:
                    log.debug("found snapshot file : %s" % full_path)
                    o = open(full_path, 'r')
                    snapXML = o.read()
                    o.close()
                    self.snapshots_desc.append(snapXML)
                
        except Exception as ex:
            log.error( str(ex))
    
    
    def update_description(self):
        """
        define the uuid to write in the description file
        
        @type uuid: string
        @param uuid: the uuid to use
        """
        if not self.description_file:
            return False
        
        desc_string = self.description_file
        
        xml_desc = xmpp.simplexml.NodeBuilder(data=desc_string).getDom()
        
        name_node = xml_desc.getTag("name")
        uuid_node = xml_desc.getTag("uuid")
        
        disk_nodes = xml_desc.getTag("devices").getTags("disk")
        for disk in disk_nodes:
            source = disk.getTag("source")
            source_file = source.getAttr("file")
            source.setAttr("file", os.path.join(self.entity.folder, source_file.replace(".gz", "")))
            #source.setAttr("file", source_file.replace(".gz", "").replace(uuid_node.getCDATA(), self.entity.uuid))
        
        nics_nodes = xml_desc.getTag("devices").getTags("interface")
        for nic in nics_nodes:
            mac = nic.getTag("mac")
            mac.setAttr("address", self.generate_new_mac())
            
        name_node.setData(self.entity.uuid)
        uuid_node.setData(self.entity.uuid)
        
        self.description_node = xml_desc
        
        return True
    
    
    def recover_snapshots(self):
        """recover any snapshots"""
        for snap in self.snapshots_desc:
            try:
                snap_node = xmpp.simplexml.NodeBuilder(data=snap).getDom()
                #snap_node.getTag("name").setData(str(uuid.uuid1()))
                snap_node.getTag("domain").getTag("uuid").setData(self.entity.uuid)
                snap_str = str(snap_node).replace('xmlns="http://www.gajim.org/xmlns/undeclared" ', '')
                #print snap_str
                self.entity.domain.snapshotCreateXML(snap_str, 0)
            except Exception as ex:
                log.error("can't recover snapshot: %s", str(ex))
    
    
    def install(self):
        """
        install a untared and uuid defined package
        @type basepath: string
        @param uuid: the base path to create the folder and install disks
        """
        
        if not self.description_file:
            return False
        
        for key, path in self.disk_files.items():
            log.debug("moving %s to %s" % (path, self.install_path))
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
        """Returns NamedTemporaryFile with unzipped content of fileobj"""
        
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
        os.system("rm -rf " + self.temp_path)
    
    
    def generate_new_mac(self):
        """generate a new mac address"""
        dico = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F"]
        digit1 = "DE"
        digit2 = "AD"
        digit3 = "%s%s" % (dico[random.randint(0, 15)], dico[random.randint(0, 15)])
        digit4 = "%s%s" % (dico[random.randint(0, 15)], dico[random.randint(0, 15)])
        digit5 = "%s%s" % (dico[random.randint(0, 15)], dico[random.randint(0, 15)])
        digit6 = "%s%s" % (dico[random.randint(0, 15)], dico[random.randint(0, 15)])
        
        return "%s:%s:%s:%s:%s:%s" % (digit1, digit2, digit3, digit4, digit5, digit6)