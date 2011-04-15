# -*- coding: utf-8 -*-
#
# archipelRosterQueryableEntity.py
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

ARCHIPEL_ERROR_CODE_GET_ROSTER          = -450001

ARCHIPEL_NS_ROSTER                      = "archipel:roster"


class TNRosterQueryableEntity (object):
    """
    TODO ADD description here
    """

    def __init__(self, configuration, permission_center, xmppclient, log):
        """
        Initialize the TNRosterQueryableEntity.
        @type configuration: configuration object
        @param configuration: the configuration
        @type permission_center: TNPermissionCenter
        @param permission_center: the permission center of the entity
        @type xmppclient: xmpp.Dispatcher
        @param xmppclient: the entity xmpp client
        @type log: TNArchipelLog
        @param log: the logger of the entity
        """
        self.configuration          = configuration
        self.permission_center      = permission_center
        self.xmppclient             = xmppclient
        self.log                    = log


    ### subclass must implement this

    def check_acp(conn, iq):
        """
        Function that verify if the ACP is valid.
        @type conn: xmpp.Dispatcher
        @param conn: the connection
        @type iq: xmpp.Protocol.Iq
        @param iq: the IQ to check
        @raise Exception: Exception if not implemented
        """
        raise Exception("Subclass of TNRosterQueryableEntity must implement check_acp.")

    def check_perm(self, conn, stanza, action_name, error_code=-1, prefix=""):
        """
        function that verify if the permissions are granted
        @type conn: xmpp.Dispatcher
        @param conn: the connection
        @type stanza: xmpp.Node
        @param stanza: the stanza containing the action
        @type action_name: string
        @param action_name: the action to check
        @type error_code: int
        @param error_code: the error code to return
        @type prefix: string
        @param prefix: the prefix of the action
        @raise Exception: Exception if not implemented
        """
        raise Exception("Subclass of TNRosterQueryableEntity must implement check_perm")

    def init_vocabulary(self):
        """
        Initialize the vocabulary.
        """
        item = {"commands" : ["roster", "users"],
                "parameters": [],
                "permissions": ["roster"],
                "method": self.message_roster,
                "description": "I'll give you the content of my roster"}
        self.add_message_registrar_item(item)


    def init_permissions(self):
        """
        Initialize the permissions.
        """
        self.permission_center.create_permission("roster", "Authorizes users to get the content of my roster", False)

    def register_handlers(self):
        """
        initialize the avatar handlers
        """
        self.xmppclient.RegisterHandler('iq', self.process_roster_iq, ns=ARCHIPEL_NS_ROSTER)

    def unregister_handlers(self):
        """
        initialize the avatar handlers
        """
        self.xmppclient.UnregisterHandler('iq', self.process_roster_iq, ns=ARCHIPEL_NS_ROSTER)


    def process_roster_iq(self, conn, iq):
        """
        This method is invoked when a ARCHIPEL_NS_ROSTER IQ is received.
        It understands IQ of type:
            - getroster
        @type conn: xmpp.Dispatcher
        @param conn: ths instance of the current connection that send the stanza
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ
        """
        reply = None
        action = self.check_acp(conn, iq)
        self.check_perm(conn, iq, action, -1)
        if action == "getroster":
            reply = self.iq_get_roster(iq)
        if reply:
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed

    def iq_get_roster(self, iq):
        """
        Return the content of the roster.
        @type iq: xmpp.Protocol.Iq
        @param iq: the IQ containing the request
        """
        try:
            reply = iq.buildReply("result")
            # reply.setQueryPayload([self.get_available_avatars()])
        except Exception as ex:
            reply = build_error_iq(self, ex, iq, ARCHIPEL_ERROR_CODE_GET_ROSTER)
        return reply

    def message_roster(self, msg):
        """
        Handle roster asking message.
        @type msg: xmpp.Protocol.Message
        @param msg: the received message
        @rtype: xmpp.Protocol.Message
        @return: a ready to send Message containing the result of the action
        """
        ret = "Here is the content of my roster : \n"
        for barejid in self.roster.getItems():
            if self.jid.getStripped() == barejid:
                continue
            ret = "%s    - %s\n" % (ret, barejid)
        return ret
