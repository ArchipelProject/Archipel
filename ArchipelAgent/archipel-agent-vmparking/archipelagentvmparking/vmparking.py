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
import random
import shutil
import sqlite3
import string
import xmpp

from archipel.archipelHypervisor import TNArchipelHypervisor
from archipel.archipelVirtualMachine import TNArchipelVirtualMachine
from archipelcore.archipelPlugin import TNArchipelPlugin
from archipelcore.utils import build_error_iq, build_error_message

ARCHIPEL_ERROR_CODE_VMPARK_LIST = -11001
ARCHIPEL_ERROR_CODE_VMPARK_PARK = -11002
ARCHIPEL_ERROR_CODE_VMPARK_UNPARK = -11003
ARCHIPEL_ERROR_CODE_VMPARK_DELETE = -11004
ARCHIPEL_ERROR_CODE_VMPARK_UPDATEXML = -11004
ARCHIPEL_ERROR_CODE_VMPARK_CREATE_PARKED = -11005

ARCHIPEL_NS_HYPERVISOR_VMPARKING = "archipel:hypervisor:vmparking"
ARCHIPEL_NS_VM_VMPARKING = "archipel:vm:vmparking"

ARCHIPEL_PARKING_STATUS_NOT_PARKED = 0
ARCHIPEL_PARKING_STATUS_PARKED = 1
ARCHIPEL_PARKING_STATUS_STATE_CHANGING = 2

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

        # creates permissions
        self.entity.permission_center.create_permission("vmparking_park", "Authorizes user to park a virtual machines", False)

        if isinstance(self.entity, TNArchipelHypervisor):
            self.entity.permission_center.create_permission("vmparking_list", "Authorizes user to list virtual machines in parking", False)
            self.entity.permission_center.create_permission("vmparking_unpark", "Authorizes user to unpark a virtual machines", False)
            self.entity.permission_center.create_permission("vmparking_delete", "Authorizes user to delete parked virtual machines", False)
            self.entity.permission_center.create_permission("vmparking_updatexml", "Authorizes user to delete parked virtual machines", False)
            self.entity.permission_center.create_permission("vmparking_create_parked", "Authorizes user to create a new VM in parking", False)

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

        # register to the node parking and create database if needed
        if isinstance(self.entity, TNArchipelHypervisor):
            self.manage_database()

        if self.entity.__class__.__name__ == "TNArchipelVirtualMachine":
            self.entity.register_hook("HOOK_VM_DEFINE", method=self.hook_vm_define)
            self.entity.register_hook("HOOK_VM_UNDEFINE", method=self.hook_vm_undefine)

    ### Hooks
    def hook_vm_define(self, origin=None, user_info=None, arguments=None):
        """
        Called when a VM definition occurs.
        This will insert the XML desc in the parking
        """
        hypervisor_parking_plugin = self.entity.hypervisor.get_plugin("vmparking")
        xmldesc = self.entity.xmldesc(mask_description=False)

        if not hypervisor_parking_plugin.is_vm_registered(self.entity.uuid):
            vms_info = [{"uuid": self.entity.uuid, "domain": xmldesc, "parker": "nobody", "status": ARCHIPEL_PARKING_STATUS_NOT_PARKED, "date": datetime.datetime.now()}]
            hypervisor_parking_plugin.register_vms_into_db(vms_info)
        else:
            hypervisor_parking_plugin.update_vm_domain_in_db(self.entity.uuid, xmldesc)

    def hook_vm_undefine(self, origin=None, user_info=None, arguments=None):
        """
        Called when a VM definition occurs.
        This will insert the XML desc in the parking
        """
        hypervisor_parking_plugin = self.entity.hypervisor.get_plugin("vmparking")

        if hypervisor_parking_plugin.is_vm_registered(self.entity.uuid):
            if not hypervisor_parking_plugin.is_vm_parked(self.entity.uuid):
                hypervisor_parking_plugin.unregister_vms_from_db([{"uuid": self.entity.uuid}])

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


    ### Database Management

    def manage_database(self):
        """
        Create and / or recover the parking database
        """
        self.database = sqlite3.connect(self.configuration.get("VMPARKING", "database"), check_same_thread=False)
        self.database.row_factory = sqlite3.Row
        self.database.execute("create table if not exists parking (uuid text unique, parker string, creation_date date, domain string, status int)")
        self.database.commit()

    def register_vms_into_db(self, vm_informations):
        """
        Add a VM in the parking
        @type vm_informations: list
        @param vm_informations: list of dict containing {"uuid": x, "parker": y, "creation_date": z, "status": s}
        """
        self.database.executemany("insert into parking values(:uuid, :parker, :creation_date, :domain, :status)",  vm_informations)
        self.database.commit()

    def unregister_vms_from_db(self, vms_uuid):
        """
        Add a VM in the parking
        @type vm_informations: list
        @param vm_informations: list of dict containing {"uuid": x}
        """
        self.database.executemany("delete from parking where uuid=:uuid", vms_uuid)
        self.database.commit()

    def is_vm_registered(self, uuid):
        """
        Check if vm with given UUID is already in DB
        @type uuid: String
        @param uuid: the UUID of the vm
        @rtype: Boolean
        @return: True is vm is already in park
        """
        rows = self.database.execute("select uuid from parking where uuid=?", (uuid,))
        n = rows.fetchone()
        if n and n[0] > 1:
            return True
        return False

    def is_vm_parked(self, uuid):
        """
        Check if vm with given UUID is already parked
        @type uuid: String
        @param uuid: the UUID of the vm
        @rtype: Boolean
        @return: True is vm is already in park
        """
        rows = self.database.execute("select uuid from parking where uuid=? and status=?", (uuid, ARCHIPEL_PARKING_STATUS_PARKED))
        n = rows.fetchone()
        if n and n[0] > 1:
            return True
        return False

    def get_vm_by_uuid_from_db(self, uuid):
        """
        Get a VM from the parking
        @type uuid: String
        @param uuid: The UUID of the VM
        @rtype: dict
        @return: dict like {"uuid": x, "parker": y, "date": z, "status": s, "domain": d}
        """
        rows = self.database.execute("select * from parking where uuid=?", (uuid,))
        if not rows:
            return None
        row = rows.fetchone()
        return {"uuid": row[0], "parker": row[1], "date": row[2], "status": row[4], "domain": xmpp.simplexml.NodeBuilder(data=row[3]).getDom()}

    def get_all_vms_from_db(self):
        """
        Return all vms in parkings
        @rtype: list
        @return: list containing dict like {"uuid": x, "parker": y, "date": z, "status": s, "domain": d}
        """
        rows = self.database.execute("select * from parking where status=?", (ARCHIPEL_PARKING_STATUS_PARKED,))
        ret = []
        for row in rows:
            ret.append({"uuid": row[0], "parker": row[1], "date": row[2], "status": row[4], "domain": xmpp.simplexml.NodeBuilder(data=row[3]).getDom()})
        return ret

    def update_vm_domain_in_db(self, uuid, new_domain):
        """
        Update the domain of a parked virtual machine
        @type uuid: string
        @param uuid: the UUID of the parked VM to update
        """
        self.database.execute("update parking set domain=? where uuid=?", (str(new_domain).replace('xmlns=\"archipel:hypervisor:vmparking\"', ''), uuid))
        self.database.commit()

    def set_vms_status(self, vm_informations):
        """
        Set the status of the parking
        @type vm_informations: list
        @param vm_informations: list of dict containing {"uuid": x, "parker": y, "status": z}
        """
        self.database.executemany("update parking set status=:status, parker=:parker where uuid=:uuid", vm_informations)
        self.database.commit()


    ### Plugin information

    @staticmethod
    def plugin_info():
        """
        Return informations about the plugin.
        @rtype: dict
        @return: dictionary contaning plugin informations
        """
        plugin_friendly_name = "Virtual Machine Parking"
        plugin_identifier = "vmparking"
        plugin_configuration_section = "VMPARKING"
        plugin_configuration_tokens = ["database"]
        return {"common-name": plugin_friendly_name,
                "identifier": plugin_identifier,
                "configuration-section": plugin_configuration_section,
                "configuration-tokens": plugin_configuration_tokens}


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
        vms = self.get_all_vms_from_db()
        ret = []
        for vm in vms:
            ret.append({"info": {"uuid": vm["uuid"], "parker": vm["parker"], "date": vm["date"]}, "domain": vm["domain"]})

        def sorting(a, b):
            return cmp(a["domain"].getTag("name").getData(), b["domain"].getTag("name").getData())

        ret.sort(sorting)
        return ret

    def park(self, vm_informations):
        """
        Park a virtual machine
        @type vm_informations: list
        @param vm_informations: list of dict like {"uuid": x, "status": y, "parker": z)}
        """
        vm_informations_cleaned = []
        for vm_info in vm_informations:
            if self.is_vm_parked(vm_info["uuid"]):
                self.entity.log.error("VMPARKING: VM with UUID %s is already parked" % vm_info["uuid"])
                continue

            vm = self.entity.get_vm_by_uuid(vm_info["uuid"])
            if not vm:
                self.entity.log.error("VMPARKING: No virtual machine with UUID %s" % vm_info["uuid"])
                continue
            if not vm.domain:
                self.entity.log.error("VMPARKING: VM with UUID %s cannot be parked because it is not defined" % vm_info["uuid"])
                continue
            vm_informations_cleaned.append(vm_info)

        # Now, perform operations
        for vm_info in vm_informations_cleaned:
            vm = self.entity.get_vm_by_uuid(vm_info["uuid"])
            if not vm.info()["state"] == 5:
                vm.destroy()
            domain = vm.xmldesc(mask_description=False)
            vm_jid = xmpp.JID(domain.getTag("description").getData().split("::::")[0])
            self.set_vms_status([vm_info])
            self.entity.soft_free(vm_jid)
        self.entity.push_change("vmparking", "parked")

    def unpark(self, vm_informations):
        """
        Unpark virtual machine
        @type vm_informations: list
        @param vm_informations: list of dict like {"uuid": x, "status": y, "start": True|False, "parker": z}
        """
        vm_informations_cleaned = []
        # First, check if everything is correct and cleanup bad items
        for vm_info in vm_informations:
            if self.is_vm_parked(vm_info["uuid"]):
                vm_informations_cleaned.append(vm_info)
            else:
                self.entity.log.error("VMPARKING: There is no virtual machine parked with uuid %s" % vm_info["uuid"])

        # Now, perform operations
        for vm_info in vm_informations_cleaned:
            vm_item = self.get_vm_by_uuid_from_db(vm_info["uuid"])
            domain = vm_item["domain"]
            ret = str(domain).replace('xmlns=\"archipel:hypervisor:vmparking\"', '')
            domain = xmpp.simplexml.NodeBuilder(data=ret).getDom()
            vmjid = domain.getTag("description").getData().split("::::")[0]
            vmpass = domain.getTag("description").getData().split("::::")[1]
            vmname = domain.getTag("name").getData()
            vm_thread = self.entity.soft_alloc(xmpp.JID(vmjid), vmname, vmpass, start=False, organizationInfo=self.entity.vcard_infos)
            vm = vm_thread.get_instance()
            vm.register_hook("HOOK_ARCHIPELENTITY_XMPP_AUTHENTICATED", method=vm.define_hook, user_info=domain, oneshot=True)
            if vm_info["start"]:
                vm.register_hook("HOOK_ARCHIPELENTITY_XMPP_AUTHENTICATED", method=vm.control_create_hook, oneshot=True)
            vm_thread.start()
            self.set_vms_status([vm_info])

        self.entity.push_change("vmparking", "unparked")
        self.entity.log.info("VMPARKING: successfully unparked %s" % str(vmjid))

    def delete(self, vm_uuids):
        """
        Delete a parked virtual machine
        @type vm_uuids: list
        @param uuid: list of dic like {"uuid": x}
        """
        vm_jids = []
        # first, check there is no problems
        for vm_uuid in vm_uuids:
            if not self.is_vm_parked(vm_uuid["uuid"]):
                raise Exception("There is no virtual machine parked with uuid %s" % vm_uuid["uuid"])
            vm_item = self.get_vm_by_uuid_from_db(vm_uuid["uuid"])
            vm_jids.append(xmpp.JID(vm_item["domain"].getTag("description").getData().split("::::")[0]))

        # Update DB and Push
        self.unregister_vms_from_db(vm_uuids)
        self.entity.push_change("vmparking", "deleted")

        # Then perfom cleanup operations
        for vm_jid in vm_jids:
            vmfolder = "%s/%s" % (self.configuration.get("VIRTUALMACHINE", "vm_base_path"), vm_jid.getNode())
            if os.path.exists(vmfolder):
                shutil.rmtree(vmfolder)

        # And remove the XMPP account
        self.entity.get_plugin("xmppserver").users_unregister(vm_jids)
        self.entity.log.info("VMPARKING: successfully deleted %s from parking" % str(vm_jids))

    def updatexml(self, uuid, domain):
        """
        Update the domain XML of a parked VM
        @type uuid: String
        @param uuid: the VM UUID
        @type domain: xmpp.Node
        @param domain: the new XML description
        """
        if not self.is_vm_parked(uuid):
            raise Exception("There is no virtual machine parked with uuid %s" % uuid)

        vm_item = self.get_vm_by_uuid_from_db(uuid)

        old_domain = vm_item["domain"]
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
        self.update_vm_domain_in_db(uuid, domain)
        self.entity.push_change("vmparking", "updated")

    def create_parked(self, vm_informations):
        """
        Creates a VM directly into the parking.
        @type vm_informations: list
        @param vm_informations: list containing VM to park [{"uuid": x, domain: y, parker: x, creation_date: d, status: s}]
        """
        for vm_info in vm_informations:
            if self.is_vm_parked(vm_info["uuid"]):
                raise Exception("VM with UUID %s is already parked" % vm_info["uuid"])

            vm = self.entity.get_vm_by_uuid(vm_info["uuid"])
            if vm:
                raise Exception("There is already a VM with UUID %s" % vm_info["uuid"])

            if vm_info["domain"].getTag("description"):
                raise Exception("You cannot park a VM XML with a <description/> tag. Please remove it")

            password = ''.join([random.choice(string.letters + string.digits) for i in range(32)])
            vm_info["domain"].addChild("description").setData("%s@%s::::%s" % (vm_info["uuid"], self.entity.jid.getDomain(), password))
            vm_info["domain"] = str(vm_info["domain"]).replace('xmlns=\"archipel:hypervisor:vmparking\"', '')

        self.register_vms_into_db(vm_informations)

        self.entity.push_change("vmparking", "parked")


    ### XMPP Management for hypervisors

    def process_iq_for_hypervisor(self, conn, iq):
        """
        This method is invoked when a ARCHIPEL_NS_HYPERVISOR_VMPARKING IQ is received.
        It understands IQ of type:
            - list
            - park
            - create_parked
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
        if action == "create_parked":
            reply = self.iq_create_parked(iq)
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
            vms_info = []
            for item in items:
                vm_uuid = item.getAttr("uuid")
                if not vm_uuid:
                    self.entity.log.error("VMPARKING: Unable to park vm: missing 'uuid' element.")
                    raise Exception("You must must set the UUID of the vms you want to park")

                vms_info.append({"uuid": vm_uuid, "status": ARCHIPEL_PARKING_STATUS_PARKED, "parker": str(iq.getFrom())})

            self.park(vms_info)

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
            vms_info = []
            for vmuuid in uuids:
                vms_info.append({"uuid": vmuuid, "status": ARCHIPEL_PARKING_STATUS_PARKED, "parker": str(msg.getFrom())})

            self.park(vms_info)

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
            vms_info = []
            for item in items:
                identifier = item.getAttr("identifier")
                autostart = False
                if item.getAttr("start") and item.getAttr("start").lower() in ("yes", "y", "true", "1"):
                    autostart = True
                vms_info.append({"uuid": identifier, "status": ARCHIPEL_PARKING_STATUS_NOT_PARKED, "start": autostart, "parker": str(iq.getFrom())})

            self.unpark(vms_info)

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
            vms_info = []
            for itemid in itemids:
                vms_info.append({"uuid": itemid, "start": False, "status": ARCHIPEL_PARKING_STATUS_NOT_PARKED, "parker": str(msg.getFrom())})

            self.unpark(vms_info)

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
            vm_uuids = []

            for item in items:
                vm_uuids.append({"uuid": item.getAttr("identifier")})

            self.delete(vm_uuids)

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

    def iq_create_parked(self, iq):
        """
        Create a VM in directly into the parking
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ
        @rtype: xmpp.Protocol.Iq
        @return: a ready to send IQ containing the result of the action
        """
        try:
            items = iq.getTag("query").getTag("archipel").getTags("item")
            vms_info = []
            for item in items:
                vm_uuid = item.getAttr("uuid")
                if not vm_uuid:
                    self.entity.log.error("VMPARKING: Unable to park vm: missing 'uuid' element.")
                    raise Exception("You must must set the UUID of the vms you want to park")
                vm_domain = item.getTag("domain")
                vms_info.append({"uuid": vm_uuid, "domain": vm_domain, "parker": str(iq.getFrom()), "creation_date": datetime.datetime.now(), "status": ARCHIPEL_PARKING_STATUS_PARKED})

            self.create_parked(vms_info)

            reply = iq.buildReply("result")
        except Exception as ex:
            reply = build_error_iq(self, ex, iq, ARCHIPEL_ERROR_CODE_VMPARK_CREATE_PARKED)
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
            vms_info = [{"uuid": self.entity.uuid, "status": ARCHIPEL_PARKING_STATUS_PARKED, "parker": str(iq.getFrom())}]
            self.entity.hypervisor.get_plugin("vmparking").park(vms_info)
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
            vms_info = [{"uuid": self.entity.uuid, "status": ARCHIPEL_PARKING_STATUS_PARKED, "parker": str(msg.getFrom())}]
            self.entity.hypervisor.get_plugin("vmparking").park(vms_info)
            return "I'm parking."
        except Exception as ex:
            return build_error_message(self, ex, msg)
