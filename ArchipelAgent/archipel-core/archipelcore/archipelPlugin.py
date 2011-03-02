#
# archipelPlugin.py
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


class TNArchipelPlugin:

    def __init__(self, configuration=None, entity=None, entry_point_group=None):
        self.configuration              = configuration
        self.entity                     = entity
        self.plugin_entry_point_group   = entry_point_group


    def register_for_stanza(self):
        pass

    @classmethod
    def plugin_info(self, group):
        raise Exception("plugins objects must implement 'plugin_info'")
