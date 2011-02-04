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

import os
import archipel.core.archipelHypervisor

import xmppserver

ARCHIPEL_NS_XMPPSERVER_GROUPS  = "archipel:xmppserver:groups"
ARCHIPEL_NS_XMPPSERVER_USERS   = "archipel:xmppserver:users"

# this method will be call at loading
def __module_init__xmppserver(self):
    xmlrpc_host     = self.configuration.get("XMPPSERVER", "xmlrpc_host")
    xmlrpc_port     = self.configuration.getint("XMPPSERVER", "xmlrpc_port")
    xmlrpc_user     = self.configuration.get("XMPPSERVER", "xmlrpc_user")
    xmlrpc_password = self.configuration.get("XMPPSERVER", "xmlrpc_password")
    
    self.module_xmppserver = xmppserver.TNXMPPServerController(self, xmlrpc_host, xmlrpc_port, xmlrpc_user, xmlrpc_password)

# this method will be called at registration of handlers for XMPP
def __module_register_stanza__xmppserver(self):
    self.xmppclient.RegisterHandler('iq', self.module_xmppserver.process_groups_iq, ns=ARCHIPEL_NS_XMPPSERVER_GROUPS)
    self.xmppclient.RegisterHandler('iq', self.module_xmppserver.process_users_iq, ns=ARCHIPEL_NS_XMPPSERVER_USERS)



# WARNING THIS WILL CHANGE SOON.
# finally, we add the methods to the class
setattr(archipel.core.archipelHypervisor.TNArchipelHypervisor, "__module_init__xmppserver", __module_init__xmppserver)
setattr(archipel.core.archipelHypervisor.TNArchipelHypervisor, "__module_register_stanza__xmppserver", __module_register_stanza__xmppserver)