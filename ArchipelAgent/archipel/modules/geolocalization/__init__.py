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


import archipel.utils
import archipel.core.archipelHypervisor

import geoloc

ARCHIPEL_NS_HYPERVISOR_GEOLOC = "archipel:hypervisor:geolocalization"

# this method will be call at loading
def __module_init__geoloc(self):
    self.module_geolocalization = geoloc.TNHypervisorGeolocalization(conf=self.configuration, entity=self)


def __module_register_stanza__geoloc(self):
    self.xmppclient.RegisterHandler('iq', self.module_geolocalization.process_iq, ns=ARCHIPEL_NS_HYPERVISOR_GEOLOC)
    
    
setattr(archipel.core.archipelHypervisor.TNArchipelHypervisor, "__module_init__geoloc", __module_init__geoloc)
setattr(archipel.core.archipelHypervisor.TNArchipelHypervisor, "__module_register_stanza__geoloc", __module_register_stanza__geoloc)