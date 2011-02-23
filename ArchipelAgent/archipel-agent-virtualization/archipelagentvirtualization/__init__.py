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

import xmpp
import socket

import archipelWebSocket
import archipelHypervisor
import archipelVirtualMachine
import libvirtEventLoop

ARCHIPEL_INIT_ERROR_BAD_LIBVIRT = 3

def test_libvirt():
    """test if all needed libvirt's function are present"""
    try:
        import libvirt
    except:
        print "\n\n\033[31mERROR: you need python libvirt module. I can't import it.\033[0m\n"
        return False
    try:
        getattr(libvirt.virConnect, "domainEventRegisterAny")
    except:
        print "\n\n\033[31mERROR: your libvirt copy doesn't handle Events correctly. please update to 0.8.3+.\033[0m\n"
        return False
    return True



def init_worker(configuration):
    """
    main function of Archipel
    """
    if not test_libvirt(): sys.exit(ARCHIPEL_INIT_ERROR_BAD_LIBVIRT)
    
    # starting thre libvirt event loop
    libvirtEventLoop.virEventLoopPureStart()
    
    # initializing the hypervisor XMPP entity
    jid         = xmpp.JID(configuration.get("HYPERVISOR", "hypervisor_xmpp_jid"))
    password    = configuration.get("HYPERVISOR", "hypervisor_xmpp_password")
    database    = configuration.get("HYPERVISOR", "hypervisor_database_path")
    name        = configuration.get("HYPERVISOR", "hypervisor_name")
    jid.setResource(socket.gethostname())
    hyp = archipelHypervisor.TNArchipelHypervisor(jid, password, configuration, name, database)
    hyp.connect()
    hyp.loop()


def version():
    import pkg_resources
    return (__name__, pkg_resources.get_distribution("archipel-agent-virtualization").version)

