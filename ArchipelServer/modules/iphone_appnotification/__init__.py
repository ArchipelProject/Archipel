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

from utils import *
import archipel
import appnotificator

# this method will be call at loading
def __module_init__iphone_notification_vm(self):
    log.info("initializing iPhone notification for virtual machine")
    
    creds = self.configuration.get("IPHONENOTIFICATION", "credentials_key");
    self.iphone_notification = appnotificator.AppNotificator(creds);
    
    self.register_hook("HOOK_VM_CREATE", self.iphone_notification.vm_create)
    self.register_hook("HOOK_VM_SHUTOFF", self.iphone_notification.vm_shutoff)
    self.register_hook("HOOK_VM_STOP", self.iphone_notification.vm_stop)
    self.register_hook("HOOK_VM_DESTROY", self.iphone_notification.vm_destroy)
    self.register_hook("HOOK_VM_SUSPEND", self.iphone_notification.vm_suspend)
    self.register_hook("HOOK_VM_RESUME", self.iphone_notification.vm_resume)
    self.register_hook("HOOK_VM_UNDEFINE", self.iphone_notification.vm_undefine)
    self.register_hook("HOOK_VM_DEFINE", self.iphone_notification.vm_define)


def __module_init__iphone_notification_hypervisor(self):
    log.info("initializing iPhone notification for hypervisor")
    
    creds = self.configuration.get("IPHONENOTIFICATION", "credentials_key");
    self.iphone_notification = appnotificator.AppNotificator(creds);
    
    self.register_hook("HOOK_HYPERVISOR_ALLOC", self.iphone_notification.hypervisor_alloc)
    self.register_hook("HOOK_HYPERVISOR_FREE", self.iphone_notification.hypervisor_free)
    self.register_hook("HOOK_HYPERVISOR_MIGRATEDVM_LEAVE", self.iphone_notification.hypervisor_migrate_leave)
    self.register_hook("HOOK_HYPERVISOR_MIGRATEDVM_ARRIVE", self.iphone_notification.hypervisor_migrate_arrive)
    self.register_hook("HOOK_HYPERVISOR_CLONE", self.iphone_notification.hypervisor_clone)
        
    


# finally, we add the methods to the class
setattr(archipel.TNArchipelVirtualMachine, "__module_init__iphone_notification_vm", __module_init__iphone_notification_vm)
setattr(archipel.TNArchipelHypervisor, "__module_init__iphone_notification_hypervisor", __module_init__iphone_notification_hypervisor)