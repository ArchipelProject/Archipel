# -*- coding: utf-8 -*-
#
# virtualmachineagent.py
#
# Copyright (C) 2012 parspooyesh <everplays@gmail.com>
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

from archipelcore.archipelPlugin import TNArchipelPlugin

class TNVirtualMachineAgent(TNArchipelPlugin):
    """
    This plugin allows to create scheduled actions.
    """
    def __init__(self, configuration, entity, entry_point_group):
        """
        Initialize the plugin.
        @type configuration: Configuration object
        @param configuration: the configuration
        @type entity: L{TNArchipelEntity}
        @param entity: the entity that owns the plugin
        @type entry_point_group: string
        @param entry_point_group: the group name of plugin entry_point
        """
        TNArchipelPlugin.__init__(self, configuration=configuration, entity=entity, entry_point_group=entry_point_group)
        register_items = [{
			"commands" : ["!exec"],
			"parameters": [],
			"method": self.msg_get,
			"description": "runs command on guest os and displays result"
		}]
        self.entity.add_message_registrar_items(register_items)

    @staticmethod
    def plugin_info():
        """
        Return informations about the plugin.
        @rtype: dict
        @return: dictionary contaning plugin informations
        """
        return {    "common-name"               : "Virtual Machine Agent",
                    "identifier"                : "virtualmachineagent",
                    "configuration-section"     : None,
                    "configuration-tokens"      : []}

    def msg_get(self, msg):
        return self.entity.domain.UUIDString()
