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
import oomkiller


ARCHIPEL_NS_OOM_KILLER = "archipel:vm:oom"

# this method will be call at loading
def __module_init__oom(self):
    dbfile = self.configuration.get("OOMKILLER", "database");
    self.module_oom = oomkiller.TNOOMKiller(self, dbfile)
    self.register_hook("HOOK_VM_INITIALIZE", self.module_oom.vm_initialized)
    self.register_hook("HOOK_VM_CREATE", self.module_oom.vm_create)
    self.register_hook("HOOK_VM_TERMINATE", self.module_oom.vm_terminate)
    

# this method will be called at registration of handlers for XMPP
def __module_register_stanza__oom(self):
    self.xmppclient.RegisterHandler('iq', self.module_oom.process_iq, ns=ARCHIPEL_NS_OOM_KILLER)


setattr(archipel.TNArchipelVirtualMachine, "__module_init__oom", __module_init__oom)
setattr(archipel.TNArchipelVirtualMachine, "__module_register_stanza__oom", __module_register_stanza__oom)