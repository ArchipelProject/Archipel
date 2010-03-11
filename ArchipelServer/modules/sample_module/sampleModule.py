#!/usr/bin/python
# archipelModuleHypervisorTest.py
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


# we need to import the package containing the class to surclass
import xmpp
from utils import *
import archipel




# this method will be call at loading
def __module_init__sample_module(self):
    log(self, LOG_LEVEL_INFO, "hello from sample module");

# this method will be called at registration of handlers for XMPP
def __module_register_stanza__sample_module(self):
    self.xmppclient.RegisterHandler('iq', self.__process_sample_iq, typ="a:type:that:doesnt:exists")


# this method is called according to the registration below
def __module__sample_module_process_sample_iq(self, conn, iq):
    reply = iq.buildReply("success");
    return reply




# finally, we add the methods to the class
#setattr(archipelHypervisor.TNArchipelHypervisor, "__module_init__sample_module", __module_init__sample_module)
#setattr(archipelHypervisor.TNArchipelHypervisor, "__module_register_stanza__sample_module", __module_register_stanza__sample_module)
#setattr(archipelHypervisor.TNArchipelHypervisor, "__module__sample_module_process_sample_iq", __module__sample_module_process_sample_iq)