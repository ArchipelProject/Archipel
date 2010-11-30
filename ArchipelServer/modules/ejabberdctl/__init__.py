#!/usr/bin/python
import ejabberdctl
import archipel


ARCHIPEL_NS_EJABBERDCTL_ROSTERS  = "archipel:ejabberdctl:rosters"
ARCHIPEL_NS_EJABBERDCTL_USERS   = "archipel:ejabberdctl:users"

# this method will be call at loading
def __module_init__ejabberdctl(self):
    exec_path = self.configuration.get("EJABBERDCTL", "exec_path")
    self.module_ejabberdctl = ejabberdctl.TNEjabberdctl(self, exec_path=exec_path)

# this method will be called at registration of handlers for XMPP
def __module_register_stanza__ejabberdctl(self):
    self.xmppclient.RegisterHandler('iq', self.module_ejabberdctl.process_rosters_iq, ns=ARCHIPEL_NS_EJABBERDCTL_ROSTERS)
    self.xmppclient.RegisterHandler('iq', self.module_ejabberdctl.process_users_iq, ns=ARCHIPEL_NS_EJABBERDCTL_USERS)



# WARNING THIS WILL CHANGE SOON.
# finally, we add the methods to the class
setattr(archipel.TNArchipelHypervisor, "__module_init__ejabberdctl", __module_init__ejabberdctl)
setattr(archipel.TNArchipelHypervisor, "__module_register_stanza__ejabberdctl", __module_register_stanza__ejabberdctl)