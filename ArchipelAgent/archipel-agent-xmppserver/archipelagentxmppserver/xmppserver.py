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

import xmlrpclib
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
        self.xmpp_server        = entity.jid.getDomain()
        self.xmlrpc_host        = self.configuration.get("XMPPSERVER", "xmlrpc_host")
        self.xmlrpc_port        = self.configuration.getint("XMPPSERVER", "xmlrpc_port")
        self.xmlrpc_user        = self.configuration.get("XMPPSERVER", "xmlrpc_user")
        self.xmlrpc_password    = self.configuration.get("XMPPSERVER", "xmlrpc_password")
        self.xmlrpc_call        = "http://%s:%s@%s:%s/" % (self.xmlrpc_user, self.xmlrpc_password, self.xmlrpc_host, self.xmlrpc_port)
        self.xmlrpc_server      = xmlrpclib.ServerProxy(self.xmlrpc_call)

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
        plugin_configuration_tokens    = [  "xmlrpc_host",
                                            "xmlrpc_port",
                                            "xmlrpc_user",
                                            "xmlrpc_password"]
        return {    "common-name"               : plugin_friendly_name,
                    "identifier"                : plugin_identifier,
                    "configuration-section"     : plugin_configuration_section,
                    "configuration-tokens"      : plugin_configuration_tokens }


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
            reply       = iq.buildReply("result")
            groupID     = iq.getTag("query").getTag("archipel").getAttr("id")
            groupName   = iq.getTag("query").getTag("archipel").getAttr("name")
            groupDesc   = iq.getTag("query").getTag("archipel").getAttr("description")
            server      = self.entity.jid.getDomain()
            answer      = self.xmlrpc_server.srg_create({"host": server, "display": groupID, "name": groupName, "description": groupDesc, "group": groupID})
            if not answer['res'] == 0:
                raise Exception("Cannot create shared roster group.")
            self.entity.log.info("Creating a new shared group %s" % groupID)
            self.entity.push_change("xmppserver:groups", "created")
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
            reply       = iq.buildReply("result")
            groupID     = iq.getTag("query").getTag("archipel").getAttr("id")
            server      = self.entity.jid.getDomain()
            answer      = self.xmlrpc_server.srg_delete({"host": server, "group": groupID})
            if not answer['res'] == 0:
                raise Exception("Cannot create shared roster group.")
            self.entity.log.info("Removing a shared group %s" % groupID)
            self.entity.push_change("xmppserver:groups", "deleted")
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
            reply       = iq.buildReply("result")
            server      = self.entity.jid.getDomain()
            answer      = self.xmlrpc_server.srg_list({"host": server})
            groups      = answer["groups"]
            groupsNode  = []

            for group in groups:
                answer          = self.xmlrpc_server.srg_get_info({"host": server, "group": group["id"]})
                informations    = answer["informations"]
                for info in informations:
                    if info['information'][0]["key"] == "name":
                        displayed_name = info['information'][1]["value"]
                    if info['information'][0]["key"] == "description":
                        description = info['information'][1]["value"]
                info    = {"id": group["id"], "displayed_name": displayed_name.replace("\"", ""), "description": description.replace("\"", "")}
                newNode = xmpp.Node("group", attrs=info)
                answer  = self.xmlrpc_server.srg_get_members({"host": server, "group": group["id"]})
                members = answer["members"]
                for member in members:
                    newNode.addChild("user", attrs={"jid": member["member"]})
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
            reply       = iq.buildReply("result")
            groupID     = iq.getTag("query").getTag("archipel").getAttr("groupid")
            users       = iq.getTag("query").getTag("archipel").getTags("user")
            server      = self.entity.jid.getDomain()
            for user in users:
                userJID = xmpp.JID(user.getAttr("jid"))
                answer  = self.xmlrpc_server.srg_user_add({"user": userJID.getNode(), "host": userJID.getDomain(), "group": groupID, "grouphost": server})
                if not answer['res'] == 0:
                    raise Exception("Cannot add user to shared roster group.")
                self.entity.log.info("Adding user %s into shared group %s" % (userJID, groupID))
            self.entity.push_change("xmppserver:groups", "usersadded")
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
            reply       = iq.buildReply("result")
            groupID     = iq.getTag("query").getTag("archipel").getAttr("groupid")
            users       = iq.getTag("query").getTag("archipel").getTags("user")
            server      = self.entity.jid.getDomain()
            for user in users:
                userJID = xmpp.JID(user.getAttr("jid"))
                answer  = self.xmlrpc_server.srg_user_del({"user": userJID.getNode(), "host": userJID.getDomain(), "group": groupID, "grouphost": server})
                if not answer['res'] == 0:
                    raise Exception("Cannot remove user from shared roster group.")
                self.entity.log.info("Removing user %s from shared group %s" % (userJID, groupID))
            self.entity.push_change("xmppserver:groups", "usersdeleted")
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
            reply       = iq.buildReply("result")
            users       = iq.getTag("query").getTag("archipel").getTags("user")
            server      = self.entity.jid.getDomain()
            for user in users:
                username    = user.getAttr("username")
                password    = user.getAttr("password")
                answer      = self.xmlrpc_server.register({"user": username, "password": password, "host": server})
                if not answer['res'] == 0:
                    raise Exception("Cannot register new user.")
                self.entity.log.info("Registred a new user %s@%s" % (username, server))
            self.entity.push_change("xmppserver:users", "registered")
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
            reply       = iq.buildReply("result")
            users       = iq.getTag("query").getTag("archipel").getTags("user")
            server      = self.entity.jid.getDomain()
            for user in users:
                username    = user.getAttr("username")
                answer      = self.xmlrpc_server.unregister({"user": username,"host": server})
                if not answer['res'] == 0:
                    raise Exception("Cannot unregister user.")
                self.entity.log.info("Unregistred user %s@%s" % (username, server))
            self.entity.push_change("xmppserver:users", "unregistered")
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
            reply       = iq.buildReply("result")
            server      = self.entity.jid.getDomain()
            answer      = self.xmlrpc_server.registered_users({"host": server})
            nodes       = []
            users       = answer["users"]
            for user in users:
                entity_type = "human"
                try:
                    answer = self.xmlrpc_server.get_vcard({"host": server, "user": user["username"], "name" : "ROLE"})
                    if answer["content"] in ("hypervisor", "virtualmachine"):
                        entity_type = answer["content"]
                except:
                    pass
                nodes.append(xmpp.Node("user", attrs={"jid": "%s@%s" % (user["username"], server), "type": entity_type}))
            reply.setQueryPayload(nodes)
        except Exception as ex:
            reply = build_error_iq(self, ex, iq, ARCHIPEL_ERROR_CODE_XMPPSERVER_USERS_LIST)
        return reply