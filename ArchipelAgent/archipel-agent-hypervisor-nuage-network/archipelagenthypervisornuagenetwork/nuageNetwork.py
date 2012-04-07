# -*- coding: utf-8 -*-
#
# NuageNetwork.py
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

import commands
import os
import xmpp

from archipelcore.archipelPlugin import TNArchipelPlugin
from archipelcore.utils import build_error_iq, build_error_message


ARCHIPEL_NS_HYPERVISOR_NUAGE_NETWORK        = "archipel:hypervisor:nuage:network"
ARCHIPEL_ERROR_CODE_NUAGE_NETWORKS_CREATE   = -12001
ARCHIPEL_ERROR_CODE_NUAGE_NETWORKS_DELETE   = -12001
ARCHIPEL_ERROR_CODE_NUAGE_NETWORKS_UPDATE   = -12001
ARCHIPEL_ERROR_CODE_NUAGE_NETWORKS_GET      = -12001



class TNHypervisorNuageNetworks (TNArchipelPlugin):

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
        self.pubsub_nuage_networks = None;

        # permissions
        self.entity.permission_center.create_permission("nuagenetwork_get", "Authorizes user to get the existing Nuage networks", False)

        if self.entity.__class__.__name__ == "TNArchipelHypervisor":
            self.entity.permission_center.create_permission("nuagenetwork_create", "Authorizes user to create a Nuage network", False)
            self.entity.permission_center.create_permission("nuagenetwork_delete", "Authorizes user to delete a Nuage network", False)
            self.entity.permission_center.create_permission("nuagenetwork_update", "Authorizes user to update a Nuage network", False)

        # register to the node vmrequest
        if isinstance(self.entity, TNArchipelHypervisor):
            self.entity.register_hook("HOOK_ARCHIPELENTITY_XMPP_AUTHENTICATED", method=self.manage_nuage_network_node)


    ### Plugin implementation

    def register_handlers(self):
        """
        This method will be called by the plugin user when it will be
        necessary to register module for listening to stanza.
        """
        if self.entity.__class__.__name__ == "TNArchipelVirtualMachine":
            self.entity.xmppclient.RegisterHandler('iq', self.process_iq_for_virtualmachine, ns=ARCHIPEL_NS_HYPERVISOR_NUAGE_NETWORK)
        elif self.entity.__class__.__name__ == "TNArchipelHypervisor":
            self.entity.xmppclient.RegisterHandler('iq', self.process_iq_for_hypervisor, ns=ARCHIPEL_NS_HYPERVISOR_NUAGE_NETWORK)

    def unregister_handlers(self):
        """
        Unregister the handlers.
        """
        if self.entity.__class__.__name__ == "TNArchipelVirtualMachine":
            self.entity.xmppclient.UnregisterHandler('iq', self.process_iq_for_virtualmachine, ns=ARCHIPEL_NS_HYPERVISOR_NUAGE_NETWORK)
        elif self.entity.__class__.__name__ == "TNArchipelHypervisor":
            self.entity.xmppclient.UnregisterHandler('iq', self.process_iq_for_hypervisor, ns=ARCHIPEL_NS_HYPERVISOR_NUAGE_NETWORK)

    @staticmethod
    def plugin_info():
        """
        Return informations about the plugin.
        @rtype: dict
        @return: dictionary contaning plugin informations
        """
        plugin_friendly_name           = "Hypervisor Nuage Networks"
        plugin_identifier              = "hypervisor_nuage_network"
        plugin_configuration_section   = "NUAGE NETWORKS" //// HERE
        plugin_configuration_tokens    = []
        return {    "common-name"               : plugin_friendly_name,
                    "identifier"                : plugin_identifier,
                    "configuration-section"     : plugin_configuration_section,
                    "configuration-tokens"      : plugin_configuration_tokens }


    ### PubSub Management

    def manage_nuage_network_node(self, origin, user_info, arguments):
        """
        Register to pubsub event node /archipel/nuage/networks
        and /archipel/platform/requests/out
        @type origin: L{TNArchipelEnity}
        @param origin: the origin of the hook
        @type user_info: object
        @param user_info: random user information
        @type arguments: object
        @param arguments: runtime argument
        """
        nodeName = "/archipel/nuage/networks"
        self.entity.log.info("NUAGENETWORKS: getting the pubsub node %s" % nodeName)
        self.pubsub_nuage_networks = TNPubSubNode(self.entity.xmppclient, self.entity.pubsubserver, nodeName)
        self.pubsub_nuage_networks.recover(wait=True)
        self.entity.log.info("NUAGENETWORKS: node %s recovered." % nodeName)
        # self.pubsub_nuage_networks.subscribe(self.entity.jid, self._handle_request_event, wait=True)
        self.pubsub_nuage_networks.subscribe(self.entity.jid, wait=True)
        self.entity.log.info("NUAGENETWORKS: entity %s is now subscribed to events from node %s" % (self.entity.jid, nodeName))

    ### Utilities

    def get_ticket_from_identifier(self, identifier):
        """
        parse the parked vm to find the ticket of the given uuid
        @type identifier: String
        @param identifier: the identifier of the network
        @rtype: String
        @return: pubsub item id
        """
        items = self.pubsub_nuage_networks.get_items()
        for item in items:
            # domain = item.getTag("virtualmachine").getTag("domain")
            # if domain.getTag("uuid").getData() == uuid:
            #     return item.getAttr("id")
        return None

    def is_network_already_exists(self, identifier):
        """
        Check if vm with given UUID is already parked
        @type identifier: String
        @param identifier: the identifier of the network
        @rtype: Boolean
        @return: True is vm is already in park
        """
        if self.get_ticket_from_identifier(identifier):
            return True
        return False



    ### Business logic

    def get(self):
        """
        List Nuage networks in the pubsub. It returns a dict with the following form:
        [{"info": { "itemid": <PUBSUB-TICKET>,
                    "creator": <JID-OF-CREATOR>,
                    "date": <DATE-OF-LAST-UPDATE>},
                    "network": <XML-NUAGE-NETWORK>},
                    ...
        ]
        @rtype: Array
        @return: listinformations about virtual machines.
        """
        nodes = self.pubsub_nuage_networks.get_items()
        ret = []
        for node in nodes:
            network = xmpp.Node(node=node.getTag("network"))
            # ret.append({"info":
            #                 {"itemid": node.getAttr("id"),
            #                 "parker": node.getTag("virtualmachine").getAttr("parker"),
            #                 "date": node.getTag("virtualmachine").getAttr("date")},
            #                 "domain": domain})
        # def sorting(a, b):
        #     return cmp(a["domain"].getTag("name").getData(), b["domain"].getTag("name").getData())
        # ret.sort(sorting)
        return ret


    def delete(self, identifier):
        """
        delete the network with given identifier
        @type identifier: string
        @param identifier: the identifer of the network to destroy. It can be its name or UUID
        """
        pass

    def create(self, definition):
        """
        define the network
        @type definition: string
        @param definition: the XML definition to use
        """
        pass

    def update(self, identifier, definition):
        """
        define the network
        @type identifier: String
        @param identifier: the identifier of the network
        @type definition: string
        @param definition: the XML definition to use
        """
        pass


    ### XMPP Processing

    def process_iq_for_hypervisor(self, conn, iq):
        """
        This method is invoked when a ARCHIPEL_NS_HYPERVISOR_NUAGE_NETWORK IQ is received.
        It understands IQ of type:
            - create
            - get
            - destroy
            - update
        @type conn: xmpp.Dispatcher
        @param conn: ths instance of the current connection that send the stanza
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ
        """
        reply = None
        action = self.entity.check_acp(conn, iq)
        self.entity.check_perm(conn, iq, action, -1, prefix="nuagenetwork_")
        if action == "create":
            reply = self.iq_create(iq)
        elif action == "delete":
            reply = self.iq_delete(iq)
        elif action == "update":
            reply = self.iq_update(iq)
        elif action == "get":
            reply = self.iq_get(iq)
        if reply:
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed

    def process_iq_for_virtualmachine(self, conn, iq):
        """
        This method is invoked when a ARCHIPEL_NS_HYPERVISOR_NUAGE_NETWORK IQ is received.
        It understands IQ of type:
            - get
        @type conn: xmpp.Dispatcher
        @param conn: ths instance of the current connection that send the stanza
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ
        """
        reply = None
        action = self.entity.check_acp(conn, iq)
        self.entity.check_perm(conn, iq, action, -1, prefix="nuagenetwork_")
        if action == "get":
            reply = self.iq_get(iq)
        if reply:
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed

    def iq_create(self, iq):
        """
        Crate a Nuage network according to the XML data
        network passed in argument.
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ
        @rtype: xmpp.Protocol.Iq
        @return: a ready to send IQ containing the result of the action
        """
        try:
            pass
        except Exception as ex:
            reply = build_error_iq(self, ex, iq, ARCHIPEL_ERROR_CODE_NUAGE_NETWORKS_CREATE)
        return reply

    def iq_delete(self, iq):
        """
        Delete a nuage network according to name passed in argument.
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ
        @rtype: xmpp.Protocol.Iq
        @return: a ready to send IQ containing the result of the action
        """
        try:
            pass
        except Exception as ex:
            reply = build_error_iq(self, ex, iq, ARCHIPEL_ERROR_CODE_NUAGE_NETWORKS_DELETE)
        return reply

    def iq_update(self, iq):
        """
        Update a Nuage network.
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ
        @rtype: xmpp.Protocol.Iq
        @return: a ready to send IQ containing the result of the action
        """
        try:
            pass
        except Exception as ex:
            reply = build_error_iq(self, ex, iq, ARCHIPEL_ERROR_CODE_NUAGE_NETWORKS_UPDATE)
        return reply

    def iq_get(self, iq):
        """
        Get information of a Nuage network.
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ
        @rtype: xmpp.Protocol.Iq
        @return: a ready to send IQ containing the result of the action
        """
        try:
            pass;
        except Exception as ex:
            reply = build_error_iq(self, ex, iq, ARCHIPEL_ERROR_CODE_NUAGE_NETWORKS_GET)
        return reply
