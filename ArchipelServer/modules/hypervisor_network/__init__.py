#!/usr/bin/python
import network
import archipel



NS_ARCHIPEL_HYPERVISOR_NETWORK = "archipel:hypervisor:network"


def __module_init__network_management(self):
    self.module_hypervisor_network = network.TNHypervisorNetworks(self);

def __module_register_stanza__network_management_hyp(self):
    self.xmppclient.RegisterHandler('iq', self.module_hypervisor_network.process_iq_for_hypervisor, typ=NS_ARCHIPEL_HYPERVISOR_NETWORK)

def __module_register_stanza__network_management_vm(self):
    self.xmppclient.RegisterHandler('iq', self.module_hypervisor_network.process_iq_for_virtualmachine, typ=NS_ARCHIPEL_HYPERVISOR_NETWORK)



setattr(archipel.TNArchipelHypervisor, "__module_init__network_management", __module_init__network_management)
setattr(archipel.TNArchipelHypervisor, "__module_register_stanza__network_management_hyp", __module_register_stanza__network_management_hyp);

setattr(archipel.TNArchipelVirtualMachine, "__module_init__network_management", __module_init__network_management)
setattr(archipel.TNArchipelVirtualMachine, "__module_register_stanza__network_management_vm", __module_register_stanza__network_management_vm);