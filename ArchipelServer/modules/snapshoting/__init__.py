#!/usr/bin/python
import snapshoting
import archipel


# the stanza type "archipel:virtualmachine:foo" or "archipel:hypervisor:bar"
ARCHIPEL_NS_SNAPSHOTING = "archipel:virtualmachine:snapshoting"

# this method will be call at loading
def __module_init__snapshoting(self):
    self.module_snapshoting = snapshoting.TNSnapshoting(entity=self)

# this method will be called at registration of handlers for XMPP
def __module_register_stanza__snapshoting(self):
    self.xmppclient.RegisterHandler('iq', self.module_snapshoting.process_iq, ns=ARCHIPEL_NS_SNAPSHOTING)



# WARNING THIS WILL CHANGE SOON.
# finally, we add the methods to the class
setattr(archipel.TNArchipelVirtualMachine, "__module_init__snapshoting", __module_init__snapshoting)
setattr(archipel.TNArchipelVirtualMachine, "__module_register_stanza__snapshoting", __module_register_stanza__snapshoting)