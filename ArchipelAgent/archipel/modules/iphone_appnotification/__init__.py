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

from archipel.utils import *
import archipel.core.archipelHypervisor
import archipel.core.archipelVirtualMachine

import appnotificator


# this method will be call at loading
def __module_init__iphone_notification_vm(self):
    self.log.info("initializing iPhone notification for virtual machine")
    
    self.iphone_notifications = []
    creds = self.configuration.get("IPHONENOTIFICATION", "credentials_key")
    
    for cred in creds.split(",,"):
        iphone_n = appnotificator.AppNotificator(cred)
        self.iphone_notifications.append(iphone_n)
        
        self.register_hook("HOOK_VM_CREATE", iphone_n.vm_create)
        self.register_hook("HOOK_VM_SHUTOFF", iphone_n.vm_shutoff)
        self.register_hook("HOOK_VM_STOP", iphone_n.vm_stop)
        self.register_hook("HOOK_VM_DESTROY", iphone_n.vm_destroy)
        self.register_hook("HOOK_VM_SUSPEND", iphone_n.vm_suspend)
        self.register_hook("HOOK_VM_RESUME", iphone_n.vm_resume)
        self.register_hook("HOOK_VM_UNDEFINE", iphone_n.vm_undefine)
        self.register_hook("HOOK_VM_DEFINE", iphone_n.vm_define)


def __module_init__iphone_notification_hypervisor(self):
    self.log.info("initializing iPhone notification for hypervisor")
    
    self.iphone_notifications = []
    creds = self.configuration.get("IPHONENOTIFICATION", "credentials_key")
    
    for cred in creds.split(",,"):
        iphone_n = appnotificator.AppNotificator(cred)
        self.iphone_notifications.append(iphone_n)
        
        self.register_hook("HOOK_HYPERVISOR_ALLOC", iphone_n.hypervisor_alloc)
        self.register_hook("HOOK_HYPERVISOR_FREE", iphone_n.hypervisor_free)
        self.register_hook("HOOK_HYPERVISOR_MIGRATEDVM_LEAVE", iphone_n.hypervisor_migrate_leave)
        self.register_hook("HOOK_HYPERVISOR_MIGRATEDVM_ARRIVE", iphone_n.hypervisor_migrate_arrive)
        self.register_hook("HOOK_HYPERVISOR_CLONE", iphone_n.hypervisor_clone)
        
    


# finally, we add the methods to the class
setattr(archipel.core.archipelVirtualMachine.TNArchipelVirtualMachine, "__module_init__iphone_notification_vm", __module_init__iphone_notification_vm)
setattr(archipel.core.archipelHypervisor.TNArchipelHypervisor, "__module_init__iphone_notification_hypervisor", __module_init__iphone_notification_hypervisor)