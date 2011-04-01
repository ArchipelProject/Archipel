# -*- coding: utf-8 -*-
#
# computingunit.py
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

from archipelagenthypervisorplatformrequest.scorecomputing import TNBasicPlatformScoreComputing


class TNDefaultComputingUnit (TNBasicPlatformScoreComputing):

    ### Initialization

    def __init__(self):
        """
        Initialize the TNBasicPlatformScoreComputing.
        """
        TNBasicPlatformScoreComputing.__init__(self)


    ## Plugin implementation

    @staticmethod
    def plugin_info():
        """
        Return informations about the plugin.
        @rtype: dict
        @return: dictionary contaning plugin informations
        """
        plugin_friendly_name           = "Platform Request Default Score Computing Unit"
        plugin_identifier              = "defaultcomputingunit"
        plugin_configuration_section   = None
        plugin_configuration_tokens    = []
        return {    "common-name"               : plugin_friendly_name,
                    "identifier"                : plugin_identifier,
                    "configuration-section"     : plugin_configuration_section,
                    "configuration-tokens"      : plugin_configuration_tokens }


    ### Score computing

    def score(self, action=None):
        """
        Perform the score. The highest is the score, the highest chance
        you got to perform the action. If you want to decline
        the performing of the action, return 0.0 or None. the max score
        you can return is 1.0 (so basically see it as a percentage).
        @type action: string
        @param action: the name of the action if you want to use it to compute the score (optionnal)
        @rtype: float
        @return: the score
        """
        return 0.42 # TODO