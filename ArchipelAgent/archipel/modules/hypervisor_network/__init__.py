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

import archipel.core.archipelHypervisor
import archipel.core.archipelVirtualMachine

import network


ARCHIPEL_NS_HYPERVISOR_NETWORK = "archipel:hypervisor:network"


def __module_init__network_management(self):
    self.module_hypervisor_network = network.TNHypervisorNetworks(self)

def __module_register_stanza__network_management_hyp(self):
    self.xmppclient.RegisterHandler('iq', self.module_hypervisor_network.process_iq_for_hypervisor, typ=ARCHIPEL_NS_HYPERVISOR_NETWORK)

def __module_register_stanza__network_management_vm(self):
    self.xmppclient.RegisterHandler('iq', self.module_hypervisor_network.process_iq_for_virtualmachine, typ=ARCHIPEL_NS_HYPERVISOR_NETWORK)



setattr(archipel.core.archipelHypervisor.TNArchipelHypervisor, "__module_init__network_management", __module_init__network_management)
setattr(archipel.core.archipelHypervisor.TNArchipelHypervisor, "__module_register_stanza__network_management_hyp", __module_register_stanza__network_management_hyp)

setattr(archipel.core.archipelVirtualMachine.TNArchipelVirtualMachine, "__module_init__network_management", __module_init__network_management)
setattr(archipel.core.archipelVirtualMachine.TNArchipelVirtualMachine, "__module_register_stanza__network_management_vm", __module_register_stanza__network_management_vm)