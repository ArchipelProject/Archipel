#!/usr/bin/python
import vmcasting
import instancier
import xmpp
from utils import *
import archipel

NS_ARCHIPEL_HYPERVISOR_VMCASTING = "archipel:hypervisor:vmcasting"

globals()["COLORING_MAPPING_CLASS"].update({"TNHypervisorVMCasting": u'\033[36m', "TNArchipelPackageInstancier": u'\033[37m'})

def __module_init__vmcasting_module_for_hypervisor(self):
    db_path     = self.configuration.get("VMCasting", "vmcasting_database_path");
    repo_path   = self.configuration.get("VMCasting", "repository_path");
    
    self.module_vmcasting = vmcasting.TNHypervisorVMCasting(db_path, repo_path, self);

def __module_init__vmcasting_module_for_virtualmachine(self):
    db_path     = self.configuration.get("VMCasting", "vmcasting_database_path");
    repo_path   = self.configuration.get("VMCasting", "repository_path");
    temp_path   = self.configuration.get("VMCasting", "temp_path");
    disks_ext   = self.configuration.get("VMCasting", "disks_extensions");
    
    self.module_vmcasting = instancier.TNArchipelPackageInstancier(db_path, temp_path, disks_ext, self);

# this method will be called at registration of handlers for XMPP
def __module_register_stanza__vmcasting_module(self):
    self.xmppclient.RegisterHandler('iq', self.module_vmcasting.process_iq, typ=NS_ARCHIPEL_HYPERVISOR_VMCASTING)


# finally, we add the methods to the class
setattr(archipel.TNArchipelHypervisor, "__module_init__vmcasting_module_for_hypervisor", __module_init__vmcasting_module_for_hypervisor)
setattr(archipel.TNArchipelHypervisor, "__module_register_stanza__vmcasting_module", __module_register_stanza__vmcasting_module)

setattr(archipel.TNArchipelVirtualMachine, "__module_init__vmcasting_module_for_virtualmachine", __module_init__vmcasting_module_for_virtualmachine)
setattr(archipel.TNArchipelVirtualMachine, "__module_register_stanza__vmcasting_module", __module_register_stanza__vmcasting_module)
