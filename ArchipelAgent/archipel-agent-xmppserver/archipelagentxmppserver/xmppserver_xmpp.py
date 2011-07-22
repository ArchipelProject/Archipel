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

import re
import subprocess
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

IQ_REGISTER_USER_FORM = """
<iq to='%s' type='set'>
  <command xmlns='http://jabber.org/protocol/commands' node='http://jabber.org/protocol/admin#add-user'>
    <x xmlns='jabber:x:data' type='submit'>
      <field type='hidden' var='FORM_TYPE'>
        <value>http://jabber.org/protocol/admin</value>
      </field>
      <field var='accountjid'>
        <value>%s</value>
      </field>
      <field var='password'>
        <value>%s</value>
      </field>
      <field var='password-verify'>
        <value>%s</value>
      </field>
      <field var='email'>
        <value>%s</value>
      </field>
      <field var='given_name'>
        <value>%s</value>
      </field>
      <field var='surname'>
        <value>%s</value>
      </field>
    </x>
  </command>
</iq>
"""

IQ_UNREGISTRATION_FORM = """
<iq to='%s' type='set'>
  <command xmlns='http://jabber.org/protocol/commands' node='http://jabber.org/protocol/admin#delete-user'>
    <x xmlns='jabber:x:data' type='submit'>
      <field type='hidden' var='FORM_TYPE'>
        <value>http://jabber.org/protocol/admin</value>
      </field>
      <field var='accountjids'>
%s
      </field>
    </x>
  </command>
</iq>
"""

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
        self.entities_types_cache = {}

        self.entity.log.info("XMPPSERVER: module is using XMPP API for managing XMPP server")

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
            raise Exception("Shared roster group support is not implemented with XMPP API for now")
        except Exception as ex:
            reply = build_error_iq(self, ex, iq)
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
            raise Exception("Shared roster group support is not implemented with XMPP API for now")
        except Exception as ex:
            reply = build_error_iq(self, ex, iq)
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
            raise Exception("Shared roster group support is not implemented with XMPP API for now")
        except Exception as ex:
            reply = build_error_iq(self, ex, iq)
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
            raise Exception("Shared roster group support is not implemented with XMPP API for now")
        except Exception as ex:
            reply = build_error_iq(self, ex, iq)
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
            raise Exception("Shared roster group support is not implemented with XMPP API for now")
        except Exception as ex:
            reply = build_error_iq(self, ex, iq)
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
            def on_receive_registration(conn, iq):
                if iq.getType() == "result":
                    self.entity.log.info("XMPPSERVER: Successfully registred user.")
                    self.entity.log.debug("XMPPSERVER: Caching entity type %s as human" % iq.getFrom().getStripped())
                    self.entity.push_change("xmppserver:users", "registered")
                else:
                    self.entity.push_change("xmppserver:users", "registerationerror", content_node=iq)
                    self.entity.log.error("XMPPSERVER: Unable to register user. %s" % str(iq))
            reply = iq.buildReply("result")
            users = iq.getTag("query").getTag("archipel").getTags("user")
            server = self.entity.jid.getDomain()
            for user in users:
                username    = user.getAttr("username")
                password    = user.getAttr("password")
                iq_string = IQ_REGISTER_USER_FORM % (self.entity.jid.getDomain(), username, password, password, "", "", "")
                iq = xmpp.simplexml.NodeBuilder(data=iq_string).getDom()
                self.entity.xmppclient.SendAndCallForResponse(iq, on_receive_registration)
                self.entities_types_cache[username] = "human"
                self.entity.log.info("XMPPSERVER: Registring a new user %s@%s" % (username, server))
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
            def on_receive_unregistration(conn, iq):
                if iq.getType() == "result":
                    self.entity.log.info("XMPPSERVER: Successfully unregistred user.")
                    self.entity.push_change("xmppserver:users", "unregistered")
                else:
                    self.entity.push_change("xmppserver:users", "unregisterationerror", content_node=iq)
                    self.entity.log.error("XMPPSERVER: unable to unregister user. %s" % str(iq))
            reply = iq.buildReply("result")
            users = iq.getTag("query").getTag("archipel").getTags("user")
            server = self.entity.jid.getDomain()
            jids_string_nodes = ""
            for user in users:
                username    = user.getAttr("username")
                jid = "        <value>%s</value>\n" % username
                jids_string_nodes = "%s%s" % (jids_string_nodes, jid)
                if username in self.entities_types_cache:
                    self.entity.log.debug("XMPPSERVER: uncaching entity type for %s" % username)
                    del self.entities_types_cache[username]
            iq_string = IQ_UNREGISTRATION_FORM % (self.entity.jid.getDomain(), jids_string_nodes)
            iq = xmpp.simplexml.NodeBuilder(data=iq_string).getDom()
            self.entity.xmppclient.SendAndCallForResponse(iq, on_receive_unregistration)
            self.entity.log.info("XMPPSERVER: Unregistring some users %s" % str(users))

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

            def on_receive_users(conn, iq):
                if not iq.getType() == "result":
                    return
                try:
                    items = iq.getTag("query").getTags("item")
                    users = map(lambda x: x.getAttr("jid"), items)
                    nodes = []
                    number_of_users = len(users)
                    number_of_vcards = 0

                    def on_receive_vcard(conn, iq):
                        try:
                            if not iq.getType() == "result":
                                return
                            entity_type = "human"
                            if iq.getTag("vCard") and iq.getTag("vCard").getTag("ROLE"):
                                vcard_role = iq.getTag("vCard").getTag("ROLE").getData()
                                if vcard_role in ("hypervisor", "virtualmachine"):
                                    entity_type = vcard_role
                            self.entities_types_cache[iq.getFrom().getStripped()] = entity_type
                            nodes.append(xmpp.Node("user", attrs={"jid": iq.getFrom().getStripped(), "type": entity_type}))
                            if len(nodes) >= number_of_users:
                                self.entity.push_change("xmppserver:users", "listfetched", content_node=xmpp.Node("users", payload=nodes))
                        except Exception as ex:
                            self.entity.log.error("XMPPSERVER: Error while fetching contact vCard: %s" % str(ex))
                            self.entity.push_change("xmppserver:users", "listfetcherror", content_node=iq)

                    for user in users:
                        iq_vcard = xmpp.Iq(typ="get", to=user)
                        iq_vcard.addChild("vCard", namespace="vcard-temp")
                        if not user in self.entities_types_cache:
                            self.entity.log.debug("XMPPSERVER: Entity type of %s is not cached. fetching..." % user)
                            self.entity.xmppclient.SendAndCallForResponse(iq_vcard, on_receive_vcard)
                        else:
                            self.entity.log.debug("XMPPSERVER: Entity type of %s is already cached (%s)" % (user, self.entities_types_cache[user]))
                            nodes.append(xmpp.Node("user", attrs={"jid": user, "type": self.entities_types_cache[user]}))
                            if len(nodes) >= number_of_users:
                                self.entity.push_change("xmppserver:users", "listfetched", content_node=xmpp.Node("users", payload=nodes))

                except Exception as ex:
                    self.entity.log.error("XMPPSERVER: Unable to manage to get users or their vcards. error is %s" % str(ex))

            user_iq = xmpp.Iq(typ="get", to=self.entity.jid.getDomain())
            user_iq.addChild("query", attrs={"node": "all users"}, namespace="http://jabber.org/protocol/disco#items")
            self.entity.xmppclient.SendAndCallForResponse(user_iq, on_receive_users)

        except Exception as ex:
            reply = build_error_iq(self, ex, iq, ARCHIPEL_ERROR_CODE_XMPPSERVER_USERS_LIST)
        return reply