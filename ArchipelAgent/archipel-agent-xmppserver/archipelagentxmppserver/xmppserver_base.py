# -*- coding: utf-8 -*-
#
# xmppserver_base.py
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

from archipel.archipelHypervisor import TNArchipelHypervisor
from archipel.archipelVirtualMachine import TNArchipelVirtualMachine
from archipelcore.archipelPlugin import TNArchipelPlugin
from archipelcore.utils import build_error_iq


ARCHIPEL_NS_XMPPSERVER_GROUPS   = "archipel:xmppserver:groups"
ARCHIPEL_NS_XMPPSERVER_USERS    = "archipel:xmppserver:users"

ARCHIPEL_ERROR_CODE_XMPPSERVER_GROUP_ADDUSERS       = -10001
ARCHIPEL_ERROR_CODE_XMPPSERVER_GROUP_CREATE         = -10002
ARCHIPEL_ERROR_CODE_XMPPSERVER_GROUP_DELETE         = -10003
ARCHIPEL_ERROR_CODE_XMPPSERVER_GROUP_DELETEUSERS    = -10004
ARCHIPEL_ERROR_CODE_XMPPSERVER_GROUP_LIST           = -10005
ARCHIPEL_ERROR_CODE_XMPPSERVER_USERS_LIST           = -10006
ARCHIPEL_ERROR_CODE_XMPPSERVER_USERS_REGISTER       = -10007
ARCHIPEL_ERROR_CODE_XMPPSERVER_USERS_UNREGISTER     = -10008
ARCHIPEL_ERROR_CODE_XMPPSERVER_USERS_FILTER         = -10009


class TNXMPPServerControllerBase (TNArchipelPlugin):

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

        if configuration.has_option("XMPPSERVER", "auto_group") and configuration.getboolean("XMPPSERVER", "auto_group"):
            self.autogroup_name_hypervisors = "All Hypervisors"
            self.autogroup_name_vms = "All Virtual Machines"
            if configuration.has_option("XMPPSERVER", "auto_group_name_virtualmachines"):
                self.autogroup_name_vms = configuration.get("XMPPSERVER", "auto_group_name_virtualmachines")
            if configuration.has_option("XMPPSERVER", "auto_group_name_hypervisors"):
                self.autogroup_name_hypervisors = configuration.get("XMPPSERVER", "auto_group_name_hypervisors")

            auto_group_filter = "all"
            if configuration.has_option("XMPPSERVER", "auto_group_filter"):
                auto_group_filter = configuration.get("XMPPSERVER", "auto_group_filter")
                if not auto_group_filter in ("virtualmachines", "hypervisors", "all"):
                    raise Exception("Bad configuration", "auto_group_filter must be virtualmachines, hypervisors or all.")
            self.autogroup_vms_id = "AUTOGROUP_SYSTEM_VM"
            self.autogroup_hypervisors_id = "AUTOGROUP_SYSTEM_HYPERVISORS"

            self.entity.register_hook("HOOK_ARCHIPELENTITY_PLUGIN_ALL_LOADED", method=self.create_autogroups_if_needed)
            if auto_group_filter in ("all", "hypervisors"):
                self.entity.register_hook("HOOK_HYPERVISOR_WOKE_UP", method=self.handle_autogroup_for_entity)

            if auto_group_filter in ("all", "virtualmachines"):
                self.entity.register_hook("HOOK_HYPERVISOR_ALLOC", method=self.handle_autogroup_for_entity)
                self.entity.register_hook("HOOK_HYPERVISOR_SOFT_ALLOC", method=self.handle_autogroup_for_entity)
                self.entity.register_hook("HOOK_HYPERVISOR_VM_WOKE_UP", method=self.handle_autogroup_for_entity)

        self.user_page_size = 50

        # permissions
        if self.entity.__class__.__name__ == "TNArchipelHypervisor":
            self.entity.permission_center.create_permission("xmppserver_groups_create", "Authorizes user to create shared groups", False)
            self.entity.permission_center.create_permission("xmppserver_groups_delete", "Authorizes user to delete shared groups", False)
            self.entity.permission_center.create_permission("xmppserver_groups_list", "Authorizes user to list shared groups", False)
            self.entity.permission_center.create_permission("xmppserver_groups_addusers", "Authorizes user to add users in shared groups", False)
            self.entity.permission_center.create_permission("xmppserver_groups_deleteusers", "Authorizes user to remove users from shared groups", False)
            self.entity.permission_center.create_permission("xmppserver_users_register", "Authorizes user to register XMPP users", False)
            self.entity.permission_center.create_permission("xmppserver_users_unregister", "Authorizes user to unregister XMPP users", False)

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
            self.entity.xmppclient.RegisterHandler('iq', self.process_users_iq_for_hypervisors, ns=ARCHIPEL_NS_XMPPSERVER_USERS)
            self.entity.xmppclient.RegisterHandler('iq', self.process_groups_iq, ns=ARCHIPEL_NS_XMPPSERVER_GROUPS)

    def unregister_handlers(self):
        """
        Unregister the handlers.
        """
        if self.entity.__class__.__name__ == "TNArchipelVirtualMachine":
            self.entity.xmppclient.UnregisterHandler('iq', self.process_users_iq_for_virtualmachines, ns=ARCHIPEL_NS_XMPPSERVER_USERS)
        elif self.entity.__class__.__name__ == "TNArchipelHypervisor":
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
            self.entity.log.info("XMPPSERVER: Trying to create the autogroup %s in needed" % self.autogroup_name_vms)
            self.group_create(self.autogroup_vms_id, self.autogroup_name_vms, "Automatic group")
        except Exception as ex:
            self.entity.log.warning("XMPPSERVER: unable to create auto group %s: %s" % (self.autogroup_name_vms, ex))
        try:
            self.entity.log.info("XMPPSERVER: Trying to create the autogroup %s in needed" % self.autogroup_name_hypervisors)
            self.group_create(self.autogroup_hypervisors_id, self.autogroup_name_hypervisors, "Automatic group")
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


    ### Protocol to implement

    def users_register(self, users):
        """
        Reister new users
        @type users: list
        @param users: list of users to register
        """
        raise Exception("Not Implemented")

    def users_unregister(self, users):
        """
        Unregister users
        @type users: list
        @param users: list of users to unregister
        """
        raise Exception("Not Implemented")

    def users_number(self, perpared_reply, only_humans=True):
        """
        Return total number of users
        @type prepared_reply: xmpp.Iq
        @param prepared_reply: the base reply to use for sending users
        @type only_humans: Boolean
        @param only_humans: if true, don't count hypervisors or virtualmachines
        """
        raise Exception("Not Implemented")

    def users_list(self, perpared_reply, page, only_humans=True):
        """
        List all registered users
        @type prepared_reply: xmpp.Iq
        @param prepared_reply: the base reply to use for sending users
        @type page: Integer
        @param page: the page number
        @type only_humans: Boolean
        @param only_humans: if true, don't count hypervisors or virtualmachines
        """
        raise Exception("Not Implemented")

    def users_filter(self, perpared_reply, filterString):
        """
        filter all registered users
        @type prepared_reply: xmpp.Iq
        @param prepared_reply: the base reply to use for sending users
        @type filterString: String
        @param filterString: the filter
        """
        raise Exception("Not Implemented")

    def group_create(self, ID, name, description):
        """
        Create a new shared roster group
        @type ID: string
        @param ID: the ID of the group
        @type name: string
        @param name: the name of the group
        @type description: string
        @param description: the description of the group
        """
        raise Exception("Not Implemented")

    def group_delete(self, ID):
        """
        Destroy a shared roster group
        @type ID: string
        @param ID: the ID of the group to delete
        """
        raise Exception("Not Implemented")

    def group_list(self):
        """
        Returns a list of existing groups
        """
        raise Exception("Not Implemented")

    def group_add_users(self, ID, users):
        """
        Add users into a group
        @type ID: string
        @param ID: the ID of the group
        @type users: list
        @param users: list of the users to add in the group
        """
        raise Exception("Not Implemented")

    def group_delete_users(self, ID, users):
        """
        Delete users from a group
        @type ID: string
        @param ID: the ID of the group
        @type users: list
        @param users: list of users to remove
        """
        raise Exception("Not Implemented")


    ### XMPP Processing for shared groups

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
            self.group_create(groupID, groupName, groupDesc)
        except Exception as ex:
            reply = build_error_iq(self, ex, iq, ARCHIPEL_ERROR_CODE_XMPPSERVER_GROUP_CREATE)
        return reply

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


    ### XMPP Processing for users

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
