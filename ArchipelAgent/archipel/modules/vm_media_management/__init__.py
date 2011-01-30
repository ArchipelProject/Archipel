#!/usr/bin/python
# 
# __init__.py
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

import os

from archipel.utils import *
import archipel.core.archipelHypervisor
import archipel.core.archipelVirtualMachine

import diskManagement

ARCHIPEL_NS_VM_DISK = "archipel:vm:disk"

def __module_init__disk_management(self):
    shared_isos_folder = self.configuration.get("MEDIAS", "iso_base_path") + "/"
    
    ## create directories if needed
    if not os.path.exists(shared_isos_folder): os.makedirs(shared_isos_folder)
    
    self.module_media = diskManagement.TNMediaManagement(shared_isos_folder, self)
    
def __module_register_stanza__disk_management(self):
    self.xmppclient.RegisterHandler('iq', self.module_media.process_iq, ns=ARCHIPEL_NS_VM_DISK)


setattr(archipel.core.archipelVirtualMachine.TNArchipelVirtualMachine, "__module_init__disk_management", __module_init__disk_management)
setattr(archipel.core.archipelVirtualMachine.TNArchipelVirtualMachine, "__module_register_stanza__disk_management", __module_register_stanza__disk_management)