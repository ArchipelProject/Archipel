#!/usr/bin/python
import xmppserver
import archipel
import os

ARCHIPEL_NS_XMPPSERVER_GROUPS  = "archipel:xmppserver:groups"
ARCHIPEL_NS_XMPPSERVER_USERS   = "archipel:xmppserver:users"

# this method will be call at loading
def __module_init__xmppserver(self):
    exec_path = self.configuration.get("XMPPSERVER", "exec_path")
    if not os.path.exists(exec_path):
        self.log.warning("unable to find %s command. aborting loading of module XMPPServer" % exec_path)
        self.module_xmppserver = False
        return
    self.module_xmppserver = xmppserver.TNXMPPServerController(self, exec_path=exec_path)

# this method will be called at registration of handlers for XMPP
def __module_register_stanza__xmppserver(self):
    if not self.module_xmppserver: return
    self.xmppclient.RegisterHandler('iq', self.module_xmppserver.process_groups_iq, ns=ARCHIPEL_NS_XMPPSERVER_GROUPS)
    self.xmppclient.RegisterHandler('iq', self.module_xmppserver.process_users_iq, ns=ARCHIPEL_NS_XMPPSERVER_USERS)



# WARNING THIS WILL CHANGE SOON.
# finally, we add the methods to the class
setattr(archipel.TNArchipelHypervisor, "__module_init__xmppserver", __module_init__xmppserver)
setattr(archipel.TNArchipelHypervisor, "__module_register_stanza__xmppserver", __module_register_stanza__xmppserver)