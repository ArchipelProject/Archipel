#!/usr/bin/python
import health
from utils import *
import archipel


NS_ARCHIPEL_HYPERVISOR_HEALTH = "archipel:hypervisor:health"

# adding a new color log for class TNThreadedHealthCollector
globals()["COLORING_MAPPING_CLASS"].update({"TNThreadedHealthCollector": u'\033[35m'})

######################################################################################################
### Registring of the stanza
######################################################################################################

def __module_init__health_module(self):
    db_file                 = self.configuration.get("Module Health", "health_database_path")
    snmp_agent              = self.configuration.get("Module Health", "health_snmp_agent")
    snmp_community          = self.configuration.get("Module Health", "health_snmp_community")
    snmp_version            = self.configuration.getint("Module Health", "health_snmp_version")
    snmp_port               = self.configuration.getint("Module Health", "health_snmp_port")
    collection_interval     = self.configuration.getint("Module Health", "health_collection_interval")
    max_rows_before_purge   = self.configuration.getint("Module Health", "max_rows_before_purge")
    
    self.module_health = health.TNHypervisorHealth(db_file,collection_interval, max_rows_before_purge, snmp_agent, snmp_community, snmp_version, snmp_port);


def __module_register_stanza__heatlh_module(self):
    self.xmppclient.RegisterHandler('iq', self.module_health.process_iq, typ=NS_ARCHIPEL_HYPERVISOR_HEALTH)



setattr(archipel.TNArchipelHypervisor, "__module_init__health_module", __module_init__health_module)
setattr(archipel.TNArchipelHypervisor, "__module_register_stanza__heatlh_module", __module_register_stanza__heatlh_module)
