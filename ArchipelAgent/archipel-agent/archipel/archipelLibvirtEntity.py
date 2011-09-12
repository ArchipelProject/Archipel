# -*- coding: utf-8 -*-
#
# archipelLibvirtEntity.py
#
# Copyright (C) 2010 Antoine Mercadal <antoine.mercadal@inframonde.eu>
# Copyright, 2011 - Franck Villaume <franck.villaume@trivialdev.com>
# This file is part of ArchipelProject
# http://archipelproject.org
#
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
import random
import sys

ARCHIPEL_NS_LIBVIRT_GENERIC_ERROR = "libvirt:error:generic"

# hypervisor kinds
ARCHIPEL_HYPERVISOR_TYPE_QEMU       = "QEMU"
ARCHIPEL_HYPERVISOR_TYPE_XEN        = "XEN"
ARCHIPEL_HYPERVISOR_TYPE_OPENVZ     = "OPENVZ"
ARCHIPEL_HYPERVISOR_TYPE_LXC        = "LXC"


def generate_mac_adress():
    """
    Generate a new mac address.
    @rtype: string
    @return: generated MAC address
    """
    dico = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F"]
    digit1 = "DE"
    digit2 = "AD"
    digit3 = "%s%s" % (dico[random.randint(0, 15)], dico[random.randint(0, 15)])
    digit4 = "%s%s" % (dico[random.randint(0, 15)], dico[random.randint(0, 15)])
    digit5 = "%s%s" % (dico[random.randint(0, 15)], dico[random.randint(0, 15)])
    digit6 = "%s%s" % (dico[random.randint(0, 15)], dico[random.randint(0, 15)])
    return "%s:%s:%s:%s:%s:%s" % (digit1, digit2, digit3, digit4, digit5, digit6)



class TNArchipelLibvirtEntity (object):

    def __init__(self, configuration):
        """
        Initialize the TNArchipelLibvirtEntity.
        """
        self._libvirt_version = None
        self._driver_version = None
        self.configuration = configuration
        self.local_libvirt_uri = self.configuration.get("GLOBAL", "libvirt_uri")
        self.libvirt_connection = None
        if self.configuration.has_option("GLOBAL", "libvirt_need_authentication"):
            self.need_auth = self.configuration.getboolean("GLOBAL", "libvirt_need_authentication")
        else:
            self.need_auth = None

    def manage_vcard_hook(self, origin, user_info, parameters):
        """
        Hook to manage VCard.
        """
        self.manage_vcard()

    def connect_libvirt(self):
        """
        Connect to the libvirt according to parameters in configuration.
        """
        if self.need_auth:
            auth = [[libvirt.VIR_CRED_AUTHNAME, libvirt.VIR_CRED_PASSPHRASE], self.libvirt_credential_callback, None]
            self.libvirt_connection = libvirt.openAuth(self.local_libvirt_uri, auth, 0)
        else:
            self.libvirt_connection = libvirt.open(self.local_libvirt_uri)
            if self.libvirt_connection == None:
                self.log.error("Unable to connect libvirt.")
                sys.exit(-42)
        self.log.info("Connected to libvirt uri %s" % self.local_libvirt_uri)

    def libvirt_credential_callback(self, creds, cbdata):
        """
        Manage the libvirt credentials.
        """
        if creds[0][0] == libvirt.VIR_CRED_PASSPHRASE:
            ## TODO:  manage this more
            creds[0][4] = self.configuration.get("GLOBAL", "libvirt_auth_password")
            return 0
        else:
            return -1

    def current_hypervisor(self):
        """
        Return the result of libvirt getType() function.
        @rtype: string
        @return: uppercased string name of the current hypervisor
        """
        return self.libvirt_connection.getType().upper()

    def is_hypervisor(self, names):
        """
        Return True if hypervisor is one of the given names (tupple).
        @type names: tupple
        @param names: tupple containing names
        @rtype: boolean
        @return: True of False
        """
        return self.current_hypervisor() in names

    def libvirt_version(self):
        """
        Return the version of the libvirt
        """
        if not self._libvirt_version:
            libvirtnumber = libvirt.getVersion()
            self._libvirt_version = { "major": libvirtnumber / 1000000,
                                     "minor": libvirtnumber / 1000,
                                     "release": libvirtnumber % 1000}
        return self._libvirt_version

    def driver_version(self):
        """
        Return the version of the libvirt driver
        """
        if not self._driver_version:
            drivernumber = self.libvirt_connection.getVersion()
            self._driver_version = { "major": drivernumber / 1000000,
                                     "minor": drivernumber / 1000,
                                     "release": drivernumber % 1000}
        return self._driver_version