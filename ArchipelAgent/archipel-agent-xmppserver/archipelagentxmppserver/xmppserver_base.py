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
            if configuration.has_option("XMPPSERVER", "auto_group_name"):
                self.autogroup_name = configuration.get("XMPPSERVER", "auto_group_name")
            else:
                self.autogroup_name = "Platform"
            self.autogroup_id = "AUTOGROUP_SYSTEM"
            self.entity.register_hook("HOOK_ARCHIPELENTITY_PLUGIN_ALL_LOADED", method=self.create_autogroup_if_needed)
            self.entity.register_hook("HOOK_HYPERVISOR_ALLOC", method=self.handle_autogroup_on_alloc)
            self.entity.register_hook("HOOK_HYPERVISOR_VM_WOKE_UP", method=self.handle_autogroup_on_vm_wake_up)

        # permissions
        self.entity.permission_center.create_permission("xmppserver_groups_create", "Authorizes user to create shared groups", False)
        self.entity.permission_center.create_permission("xmppserver_groups_delete", "Authorizes user to delete shared groups", False)
        self.entity.permission_center.create_permission("xmppserver_groups_list", "Authorizes user to list shared groups", False)
        self.entity.permission_center.create_permission("xmppserver_groups_addusers", "Authorizes user to add users in shared groups", False)
        self.entity.permission_center.create_permission("xmppserver_groups_deleteusers", "Authorizes user to remove users from shared groups", False)
        self.entity.permission_center.create_permission("xmppserver_users_register", "Authorizes user to register XMPP users", False)
        self.entity.permission_center.create_permission("xmppserver_users_unregister", "Authorizes user to unregister XMPP users", False)
        self.entity.permission_center.create_permission("xmppserver_users_list", "Authorizes user to list XMPP users", False)


    ### Plugin interface

    def register_handlers(self):
        """
        This method will be called by the plugin user when it will be
        necessary to register module for listening to stanza.
        """
        self.entity.xmppclient.RegisterHandler('iq', self.process_groups_iq, ns=ARCHIPEL_NS_XMPPSERVER_GROUPS)
        self.entity.xmppclient.RegisterHandler('iq', self.process_users_iq, ns=ARCHIPEL_NS_XMPPSERVER_USERS)

    def unregister_handlers(self):
        """
        Unregister the handlers.
        """
        self.entity.xmppclient.UnregisterHandler('iq', self.process_groups_iq, ns=ARCHIPEL_NS_XMPPSERVER_GROUPS)
        self.entity.xmppclient.UnregisterHandler('iq', self.process_users_iq, ns=ARCHIPEL_NS_XMPPSERVER_USERS)

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

    def handle_autogroup_on_alloc(self, origin, user_info, newvm):
        """
        Will add all new virtual machines in autogroup if configured to
        @type origin: L{TNArchipelEntity}
        @param origin: the origin of the hook
        @type user_info: object
        @param user_info: random user info
        @type newvm: object
        @param newvm: runtime argument
        """
        try:
            self.entity.log.info("XMPPSERVER: Adding new entity %s in autogroup %s" % (newvm.jid, self.autogroup_name))
            self.group_add_users(self.autogroup_id, [newvm.jid.getStripped()])
        except Exception as ex:
            self.entity.log.warning("XMPPSERVER: unable to add entity %s in autogroup %s: %s" % (newvm.jid, self.autogroup_name, ex))

    def create_autogroup_if_needed(self, origin, user_info, parameters):
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
            self.entity.log.info("XMPPSERVER: Trying to create the autogroup %s in needed" % self.autogroup_name)
            self.group_create(self.autogroup_id, self.autogroup_name, "Automatic group")
        except Exception as ex:
            self.entity.log.warning("XMPPSERVER: unable to create auto group %s: %s" % (self.autogroup_name, ex))
        try:
            self.entity.log.info("XMPPSERVER: Trying to add hypervisor %s into the autogroup %s" % (self.entity.jid, self.autogroup_name))
            self.group_add_users(self.autogroup_id, [self.entity.jid.getStripped()])
        except Exception as ex:
            self.entity.log.warning("XMPPSERVER: unable to add hypervisor %s in auto group %s: %s" % (self.entity.jid, self.autogroup_name, ex))


    def handle_autogroup_on_vm_wake_up(self, origin, user_info, vm):
        """
        Will add awaken virtual machine in autogroup if needed
        @type origin: L{TNArchipelEntity}
        @param origin: the origin of the hook
        @type user_info: object
        @param user_info: random user info
        @type parameters: object
        @param parameters: runtime argument
        """
        try:
            self.entity.log.info("XMPPSERVER: Trying to add virtual machine %s into the autogroup %s" % (vm.jid, self.autogroup_name))
            self.group_add_users(self.autogroup_id, [vm.jid.getStripped()])
        except Exception as ex:
            self.entity.log.warning("XMPPSERVER: unable to add hypervisor %s in auto group %s: %s" % (vm.jid, self.autogroup_name, ex))


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

    def users_list(self):
        """
        List all registered users
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

    def process_users_iq(self, conn, iq):
        """
        This method is invoked when a ARCHIPEL_NS_EJABBERDCTL_USERS IQ is received.
        It understands IQ of type:
            - register
            - unregister
            - list
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
        elif action == "list":
            reply = self.iq_users_list(iq)
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
            users = map(lambda x: {"username": x.getAttr("username"), "password": x.getAttr("password")}, iq.getTag("query").getTag("archipel").getTags("user"))
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
            users = map(lambda x: x.getAttr("username"), iq.getTag("query").getTag("archipel").getTags("user"))
            self.users_unregister(users)
        except Exception as ex:
            reply = build_error_iq(self, ex, iq, ARCHIPEL_ERROR_CODE_XMPPSERVER_USERS_UNREGISTER)
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
            nodes = []
            users = self.users_list()
            for user in users:
                nodes.append(xmpp.Node("user", attrs=user))
            reply.setQueryPayload(nodes)
            self.entity.push_change("xmppserver:users", "listfetched", content_node=xmpp.Node("users", payload=nodes))
        except Exception as ex:
            reply = build_error_iq(self, ex, iq, ARCHIPEL_ERROR_CODE_XMPPSERVER_USERS_LIST)
        return reply
