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

import health


ARCHIPEL_NS_HYPERVISOR_HEALTH = "archipel:hypervisor:health"


### Registring of the stanza


def __module_init__health_module(self):
    db_file                 = self.configuration.get("HEALTH", "health_database_path")
    collection_interval     = self.configuration.getint("HEALTH", "health_collection_interval")
    max_rows_before_purge   = self.configuration.getint("HEALTH", "max_rows_before_purge")
    max_cached_rows         = self.configuration.getint("HEALTH", "max_cached_rows")
    log_file                = self.configuration.get("LOGGING", "logging_file_path")
    
    self.module_health = health.TNHypervisorHealth(self, db_file, collection_interval, max_rows_before_purge, max_cached_rows, log_file)


def __module_register_stanza__heatlh_module(self):
    self.xmppclient.RegisterHandler('iq', self.module_health.process_iq, ns=ARCHIPEL_NS_HYPERVISOR_HEALTH)



setattr(archipel.core.archipelHypervisor.TNArchipelHypervisor, "__module_init__health_module", __module_init__health_module)
setattr(archipel.core.archipelHypervisor.TNArchipelHypervisor, "__module_register_stanza__heatlh_module", __module_register_stanza__heatlh_module)
