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
from threading import Thread
import xmpp
import shutil

class TNArchipelPackage(Thread):
    
    def __init__(self, working_dir, disk_exts):
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
        self.disk_files         = [];
        self.other_files        = [];
        
        Thread.__init__(self);
    
    
    def unpack(self, xvm2_package_path):
        """
        unpack the given xvm2 package
        @type xvm2_package_path: string
        @param xvm2_package_path: The path to the package
        """
        self.package_path   = xvm2_package_path;
        self.temp_path      = tempfile.mkdtemp(dir=self.working_dir);
        extract_path        = os.path.join(temp_path, "export");
        package             = tarfile.open(name=self.package_path);
        
        package.extractall(path=extract_path);
        
        for aFile in os.listdir(extract_path):
            full_path = os.path.join(extract_path, aFile);
            
            if os.path.splitext(full_path)[-1] == ".gz":
                i = gzip.open(full_path, 'rb')
                o = open(full_path.replace(".gz", ""), 'w');
                o.write(i.read());
                i.close()
                o.close()
            
            if os.path.splitext(full_path)[-1] in self.disk_extensions:
                self.disk_files.append(full_path);
            
            if aFile == "description.xml":
                self.description_file = full_path;
    
    
    def define_uuid(self, uuid):
        """
        define the uuid to write in the description file
        
        @type uuid: string
        @param uuid: the uuid to use
        """
        if not self.description_file:
            return False;
        
        self.uuid = uuid;
        
        f = open(self.description_file, 'r');
        desc_string = f.read()
        f.close();
        
        xml_desc = xmpp.simplexml.NodeBuilder(data=desc_string).getDom();
        
        name_node = xml_desc.getTag("name");
        uuid_node = xml_desc.getTag("uuid");
        name_node.setData(self.uuid);
        uuid_node.setData(self.uuid);
        
        f = open(self.description_file, 'w');
        f.write(str(xml_desc)) 
        f.close();
        
        return True;
    
    
    def get_description_file(self):
        return self.description_file;
    
    
    def install(self, basepath):
        """
        install a untared and uuid defined package
        @type basepath: string
        @param uuid: the base path to create the folder and install disks
        """
        
        if not self.description_file or not self.uuid:
            return False;
            
        self.basepath = os.path.join(basepath, self.uuid);
        os.mkdir(self.basepath);
        
        for path in self.disk_files:
            shutil.move(path, self.basepath);
        
        return True;
    
    
    def clean(self):
        os.system("rm -rf " + self.temp_path)
    