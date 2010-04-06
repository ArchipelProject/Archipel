#!/usr/bin/python
import vmcasting
import xmpp
from utils import *
import archipel

NS_ARCHIPEL_HYPERVISOR_VMCASTING = "archipel:hypervisor:vmcasting"


def __module_init__vmcasting_module(self):
    db_path = self.configuration.get("VMCasting", "vmcasting_database_path");
    repo_path = self.configuration.get("VMCasting", "repository_path");
    
    self.module_vmcasting = vmcasting.TNHypervisorVMCasting(db_path, repo_path);

# this method will be called at registration of handlers for XMPP
def __module_register_stanza__vmcasting_module(self):
    self.xmppclient.RegisterHandler('iq', self.module_vmcasting.process_iq, typ=NS_ARCHIPEL_HYPERVISOR_VMCASTING)


# finally, we add the methods to the class
setattr(archipel.TNArchipelHypervisor, "__module_init__vmcasting_module", __module_init__vmcasting_module)
setattr(archipel.TNArchipelHypervisor, "__module_register_stanza__vmcasting_module", __module_register_stanza__vmcasting_module)
