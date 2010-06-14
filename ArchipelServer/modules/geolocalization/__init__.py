#!/usr/bin/python
import geoloc
import archipel
import utils

NS_ARCHIPEL_HYPERVISOR_GEOLOC = "archipel:hypervisor:geolocalization"

# this method will be call at loading
def __module_init__geoloc(self):
    self.module_geolocalization = geoloc.TNHypervisorGeolocalization(self.configuration)


def __module_register_stanza__geoloc(self):
    self.xmppclient.RegisterHandler('iq', self.module_geolocalization.process_iq, typ=NS_ARCHIPEL_HYPERVISOR_GEOLOC)
    
    
setattr(archipel.TNArchipelHypervisor, "__module_init__geoloc", __module_init__geoloc)
setattr(archipel.TNArchipelHypervisor, "__module_register_stanza__geoloc", __module_register_stanza__geoloc)