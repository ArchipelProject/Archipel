# -*- coding: utf-8 -*-
#
# computingunit.py
#
# Copyright (C) 2010 Antoine Mercadal <antoine.mercadal@inframonde.eu>
# Copyright (C) 2013 Nicolas Ochem <nicolas.ochem@free.fr>
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

from archipelcentralagentplatformrequest.scorecomputing import TNBasicPlatformScoreComputing


class TNDefaultComputingUnit (TNBasicPlatformScoreComputing):

    ### Initialization

    def __init__(self):
        """
        Initialize the TNBasicPlatformScoreComputing.
        """
        TNBasicPlatformScoreComputing.__init__(self)
        self.required_stats = [ { "major":"memory", "minor":"free" } ]


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

    def score(self, database, limit=10):
        """
        Perform the score. The highest is the score, the highest chance
        you got to perform the action. If you want to decline
        the performing of the action, return 0.0 or None. the max score
        you can return is 1.0 (so basically see it as a percentage).
        @type limit: integer
        @param limit: the number of potential hypervisors to suggest
        @rtype: list
        @return: scores of the top hypervisors
        """
        # stat1 is the free ram available, we divide it by 256GB of ram to get a first score, the highest ram the better;
        # 1/(1+num_vm) gives us another score based on the number of vms running, the less the better;
        # but we have to perform an union to take into account the case of hypervisors with no vms
        # we multiply these 2 scores to get the final score.
        hyp_list = []
        rows = database.execute("select hypervisors.jid, 1.0/(1+count(vms.uuid))*(hypervisors.stat1/256000000.0) as score_vms\
                from hypervisors join vms on hypervisors.jid=vms.hypervisor\
                where hypervisors.status='Online'\
                union\
                select hypervisors.jid, (hypervisors.stat1/256000000.0) as score_vms\
                from hypervisors left outer join vms on hypervisors.jid=vms.hypervisor\
                where hypervisors.status='Online'\
                and vms.uuid is null \
                order by score_vms asc \
                limit %s;" % limit)
        for row in rows:
            hyp_list.append({"jid":row[0], "score":row[1]})
        return hyp_list
