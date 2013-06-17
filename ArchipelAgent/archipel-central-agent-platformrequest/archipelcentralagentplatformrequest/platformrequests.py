# -*- coding: utf-8 -*-
#
# platformrequests.py
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

import xmpp
from pkg_resources import iter_entry_points

from archipelcore.archipelPlugin import TNArchipelPlugin
from archipelcore.utils import build_error_iq

from scorecomputing import TNBasicPlatformScoreComputing


ARCHIPEL_NS_PLATFORM = "archipel:centralagent:platform"


class TNPlatformRequests (TNArchipelPlugin):

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
        self.computing_unit = None
        # get computing unit plugin if present
        self.load_computing_unit()

    ### Plugin interface

    def register_handlers(self):
        """
        This method will be called by the plugin user when it will be
        necessary to register module for listening to stanza.
        """
        self.entity.log.debug("PLATFORMREQ: Registering handler for platform request")
        self.entity.xmppclient.RegisterHandler('iq', self.process_iq, ns=ARCHIPEL_NS_PLATFORM)

    def unregister_handlers(self):
        """
        Unregister the handlers.
        """
        self.entity.xmppclient.UnregisterHandler('iq', self.process_iq, ns=ARCHIPEL_NS_PLATFORM)

    @staticmethod
    def plugin_info():
        """
        Return informations about the plugin.
        @rtype: dict
        @return: dictionary contaning plugin informations
        """
        plugin_friendly_name = "Central Agent Platform Request"
        plugin_identifier = "platformrequest"
        plugin_configuration_section = None
        plugin_configuration_tokens = []
        return {"common-name": plugin_friendly_name,
                "identifier": plugin_identifier,
                "configuration-section": plugin_configuration_section,
                "configuration-tokens": plugin_configuration_tokens}


    ### Plugin loading

    def load_computing_unit(self):
        """
        Loads the external computing unit.
        """
        for factory_method in iter_entry_points(group="archipel.plugin.platform.computingunit", name="factory"):
            method = factory_method.load()
            plugin_content = method()
            self.computing_unit = plugin_content["plugin"]
            self.entity.log.info("PLATFORMREQ: loading computing unit %s" % plugin_content["info"]["common-name"])
            break
        if not self.computing_unit:
            self.computing_unit = TNBasicPlatformScoreComputing()
            self.entity.log.warning("PLATFORMREQ: using dummy computing unit. It returns random values !")


    ### XMPP Management

    def process_iq(self, conn, iq):
        """
        This method is invoked when a ARCHIPEL_NS_PLATFORM IQ is received.
        It understands IQ of type:
            - request
        @type conn: xmpp.Dispatcher
        @param conn: ths instance of the current connection that send the stanza
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ
        """
        reply = None
        action = self.entity.check_acp(conn, iq)
        if action == "request":
            reply = self.iq_request(iq)
        if reply:
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed

    def iq_request(self, iq):
        """
        Process platform request.
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ
        @rtype: xmpp.Protocol.Iq
        @return: a ready to send IQ containing the result of the action
        """
        try:
            reply = iq.buildReply("result")
            limit = iq.getTag("query").getTag("archipel").getAttr("limit")
            computed_items = self.computing_unit.score(self.entity.database, limit=limit)
            self.entity.log.debug("PLATFORMREQ: computed items : %s" % computed_items)
            for computed_item in computed_items: 
                reply.addChild("hypervisor", attrs=computed_item)
        except Exception as ex:
            reply = build_error_iq(self, ex, iq)
        return reply
