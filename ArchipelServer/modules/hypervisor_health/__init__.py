#!/usr/bin/python
import health
from utils import *
import archipel


ARCHIPEL_NS_HYPERVISOR_HEALTH = "archipel:hypervisor:health"

######################################################################################################
### Registring of the stanza
######################################################################################################

def __module_init__health_module(self):
    db_file                 = self.configuration.get("HEALTH", "health_database_path")
    collection_interval     = self.configuration.getint("HEALTH", "health_collection_interval")
    max_rows_before_purge   = self.configuration.getint("HEALTH", "max_rows_before_purge")
    #snmp_agent              = self.configuration.get("HEALTH", "health_snmp_agent")
    #snmp_community          = self.configuration.get("HEALTH", "health_snmp_community")
    #snmp_version            = self.configuration.getint("HEALTH", "health_snmp_version")
    #snmp_port               = self.configuration.getint("HEALTH", "health_snmp_port")
    #snmp_infos               = {"snmp_agent": snmp_agent, "snmp_community": snmp_community, "snmp_version": snmp_version, "snmp_port": snmp_port}
    
    self.module_health = health.TNHypervisorHealth(db_file, collection_interval, max_rows_before_purge) #, snmp_infos)


def __module_register_stanza__heatlh_module(self):
    self.xmppclient.RegisterHandler('iq', self.module_health.process_iq, ns=ARCHIPEL_NS_HYPERVISOR_HEALTH)



setattr(archipel.TNArchipelHypervisor, "__module_init__health_module", __module_init__health_module)
setattr(archipel.TNArchipelHypervisor, "__module_register_stanza__heatlh_module", __module_register_stanza__heatlh_module)
