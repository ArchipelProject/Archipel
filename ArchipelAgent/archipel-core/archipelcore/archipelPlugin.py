# -*- coding: utf-8 -*-
#
# archipelPlugin.py
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


class TNArchipelPlugin:

    def __init__(self, configuration=None, entity=None, entry_point_group=None):
        """
        Initialize the plugin.
        @type configuration: Configuration object
        @param configuration: the configuration
        @type entity: L{TNArchipelEntity}
        @param entity: the entity that owns the plugin
        @type entry_point_group: string
        @param entry_point_group: the group name of plugin entry_point
        """
        self.configuration              = configuration
        self.entity                     = entity
        self.plugin_entry_point_group   = entry_point_group

    def register_handlers(self):
        """
        This method will be called to when entiyt will register
        handlers for stanzas. Place plugin handlers registration here.
        """
        pass

    def unregister_handlers(self):
        """
        Unregister the handlers. This method must be implemented if register_handlers
        is implemented.
        """
        pass

    @classmethod
    def plugin_info(self, group):
        """
        Return plugin information. it must return a dict like:
        plugin_friendly_name           = "User friendly name of plugin"
        plugin_identifier              = "plugin_identifier"
        plugin_configuration_section   = "required [SECTION] in configuration"
        plugin_configuration_tokens    = [  "required_token_section1",
                                            "required_token_section2"]
        return {    "common-name"               : plugin_friendly_name,
                    "identifier"                : plugin_identifier,
                    "configuration-section"     : plugin_configuration_section,
                    "configuration-tokens"      : plugin_configuration_tokens }
        @raise Exception: Exception if not implemented
        """
        raise Exception("plugins objects must implement 'plugin_info'")