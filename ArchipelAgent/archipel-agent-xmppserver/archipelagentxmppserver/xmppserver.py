# -*- coding: utf-8 -*-
#
# xmppserver.py
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

import xmpp
import xmlrpclib

from archipel.archipelHypervisor import TNArchipelHypervisor
from archipel.archipelVirtualMachine import TNArchipelVirtualMachine
from archipelcore.archipelPlugin import TNArchipelPlugin
from archipelcore.utils import build_error_iq

ARCHIPEL_NS_XMPPSERVER          = "archipel:xmppserver"
ARCHIPEL_NS_XMPPSERVER_GROUPS   = "archipel:xmppserver:groups"
ARCHIPEL_NS_XMPPSERVER_USERS    = "archipel:xmppserver:users"

ARCHIPEL_ERROR_CODE_XMPPSERVER_MANAGEMENT           = -10000

ARCHIPEL_ERROR_CODE_XMPPSERVER_GROUP_ADDUSERS       = -20001
ARCHIPEL_ERROR_CODE_XMPPSERVER_GROUP_CREATE         = -20002
ARCHIPEL_ERROR_CODE_XMPPSERVER_GROUP_DELETE         = -20003
ARCHIPEL_ERROR_CODE_XMPPSERVER_GROUP_DELETEUSERS    = -20004
ARCHIPEL_ERROR_CODE_XMPPSERVER_GROUP_LIST           = -20005

ARCHIPEL_ERROR_CODE_XMPPSERVER_USERS_CHANGEPASSWORD = -30001
ARCHIPEL_ERROR_CODE_XMPPSERVER_USERS_FILTER         = -30002
ARCHIPEL_ERROR_CODE_XMPPSERVER_USERS_LIST           = -30003
ARCHIPEL_ERROR_CODE_XMPPSERVER_USERS_REGISTER       = -30004
ARCHIPEL_ERROR_CODE_XMPPSERVER_USERS_UNREGISTER     = -30005


class TNXMPPServerController (TNArchipelPlugin):

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

        self.users = []
        self.user_page_size = 50
        self.need_user_refresh = True
        self.entities_types_cache = {}
        self.users_management_capabilities  = {"xmpp": False, "xmlrpc": False}
        self.groups_management_capabilities = {"xmpp": False, "xmlrpc": False}

        if configuration.has_option("XMPPSERVER", "use_xmlrpc_api") and configuration.getboolean("XMPPSERVER", "use_xmlrpc_api"):
            self.xmpp_server        = entity.jid.getDomain()
            self.xmlrpc_host        = configuration.get("XMPPSERVER", "xmlrpc_host")
            self.xmlrpc_port        = configuration.getint("XMPPSERVER", "xmlrpc_port")
            self.xmlrpc_user        = configuration.get("HYPERVISOR", "hypervisor_xmpp_jid").split("@")[0]
            self.xmlrpc_password    = configuration.get("HYPERVISOR", "hypervisor_xmpp_password")
            self.xmlrpc_prefix      = "https" if configuration.getboolean("XMPPSERVER", "xmlrpc_sslonly") else "http"
            self.xmlrpc_call        = "%s://%s:%s/" % (self.xmlrpc_prefix, self.xmlrpc_host, self.xmlrpc_port)
            self.xmlrpc_auth        = {'user':self.xmlrpc_user, 'server': self.xmlrpc_host, 'password': self.xmlrpc_password}
            self.xmlrpc_server      = xmlrpclib.ServerProxy(self.xmlrpc_call)
            try:
                answer = self._send_xmlrpc_call("srg_list", {"host": self.xmlrpc_host})
                self.groups_management_capabilities["xmlrpc"] = True
                self.entity.log.info("XMPPSERVER: Module is using XMLRPC API for managing Shared Roster Groups")
                if configuration.has_option("XMPPSERVER", "auto_group") and configuration.getboolean("XMPPSERVER", "auto_group"):
                    self.autogroup_name_hypervisors = "All Hypervisors"
                    self.autogroup_name_vms = "All Virtual Machines"
                    self.autogroup_name_users = "All Users"
                    if configuration.has_option("XMPPSERVER", "auto_group_name_virtualmachines"):
                        self.autogroup_name_vms = configuration.get("XMPPSERVER", "auto_group_name_virtualmachines")
                    if configuration.has_option("XMPPSERVER", "auto_group_name_hypervisors"):
                        self.autogroup_name_hypervisors = configuration.get("XMPPSERVER", "auto_group_name_hypervisors")
                    if configuration.has_option("XMPPSERVER", "auto_group_name_users"):
                        self.autogroup_name_users = configuration.get("XMPPSERVER", "auto_group_name_users")

                    auto_group_filter = "all"
                    if configuration.has_option("XMPPSERVER", "auto_group_filter"):
                        auto_group_filter = configuration.get("XMPPSERVER", "auto_group_filter")
                        if not auto_group_filter in ("virtualmachines", "hypervisors", "all"):
                            raise Exception("Bad configuration", "auto_group_filter must be virtualmachines, hypervisors or all.")
                    self.autogroup_vms_id = self.autogroup_name_vms
                    self.autogroup_hypervisors_id = self.autogroup_name_hypervisors
                    self.autogroup_users_id = self.autogroup_name_users

                    self.entity.register_hook("HOOK_ARCHIPELENTITY_PLUGIN_ALL_LOADED", method=self.create_autogroups_if_needed)
                    if auto_group_filter in ("all", "hypervisors"):
                        self.entity.register_hook("HOOK_HYPERVISOR_WOKE_UP", method=self.handle_autogroup_for_entity)

                    if auto_group_filter in ("all", "virtualmachines"):
                        self.entity.register_hook("HOOK_HYPERVISOR_ALLOC", method=self.handle_autogroup_for_entity)
                        self.entity.register_hook("HOOK_HYPERVISOR_SOFT_ALLOC", method=self.handle_autogroup_for_entity)
                        self.entity.register_hook("HOOK_HYPERVISOR_VM_WOKE_UP", method=self.handle_autogroup_for_entity)

            except Exception as ex:
                self.entity.log.warning("Shared Roster Group management is not allowed to this hypervisor through XMLRPC and mod_admin_extra : %s" % ex)

        else:
            self.entity.log.info("XMLRPC module for Shared Roster Group management is disabled for this hypervisor")

        self.entity.register_hook("HOOK_HYPERVISOR_WOKE_UP", method=self._xmpp_server_admin_test)

        # permissions
        if self.entity.__class__.__name__ == "TNArchipelHypervisor":
            self.entity.permission_center.create_permission("xmppserver_groups_create", "Authorizes user to create shared groups", False)
            self.entity.permission_center.create_permission("xmppserver_groups_delete", "Authorizes user to delete shared groups", False)
            self.entity.permission_center.create_permission("xmppserver_groups_list", "Authorizes user to list shared groups", False)
            self.entity.permission_center.create_permission("xmppserver_groups_addusers", "Authorizes user to add users in shared groups", False)
            self.entity.permission_center.create_permission("xmppserver_groups_deleteusers", "Authorizes user to remove users from shared groups", False)
            self.entity.permission_center.create_permission("xmppserver_users_register", "Authorizes user to register XMPP users", False)
            self.entity.permission_center.create_permission("xmppserver_users_unregister", "Authorizes user to unregister XMPP users", False)

        if self.entity.__class__.__name__ != "TNArchipelCentralAgent":
            self.entity.permission_center.create_permission("xmppserver_users_list", "Authorizes user to list XMPP users", False)
            self.entity.permission_center.create_permission("xmppserver_users_number", "Authorizes user to get the total number of XMPP users", False)
  



    ### Plugin interface
    def register_handlers(self):
        """
        This method will be called by the plugin user when it will be
        necessary to register module for listening to stanza.
        """
        if self.entity.__class__.__name__ == "TNArchipelVirtualMachine":
            self.entity.xmppclient.RegisterHandler('iq', self.process_users_iq_for_virtualmachines, ns=ARCHIPEL_NS_XMPPSERVER_USERS)
        elif self.entity.__class__.__name__ == "TNArchipelHypervisor":
            self.entity.xmppclient.RegisterHandler('iq', self.process_iq_for_hypervisors, ns=ARCHIPEL_NS_XMPPSERVER)
            self.entity.xmppclient.RegisterHandler('iq', self.process_users_iq_for_hypervisors, ns=ARCHIPEL_NS_XMPPSERVER_USERS)
            self.entity.xmppclient.RegisterHandler('iq', self.process_groups_iq, ns=ARCHIPEL_NS_XMPPSERVER_GROUPS)

    def unregister_handlers(self):
        """
        Unregister the handlers.
        """
        if self.entity.__class__.__name__ == "TNArchipelVirtualMachine":
            self.entity.xmppclient.UnregisterHandler('iq', self.process_users_iq_for_virtualmachines, ns=ARCHIPEL_NS_XMPPSERVER_USERS)
        elif self.entity.__class__.__name__ == "TNArchipelHypervisor":
            self.entity.xmppclient.UnregisterHandler('iq', self.process_iq_for_hypervisors, ns=ARCHIPEL_NS_XMPPSERVER)
            self.entity.xmppclient.UnregisterHandler('iq', self.process_users_iq_for_hypervisors, ns=ARCHIPEL_NS_XMPPSERVER_USERS)
            self.entity.xmppclient.UnregisterHandler('iq', self.process_groups_iq, ns=ARCHIPEL_NS_XMPPSERVER_GROUPS)

    @staticmethod
    def plugin_info():
        """
        Return informations about the plugin.
        @rtype: dict
        @return: dictionary contaning plugin informations
        """
        plugin_friendly_name           = "XMPP Server Manager"
        plugin_identifier              = "xmppserver"
        plugin_configuration_section   = "XMPPSERVER"
        plugin_configuration_tokens    = []
        return {    "common-name"               : plugin_friendly_name,
                    "identifier"                : plugin_identifier,
                    "configuration-section"     : plugin_configuration_section,
                    "configuration-tokens"      : plugin_configuration_tokens }

    ## Hooks

    def create_autogroups_if_needed(self, origin, user_info, parameters):
        """
        Will create the auto_group when plugin loaded and add hypervisor if needed
        @type origin: L{TNArchipelEntity}
        @param origin: the origin of the hook
        @type user_info: object
        @param user_info: random user info
        @type parameters: object
        @param parameters: runtime argument
        """
        try:
            self.entity.log.info("XMPPSERVER: Trying to create the autogroup %s if needed" % self.autogroup_name_users)
            self.group_create(self.autogroup_users_id, self.autogroup_name_users, "Automatic group", "%s\\n%s" % (self.autogroup_hypervisors_id, self.autogroup_vms_id))
        except Exception as ex:
            self.entity.log.warning("XMPPSERVER: unable to create auto group %s: %s" % (self.autogroup_name_users, ex))

        try:
            self.entity.log.info("XMPPSERVER: Adding declared admins in archipel.conf to the autogroup %s if needed" % self.autogroup_name_users)
            admins_accounts = self.configuration.get("GLOBAL", "archipel_root_admins").split()
            self.group_add_users(self.autogroup_users_id, admins_accounts)
        except Exception as ex:
            self.entity.log.warning("XMPPSERVER: unable to create auto group %s: %s" % (self.autogroup_name_users, ex))

        try:
            self.entity.log.info("XMPPSERVER: Trying to create the autogroup %s if needed" % self.autogroup_name_vms)
            self.group_create(self.autogroup_vms_id, self.autogroup_name_vms, "Automatic group", self.autogroup_users_id)
        except Exception as ex:
            self.entity.log.warning("XMPPSERVER: unable to create auto group %s: %s" % (self.autogroup_name_vms, ex))
        try:
            self.entity.log.info("XMPPSERVER: Trying to create the autogroup %s if needed" % self.autogroup_name_hypervisors)
            self.group_create(self.autogroup_hypervisors_id, self.autogroup_name_hypervisors, "Automatic group", self.autogroup_users_id)
        except Exception as ex:
            self.entity.log.warning("XMPPSERVER: unable to create auto group %s: %s" % (self.autogroup_name_hypervisors, ex))

    def handle_autogroup_for_entity(self, origin, user_info, entity):
        """
        Will add all new virtual machines in autogroup if configured to
        @type origin: L{TNArchipelEntity}
        @param origin: the origin of the hook
        @type user_info: object
        @param user_info: random user info
        @type entity: object
        @param entity: runtime argument
        """
        if isinstance(entity, TNArchipelVirtualMachine):
            group_name = self.autogroup_name_vms
            group_id = self.autogroup_vms_id
        elif isinstance(entity, TNArchipelHypervisor):
            group_name = self.autogroup_name_hypervisors
            group_id = self.autogroup_hypervisors_id
        try:
            self.entity.log.info("XMPPSERVER: Adding new entity %s in autogroup %s" % (entity.jid, group_name))
            self.group_add_users(group_id, [entity.jid.getStripped()])
        except Exception as ex:
            self.entity.log.warning("XMPPSERVER: unable to add entity %s in autogroup %s: %s" % (entity.jid, group_name, ex))

    ## Utils

    def _xmpp_server_admin_test(self, origin, user_info, entity):
        """
        Build the xmpp management capabilities dictionnary
        """
        # use disco#info to see if we can use admin-server command XEP-133
        def on_receive_info(conn, iq):
            if iq.getType() == "result":
                self.entity.log.info("XMMP user management is allowed to this hypervisor through XEP-133")
                self.users_management_capabilities["xmpp"] = True
            else:
                self.entity.log.warning("XMPP user management is not allowed to this hypervisor through XEP-133")
                self.users_management_capabilities["xmpp"] = False

        user_iq = xmpp.Iq(typ="get", to=entity.jid.getDomain())
        user_iq.addChild("query", attrs={"node": "http://jabber.org/protocol/admin#get-registered-users-num"}, namespace="http://jabber.org/protocol/disco#info")
        if self.entity.__class__.__name__ == "TNArchipelVirtualMachine":
            self.entity.hypervisor.xmppclient.SendAndCallForResponse(user_iq, on_receive_info)
        else:
            self.entity.xmppclient.SendAndCallForResponse(user_iq, on_receive_info)

    def _send_xmlrpc_call(self, method, args):
        """
        Sends the xml rpc call with given args
        @type method: function
        @param method: the xmlrpc method to launch
        @type args: dict
        @param args: containing the xmlrpc call arguments
        @rtype: dict
        @return: the xmlrpc reply
        """
        fn = getattr(self.xmlrpc_server, method)
        try:
            return fn(self.xmlrpc_auth, args)
        except Exception as ex:
            raise Exception(str(ex).replace(self.xmlrpc_password, "[PASSWORD_HIDDEN]"))

    def _extract_entity_type(self, vcard_node):
        """
        Extract the entity type from given vcard
        @type vcard_node: xmpp.Node
        @param vcard_node: the VCard
        @rtype: String
        @return: the entity type : virtualmachine, hypervisor or human
        """
        if vcard_node and vcard_node.getTag("ROLE"):
            vcard_role = vcard_node.getTag("ROLE").getData()
            if vcard_role in ("hypervisor", "virtualmachine", "central-agent"):
                return vcard_role
        return "human"

    def _fetch_users(self, xmppserver, callback, args=None):
        """
        Fetch users and populate the internal list
        @type xmppserver: String
        @param xmppserver: the xmpp server to query
        @type callback: function
        @param callback: the callback to call when fetching is complete
        @type args: dict
        @param args: optional kwards of the callback
        """
        self.users = []
        self.need_user_refresh = False

        def on_receive_users_num(conn, iq):
            if iq.getType() != "result":
                self.entity.log.error("unable to get user number: %s" % str(iq))
                return
            total_number_of_users = int(iq.getTag("command").getTag("x").getTags("field")[1].getTag("value").getData())

            def on_receive_users(conn, iq):

                if not iq.getType() == "result":
                    self.entity.log.error("unable to fetch users: %s" % str(iq))
                    return

                def manage_received_users(conn, iq):
                    items = iq.getTag("query").getTags("item")
                    users = map(lambda x: x.getAttr("jid"), items)

                    def on_receive_vcard(conn, iq):
                        try:
                            entity_type = self._extract_entity_type(iq.getTag("vCard"))
                            self.entities_types_cache[iq.getFrom().getStripped()] = entity_type
                            self.users.append({"jid": iq.getFrom().getStripped(), "type": entity_type})
                            if len(self.users) == total_number_of_users:
                                callback(**args)
                        except Exception as ex:
                            self.entity.log.error("XMPPSERVER: Error while fetching contact vCard: %s" % str(ex))

                    for user in users:
                        if not user in self.entities_types_cache:
                            iq_vcard = xmpp.Iq(typ="get", to=user)
                            iq_vcard.addChild("vCard", namespace="vcard-temp")
                            self.entity.log.debug("XMPPSERVER: Entity type of %s is not cached. fetching..." % user)
                            if self.entity.__class__.__name__ == "TNArchipelVirtualMachine":
                                self.entity.hypervisor.xmppclient.SendAndCallForResponse(iq_vcard, on_receive_vcard)
                            else:
                                self.entity.xmppclient.SendAndCallForResponse(iq_vcard, on_receive_vcard)

                        else:
                            self.entity.log.debug("XMPPSERVER: Entity type of %s is already cached (%s)" % (user, self.entities_types_cache[user]))
                            self.users.append({"jid": user, "type": self.entities_types_cache[user]})
                            if len(self.users) == total_number_of_users:
                                callback(**args)

                try:
                    items = iq.getTag("query").getTags("item")
                    if items[0].getAttr("node"):
                        for page in range(0, len(items)):
                            iq_page = xmpp.Iq(typ="get", to=iq.getFrom())
                            iq_page.addChild("query", attrs={"node": iq.getTag("query").getTags("item")[page].getAttr("node")}, namespace="http://jabber.org/protocol/disco#items")
                            if self.entity.__class__.__name__ == "TNArchipelVirtualMachine":
                                self.entity.hypervisor.xmppclient.SendAndCallForResponse(iq_page, manage_received_users)
                            else:
                                self.entity.xmppclient.SendAndCallForResponse(iq_page, manage_received_users)
                    else:
                        manage_received_users(conn, iq)

                except Exception as ex:
                    self.entity.log.error("XMPPSERVER: Unable to manage to get users or their vcards. error is %s" % str(ex))

            user_iq = xmpp.Iq(typ="get", to=xmppserver)
            user_iq.addChild("query", attrs={"node": "all users"}, namespace="http://jabber.org/protocol/disco#items")
            if self.entity.__class__.__name__ == "TNArchipelVirtualMachine":
                self.entity.hypervisor.xmppclient.SendAndCallForResponse(user_iq, on_receive_users)
            else:
                self.entity.xmppclient.SendAndCallForResponse(user_iq, on_receive_users)

        iq = xmpp.Iq(typ="set", to=xmppserver)
        iq.addChild("command", attrs={"action": "execute", "node": "http://jabber.org/protocol/admin#get-registered-users-num"}, namespace="http://jabber.org/protocol/commands")
        if self.entity.__class__.__name__ == "TNArchipelVirtualMachine":
            self.entity.hypervisor.xmppclient.SendAndCallForResponse(iq, on_receive_users_num)
        else:
            self.entity.xmppclient.SendAndCallForResponse(iq, on_receive_users_num)

    ### XMPP Processing for shared groups thtough XMLRPC

    def process_groups_iq(self, conn, iq):
        """
        This method is invoked when a ARCHIPEL_NS_XMPPSERVER_GROUPS IQ is received.
        It understands IQ of type:
            - create
            - delete
            - list
            - addusers
            - deleteusers
        @type conn: xmpp.Dispatcher
        @param conn: ths instance of the current connection that send the stanza
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ
        """
        reply = None
        action = self.entity.check_acp(conn, iq)
        self.entity.check_perm(conn, iq, action, -1, prefix="xmppserver_groups_")
        if action == "create":
            reply = self.iq_group_create(iq)
        elif action == "delete":
            reply = self.iq_group_delete(iq)
        elif action == "list":
            reply = self.iq_group_list(iq)
        elif action == "addusers":
            reply = self.iq_group_add_users(iq)
        elif action == "deleteusers":
            reply = self.iq_group_delete_users(iq)
        if reply:
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed

    def iq_group_create(self, iq):
        """
        Create a new shared roster.
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ
        @rtype: xmpp.Protocol.Iq
        @return: a ready to send IQ containing the result of the action
        """
        try:
            reply = iq.buildReply("result")
            groupID = iq.getTag("query").getTag("archipel").getAttr("id")
            groupName = iq.getTag("query").getTag("archipel").getAttr("name")
            groupDesc = iq.getTag("query").getTag("archipel").getAttr("description")            
            groupDisplay = iq.getTag("query").getTag("archipel").getAttr("display")
            self.group_create(groupID, groupName, groupDesc, groupDisplay)
        except Exception as ex:
            reply = build_error_iq(self, ex, iq, ARCHIPEL_ERROR_CODE_XMPPSERVER_GROUP_CREATE)
        return reply

    def group_create(self, ID, name, description, display=""):
        """
        Create a new shared roster group
        @type ID: string
        @param ID: the ID of the group
        @type name: string
        @param name: the name of the group
        @type description: string
        @param description: the description of the group
        """
        server = self.entity.jid.getDomain()
        answer = self._send_xmlrpc_call("srg_create", {"host": server, "display": ID, "name": name, "description": description, "group": ID})
        if not answer['res'] == 0:
            raise Exception("Cannot create shared roster group. %s" % str(answer))
        self.entity.log.info("XMPPSERVER: Creating a new shared group %s" % ID)
        self.entity.push_change("xmppserver:groups", "created")
        return True

    def iq_group_delete(self, iq):
        """
        Delete a shared group.
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ
        @rtype: xmpp.Protocol.Iq
        @return: a ready to send IQ containing the result of the action
        """
        try:
            reply = iq.buildReply("result")
            groupID = iq.getTag("query").getTag("archipel").getAttr("id")
            self.group_delete(groupID)
        except Exception as ex:
            reply = build_error_iq(self, ex, iq, ARCHIPEL_ERROR_CODE_XMPPSERVER_GROUP_DELETE)
        return reply

    def group_delete(self, ID):
        """
        Destroy a shared roster group
        @type ID: string
        @param ID: the ID of the group to delete
        """
        server = self.entity.jid.getDomain()
        answer = self._send_xmlrpc_call("srg_delete", {"host": server, "group": ID})
        if not answer['res'] == 0:
            raise Exception("Cannot create shared roster group. %s" % str(answer))
        self.entity.log.info("XMPPSERVER: Removing a shared group %s" % ID)
        self.entity.push_change("xmppserver:groups", "deleted")

    def iq_group_list(self, iq):
        """
        List shared groups.
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ
        @rtype: xmpp.Protocol.Iq
        @return: a ready to send IQ containing the result of the action
        """
        try:
            reply = iq.buildReply("result")
            groups = self.group_list()
            groupsNode = []
            for group in groups:
                members = group["members"]
                del group["members"]
                newNode = xmpp.Node("group", attrs=group)
                for member in members:
                    newNode.addChild("user", attrs={"jid": member})
                groupsNode.append(newNode)
            reply.setQueryPayload(groupsNode)
        except Exception as ex:
            reply = build_error_iq(self, ex, iq, ARCHIPEL_ERROR_CODE_XMPPSERVER_GROUP_LIST)
        return reply

    def group_list(self):
        """
        Returns a list of existing groups
        """
        server = self.entity.jid.getDomain()
        answer = self._send_xmlrpc_call("srg_list", {"host": server})
        groups = answer["groups"]
        ret = []

        for group in groups:
            answer = self._send_xmlrpc_call("srg_get_info", {"host": server, "group": group["id"]})
            informations = answer["informations"]
            for info in informations:
                if info['information'][0]["key"] == "name":
                    displayed_name = info['information'][1]["value"]
                if info['information'][0]["key"] == "description":
                    description = info['information'][1]["value"]
            info = {"id": group["id"], "displayed_name": displayed_name.replace("\"", ""), "description": description.replace("\"", ""), "members": []}
            answer = self._send_xmlrpc_call("srg_get_members", {"host": server, "group": group["id"]})
            members = answer["members"]
            for member in members:
                info["members"].append(member["member"])
            ret.append(info)
        return ret

    def iq_group_add_users(self, iq):
        """
        Add a user into a shared group.
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ
        @rtype: xmpp.Protocol.Iq
        @return: a ready to send IQ containing the result of the action
        """
        try:
            reply = iq.buildReply("result")
            groupID = iq.getTag("query").getTag("archipel").getAttr("groupid")
            users = map(lambda x: x.getAttr("jid"), iq.getTag("query").getTag("archipel").getTags("user"))
            self.group_add_users(groupID, users)
        except Exception as ex:
            reply = build_error_iq(self, ex, iq, ARCHIPEL_ERROR_CODE_XMPPSERVER_GROUP_ADDUSERS)
        return reply

    def group_add_users(self, ID, users):
        """
        Add users into a group
        @type ID: string
        @param ID: the ID of the group
        @type users: list
        @param users: list of the users to add in the group
        """
        server = self.entity.jid.getDomain()
        for user in users:
            userJID = xmpp.JID(user)
            answer = self._send_xmlrpc_call("srg_user_add", {"user": userJID.getNode(), "host": userJID.getDomain(), "group": ID, "grouphost": server})
            if not answer['res'] == 0:
                raise Exception("Cannot add user to shared roster group. %s" % str(answer))
            self.entity.log.info("XMPPSERVER: Adding user %s into shared group %s" % (userJID, ID))
        self.entity.push_change("xmppserver:groups", "usersadded")

    def iq_group_delete_users(self, iq):
        """
        delete a user from a shared group
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ
        @rtype: xmpp.Protocol.Iq
        @return: a ready to send IQ containing the result of the action
        """
        try:
            reply = iq.buildReply("result")
            groupID = iq.getTag("query").getTag("archipel").getAttr("groupid")
            users = map(lambda x: x.getAttr("jid"), iq.getTag("query").getTag("archipel").getTags("user"))
            self.group_delete_users(groupID, users)
        except Exception as ex:
            reply = build_error_iq(self, ex, iq, ARCHIPEL_ERROR_CODE_XMPPSERVER_GROUP_DELETEUSERS)
        return reply

    def group_delete_users(self, ID, users):
        """
        Delete users from a group
        @type ID: string
        @param ID: the ID of the group
        @type users: list
        @param users: list of users to remove
        """
        server = self.entity.jid.getDomain()
        for user in users:
            userJID = xmpp.JID(user)
            answer = self._send_xmlrpc_call("srg_user_del", {"user": userJID.getNode(), "host": userJID.getDomain(), "group": ID, "grouphost": server})
            if not answer['res'] == 0:
                raise Exception("Cannot remove user from shared roster group. %s" % str(answer))
            self.entity.log.info("XMPPSERVER: Removing user %s from shared group %s" % (userJID, ID))
        self.entity.push_change("xmppserver:groups", "usersdeleted")

    ### XMPP Processing for users through XEP-133

    def process_users_iq_for_virtualmachines(self, conn, iq):
        """
        This method is invoked when a ARCHIPEL_NS_XMPPSERVER_USERS IQ is received.
        It understands IQ of type:
            - list
            - filter
            - number
        @type conn: xmpp.Dispatcher
        @param conn: ths instance of the current connection that send the stanza
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ
        """
        action = self.entity.check_acp(conn, iq)
        self.entity.check_perm(conn, iq, action, -1, prefix="xmppserver_users_")
        reply = None
        if action == "number":
            reply = self.iq_users_number(iq)
            if not reply:
                raise xmpp.protocol.NodeProcessed
        elif action == "list":
            reply = self.iq_users_list(iq)
            if not reply:
                raise xmpp.protocol.NodeProcessed
        elif action == "filter":
            reply = self.iq_users_filter(iq)
            if not reply:
                raise xmpp.protocol.NodeProcessed
        if reply:
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed

    def process_users_iq_for_hypervisors(self, conn, iq):
        """
        This method is invoked when a ARCHIPEL_NS_XMPPSERVER_USERS IQ is received.
        It understands IQ of type:
            - register
            - unregister
            - list
            - filter
            - number
            - changepassword
        @type conn: xmpp.Dispatcher
        @param conn: ths instance of the current connection that send the stanza
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ
        """
        action = self.entity.check_acp(conn, iq)
        self.entity.check_perm(conn, iq, action, -1, prefix="xmppserver_users_")
        reply = None
        if action == "register":
            reply = self.iq_users_register(iq)
        elif action == "unregister":
            reply = self.iq_users_unregister(iq)
        elif action == "number":
            reply = self.iq_users_number(iq)
            if not reply:
                raise xmpp.protocol.NodeProcessed
        elif action == "list":
            reply = self.iq_users_list(iq)
            if not reply:
                raise xmpp.protocol.NodeProcessed
        elif action == "filter":
            reply = self.iq_users_filter(iq)
            if not reply:
                raise xmpp.protocol.NodeProcessed
        elif action == "changepassword":
            reply = self.iq_users_change_password(iq)
            if not reply:
                raise xmpp.protocol.NodeProcessed
        if reply:
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed

    def iq_users_register(self, iq):
        """
        Register some new users.
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ
        @rtype: xmpp.Protocol.Iq
        @return: a ready to send IQ containing the result of the action
        """
        try:
            reply = iq.buildReply("result")
            users = map(lambda x: {"jid": xmpp.JID(x.getAttr("jid")), "password": x.getAttr("password")}, iq.getTag("query").getTag("archipel").getTags("user"))
            self.users_register(users)
        except Exception as ex:
            reply = build_error_iq(self, ex, iq, ARCHIPEL_ERROR_CODE_XMPPSERVER_USERS_REGISTER)
        return reply

    def users_register(self, users):
        """
        Register new users
        @type users: list
        @param users: list of users to register
        """
        def on_receive_registration(conn, iq):
            if iq.getType() == "result":
                for user in users:
                    self.users.append({"jid": user["jid"].getStripped(), "type": "human"})
                self.entities_types_cache[user["jid"].getStripped()] = "human"
                self.entity.log.info("XMPPSERVER: Successfully registered user(s).")
                self.entity.push_change("xmppserver:users", "registered")
            else:
                self.entity.push_change("xmppserver:users", "registerationerror", content_node=iq)
                self.entity.log.error("XMPPSERVER: Unable to register user. %s" % str(iq))
        server = self.entity.jid.getDomain()
        for user in users:
            iq = xmpp.Iq(typ="set", to=self.entity.jid.getDomain())
            iq_command = iq.addChild("command", namespace="http://jabber.org/protocol/commands", attrs={"node": "http://jabber.org/protocol/admin#add-user"})
            iq_command_x = iq_command.addChild("x", namespace="jabber:x:data", attrs={"type": "submit"})
            iq_command_x.addChild("field", attrs={"type": "hidden", "var": "FORM_TYPE"}).addChild("value").setData("http://jabber.org/protocol/admin")
            iq_command_x.addChild("field", attrs={"var": "accountjid"}).addChild("value").setData(user["jid"])
            iq_command_x.addChild("field", attrs={"var": "password"}).addChild("value").setData(user["password"])
            iq_command_x.addChild("field", attrs={"var": "password-verify"}).addChild("value").setData(user["password"])
            if self.entity.__class__.__name__ == "TNArchipelVirtualMachine":
                self.entity.hypervisor.xmppclient.SendAndCallForResponse(iq, on_receive_registration)
            else:
                self.entity.xmppclient.SendAndCallForResponse(iq, on_receive_registration)
            self.entity.log.info("XMPPSERVER: Registering a new user %s@%s" % (user["jid"], server))

    def iq_users_unregister(self, iq):
        """
        Unregister somes users.
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ
        @rtype: xmpp.Protocol.Iq
        @return: a ready to send IQ containing the result of the action
        """
        try:
            reply = iq.buildReply("result")
            users = map(lambda x: xmpp.JID(x.getAttr("jid")), iq.getTag("query").getTag("archipel").getTags("user"))
            self.users_unregister(users)
        except Exception as ex:
            reply = build_error_iq(self, ex, iq, ARCHIPEL_ERROR_CODE_XMPPSERVER_USERS_UNREGISTER)
        return reply

    def users_unregister(self, users):
        """
        Unregister users
        @type users: list
        @param users: list of users to unregister
        """
        def on_receive_unregistration(conn, iq):
            if iq.getType() == "result":
                for jid in users:
                    self.users.remove({"jid": jid.getStripped(), "type": "human"})
                self.entity.log.info("XMPPSERVER: Successfully unregistered user(s).")
                self.entity.push_change("xmppserver:users", "unregistered")
            else:
                self.entity.push_change("xmppserver:users", "unregisterationerror", content_node=iq)
                self.entity.log.error("XMPPSERVER: unable to unregister user. %s" % str(iq))

        iq = xmpp.Iq(typ="set", to=self.entity.jid.getDomain())
        iq_command = iq.addChild("command", namespace="http://jabber.org/protocol/commands", attrs={"node": "http://jabber.org/protocol/admin#delete-user"})
        iq_command_x = iq_command.addChild("x", namespace="jabber:x:data", attrs={"type": "submit"})
        iq_command_x.addChild("field", attrs={"type": "hidden", "var": "FORM_TYPE"}).addChild("value").setData("http://jabber.org/protocol/admin")
        accountjids_node = iq_command_x.addChild("field", attrs={"var": "accountjids"})
        for jid in users:
            accountjids_node.addChild("value").setData(jid.getStripped())
            if jid.getStripped() in self.entities_types_cache:
                del self.entities_types_cache[jid.getStripped()]
        if self.entity.__class__.__name__ == "TNArchipelVirtualMachine":
            self.entity.hypervisor.xmppclient.SendAndCallForResponse(iq, on_receive_unregistration)
        else:
            self.entity.xmppclient.SendAndCallForResponse(iq, on_receive_unregistration)
        self.entity.log.info("XMPPSERVER: Unregistring some users %s" % str(users))

    def iq_users_number(self, iq):
        """
        Return number of registered users.
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ
        @rtype: xmpp.Protocol.Iq
        @return: a ready to send IQ containing the result of the action
        """
        try:
            reply = iq.buildReply("result")
            only_humans = iq.getTag("query").getTag("archipel").getAttr("humans_only")
            if only_humans and only_humans.lower() in ("true", "1", "yes"):
                only_humans = True
            else:
                only_humans = False
            self.users_number(reply, only_humans)
            return None
        except Exception as ex:
            reply = build_error_iq(self, ex, iq, ARCHIPEL_ERROR_CODE_XMPPSERVER_USERS_LIST)
        return reply

    def users_number(self, base_reply, only_humans=True):
        """
        Return total number of registered users
        """
        def send_number(base_reply):
            n = 0
            for user in self.users:
                if only_humans and not user["type"] == "human":
                    continue
                n = n + 1
            base_reply.setQueryPayload([xmpp.Node("users", attrs={"total": n})])
            self.entity.xmppclient.send(base_reply)
        if self.need_user_refresh:
            self._fetch_users(self.entity.jid.getDomain(), send_number, {"base_reply": base_reply})
        else:
            send_number(base_reply)

    def iq_users_list(self, iq):
        """
        List all registered users.
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ
        @rtype: xmpp.Protocol.Iq
        @return: a ready to send IQ containing the result of the action
        """
        try:
            reply = iq.buildReply("result")
            page = int(iq.getTag("query").getTag("archipel").getAttr("page"))
            only_humans = iq.getTag("query").getTag("archipel").getAttr("humans_only")
            if only_humans and only_humans.lower() in ("true", "1", "yes"):
                only_humans = True
            else:
                only_humans = False
            self.users_list(reply, page, only_humans)
            return None
        except Exception as ex:
            reply = build_error_iq(self, ex, iq, ARCHIPEL_ERROR_CODE_XMPPSERVER_USERS_LIST)
        return reply

    def users_list(self, base_reply, page, only_humans=True):
        """
        List all registered users
        """
        def send_users(base_reply):
            nodes = []
            bound_begin = page * self.user_page_size
            bound_end = bound_begin + self.user_page_size
            users = sorted(self.users, cmp=lambda x, y: cmp(x["jid"], y["jid"]))[bound_begin:bound_end]
            for user in users:
                if only_humans and not user["type"] == "human":
                    continue
                nodes.append(xmpp.Node("user", attrs={"jid": user["jid"], "type": user["type"]}))
            base_reply.setQueryPayload(nodes)
            self.entity.xmppclient.send(base_reply)

        if self.need_user_refresh:
            self._fetch_users(self.entity.jid.getDomain(), send_users, {"base_reply": base_reply})
        else:
            send_users(base_reply)

    def iq_users_filter(self, iq):
        """
        Filter all registered users.
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ
        @rtype: xmpp.Protocol.Iq
        @return: a ready to send IQ containing the result of the action
        """
        try:
            reply = iq.buildReply("result")
            filterString = iq.getTag("query").getTag("archipel").getAttr("filter")
            users = self.users_filter(reply, filterString)
            return None
        except Exception as ex:
            reply = build_error_iq(self, ex, iq, ARCHIPEL_ERROR_CODE_XMPPSERVER_USERS_FILTER)
        return reply

    def users_filter(self, base_reply, filterString):
        """
        Filter all registered users.
        """
        def send_filtered_users(base_reply):
            nodes = []
            users = sorted(self.users, cmp=lambda x, y: cmp(x["jid"], y["jid"]))
            for user in users:
                if not user["jid"].upper().find(filterString.upper()) > -1:
                    continue
                nodes.append(xmpp.Node("user", attrs={"jid": user["jid"], "type": user["type"]}))
            base_reply.setQueryPayload(nodes)

            if self.entity.__class__.__name__ == "TNArchipelVirtualMachine":
                self.entity.hypervisor.xmppclient.send(base_reply)
            else:
                self.entity.xmppclient.send(base_reply)

        if self.need_user_refresh:
            self._fetch_users(self.entity.jid.getDomain(), send_filtered_users, {"base_reply": base_reply})
        else:
            send_filtered_users(base_reply)

    def iq_users_change_password(self, iq):
        """
        Change password for users.
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ
        @rtype: xmpp.Protocol.Iq
        @return: a ready to send IQ containing the result of the action
        """
        try:
            reply = iq.buildReply("result")
            users = map(lambda x: {"jid": xmpp.JID(x.getAttr("jid")), "password": x.getAttr("password")}, iq.getTag("query").getTag("archipel").getTags("user"))
            self.users_change_password(users)
        except Exception as ex:
            reply = build_error_iq(self, ex, iq, ARCHIPEL_ERROR_CODE_XMPPSERVER_USERS_CHANGEPASSWORD)
        return reply

    def users_change_password(self, users):
        """
        Change password for users
        @type users: list
        @param users: list of users to change password
        """
        def on_receive_password_changed(conn, iq):
            if iq.getType() == "result":
                self.entity.log.info("XMPPSERVER: Successfully changed paswword for user(s).")
                self.entity.push_change("xmppserver:users", "passwordchanged")
            else:
                self.entity.push_change("xmppserver:users", "changepassworderror", content_node=iq)
                self.entity.log.error("XMPPSERVER: Unable to change password for user. %s" % str(iq))
        server = self.entity.jid.getDomain()
        for user in users:
            iq = xmpp.Iq(typ="set", to=self.entity.jid.getDomain())
            iq_command = iq.addChild("command", namespace="http://jabber.org/protocol/commands", attrs={"node": "http://jabber.org/protocol/admin#change-user-password"})
            iq_command_x = iq_command.addChild("x", namespace="jabber:x:data", attrs={"type": "submit"})
            iq_command_x.addChild("field", attrs={"type": "hidden", "var": "FORM_TYPE"}).addChild("value").setData("http://jabber.org/protocol/admin")
            iq_command_x.addChild("field", attrs={"var": "accountjid"}).addChild("value").setData(user["jid"])
            iq_command_x.addChild("field", attrs={"var": "password"}).addChild("value").setData(user["password"])
            if self.entity.__class__.__name__ == "TNArchipelVirtualMachine":
                self.entity.hypervisor.xmppclient.SendAndCallForResponse(iq, on_receive_password_changed)
            else:
                self.entity.xmppclient.SendAndCallForResponse(iq, on_receive_password_changed)
            self.entity.log.info("XMPPSERVER: Changing password for user %s@%s" % (user["jid"], server))

    def process_iq_for_hypervisors(self, conn, iq):
        """
        This method is invoked when a ARCHIPEL_NS_XMPPSERVER IQ is received.
        It understands IQ of type:
            - managementcapabilities
        @type conn: xmpp.Dispatcher
        @param conn: ths instance of the current connection that send the stanza
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ
        """
        action = self.entity.check_acp(conn, iq)
        self.entity.check_perm(conn, iq, action, -1, prefix="xmppserver_")
        reply = None
        if action == "managementcapabilities":
            reply = self.iq_management_capabilities(iq)
            if not reply:
                raise xmpp.protocol.NodeProcessed
        if reply:
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed

    def iq_management_capabilities(self, iq):
        """
        Reply the hypervisor xmpp management capabitilies
        """
        try:
            reply = iq.buildReply("result")
            users_node  = xmpp.Node("users",  attrs={"xmpp": self.users_management_capabilities["xmpp"],  "xmlrpc": self.users_management_capabilities["xmlrpc"]})
            groups_node = xmpp.Node("groups", attrs={"xmpp": self.groups_management_capabilities["xmpp"], "xmlrpc": self.groups_management_capabilities["xmlrpc"]})
            reply.setQueryPayload([users_node, groups_node])

        except Exception as ex:
            reply = build_error_iq(self, ex, iq, ARCHIPEL_ERROR_CODE_XMPPSERVER_MANAGEMENT)
        return reply
