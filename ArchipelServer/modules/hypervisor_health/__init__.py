#!/usr/bin/python
import health
from utils import *
import archipel


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



setattr(archipel.TNArchipelHypervisor, "__module_init__health_module", __module_init__health_module)
setattr(archipel.TNArchipelHypervisor, "__module_register_stanza__heatlh_module", __module_register_stanza__heatlh_module)
