# 
# archipelLibvirtEntity.py
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


import libvirt

class TNArchipelLibvirtEntity:
    
    def __init__(self, configuration):
        """
        initialize the TNArchipelLibvirtEntity
        """
        self.configuration      = configuration
        self.local_libvirt_uri  = self.configuration.get("GLOBAL", "libvirt_uri")
        self.libvirt_connection = None
        if self.configuration.has_option("GLOBAL", "libvirt_need_authentication"):
            self.need_auth  = self.configuration.getboolean("GLOBAL", "libvirt_need_authentication")
        else:
            self.need_auth = None
        
        
    def connect_libvirt(self):
        """
        connect to the libvirt according to parameters in configuration
        """
        if self.need_auth:
            auth = [[libvirt.VIR_CRED_AUTHNAME, libvirt.VIR_CRED_PASSPHRASE], self.libvirt_credential_callback, None]
            self.libvirt_connection = libvirt.openAuth(self.local_libvirt_uri, auth, 0)
        else:
            self.libvirt_connection = libvirt.open(self.local_libvirt_uri)
            if self.libvirt_connection == None:
                self.log.error("unable to connect libvirt")
                sys.exit(-42)
        self.log.info("connected to libvirt uri %s" % self.local_libvirt_uri)
    
    
    
    def libvirt_credential_callback(self, creds, cbdata):
        """
        manage the libvirt credentials
        """
        if creds[0][0] == libvirt.VIR_CRED_PASSPHRASE:
            ## TODO:  manage this more
            creds[0][4] = self.configuration.get("GLOBAL", "libvirt_auth_password")
            return 0
        else:
            return -1
