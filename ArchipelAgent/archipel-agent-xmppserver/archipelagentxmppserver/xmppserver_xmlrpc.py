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

from archipelcore.utils import build_error_iq
from xmppserver_base import TNXMPPServerControllerBase

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
        TNXMPPServerControllerBase.__init__(self, configuration=configuration, entity=entity, entry_point_group=entry_point_group)
        self.xmpp_server        = entity.jid.getDomain()
        self.xmlrpc_host        = self.configuration.get("XMPPSERVER", "xmlrpc_host")
        self.xmlrpc_port        = self.configuration.getint("XMPPSERVER", "xmlrpc_port")
        self.xmlrpc_user        = self.configuration.get("XMPPSERVER", "xmlrpc_user")
        self.xmlrpc_password    = self.configuration.get("XMPPSERVER", "xmlrpc_password")
        self.xmlrpc_call        = "http://%s:%s@%s:%s/" % (self.xmlrpc_user, self.xmlrpc_password, self.xmlrpc_host, self.xmlrpc_port)
        self.xmlrpc_server      = xmlrpclib.ServerProxy(self.xmlrpc_call)
        self.entity.log.info("XMPPSERVER: Module is using XMLRPC API for managing XMPP server")


    ## TNXMPPServerControllerBase implementation

    def users_register(self, users):
        """
        Reister new users
        @type users: list
        @param users: list of users to register
        """
        server = self.entity.jid.getDomain()
        for user in users:
            answer = self.xmlrpc_server.register({"user": user["jid"].getNode(), "password": user["password"], "host": server})
            if not answer['res'] == 0:
                raise Exception("Cannot register new user. %s" % str(answer))
            self.entity.log.info("XMPPSERVER: Registered a new user %s@%s" % (user["jid"].getNode(), server))
        self.entity.push_change("xmppserver:users", "registered")
        return True

    def users_unregister(self, users):
        """
        Unregister users
        @type users: list
        @param users: list of users to unregister
        """
        server = self.entity.jid.getDomain()
        for jid in users:
            answer = self.xmlrpc_server.unregister({"user": jid.getNode(),"host": server})
            if not answer['res'] == 0:
                raise Exception("Cannot unregister user. %s" % str(answer))
            self.entity.log.info("XMPPSERVER: Unregistered user %s@%s" % (jid.getNode(), server))
        self.entity.push_change("xmppserver:users", "unregistered")
        return True

    def users_number(self, base_reply, only_humans=True):
        """
        Return total number of registered users
        """
        server = self.entity.jid.getDomain()
        answer = self.xmlrpc_server.registered_users({"host": server})
        n = 0
        if not only_humans:
            n = len(answer["users"])
        else:
            users = answer["users"]
            for user in users:
                entity_type = "human"
                try:
                    answer = self.xmlrpc_server.get_vcard({"host": server, "user": user["username"], "name" : "ROLE"})
                    if not answer["content"] in ("hypervisor", "virtualmachine"):
                        n = n + 1
                except:
                    n = n + 1
        base_reply.setQueryPayload([xmpp.Node("users", attrs={"total": n})])
        self.entity.xmppclient.send(base_reply)

    def users_list(self, base_reply, page, only_humans=True):
        """
        List all registered users
        """
        server = self.entity.jid.getDomain()
        answer = self.xmlrpc_server.registered_users({"host": server})
        nodes = []
        bound_begin = page * self.user_page_size
        bound_end = bound_begin + self.user_page_size
        users = sorted(answer["users"], cmp=lambda x, y: cmp(x["username"], y["username"]))[bound_begin:bound_end]
        for user in users:
            entity_type = "human"
            try:
                answer = self.xmlrpc_server.get_vcard({"host": server, "user": user["username"], "name" : "ROLE"})
                if answer["content"] in ("hypervisor", "virtualmachine"):
                    entity_type = answer["content"]
                if only_humans and not entity_type == "human":
                    continue
            except:
                pass
            nodes.append(xmpp.Node("user", attrs={"jid": "%s@%s" % (user["username"], server), "type": entity_type}))
        base_reply.setQueryPayload(nodes)
        self.entity.xmppclient.send(base_reply)

    def users_filter(self, base_reply, filterString):
        """
        Filter all registered users.
        """
        server = self.entity.jid.getDomain()
        answer = self.xmlrpc_server.registered_users({"host": server})
        nodes = []
        users = sorted(answer["users"], cmp=lambda x, y: cmp(x["username"], y["username"]))
        for user in users:
            if not user["username"].upper().find(filterString.upper()) > -1:
                continue
            entity_type = "human"
            try:
                answer = self.xmlrpc_server.get_vcard({"host": server, "user": user["username"], "name" : "ROLE"})
                if answer["content"] in ("hypervisor", "virtualmachine"):
                    entity_type = answer["content"]
            except:
                pass
            nodes.append(xmpp.Node("user", attrs={"jid": "%s@%s" % (user["username"], server), "type": entity_type}))
        base_reply.setQueryPayload(nodes)
        self.entity.xmppclient.send(base_reply)

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
        server = self.entity.jid.getDomain()
        answer = self.xmlrpc_server.srg_create({"host": server, "display": ID, "name": name, "description": description, "group": ID})
        if not answer['res'] == 0:
            raise Exception("Cannot create shared roster group. %s" % str(answer))
        self.entity.log.info("XMPPSERVER: Creating a new shared group %s" % ID)
        self.entity.push_change("xmppserver:groups", "created")
        return True

    def group_delete(self, ID):
        """
        Destroy a shared roster group
        @type ID: string
        @param ID: the ID of the group to delete
        """
        server = self.entity.jid.getDomain()
        answer = self.xmlrpc_server.srg_delete({"host": server, "group": ID})
        if not answer['res'] == 0:
            raise Exception("Cannot create shared roster group. %s" % str(answer))
        self.entity.log.info("XMPPSERVER: Removing a shared group %s" % ID)
        self.entity.push_change("xmppserver:groups", "deleted")

    def group_list(self):
        """
        Returns a list of existing groups
        """
        server = self.entity.jid.getDomain()
        answer = self.xmlrpc_server.srg_list({"host": server})
        groups = answer["groups"]
        ret = []

        for group in groups:
            answer = self.xmlrpc_server.srg_get_info({"host": server, "group": group["id"]})
            informations = answer["informations"]
            for info in informations:
                if info['information'][0]["key"] == "name":
                    displayed_name = info['information'][1]["value"]
                if info['information'][0]["key"] == "description":
                    description = info['information'][1]["value"]
            info = {"id": group["id"], "displayed_name": displayed_name.replace("\"", ""), "description": description.replace("\"", ""), "members": []}
            answer  = self.xmlrpc_server.srg_get_members({"host": server, "group": group["id"]})
            members = answer["members"]
            for member in members:
                info["members"].append(member["member"])
            ret.append(info)
        return ret

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
            answer = self.xmlrpc_server.srg_user_add({"user": userJID.getNode(), "host": userJID.getDomain(), "group": ID, "grouphost": server})
            if not answer['res'] == 0:
                raise Exception("Cannot add user to shared roster group. %s" % str(answer))
            self.entity.log.info("XMPPSERVER: Adding user %s into shared group %s" % (userJID, ID))
        self.entity.push_change("xmppserver:groups", "usersadded")

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
            answer  = self.xmlrpc_server.srg_user_del({"user": userJID.getNode(), "host": userJID.getDomain(), "group": ID, "grouphost": server})
            if not answer['res'] == 0:
                raise Exception("Cannot remove user from shared roster group. %s" % str(answer))
            self.entity.log.info("XMPPSERVER: Removing user %s from shared group %s" % (userJID, ID))
        self.entity.push_change("xmppserver:groups", "usersdeleted")
