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
from utils import *

class AppNotificator:
    
    def __init__(self, credentials):
        self.credentials = credentials;
    
    def send(self, title, message):
        notifications.send_async(credentials=self.credentials, title=title, message=message)
    
    
    def vm_create(self, entity, args):
        self.send("Archipel: %s" % entity.name, "virtual machine has been started")
    
    
    def vm_shutoff(self, entity, args):
        self.send("Archipel: %s" % entity.name, "virtual machine has been shut off")
    
    
    def vm_stop(self, entity, args):
        self.send("Archipel: %s" % entity.name, "virtual machine has been stopped")
    
    
    def vm_destroy(self, entity, args):
        self.send("Archipel: %s" % entity.name, "virtual machine has been destroyed")
    
    
    def vm_suspend(self, entity, args):
        self.send("Archipel: %s" % entity.name, "virtual machine has been suspended")
    
    
    def vm_resume(self, entity, args):
        self.send("Archipel: %s" % entity.name, "virtual machine has been resumed")
    
    
    def vm_undefine(self, entity, args):
        self.send("Archipel: %s" % entity.name, "virtual machine has been undefined")
    
    
    def vm_define(self, entity, args):
        self.send("Archipel: %s" % entity.name, "virtual machine has been defined")



    def hypervisor_alloc(self, entity, args):
        self.send("Archipel: %s" % entity.name, "virtual machine %s has been allocated" % args.name)
    
    
    def hypervisor_free(self, entity, args):
        self.send("Archipel: %s" % entity.name, "virtual machine %s has been removed" % args.name)
    
    
    def hypervisor_clone(self, entity, args):
        self.send("Archipel: %s" % entity.name, "virtual machine %s has been cloned" % args.name)
    
    
    def hypervisor_migrate_leave(self, entity, args):
        self.send("Archipel: %s" % entity.name, "virtual machine %s has migrate to another hypervisor" % args.name)
    
    
    def hypervisor_migrate_arrive(self, entity, args):
        self.send("Archipel: %s" % entity.name, "virtual machine %s has juste arrived from another hypervisor" % args.name)
    

