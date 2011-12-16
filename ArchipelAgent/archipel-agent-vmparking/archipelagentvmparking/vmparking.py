# -*- coding: utf-8 -*-
#
# vmparking.py
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

import datetime
import os
import shutil
import xmpp

from archipel.archipelHypervisor import TNArchipelHypervisor
from archipel.archipelVirtualMachine import TNArchipelVirtualMachine
from archipelcore.archipelPlugin import TNArchipelPlugin
from archipelcore.pubsub import TNPubSubNode
from archipelcore.utils import build_error_iq, build_error_message

ARCHIPEL_ERROR_CODE_VMPARK_LIST         = -11001
ARCHIPEL_ERROR_CODE_VMPARK_PARK         = -11002
ARCHIPEL_ERROR_CODE_VMPARK_UNPARK       = -11003
ARCHIPEL_ERROR_CODE_VMPARK_DELETE       = -11004
ARCHIPEL_ERROR_CODE_VMPARK_UPDATEXML    = -11004

ARCHIPEL_NS_HYPERVISOR_VMPARKING = "archipel:hypervisor:vmparking"
ARCHIPEL_NS_VM_VMPARKING         = "archipel:vm:vmparking"

class TNVMParking (TNArchipelPlugin):

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
        self.pubsub_vmparking = None;
        self.inhibit_next_general_push = None

        # creates permissions
        self.entity.permission_center.create_permission("vmparking_park", "Authorizes user to park a virtual machines", False)

        if isinstance(self.entity, TNArchipelHypervisor):
            self.entity.permission_center.create_permission("vmparking_list", "Authorizes user to list virtual machines in parking", False)
            self.entity.permission_center.create_permission("vmparking_unpark", "Authorizes user to unpark a virtual machines", False)
            self.entity.permission_center.create_permission("vmparking_delete", "Authorizes user to delete parked virtual machines", False)
            self.entity.permission_center.create_permission("vmparking_updatexml", "Authorizes user to delete parked virtual machines", False)

        # vocabulary
        if isinstance(self.entity, TNArchipelHypervisor):
            registrar_items = [{    "commands" : ["park"],
                                    "parameters": [{"name": "identifiers", "description": "the UUIDs of the VM to park, separated with comas, with no space"}],
                                    "method": self.message_park_hypervisor,
                                    "permissions": ["vmparking_park"],
                                    "description": "Park the virtual machine with the given UUIDs"},

                                {   "commands" : ["unpark"],
                                    "parameters": [{"name": "identifiers", "description": "UUIDs of the virtual machines or parking tickets, separated by comas, with no space"}],
                                    "method": self.message_unpark,
                                    "permissions": ["vmparking_unpark"],
                                    "description": "Unpark the virtual machine parked with the given identifier"},

                                {    "commands" : ["park list"],
                                     "parameters": [],
                                     "method": self.message_list,
                                     "permissions": ["vmparking_list"],
                                     "description": "List all parked virtual machines" }
                                ]
        elif isinstance(self.entity, TNArchipelVirtualMachine):
            registrar_items = [{    "commands" : ["park"],
                                    "parameters": [],
                                    "method": self.message_park_vm,
                                    "permissions": ["vmparking_park"],
                                    "description": "Park the virtual machine"},
                                ]

        self.entity.add_message_registrar_items(registrar_items)

        # register to the node vmrequest
        if isinstance(self.entity, TNArchipelHypervisor):
            self.entity.register_hook("HOOK_ARCHIPELENTITY_XMPP_AUTHENTICATED", method=self.manage_vmparking_node)


    ### Plugin interface

    def register_handlers(self):
        """
        This method will be called by the plugin user when it will be
        necessary to register module for listening to stanza.
        """
        if isinstance(self.entity, TNArchipelHypervisor):
            self.entity.xmppclient.RegisterHandler('iq', self.process_iq_for_hypervisor, ns=ARCHIPEL_NS_HYPERVISOR_VMPARKING)
        elif isinstance(self.entity, TNArchipelVirtualMachine):
            self.entity.xmppclient.RegisterHandler('iq', self.process_iq_for_vm, ns=ARCHIPEL_NS_VM_VMPARKING)

    def unregister_handlers(self):
        """
        Unregister the handlers.
        """
        if isinstance(self.entity, TNArchipelHypervisor):
            self.entity.xmppclient.UnregisterHandler('iq', self.process_iq_for_hypervisor, ns=ARCHIPEL_NS_HYPERVISOR_VMPARKING)
        elif isinstance(self.entity, TNArchipelVirtualMachine):
            self.entity.xmppclient.UnregisterHandler('iq', self.process_iq_for_vm, ns=ARCHIPEL_NS_VM_VMPARKING)


    @staticmethod
    def plugin_info():
        """
        Return informations about the plugin.
        @rtype: dict
        @return: dictionary contaning plugin informations
        """
        plugin_friendly_name           = "Virtual Machine Parking"
        plugin_identifier              = "vmparking"
        plugin_configuration_section   = None
        plugin_configuration_tokens    = []
        return {    "common-name"               : plugin_friendly_name,
                    "identifier"                : plugin_identifier,
                    "configuration-section"     : plugin_configuration_section,
                    "configuration-tokens"      : plugin_configuration_tokens }



    ### Pubsub management

    def manage_vmparking_node(self, origin, user_info, arguments):
        """
        Register to pubsub event node /archipel/platform/requests/in
        and /archipel/platform/requests/out
        @type origin: L{TNArchipelEnity}
        @param origin: the origin of the hook
        @type user_info: object
        @param user_info: random user information
        @type arguments: object
        @param arguments: runtime argument
        """
        nodeVMParkingName = "/archipel/vmparking"
        self.entity.log.info("VMPARKING: getting the pubsub node %s" % nodeVMParkingName)
        self.pubsub_vmparking = TNPubSubNode(self.entity.xmppclient, self.entity.pubsubserver, nodeVMParkingName)
        self.pubsub_vmparking.recover(wait=True)
        self.entity.log.info("VMPARKING: node %s recovered." % nodeVMParkingName)
        self.pubsub_vmparking.subscribe(self.entity.jid, self._handle_request_event, wait=True)
        self.entity.log.info("VMPARKING: entity %s is now subscribed to events from node %s" % (self.entity.jid, nodeVMParkingName))

    def _handle_request_event(self, event):
        """
        Triggered when a platform wide virtual machine request is received.
        @type event: xmpp.Node
        @param event: the push event
        """
        self.entity.log.debug("VMPARKING: received pubsub event")
        if not self.inhibit_next_general_push:
            self.entity.push_change("vmparking", "external-update")
        self.inhibit_next_general_push = False



    ### Utilities

    def get_ticket_from_uuid(self, uuid):
        """
        parse the parked vm to find the ticket of the given uuid
        @type uuid: String
        @param uuid: the UUID of the vm
        @rtype: String
        @return: pubsub item id
        """
        items = self.pubsub_vmparking.get_items()
        for item in items:
            domain = item.getTag("virtualmachine").getTag("domain")
            if domain.getTag("uuid").getData() == uuid:
                return item.getAttr("id")
        return None

    def is_vm_already_parked(self, uuid):
        """
        Check if vm with given UUID is already parked
        @type uuid: String
        @param uuid: the UUID of the vm
        @rtype: Boolean
        @return: True is vm is already in park
        """
        if self.get_ticket_from_uuid(uuid):
            return True
        return False


    ### Processing function

    def list(self):
        """
        List virtual machines in the park. It returns a dict with the following form:
        [{"info": { "itemid": <PUBSUB-TICKET>,
                    "parker": <JID-OF-PARKER>,
                    "date": <DATE-OF-LAST-UPDATE>},
          "domain": <XML-DOMAIN-NODE>},
          ...
        ]
        @rtype: Array
        @return: listinformations about virtual machines.
        """
        nodes = self.pubsub_vmparking.get_items()
        ret = []
        for node in nodes:
            domain = xmpp.Node(node=node.getTag("virtualmachine").getTag("domain"))
            ret.append({"info":
                            {"itemid": node.getAttr("id"),
                            "parker": node.getTag("virtualmachine").getAttr("parker"),
                            "date": node.getTag("virtualmachine").getAttr("date")},
                        "domain": domain})
        def sorting(a, b):
            return cmp(a["domain"].getTag("name").getData(), b["domain"].getTag("name").getData())
        ret.sort(sorting)
        return ret

    def park(self, uuid, parker_jid, force=False):
        """
        Park a virtual machine
        @type uuid: String
        @param uuid: the UUID of the virtual machine to park
        @type force: Boolean
        @param force: if True, the machine will be destroyed if running
        """
        if self.is_vm_already_parked(uuid):
            raise Exception("VM with UUID %s is already parked" % uuid)

        vm = self.entity.get_vm_by_uuid(uuid)
        if not vm:
            raise Exception("No virtual machine with UUID %s" % uuid)
        if not vm.domain:
            raise Exception("VM with UUID %s cannot be parked because it is not defined" % uuid)
        if not vm.info()["state"] == 5:
            if not force:
                raise Exception("VM with UUID %s cannot be parked because it is running" % uuid)
            else:
                vm.destroy()

        domain = vm.xmldesc(mask_description=False)
        vm_jid = xmpp.JID(domain.getTag("description").getData().split("::::")[0])

        def publish_success(resp):
            if resp.getType() == "result":
                self.entity.soft_free(vm_jid)
                self.inhibit_next_general_push = True
                self.entity.push_change("vmparking", "parked")
                self.entity.log.info("VMPARKING: successfully parked %s" % str(vm_jid))
            else:
                self.inhibit_next_general_push = True
                self.entity.push_change("vmparking", "cannot-park", content_node=resp)
                self.entity.log.error("VMPARKING: cannot park: %s" % str(resp))

        vmparkednode = xmpp.Node(tag="virtualmachine", attrs={  "parker": parker_jid.getStripped(),
                                                                "date": datetime.datetime.now(),
                                                                "origin": self.entity.jid.getStripped().lower()})
        vmparkednode.addChild(node=domain)
        self.pubsub_vmparking.add_item(vmparkednode, callback=publish_success)
        self.entity.log.info("VMPARKING: virtual machine %s as been parked" % uuid)

    def unpark(self, identifier, start=False):
        """
        Unpark virtual machine
        @type identifier: String
        @param identifier: the UUID of a VM or the pubsub ID (parking ticket)
        @type start: Boolean
        @param start: if True, the virtual machine will start after unparking
        """
        ticket = self.get_ticket_from_uuid(identifier)
        if not ticket:
            ticket = identifier
        vm_item = self.pubsub_vmparking.get_item(ticket)
        if not vm_item:
            raise Exception("There is no virtual machine parked with ticket %s" % ticket)

        def retract_success(resp, user_info):
            if resp.getType() == "result":
                domain = vm_item.getTag("virtualmachine").getTag("domain")
                ret = str(domain).replace('xmlns=\"archipel:hypervisor:vmparking\"', '')
                domain = xmpp.simplexml.NodeBuilder(data=ret).getDom()
                vmjid = domain.getTag("description").getData().split("::::")[0]
                vmpass = domain.getTag("description").getData().split("::::")[1]
                vmname = domain.getTag("name").getData()
                vm_thread = self.entity.soft_alloc(xmpp.JID(vmjid), vmname, vmpass, start=False)
                vm = vm_thread.get_instance()
                vm.register_hook("HOOK_ARCHIPELENTITY_XMPP_AUTHENTICATED", method=vm.define_hook, user_info=domain, oneshot=True)
                if start:
                    vm.register_hook("HOOK_ARCHIPELENTITY_XMPP_AUTHENTICATED", method=vm.control_create_hook, oneshot=True)
                vm_thread.start()
                self.inhibit_next_general_push = True
                self.entity.push_change("vmparking", "unparked")
                self.entity.log.info("VMPARKING: successfully unparked %s" % str(vmjid))
            else:
                self.inhibit_next_general_push = True
                self.entity.push_change("vmparking", "cannot-unpark", content_node=resp)
                self.entity.log.error("VMPARKING: cannot unpark: %s" % str(resp))
        self.pubsub_vmparking.remove_item(ticket, callback=retract_success)

    def delete(self, identifier):
        """
        Delete a parked virtual machine
        @type identifier: String
        @param identifier: the UUID of a parked VM or the pubsub ID (parking ticket)
        """
        ticket = self.get_ticket_from_uuid(identifier)
        if not ticket:
            ticket = identifier
        vm_item = self.pubsub_vmparking.get_item(ticket)
        if not vm_item:
            raise Exception("There is no virtual machine parked with ticket %s" % ticket)

        def retract_success(resp, user_info):
            if resp.getType() == "result":
                vmjid = xmpp.JID(vm_item.getTag("virtualmachine").getTag("domain").getTag("description").getData().split("::::")[0])
                vmfolder = "%s/%s" % (self.configuration.get("VIRTUALMACHINE", "vm_base_path"), vmjid.getNode())
                if os.path.exists(vmfolder):
                    shutil.rmtree(vmfolder)
                self.entity.get_plugin("xmppserver").users_unregister([vmjid])
                self.inhibit_next_general_push = True
                self.entity.push_change("vmparking", "deleted")
                self.entity.log.info("VMPARKING: successfully deleted %s from parking" % str(vmjid))
            else:
                self.inhibit_next_general_push = True
                self.entity.push_change("vmparking", "cannot-delete", content_node=resp)
                self.entity.log.error("VMPARKING: cannot delete: %s" % str(resp))
        self.pubsub_vmparking.remove_item(ticket, callback=retract_success)

    def updatexml(self, identifier, domain):
        """
        Update the domain XML of a parked VM
        @type identifier: String
        @param identifier: the pubsub ID (parking ticket) or the VM UUID
        @type domain: xmpp.Node
        @param domain: the new XML description
        """
        ticket = self.get_ticket_from_uuid(identifier)
        if not ticket:
            ticket = identifier
        vm_item = self.pubsub_vmparking.get_item(ticket)
        if not vm_item:
            raise Exception("There is no virtual machine parked with ticket %s" % ticket)

        old_domain = vm_item.getTag("virtualmachine").getTag("domain")
        previous_uuid = old_domain.getTag("uuid").getData()
        previous_name = old_domain.getTag("name").getData()
        new_uuid = domain.getTag("uuid").getData()
        new_name = domain.getTag("name").getData()

        if not previous_uuid.lower() == new_uuid.lower():
            raise Exception("UUID of new description must be the same (was %s, is %s)" % (previous_uuid, new_uuid))
        if not previous_name.lower() == new_name.lower():
            raise Exception("Name of new description must be the same (was %s, is %s)" % (previous_name, new_name))
        if not new_name or new_name == "":
            raise Exception("Missing name information")
        if not new_uuid or new_uuid == "":
            raise Exception("Missing UUID information")

        if domain.getTag('description'):
            domain.delChild("description")
        domain.addChild(node=old_domain.getTag("description"))
        vm_item.getTag("virtualmachine").delChild("domain")
        vm_item.getTag("virtualmachine").addChild(node=domain)

        def publish_success(resp):
            if resp.getType() == "result":
                self.inhibit_next_general_push = True
                self.entity.push_change("vmparking", "updated")
                self.pubsub_vmparking.remove_item(ticket)
                self.entity.log.info("VMPARKING: virtual machine %s as been updated" % new_uuid)
            else:
                self.inhibit_next_general_push = True
                self.entity.push_change("vmparking", "cannot-update", content_node=resp)
                self.entity.log.error("VMPARKING: unable to update item for virtual machine %s: %s" % (new_uuid, resp))
        self.pubsub_vmparking.add_item(vm_item.getTag("virtualmachine"), callback=publish_success)



    ### XMPP Management for hypervisors

    def process_iq_for_hypervisor(self, conn, iq):
        """
        This method is invoked when a ARCHIPEL_NS_HYPERVISOR_VMPARKING IQ is received.
        It understands IQ of type:
            - list
            - park
            - unpark
            - destroy
            - updatexml
        @type conn: xmpp.Dispatcher
        @param conn: ths instance of the current connection that send the stanza
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ
        """
        reply = None
        action = self.entity.check_acp(conn, iq)
        self.entity.check_perm(conn, iq, action, -1, prefix="vmparking_")
        if action == "list":
            reply = self.iq_list(iq)
        if action == "park":
            reply = self.iq_park(iq)
        if action == "unpark":
            reply = self.iq_unpark(iq)
        if action == "delete":
            reply = self.iq_delete(iq)
        if action == "updatexml":
            reply = self.iq_updatexml(iq)
        if reply:
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed

    def iq_list(self, iq):
        """
        Return the list of parked virtual machines
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ
        @rtype: xmpp.Protocol.Iq
        @return: a ready to send IQ containing the result of the action
        """
        try:
            reply = iq.buildReply("result")
            parked_vms = self.list()
            nodes = []
            for parked_vm in parked_vms:
                vm_node = xmpp.Node("virtualmachine", attrs=parked_vm["info"])
                if parked_vm["domain"].getTag('description'):
                    parked_vm["domain"].delChild("description")
                vm_node.addChild(node=parked_vm["domain"])
                nodes.append(vm_node)
            reply.setQueryPayload(nodes)
        except Exception as ex:
            reply = build_error_iq(self, ex, iq, ARCHIPEL_ERROR_CODE_VMPARK_LIST)
        return reply

    def message_list(self, msg):
        """
        Handle the parking list message.
        @type msg: xmmp.Protocol.Message
        @param msg: the message
        @rtype: string
        @return: the answer
        """
        try:
            tokens = msg.getBody().split()
            if not len(tokens) == 2:
                return "I'm sorry, you use a wrong format. You can type 'help' to get help."
            parked_vms = self.list()
            resp = "Sure! Here is the virtual machines parked:\n"
            for info in parked_vms:
                ticket = info["info"]["itemid"]
                name = info["domain"].getTag("name").getData()
                uuid = info["domain"].getTag("uuid").getData()
                resp = "%s - [%s]: %s (%s)\n" % (resp, ticket, name, uuid)
            return resp
        except Exception as ex:
            return build_error_message(self, ex, msg)

    def iq_park(self, iq):
        """
        Park virtual machine
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ
        @rtype: xmpp.Protocol.Iq
        @return: a ready to send IQ containing the result of the action
        """
        try:
            items = iq.getTag("query").getTag("archipel").getTags("item")
            for item in items:
                vm_uuid = item.getAttr("uuid")
                if not vm_uuid:
                    self.entity.log.error("VMPARKING: Unable to park vm: missing 'uuid' element.")
                    raise Exception("You must must set the UUID of the vms you want to park")
                force_destroy = False
                if item.getAttr("force") and item.getAttr("force").lower() in ("yes", "y", "true", "1"):
                    force_destroy = True
                self.park(vm_uuid, iq.getFrom(), force=force_destroy)
            reply = iq.buildReply("result")
        except Exception as ex:
            reply = build_error_iq(self, ex, iq, ARCHIPEL_ERROR_CODE_VMPARK_PARK)
        return reply

    def message_park_hypervisor(self, msg):
        """
        Handle the park message.
        @type msg: xmmp.Protocol.Message
        @param msg: the message
        @rtype: string
        @return: the answer
        """
        try:
            tokens = msg.getBody().split()
            if len(tokens) < 2:
                return "I'm sorry, you use a wrong format. You can type 'help' to get help."
            uuids = tokens[1].split(",")
            for vmuuid in uuids:
                self.park(vmuuid, msg.getFrom())
            if len(uuids) == 1:
                return "Virtual machine is parking."
            else:
                return "Virtual machines are parking."
        except Exception as ex:
            return build_error_message(self, ex, msg)

    def iq_unpark(self, iq):
        """
        Unpark virtual machine
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ
        @rtype: xmpp.Protocol.Iq
        @return: a ready to send IQ containing the result of the action
        """
        try:
            reply = iq.buildReply("result")
            items = iq.getTag("query").getTag("archipel").getTags("item")
            for item in items:
                identifier = item.getAttr("identifier")
                autostart = False
                if item.getAttr("start") and item.getAttr("start").lower() in ("yes", "y", "true", "1"):
                    autostart = True
                self.unpark(identifier, start=autostart)
        except Exception as ex:
            reply = build_error_iq(self, ex, iq, ARCHIPEL_ERROR_CODE_VMPARK_UNPARK)
        return reply

    def message_unpark(self, msg):
        """
        Handle the unpark message.
        @type msg: xmmp.Protocol.Message
        @param msg: the message
        @rtype: string
        @return: the answer
        """
        try:
            tokens = msg.getBody().split()
            if len(tokens) < 2:
                return "I'm sorry, you use a wrong format. You can type 'help' to get help."
            itemids = tokens[1].split(",")
            for itemid in itemids:
                self.unpark(itemid)
            if len(itemids) == 1:
                return "Virtual machine is unparking."
            else:
                return "Virtual machines are unparking."
        except Exception as ex:
            return build_error_message(self, ex, msg)

    def iq_delete(self, iq):
        """
        Delete a parked virtual machine
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ
        @rtype: xmpp.Protocol.Iq
        @return: a ready to send IQ containing the result of the action
        """
        try:
            reply = iq.buildReply("result")
            items = iq.getTag("query").getTag("archipel").getTags("item")
            for item in items:
                identifier = item.getAttr("identifier")
                self.delete(identifier)
        except Exception as ex:
            reply = build_error_iq(self, ex, iq, ARCHIPEL_ERROR_CODE_VMPARK_DELETE)
        return reply

    def iq_updatexml(self, iq):
        """
        Update the XML description of a parked virtual machine
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ
        @rtype: xmpp.Protocol.Iq
        @return: a ready to send IQ containing the result of the action
        """
        try:
            reply = iq.buildReply("result")
            identifier = iq.getTag("query").getTag("archipel").getAttr("identifier")
            domain = iq.getTag("query").getTag("archipel").getTag("domain")
            self.updatexml(identifier, domain)
        except Exception as ex:
            reply = build_error_iq(self, ex, iq, ARCHIPEL_ERROR_CODE_VMPARK_UPDATEXML)
        return reply


    ## XMPP Management for hypervisors

    def process_iq_for_vm(self, conn, iq):
        """
        This method is invoked when a ARCHIPEL_NS_VM_VMPARKING IQ is received.
        It understands IQ of type:
            - park
        @type conn: xmpp.Dispatcher
        @param conn: ths instance of the current connection that send the stanza
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ
        """
        reply = None
        action = self.entity.check_acp(conn, iq)
        self.entity.check_perm(conn, iq, action, -1, prefix="vmparking_")
        if action == "park":
            reply = self.iq_park_vm(iq)
        if reply:
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed

    def iq_park_vm(self, iq):
        """
        ask own hypervisor to park the virtual machine
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ
        @rtype: xmpp.Protocol.Iq
        @return: a ready to send IQ containing the result of the action
        """
        try:
            reply = iq.buildReply("result")
            self.entity.hypervisor.get_plugin("vmparking").park(self.entity.uuid, iq.getFrom())
        except Exception as ex:
            reply = build_error_iq(self, ex, iq, ARCHIPEL_ERROR_CODE_VMPARK_PARK)
        return reply

    def message_park_vm(self, msg):
        """
        Handle the park message for vm.
        @type msg: xmmp.Protocol.Message
        @param msg: the message
        @rtype: string
        @return: the answer
        """
        try:
            tokens = msg.getBody().split()
            if not len(tokens) == 1:
                return "I'm sorry, you use a wrong format. You can type 'help' to get help."
            self.entity.hypervisor.get_plugin("vmparking").park(self.entity.uuid, msg.getFrom())
            return "I'm parking."
        except Exception as ex:
            return build_error_message(self, ex, msg)
