#!/usr/bin/python
import sampleModule
import archipel


ARCHIPEL_NS_SAMPLE = "a:type:that:doesnt:exists"

# this method will be call at loading
def __module_init__sample_module(self):
    log.info("hello from sample module")
    self.module_sample = sampleModule.TNSampleModule(self)

# this method will be called at registration of handlers for XMPP
def __module_register_stanza__sample_module(self):
    self.xmppclient.RegisterHandler('iq', self.module_sample.process_iq, ns=ARCHIPEL_NS_SAMPLE)



# WARNING THIS WILL CHANGE SOON.
# finally, we add the methods to the class
setattr(archipel.TNArchipelHypervisor, "__module_init__sample_module", __module_init__sample_module)
setattr(archipel.TNArchipelHypervisor, "__module_register_stanza__sample_module", __module_register_stanza__sample_module)