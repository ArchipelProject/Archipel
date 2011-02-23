# 
# AppNotificator.py
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

import notifications
from archipel.utils import *
from archipel.archipelPlugin import TNArchipelPlugin

class AppNotificator (TNArchipelPlugin):
    
    def __init__(self, configuration, entity, entry_point_group):
        """
        intialize the plugin
        """
        TNArchipelPlugin.__init__(self, configuration=configuration, entity=entity, entry_point_group=entry_point_group)
        
        self.credentials = []
        creds = self.configuration.get("IPHONENOTIFICATION", "credentials_key")

        for cred in creds.split(",,"):
            self.credentials.append(cred)
        
        if self.entity.__class__.__name__ == "TNArchipelVirtualMachine":
            self.entity.register_hook("HOOK_VM_CREATE", self.vm_create)
            self.entity.register_hook("HOOK_VM_SHUTOFF", self.vm_shutoff)
            self.entity.register_hook("HOOK_VM_STOP", self.vm_stop)
            self.entity.register_hook("HOOK_VM_DESTROY", self.vm_destroy)
            self.entity.register_hook("HOOK_VM_SUSPEND", self.vm_suspend)
            self.entity.register_hook("HOOK_VM_RESUME", self.vm_resume)
            self.entity.register_hook("HOOK_VM_UNDEFINE", self.vm_undefine)
            self.entity.register_hook("HOOK_VM_DEFINE", self.vm_define)
        elif self.entity.__class__.__name__ == "TNArchipelHypervisor":
            self.entity.register_hook("HOOK_HYPERVISOR_ALLOC", self.hypervisor_alloc)
            self.entity.register_hook("HOOK_HYPERVISOR_FREE", self.hypervisor_free)
            self.entity.register_hook("HOOK_HYPERVISOR_MIGRATEDVM_LEAVE", self.hypervisor_migrate_leave)
            self.entity.register_hook("HOOK_HYPERVISOR_MIGRATEDVM_ARRIVE", self.hypervisor_migrate_arrive)
            self.entity.register_hook("HOOK_HYPERVISOR_CLONE", self.hypervisor_clone)
    
    
    ### Plugin interface
    
    def plugin_info(self):
        """
        return the plugin information
        """
        return plugin_info(self.plugin_entry_point_group)
    
    
    @staticmethod
    def plugin_info():
        """
        return inforations about the plugin
        """
        plugin_friendly_name           = "iPhone Notification"
        plugin_identifier              = "iphone_notification"
        plugin_configuration_section   = "IPHONENOTIFICATION"
        plugin_configuration_tokens    = ["credentials_key"]

        return {    "common-name"               : plugin_friendly_name, 
                    "identifier"                : plugin_identifier,
                    "configuration-section"     : plugin_configuration_section,
                    "configuration-tokens"      : plugin_configuration_tokens }

    
    ### Module implementation
    
    
    def send(self, title, message, subtitle=None):
        try:
            long_message_preview = message
            for cred in self.credentials:
                notifications.send_async(cred, message, title=title, subtitle=subtitle, icon_url="http://antoinemercadal.fr/logo_archipel.png", long_message_preview=long_message_preview)
        except:
            self.entity.log.warning("cannot send iPhone notification: %s" % ex)
    
    def vm_create(self, entity, args):
        self.send("Archipel", "virtual machine %s has been started" % entity.name, subtitle="Virtual machine event")
    
    
    def vm_shutoff(self, entity, args):
        self.send("Archipel", "virtual machine %s has been shut off" % entity.name, subtitle="Virtual machine event")
    
    
    def vm_stop(self, entity, args):
        self.send("Archipel", "virtual machine %s has been stopped" % entity.name, subtitle="Virtual machine event")
    
    
    def vm_destroy(self, entity, args):
        self.send("Archipel", "virtual machine %s has been destroyed" % entity.name, subtitle="Virtual machine event")
    
    
    def vm_suspend(self, entity, args):
        self.send("Archipel", "virtual machine %s has been suspended" % entity.name, subtitle="Virtual machine event")
    
    
    def vm_resume(self, entity, args):
        self.send("Archipel", "virtual machine %s has been resumed" % entity.name, subtitle="Virtual machine event")
    
    
    def vm_undefine(self, entity, args):
        self.send("Archipel", "virtual machine %s has been undefined" % entity.name, subtitle="Virtual machine event")
    
    
    def vm_define(self, entity, args):
        self.send("Archipel", "virtual machine %s has been defined" % entity.name, subtitle="Virtual machine event")



    def hypervisor_alloc(self, entity, args):
        self.send("Archipel", "virtual machine %s has been allocated" % args.name, subtitle="Hypervisor event")
    
    
    def hypervisor_free(self, entity, args):
        self.send("Archipel", "virtual machine %s has been removed" % args.name, subtitle="Hypervisor event")
    
    
    def hypervisor_clone(self, entity, args):
        self.send("Archipel", "virtual machine %s has been cloned" % args.name, subtitle="Hypervisor event")
    
    
    def hypervisor_migrate_leave(self, entity, args):
        self.send("Archipel", "virtual machine %s has migrate to another hypervisor" % args.name, subtitle="Hypervisor event")
    
    
    def hypervisor_migrate_arrive(self, entity, args):
        self.send("Archipel", "virtual machine %s has juste arrived from another hypervisor" % args.name, subtitle="Hypervisor event")
    

