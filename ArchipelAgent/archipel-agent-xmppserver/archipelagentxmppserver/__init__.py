# -*- coding: utf-8 -*-
#
# __init__.py
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


def make_archipel_plugin(configuration, entity, group):
    """
    This function is the plugin factory. It will be called by the object you want
    to be plugged in. It must return a list whit at least on dictionary containing
    a key for the the plugin informations, and a key for the plugin object.
    @type configuration: Config Object
    @param configuration: the general configuration object
    @type entity: L{TNArchipelEntity}
    @param entity: the entity that has load the plugin
    @type group: string
    @param group: the entry point group name in which the plugin has been loaded
    @rtype: array
    @return: array of dictionary containing the plugins informations and objects
    """
    if configuration.has_option("XMPPSERVER", "use_xmlrpc_api") and configuration.getboolean("XMPPSERVER", "use_xmlrpc_api"):
        import xmppserver_xmlrpc as xmppserver
    else:
        import xmppserver_xmpp as xmppserver

    return [{"info": xmppserver.TNXMPPServerController.plugin_info(),
             "plugin": xmppserver.TNXMPPServerController(configuration, entity, group)}]


def version():
    """
    This function can be called runarchipel -v in order to get the version of the
    installed plugin. You only should have to change the egg name.
    @rtype: tupple
    @return: tupple containing the package name and the version
    """
    import pkg_resources
    import xmppserver_xmpp
    return (__name__, pkg_resources.get_distribution("archipel-agent-xmppserver").version, [xmppserver_xmpp.TNXMPPServerController.plugin_info()])