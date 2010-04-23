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
import gzip
from utils import *
from threading import Thread
from xml.dom import minidom
import xmpp
import shutil

class TNArchipelPackage(Thread):
    
    def __init__(self, working_dir, disk_exts, xvm2_package_path, uuid, install_path, define_callback, entity, package_uuid):
        """
        initialize a TNArchipelPackage
        
        @type working_dir: string
        @param working_dir: the base dir where TNArchipelPackage will works
        @type disk_exts: array
        @param disk_exts: contains all the extensions that should be considered as a disks with the initial dot (ie: .gz)
        """
        
        self.working_dir        = working_dir;
        self.disk_extensions    = disk_exts;
        self.description_file   = None;
        self.disk_files         = {};
        self.other_files        = [];
        self.xvm2_package_path  = xvm2_package_path
        self.uuid               = uuid
        self.install_path       = install_path
        self.define_callback    = define_callback
        self.entity             = entity;
        self.package_uuid       = package_uuid;
        
        Thread.__init__(self);
    
    def run(self):
        
        log(self, LOG_LEVEL_INFO, "unpacking to %s" % self.working_dir)
        self.unpack();
        
        log(self, LOG_LEVEL_INFO, "defining UUID in description file as %s" % self.uuid)
        self.update_description()
        
        log(self, LOG_LEVEL_INFO, "installing package in %s" % self.install_path)
        self.install()
        
        log(self, LOG_LEVEL_INFO, "cleaning...");
        self.clean();
        
        desc_node = self.get_description_node();
        
        define_iq = xmpp.Iq();
        define_iq.setQueryPayload([desc_node])
        
        self.define_callback(define_iq);
    
    def unpack(self):
        """
        unpack the given xvm2 package
        @type self.xvm2_package_path: string
        @param self.xvm2_package_path: The path to the package
        """
        self.package_path   = self.xvm2_package_path;
        self.temp_path      = tempfile.mkdtemp(dir=self.working_dir);
        self.extract_path   = os.path.join(self.temp_path, "export");
        package             = tarfile.open(name=self.package_path);
        
        package.extractall(path=self.extract_path);
        
        self.entity.push_change("vmcasting", "applianceunpacking");
        
        for aFile in os.listdir(self.extract_path):
            full_path = os.path.join(self.extract_path, aFile);
            log(self, LOG_LEVEL_DEBUG, "parsing file %s" % full_path)
            
            if os.path.splitext(full_path)[-1] == ".gz":
                i = gzip.open(full_path, 'rb')
                o = open(full_path.replace(".gz", ""), 'w');
                o.write(i.read());
                i.close()
                o.close()
                log(self, LOG_LEVEL_DEBUG, "found one gziped disk : %s" % full_path)
                self.disk_files[aFile.replace(".gz", "")] = full_path.replace(".gz", "");
            
            if os.path.splitext(full_path)[-1] in self.disk_extensions:
                log(self, LOG_LEVEL_DEBUG, "found one disk : %s" % full_path)
                self.disk_files[aFile] = full_path;
            
            if aFile == "description.xml":
                log(self, LOG_LEVEL_DEBUG, "found description.xml file : %s" % full_path)
                o = open(full_path, 'r');
                self.description_file = o.read();
                o.close();
            
        self.entity.push_change("vmcasting", "applianceunpacked");
    
    
    def update_description(self):
        """
        define the uuid to write in the description file
        
        @type uuid: string
        @param uuid: the uuid to use
        """
        if not self.description_file:
            return False;
        
        desc_string = self.description_file
        
        xml_desc = xmpp.simplexml.NodeBuilder(data=desc_string).getDom();
        
        name_node = xml_desc.getTag("name");
        uuid_node = xml_desc.getTag("uuid");
        disk_nodes = xml_desc.getTag("devices").getTags("disk");
        for disk in disk_nodes:
            source = disk.getTag("source");
            source_file = source.getAttr("file");
            source.setAttr("file", self.install_path + "/" + source_file.replace(".gz", ""))
        name_node.setData(self.uuid);
        uuid_node.setData(self.uuid);
        
        self.description_node = xml_desc
        
        return True;
    
    
    def get_description_node(self):
        return self.description_node;
    
    
    def install(self):
        """
        install a untared and uuid defined package
        @type basepath: string
        @param uuid: the base path to create the folder and install disks
        """
        
        if not self.description_file:
            return False;
        
        self.entity.push_change("vmcasting", "applianceinstalling");
        
        for key, path in self.disk_files.items():
            log(self, LOG_LEVEL_DEBUG, "moving %s to %s" % (path, self.install_path));
            try:
                shutil.move(path, self.install_path);
            except:
                os.remove(self.install_path + "/" + key);
            finally:
                shutil.move(path, self.install_path);
            
        f = open(self.install_path + "/current.package", "w");
        f.write(self.package_uuid)
        f.close()
        
        self.entity.push_change("vmcasting", "applianceinstalled");
        
        return True;
    
    
    def clean(self):
        os.system("rm -rf " + self.temp_path)
    