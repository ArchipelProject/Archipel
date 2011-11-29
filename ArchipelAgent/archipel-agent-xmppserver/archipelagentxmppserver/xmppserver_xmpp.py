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
import xmppserver_base



class TNXMPPServerController (xmppserver_base.TNXMPPServerControllerBase):

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
        xmppserver_base.TNXMPPServerControllerBase.__init__(self, configuration, entity, entry_point_group)
        self.users = []
        self.need_user_refresh = True
        self.entities_types_cache = {}
        self.entity.log.info("XMPPSERVER: module is using XMPP API for managing XMPP server")


    ## Utils

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
            if vcard_role in ("hypervisor", "virtualmachine"):
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
                            self.entity.xmppclient.SendAndCallForResponse(iq_page, manage_received_users)
                    else:
                        manage_received_users(conn, iq)

                except Exception as ex:
                    self.entity.log.error("XMPPSERVER: Unable to manage to get users or their vcards. error is %s" % str(ex))

            user_iq = xmpp.Iq(typ="get", to=xmppserver)
            user_iq.addChild("query", attrs={"node": "all users"}, namespace="http://jabber.org/protocol/disco#items")
            self.entity.xmppclient.SendAndCallForResponse(user_iq, on_receive_users)

        iq = xmpp.Iq(typ="set", to=xmppserver)
        iq.addChild("command", attrs={"action": "execute", "node": "http://jabber.org/protocol/admin#get-registered-users-num"}, namespace="http://jabber.org/protocol/commands")
        self.entity.xmppclient.SendAndCallForResponse(iq, on_receive_users_num)


    ## TNXMPPServerControllerBase implementation

    def users_register(self, users):
        """
        Reister new users
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
            self.entity.xmppclient.SendAndCallForResponse(iq, on_receive_registration)
            self.entity.log.info("XMPPSERVER: Registering a new user %s@%s" % (user["jid"], server))

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
        self.entity.xmppclient.SendAndCallForResponse(iq, on_receive_unregistration)
        self.entity.log.info("XMPPSERVER: Unregistring some users %s" % str(users))

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
            self.entity.xmppclient.send(base_reply)
        if self.need_user_refresh:
            self._fetch_users(self.entity.jid.getDomain(), send_filtered_users, {"base_reply": base_reply})
        else:
            send_filtered_users(base_reply)

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

    def handle_autogroup_on_alloc(self, origin, user_info, newvm):
        """
        Not supported in XMPP API
        """
        pass

    def create_autogroup_if_needed(self, origin, user_info, parameters):
        """
        Not supported in XMPP API
        """
        pass

    def handle_autogroup_on_vm_wake_up(self, origin, user_info, vm):
        """
        Not supported in XMPP API
        """
        pass