#!/usr/bin/python
import vmcasting
import instancier
import xmpp
from utils import *
import archipel

NS_ARCHIPEL_HYPERVISOR_VMCASTING        = "archipel:hypervisor:vmcasting"
NS_ARCHIPEL_VIRTUALMACHINE_VMCASTING    = "archipel:virtualmachine:vmcasting"

globals()["COLORING_MAPPING_CLASS"].update({"TNHypervisorVMCasting": u'\033[36m', "TNArchipelPackageInstancier": u'\033[37m'})

def __module_init__vmcasting_module_for_hypervisor(self):
    db_path     = self.configuration.get("VMCASTING", "vmcasting_database_path");
    repo_path   = self.configuration.get("VMCASTING", "repository_path");

    own_vmcast_uuid             = self.configuration.get("VMCASTING", "own_vmcast_uuid");
    own_vmcast_url              = self.configuration.get("VMCASTING", "own_vmcast_url");
    own_vmcast_path             = self.configuration.get("VMCASTING", "own_vmcast_path");
    own_vmcast_file_name        = self.configuration.get("VMCASTING", "own_vmcast_file_name");
    own_vmcast_name             = self.configuration.get("VMCASTING", "own_vmcast_name");
    own_vmcast_description      = self.configuration.get("VMCASTING", "own_vmcast_description");
    own_vmcast_lang             = self.configuration.get("VMCASTING", "own_vmcast_lang");
    own_vmcast_refresh_interval = self.configuration.getint("VMCASTING", "own_vmcast_refresh_interval");    
    
    repo_dict = {"uuid": own_vmcast_uuid, "url": own_vmcast_url, "name": own_vmcast_name, "description": own_vmcast_description, 
                    "path": own_vmcast_path, "filename": own_vmcast_file_name, "refresh": own_vmcast_refresh_interval, "lang": own_vmcast_lang}
                    
    self.module_vmcasting = vmcasting.TNHypervisorVMCasting(db_path, repo_path, self, repo_dict);

def __module_init__vmcasting_module_for_virtualmachine(self):
    db_path     = self.configuration.get("VMCASTING", "vmcasting_database_path");
    repo_path   = self.configuration.get("VMCASTING", "repository_path");
    temp_path   = self.configuration.get("VMCASTING", "temp_path");
    disks_ext   = self.configuration.get("VMCASTING", "disks_extensions");
    
    self.module_packaging = instancier.TNArchipelPackageInstancier(db_path, temp_path, disks_ext, self);

# this method will be called at registration of handlers for XMPP
def __module_register_stanza__vmcasting_module_for_hypervisor(self):
    self.xmppclient.RegisterHandler('iq', self.module_vmcasting.process_iq, typ=NS_ARCHIPEL_HYPERVISOR_VMCASTING)

def __module_register_stanza__vmcasting_module_for_virtualmachine(self):
    self.xmppclient.RegisterHandler('iq', self.module_packaging.process_iq, typ=NS_ARCHIPEL_VIRTUALMACHINE_VMCASTING)



# finally, we add the methods to the class
setattr(archipel.TNArchipelHypervisor, "__module_init__vmcasting_module_for_hypervisor", __module_init__vmcasting_module_for_hypervisor)
setattr(archipel.TNArchipelHypervisor, "__module_register_stanza__vmcasting_module_for_hypervisor", __module_register_stanza__vmcasting_module_for_hypervisor)

setattr(archipel.TNArchipelVirtualMachine, "__module_init__vmcasting_module_for_virtualmachine", __module_init__vmcasting_module_for_virtualmachine)
setattr(archipel.TNArchipelVirtualMachine, "__module_register_stanza__vmcasting_module_for_virtualmachine", __module_register_stanza__vmcasting_module_for_virtualmachine)
