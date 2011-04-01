# -*- coding: utf-8 -*-
#
# __init__.py
#
# Copyright (C) 2010 Antoine Mercadal <antoine.mercadal@inframonde.eu>
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

import computingunit


def make_computing_unit():
    """
    This function is the plugin factory. It will be called by the object you want
    to be plugged in. It must return a dictionary containing
    a key for the the plugin informations, and a key for the plugin object.
    @type configuration: Config Object
    @param configuration: the general configuration object
    @type entity: L{TNArchipelEntity}
    @param entity: the entity that has load the plugin
    @type group: string
    @param group: the entry point group name in which the plugin has been loaded
    @rtype: dict
    @return: dictionary containing the plugins informations and objects
    """
    return {"info": computingunit.TNDefaultComputingUnit.plugin_info(),
            "plugin": computingunit.TNDefaultComputingUnit()}

def version():
    """
    This function can be called runarchipel -v in order to get the version of the
    installed plugin. You only should have to change the egg name.
    @rtype: tupple
    @return: tupple containing the package name and the version
    """
    import pkg_resources
    return (__name__, pkg_resources.get_distribution("archipel-platformrequest-defaultcomputingunit").version, [computingunit.TNDefaultComputingUnit.plugin_info()])