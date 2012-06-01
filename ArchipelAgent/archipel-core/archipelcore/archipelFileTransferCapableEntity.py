# -*- coding: utf-8 -*-
#
# archipelFileTransferCapableEntity.py
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
import socket
import hashlib

from archipelcore.utils import build_error_iq



class TNFileTransferCapableEntity (object):
    """
    This class allow ArchipelEntity to handle file transfer.
    ** This is work in progress. It's not working for now **
    """

    def __init__(self, jid, xmppclient, permission_center, log):
        """
        Initialize the TNFileTransferCapableEntity.
        @type jid: string
        @param jid: the JID of the current entity
        @type xmppclient: xmpp.Dispatcher
        @param xmppclient: the entity xmpp client
        @type permission_center: TNPermissionCenter
        @param permission_center: the permission center of the entity
        @type log: TNArchipelLog
        @param log: the logger of the entity
        """
        self.xmppclient         = xmppclient
        self.permission_center  = permission_center
        self.jid                = jid
        self.log                = log
        self.current_sids       = {}

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
        raise Exception("Subclass of TNFileTransferCapableEntity must implement check_acp.")

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
        raise Exception("Subclass of TNFileTransferCapableEntity must implement check_perm.")


    ### Pubsub

    def init_permissions(self):
        """
        Initialize the tag permissions.
        """
        self.permission_center.create_permission("sendfiles", "Authorizes users to send files to entity", False)

    def register_handlers(self):
        """
        Initialize the handlers for tags.
        """
        pass # deactivated
        # self.xmppclient.RegisterHandler('iq', self.process_disco_request, ns="http://jabber.org/protocol/disco#info")
        # self.xmppclient.RegisterHandler('iq', self.process_si_request, ns="http://jabber.org/protocol/si")
        # self.xmppclient.RegisterHandler('iq', self.process_bytestream_request, ns="http://jabber.org/protocol/bytestreams")

    def unregister_handlers(self):
        """
        Unregister the handlers for tags.
        """
        pass # deactivated
        # self.xmppclient.UnegisterHandler('iq', self.process_disco_request, ns="http://jabber.org/protocol/disco#info")
        # self.xmppclient.UnregisterHandler('iq', self.process_si_request, ns="http://jabber.org/protocol/si")
        # self.xmppclient.UnegisterHandler('iq', self.process_bytestream_request, ns="http://jabber.org/protocol/bytestreams")


    ### Tags

    def process_disco_request(self, conn, iq):
        """
        This method is invoked when a http://jabber.org/protocol/disco#info IQ is received.
        @type conn: xmpp.Dispatcher
        @param conn: ths instance of the current connection that send the stanza
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ
        """
        reply = iq.buildReply("result")
        reply.getTag("query").addChild("identity", attrs={"category": "client", "type": "pc"})
        reply.getTag("query").addChild("feature", attrs={"var": "http://jabber.org/protocol/bytestreams"})
        conn.send(reply)
        raise xmpp.protocol.NodeProcessed

    def process_si_request(self, conn, iq):
        """
        This method is invoked when a http://jabber.org/protocol/si IQ is received.
        @type conn: xmpp.Dispatcher
        @param conn: ths instance of the current connection that send the stanza
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ
        """
        if not iq.getTag("si").getAttr("profile") == "http://jabber.org/protocol/si/profile/file-transfer":
            return
        self.check_perm(conn, iq, "sendfiles", -1)

        file_name = iq.getTag("si").getTag("file").getAttr("name")
        file_size = iq.getTag("si").getTag("file").getAttr("size")
        sender_jid = iq.getFrom()
        sid = iq.getTag("si").getAttr("id")

        self.current_sids[sid] = {"name": file_name, "size": file_size, "sender": sender_jid}

        reply = iq.buildReply("result")
        node_feature = reply.getTag("si").addChild("feature", namespace="http://jabber.org/protocol/feature-neg")
        node_x = node_feature.addChild("x", namespace="jabber:x:data", attrs={"type": "submit"})
        node_field = node_x.addChild("field", attrs={"var": "stream-method"})
        node_value = node_field.addChild("value")
        node_value.setData("http://jabber.org/protocol/bytestreams")

        self.log.info("file system request from %s: %s (%s bytes)" % (sender_jid, file_name, file_size))
        conn.send(reply)
        raise xmpp.protocol.NodeProcessed

    def process_bytestream_request(self, conn, iq):
        """
        This method is invoked when a http://jabber.org/protocol/bytestreams IQ is received.
        @type conn: xmpp.Dispatcher
        @param conn: ths instance of the current connection that send the stanza
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ
        """
        remote_host = iq.getTag("query").getTag("streamhost").getAttr("host")
        remote_port = iq.getTag("query").getTag("streamhost").getAttr("port")
        sid = iq.getTag("query").getAttr("sid")

        sock_host = "%s%s%s" % (sid, str(iq.getFrom()), str(iq.getTo()))
        sha1_hash = hashlib.sha1(sock_host).hexdigest()
        print "HASH %s" % sha1_hash
        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)

        s.connect((remote_host, int(remote_port)))

        #"CMD = X'01'\nATYP = X'03'\nDST.ADDR = %s\nDST.PORT = 0" % sha1_hash)
        s.send("\x05\x01\x00\x03\x03%s%s\x00\x00" % (chr(len(sha1_hash)), sha1_hash))

        data = s.recv(2)

        resp = iq.buildReply("result")
        resp.getTag("query").addChild("streamhost-used", attrs={"jid": str(iq.getFrom())})
        self.xmppclient.send(resp)
        raise xmpp.protocol.NodeProcessed
