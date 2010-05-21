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
import xmpp

class TNApplianceCompresser(Thread):
    
    def __init__(self, name, paths, xml_definition, install_path, working_dir, vm_dir, hypervisor_repo_path, callback):
        """
        initialize a TNApplianceCompresser
        """
        Thread.__init__(self)
        self.name = name
        self.paths = paths
        self.install_path = install_path
        self.callback = callback
        self.xml_definition = xml_definition
        self.vm_dir = vm_dir
        self.working_dir = tempfile.mkdtemp(dir=working_dir)
        self.hypervisor_repo_path = hypervisor_repo_path
    
    
    def run(self):
        log(self, LOG_LEVEL_INFO, "packaging appliance %s" % self.name)
        
        definitionXML = str(self.xml_definition).replace('xmlns="http://www.gajim.org/xmlns/undeclared" ', '');
        
        zipped_file_paths = [];
        for path in self.paths:
            log(self, LOG_LEVEL_INFO, "zipping file %s" % path)
            zipped_file_path = self.compress_disk(path)
            definitionXML = definitionXML.replace(path, zipped_file_path.split('/')[-1])
            zipped_file_paths.append(zipped_file_path)
            log(self, LOG_LEVEL_INFO, "file zipped %s" % zipped_file_path)
        
        log(self, LOG_LEVEL_INFO, "writing definion at path  %s/description.xml" % self.working_dir)
        f = open(self.working_dir + "/description.xml", 'w')
        f.write(definitionXML)
        f.close()
            
        log(self, LOG_LEVEL_INFO, "creating tar file at : %s/%s.xvm2" % (self.working_dir, self.name))
        
        tar_file = self.working_dir + "/" + self.name + ".xvm2";
        tar = tarfile.open(tar_file, "w")
        tar.add(self.working_dir + "/description.xml", "/description.xml")
        os.unlink(self.working_dir + "/description.xml");
        for zipped_file_path in zipped_file_paths:
            log(self, LOG_LEVEL_INFO, "adding to tar file %s" % zipped_file_path)
            tar.add(zipped_file_path, "/" + zipped_file_path.split("/")[-1])
            os.unlink(zipped_file_path);
        
        tar.close()
        
        os.system("mv %s %s" % (tar_file, self.hypervisor_repo_path));
        os.system("rm -rf %s" % self.working_dir)
        self.callback()

    def compress_disk(self, path):
        zip_path = self.working_dir + "/" + path.split("/")[-1] + ".gz"
        f_in = open(path, 'rb')
        f_out = gzip.open(zip_path, 'wb')
        f_out.writelines(f_in)
        f_out.close()
        f_in.close()
        
        return zip_path
