# -*- coding: utf-8 -*-
#
# appnotificator.py
#
# Copyright (C) 2010 Antoine Mercadal <antoine.mercadal@inframonde.eu>
# Copyright, 2011 - Franck Villaume <franck.villaume@trivialdev.com>
# This file is part of ArchipelProject
# http://archipelproject.org
#
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

from archipelcore.archipelPlugin import TNArchipelPlugin

import notifications


class AppNotificator (TNArchipelPlugin):

    def __init__(self, configuration, entity, entry_point_group):
        """
        Initialize the plugin.
        @type configuration: Configuration object
        @param configuration: the configuration
        @type entity: L{TNArchipelEntity}
        @param entity: the entity that owns the plugin
        @type entry_point_group: string
        @param entry_point_group: the group name of plugin entry_point
        """
        TNArchipelPlugin.__init__(self, configuration=configuration, entity=entity, entry_point_group=entry_point_group)
        self.credentials = []
        creds = self.configuration.get("IPHONENOTIFICATION", "credentials_key")
        for cred in creds.split(",,"):
            self.credentials.append(cred)
        if self.entity.__class__.__name__ == "TNArchipelVirtualMachine":
            self.entity.register_hook("HOOK_VM_CREATE", method=self.vm_create)
            self.entity.register_hook("HOOK_VM_SHUTOFF", method=self.vm_shutoff)
            self.entity.register_hook("HOOK_VM_STOP", method=self.vm_stop)
            self.entity.register_hook("HOOK_VM_DESTROY", method=self.vm_destroy)
            self.entity.register_hook("HOOK_VM_SUSPEND", method=self.vm_suspend)
            self.entity.register_hook("HOOK_VM_RESUME", method=self.vm_resume)
            self.entity.register_hook("HOOK_VM_UNDEFINE", method=self.vm_undefine)
            self.entity.register_hook("HOOK_VM_DEFINE", method=self.vm_define)
        elif self.entity.__class__.__name__ == "TNArchipelHypervisor":
            self.entity.register_hook("HOOK_HYPERVISOR_ALLOC", method=self.hypervisor_alloc)
            self.entity.register_hook("HOOK_HYPERVISOR_FREE", method=self.hypervisor_free)
            self.entity.register_hook("HOOK_HYPERVISOR_MIGRATEDVM_LEAVE", method=self.hypervisor_migrate_leave)
            self.entity.register_hook("HOOK_HYPERVISOR_MIGRATEDVM_ARRIVE", method=self.hypervisor_migrate_arrive)
            self.entity.register_hook("HOOK_HYPERVISOR_CLONE", method=self.hypervisor_clone)


    ### Plugin interface

    @staticmethod
    def plugin_info():
        """
        Return informations about the plugin.
        @rtype: dict
        @return: dictionary contaning plugin informations
        """
        plugin_friendly_name           = "iPhone Notification"
        plugin_identifier              = "iphone_notification"
        plugin_configuration_section   = "IPHONENOTIFICATION"
        plugin_configuration_tokens    = ["credentials_key"]
        return {    "common-name"               : plugin_friendly_name,
                    "identifier"                : plugin_identifier,
                    "configuration-section"     : plugin_configuration_section,
                    "configuration-tokens"      : plugin_configuration_tokens }


    ### Plugin implementation

    def send(self, title, message, subtitle=None):
        """
        Send the notification.
        @type title: string
        @param title: the title of the notification
        @type message: string
        @param message: the content of the message
        """
        try:
            long_message_preview = message
            for cred in self.credentials:
                notifications.send_async(cred, message, title=title, subtitle=subtitle, icon_url="http://antoinemercadal.fr/logo_archipel.png", long_message_preview=long_message_preview)
        except Exception as ex:
            self.entity.log.warning("Cannot send iPhone notification: %s" % ex)

    def vm_create(self, origin, user_info, parameters):
        """
        Handle hook HOOK_VM_CREATE.
        @type origin: L{TNArchipelEntity}
        @param origin: the origin of the hook
        @type user_info: object
        @param user_info: random user info
        @type parameters: object
        @param parameters: runtim argument
        """
        self.send("Archipel", "Virtual machine %s has been started." % origin.name, subtitle="Virtual machine event")

    def vm_shutoff(self, origin, user_info, parameters):
        """
        Handle hook HOOK_VM_SHUTOFF.
        @type origin: L{TNArchipelEntity}
        @param origin: the origin of the hook
        @type user_info: object
        @param user_info: random user info
        @type parameters: object
        @param parameters: runtim argument
        """
        self.send("Archipel", "Virtual machine %s has been shut off." % origin.name, subtitle="Virtual machine event")

    def vm_stop(self, origin, user_info, parameters):
        """
        Handle hook HOOK_VM_STOP.
        @type origin: L{TNArchipelEntity}
        @param origin: the origin of the hook
        @type user_info: object
        @param user_info: random user info
        @type parameters: object
        @param parameters: runtim argument
        """
        self.send("Archipel", "Virtual machine %s has been stopped." % origin.name, subtitle="Virtual machine event")

    def vm_destroy(self, origin, user_info, parameters):
        """
        Handle hook HOOK_VM_DESTROY.
        @type origin: L{TNArchipelEntity}
        @param origin: the origin of the hook
        @type user_info: object
        @param user_info: random user info
        @type parameters: object
        @param parameters: runtim argument
        """
        self.send("Archipel", "Virtual machine %s has been destroyed." % origin.name, subtitle="Virtual machine event")

    def vm_suspend(self, origin, user_info, parameters):
        """
        Handle hook HOOK_VM_SUSPEND.
        @type origin: L{TNArchipelEntity}
        @param origin: the origin of the hook
        @type user_info: object
        @param user_info: random user info
        @type parameters: object
        @param parameters: runtim argument
        """
        self.send("Archipel", "Virtual machine %s has been suspended." % origin.name, subtitle="Virtual machine event")

    def vm_resume(self, origin, user_info, parameters):
        """
        Handle hook HOOK_VM_RESUME.
        @type origin: L{TNArchipelEntity}
        @param origin: the origin of the hook
        @type user_info: object
        @param user_info: random user info
        @type parameters: object
        @param parameters: runtim argument
        """
        self.send("Archipel", "Virtual machine %s has been resumed." % origin.name, subtitle="Virtual machine event")

    def vm_undefine(self, origin, user_info, parameters):
        """
        Handle hook HOOK_VM_UNDEFINE.
        @type origin: L{TNArchipelEntity}
        @param origin: the origin of the hook
        @type user_info: object
        @param user_info: random user info
        @type parameters: object
        @param parameters: runtim argument
        """
        self.send("Archipel", "Virtual machine %s has been undefined." % origin.name, subtitle="Virtual machine event")

    def vm_define(self, origin, user_info, parameters):
        """
        Handle hook HOOK_VM_DEFINE.
        @type origin: L{TNArchipelEntity}
        @param origin: the origin of the hook
        @type user_info: object
        @param user_info: random user info
        @type parameters: object
        @param parameters: runtim argument
        """
        self.send("Archipel", "Virtual machine %s has been defined." % origin.name, subtitle="Virtual machine event")

    def hypervisor_alloc(self, origin, user_info, parameters):
        """
        Handle hook HOOK_HYPERVISOR_ALLOC.
        @type origin: L{TNArchipelEntity}
        @param origin: the origin of the hook
        @type user_info: object
        @param user_info: random user info
        @type parameters: object
        @param parameters: runtim argument
        """
        self.send("Archipel", "Virtual machine %s has been allocated." % parameters.name, subtitle="Hypervisor event")

    def hypervisor_free(self, origin, user_info, parameters):
        """
        Handle hook HOOK_HYPERVISOR_FREE.
        @type origin: L{TNArchipelEntity}
        @param origin: the origin of the hook
        @type user_info: object
        @param user_info: random user info
        @type parameters: object
        @param parameters: runtim argument
        """
        self.send("Archipel", "Virtual machine %s has been removed." % parameters.name, subtitle="Hypervisor event")

    def hypervisor_clone(self, origin, user_info, parameters):
        """
        Handle hook HOOK_HYPERVISOR_CLONE.
        @type origin: L{TNArchipelEntity}
        @param origin: the origin of the hook
        @type user_info: object
        @param user_info: random user info
        @type parameters: object
        @param parameters: runtim argument
        """
        self.send("Archipel", "Virtual machine %s has been cloned." % parameters.name, subtitle="Hypervisor event")

    def hypervisor_migrate_leave(self, origin, user_info, parameters):
        """
        Handle hook HOOK_HYPERVISOR_MIGRATEDVM_LEAVE.
        @type origin: L{TNArchipelEntity}
        @param origin: the origin of the hook
        @type user_info: object
        @param user_info: random user info
        @type parameters: object
        @param parameters: runtim argument
        """
        self.send("Archipel", "Virtual machine %s has migrate to another hypervisor." % parameters, subtitle="Hypervisor event")

    def hypervisor_migrate_arrive(self, origin, user_info, parameters):
        """
        Handle hook HOOK_HYPERVISOR_MIGRATEDVM_ARRIVE.
        @type origin: L{TNArchipelEntity}
        @param origin: the origin of the hook
        @type user_info: object
        @param user_info: random user info
        @type parameters: object
        @param parameters: runtim argument
        """
        self.send("Archipel", "Virtual machine %s has juste arrived from another hypervisor." % parameters, subtitle="Hypervisor event")