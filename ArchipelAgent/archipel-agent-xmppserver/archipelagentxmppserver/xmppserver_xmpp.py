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

from archipelcore.utils import build_error_iq
from xmppserver_base import TNXMPPServerControllerBase


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

class TNXMPPServerController (TNXMPPServerControllerBase):

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
        TNXMPPServerControllerBase.__init__(self, configuration, entity, entry_point_group)

        self.entities_types_cache = {}
        self.entity.log.info("XMPPSERVER: module is using XMPP API for managing XMPP server")


    ## TNXMPPServerControllerBase implementation

    def users_register(self, users):
        """
        Reister new users
        @type users: list
        @param users: list of users to register
        """
        def on_receive_registration(conn, iq):
            if iq.getType() == "result":
                self.entity.log.info("XMPPSERVER: Successfully registred user.")
                self.entity.log.debug("XMPPSERVER: Caching entity type %s as human" % iq.getFrom().getStripped())
                self.entity.push_change("xmppserver:users", "registered")
            else:
                self.entity.push_change("xmppserver:users", "registerationerror", content_node=iq)
                self.entity.log.error("XMPPSERVER: Unable to register user. %s" % str(iq))
        server = self.entity.jid.getDomain()
        for user in users:
            username = user["username"]
            password = user["password"]
            iq_string = IQ_REGISTER_USER_FORM % (self.entity.jid.getDomain(), username, password, password, "", "", "")
            iq = xmpp.simplexml.NodeBuilder(data=iq_string).getDom()
            self.entity.xmppclient.SendAndCallForResponse(iq, on_receive_registration)
            self.entities_types_cache[username] = "human"
            self.entity.log.info("XMPPSERVER: Registring a new user %s@%s" % (username, server))

    def users_unregister(self, users):
        """
        Unregister users
        @type users: list
        @param users: list of users to unregister
        """
        def on_receive_unregistration(conn, iq):
            if iq.getType() == "result":
                self.entity.log.info("XMPPSERVER: Successfully unregistred user.")
                self.entity.push_change("xmppserver:users", "unregistered")
            else:
                self.entity.push_change("xmppserver:users", "unregisterationerror", content_node=iq)
                self.entity.log.error("XMPPSERVER: unable to unregister user. %s" % str(iq))
        server = self.entity.jid.getDomain()
        jids_string_nodes = ""
        for username in users:
            jid = "        <value>%s</value>\n" % username
            jids_string_nodes = "%s%s" % (jids_string_nodes, jid)
            if username in self.entities_types_cache:
                self.entity.log.debug("XMPPSERVER: uncaching entity type for %s" % username)
                del self.entities_types_cache[username]
        iq_string = IQ_UNREGISTRATION_FORM % (self.entity.jid.getDomain(), jids_string_nodes)
        iq = xmpp.simplexml.NodeBuilder(data=iq_string).getDom()
        self.entity.xmppclient.SendAndCallForResponse(iq, on_receive_unregistration)
        self.entity.log.info("XMPPSERVER: Unregistring some users %s" % str(users))

    def users_list(self):
        """
        List all registered users
        """
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

    def group_create(self, ID, name, description):
        """
        Not supported in XMPP API
        """
        raise Exception("Shared roster group support is not implemented with XMPP API for now")

    def group_delete(self, ID):
        """
        Not supported in XMPP API
        """
        raise Exception("Shared roster group support is not implemented with XMPP API for now")

    def group_list(self):
        """
        Not supported in XMPP API
        """
        raise Exception("Shared roster group support is not implemented with XMPP API for now")

    def group_add_users(self, ID, users):
        """
        Not supported in XMPP API
        """
        raise Exception("Shared roster group support is not implemented with XMPP API for now")

    def group_delete_users(self, ID, users):
        """
        Not supported in XMPP API
        """
        raise Exception("Shared roster group support is not implemented with XMPP API for now")


    ### Overrides

    def iq_users_list(self, iq):
        """
        We overrides this method here because in XMPP
        we fetch the list of users using a asynchrnoous way

        List all registered users.
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ
        @rtype: xmpp.Protocol.Iq
        @return: a ready to send IQ containing the result of the action
        """
        try:
            reply = iq.buildReply("result")
            self.users_list()
        except Exception as ex:
            reply = build_error_iq(self, ex, iq, ARCHIPEL_ERROR_CODE_XMPPSERVER_USERS_LIST)
        return reply