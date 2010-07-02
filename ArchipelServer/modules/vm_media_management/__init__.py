#!/usr/bin/python
import diskManagement
from utils import *
import archipel

ARCHIPEL_NS_VM_DISK = "archipel:vm:disk"

def __module_init__disk_management(self):
    shared_isos_folder = self.configuration.get("MEDIAS", "iso_base_path") + "/"
    
    self.module_media = diskManagement.TNMediaManagement(shared_isos_folder, self)
    
def __module_register_stanza__disk_management(self):
    self.xmppclient.RegisterHandler('iq', self.module_media.process_iq, ns=ARCHIPEL_NS_VM_DISK)


setattr(archipel.TNArchipelVirtualMachine, "__module_init__disk_management", __module_init__disk_management)
setattr(archipel.TNArchipelVirtualMachine, "__module_register_stanza__disk_management", __module_register_stanza__disk_management)