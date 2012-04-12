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

import datetime
import os
import xmpp

from archipelcore.pubsub import TNPubSubNode
from archipelcore.archipelPlugin import TNArchipelPlugin
from archipelcore.utils import build_error_iq, build_error_message


ARCHIPEL_NS_HYPERVISOR_NUAGE_NETWORK        = "archipel:hypervisor:nuage:network"
ARCHIPEL_ERROR_CODE_NUAGE_NETWORKS_CREATE   = -12001
ARCHIPEL_ERROR_CODE_NUAGE_NETWORKS_DELETE   = -12002
ARCHIPEL_ERROR_CODE_NUAGE_NETWORKS_UPDATE   = -12003
ARCHIPEL_ERROR_CODE_NUAGE_NETWORKS_GET      = -12004

# This is a sample of the definition of a nuage network
# <nuage_network name="blabla" type="ipv4" >
#     <bandwidth>
#         <inbound average='1000' peak='5000' burst='5120' />
#         <outbound average='1000' peak='5000' burst='5120' />
#     </bandwidth>
#     <ip address="192.168.122.1" netmask="255.255.255.0" gateway="192.168.122.2" />
# </nuage_network>


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
        if self.entity.__class__.__name__ == "TNArchipelHypervisor":
            self.entity.register_hook("HOOK_ARCHIPELENTITY_XMPP_AUTHENTICATED", method=self.manage_nuage_network_node)

        if self.entity.__class__.__name__ == "TNArchipelVirtualMachine":
            self.entity.add_vm_definition_hook(self.update_vm_xml_hook)


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
        plugin_configuration_section   = None
        plugin_configuration_tokens    = []
        return {    "common-name"               : plugin_friendly_name,
                    "identifier"                : plugin_identifier,
                    "configuration-section"     : plugin_configuration_section,
                    "configuration-tokens"      : plugin_configuration_tokens }



    ### VM XML Desc update
    def update_vm_xml_hook(self, senderJID, vm_xml_node):
        """
        Update the VM definition to insert the metadata informations
        @type sender: xmpp.JID
        @param sender: The JID of the sender
        @type vm_xml_node: xmpp.Node
        @param vm_xml_node: The VM's XML description
        """
        if not vm_xml_node.getTag("metadata"):
            vm_xml_node.addChild("metadata")
        if vm_xml_node.getTag("metadata").getTag("nuage"):
            vm_xml_node.getTag("metadata").delChild("nuage")

        hypervisor_nuage_plugin = self.entity.hypervisor.get_plugin("hypervisor_nuage_network")

        nuage_node = xmpp.Node("nuage", attrs={"xmlns": "alcatel-lucent.com/nuage/cna"})
        nuage_node.addChild("user", attrs={"name": senderJID.getStripped()})
        nuage_node.addChild("group", attrs={"name": "Group A"})
        nuage_node.addChild("enterprise", attrs={"name": "Enterprise 1"})
        app_node = nuage_node.addChild("application", attrs={"name": "LAMP"})

        interface_nodes = vm_xml_node.getTag("devices").getTags("interface")

        for interface in interface_nodes:

            if not interface.getAttr("type") == "nuage":
                continue
            network_name = interface.getAttr("name")
            mac_address = interface.getTag("mac").getAttr("address")
            network_item = hypervisor_nuage_plugin.get_network(network_name)
            network_name_XML = xmpp.Node(node=network_item.getTag("nuage").getTag("nuage_network")) # copy
            network_name_XML.addChild("interface_mac", attrs={"address": mac_address})

            ## Now we reconfigure the nic to be a bridge
            interface.setAttr("type", "bridge")
            if interface.getAttr("name"):
                interface.delAttr("name")
            if interface.getTag("source"):
                interface.delChild("source")
            interface.addChild("source", attrs={"bridge": "wathever-bridge0"})

            app_node.addChild(node=network_name_XML)

        vm_xml_node.getTag("metadata").addChild(node=nuage_node)
        return vm_xml_node


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

    def get_network(self, network_name):
        """
        Return the a network according to a name
        @type network_name: String
        @param network_name: the name of the network
        @rtype: xmpp.Node
        @return: the pubsub item
        """
        try:
            ticket = self.get_ticket_from_network_name(network_name)
            return self.pubsub_nuage_networks.get_item(ticket)
        except:
            raise Exception("There is no Nuage network with name %s" % network_name)

    def get_ticket_from_network_name(self, identifier):
        """
        parse the parked vm to find the ticket of the given uuid
        @type identifier: String
        @param identifier: the identifier of the network
        @rtype: String
        @return: pubsub item id
        """
        items = self.pubsub_nuage_networks.get_items()
        for item in items:
            name = item.getTag("nuage").getTag("nuage_network").getAttr("name")
            if name == identifier:
                return item.getAttr("id")
        return None

    def is_network_already_existing(self, network_name):
        """
        Check if vm with given UUID is already parked
        @type network_name: String
        @param network_name: the name of the network
        @rtype: Boolean
        @return: True is vm is already in park
        """
        if self.get_ticket_from_network_name(network_name):
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
            network = xmpp.Node(node=node.getTag("nuage"))
            ret.append({"info": {"itemid": node.getAttr("id"),
                                "creator": node.getTag("nuage").getAttr("creator"),
                                "date": node.getTag("nuage").getAttr("date")},
                        "network": node.getTag("nuage").getTag("nuage_network")})
        def sorting(a, b):
            return cmp(a["network"].getAttr("name"), b["network"].getAttr("name"))
        ret.sort(sorting)
        return ret

    def delete(self, network_name):
        """
        delete the network with given identifier
        @type network_name: string
        @param network_name: the identifer of the network to destroy.
        """
        ticket = self.get_ticket_from_network_name(network_name)
        network_item = self.pubsub_nuage_networks.get_item(ticket)
        if not network_item:
            raise Exception("There is no Nuage network with name %s" % network_name)

        def retract_success(resp, user_info):
            if resp.getType() == "result":
                self.entity.push_change("nuagenetwork", "deleted")
                self.entity.log.info("NUAGENETWORKS: successfully deleted %s" % str(network_name))
            else:
                self.entity.push_change("nuagenetwork", "cannot-delete", content_node=resp)
                self.entity.log.error("NUAGENETWORKS: cannot delete Network %s: %s" % (network_name, str(resp)))
        self.pubsub_nuage_networks.remove_item(ticket, callback=retract_success)

    def create(self, definition, creator_jid):
        """
        define the network
        @type definition: string
        @param definition: the XML definition to use
        """
        network_name = definition.getAttr("name");

        if self.is_network_already_existing(network_name):
            raise Exception("Network with Name %s already exists" % network_name)

        def publish_success(resp):
            if resp.getType() == "result":
                self.entity.push_change("nuagenetwork", "created")
                self.entity.log.info("NUAGENETWORKS: Network %s successfuly created" % str(network_name))
            else:
                self.entity.push_change("nuagenetwork", "cannot-create", content_node=resp)
                self.entity.log.error("NUAGENETWORKS: cannot create network %s: %s" % (network_name, str(resp)))

        networknode = xmpp.Node(tag="nuage", attrs={    "creator": creator_jid.getStripped(),
                                                        "date": datetime.datetime.now()})
        networknode.addChild(node=definition)
        self.pubsub_nuage_networks.add_item(networknode, callback=publish_success)
        self.entity.log.info("NUAGENETWORKS: Network %s creation in progress..." % network_name)

    def update(self, network_name, definition):
        """
        define the network
        @type network_name: String
        @param network_name: the name of the network
        @type definition: string
        @param definition: the XML definition to use
        """
        ticket = self.get_ticket_from_network_name(network_name)
        network_item = self.pubsub_nuage_networks.get_item(ticket)
        if not network_item:
            raise Exception("There is no Nuage network with name %s" % network_name)

        if not definition.getAttr("name") == network_item.getTag("nuage").getTag("nuage_network").getAttr("name"):
            raise Exception("You cannot change the name of an existing network.")

        network_item.getTag("nuage").delChild("nuage_network")
        network_item.getTag("nuage").addChild(node=definition)

        def publish_success(resp):
            if resp.getType() == "result":
                self.entity.push_change("nuagenetwork", "updated")
                self.pubsub_nuage_networks.remove_item(ticket)
                self.entity.log.info("NUAGENETWORKS: Nuage network %s as been updated" % network_name)
            else:
                self.inhibit_next_general_push = True
                self.entity.push_change("nuagenetwork", "cannot-update", content_node=resp)
                self.entity.log.error("NUAGENETWORKS: unable to update network %s: %s" % (network_name, resp))
        self.pubsub_nuage_networks.add_item(network_item.getTag("nuage"), callback=publish_success)



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
            reply = iq.buildReply("result")
            definition = iq.getTag("query").getTag("archipel").getTag("nuage_network")
            self.create(definition, iq.getFrom())
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
            reply = iq.buildReply("result")
            network_name = iq.getTag("query").getTag("archipel").getAttr("name")
            self.delete(network_name)
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
            reply = iq.buildReply("result")
            network_xml = iq.getTag("query").getTag("archipel").getTag("nuage_network")
            network_name = iq.getTag("query").getTag("archipel").getAttr("name")
            self.update(network_name, network_xml)
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
            reply = iq.buildReply("result")
            networks = self.get()
            nodes = []
            for network_info in networks:
                network_node = xmpp.Node("nuage", attrs=network_info["info"])
                network_node.addChild(node=network_info["network"])
                nodes.append(network_node)
            reply.setQueryPayload(nodes)
        except Exception as ex:
            reply = build_error_iq(self, ex, iq, ARCHIPEL_ERROR_CODE_NUAGE_NETWORKS_GET)
        return reply
