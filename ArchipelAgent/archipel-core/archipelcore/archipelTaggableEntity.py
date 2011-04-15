# -*- coding: utf-8 -*-
#
# archipelTaggableEntity.py
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

from archipelcore.pubsub import TNPubSubNode
from archipelcore.utils import build_error_iq


ARCHIPEL_ERROR_CODE_SET_TAGS            = -7
ARCHIPEL_NS_TAGS                                = "archipel:tags"


class TNTaggableEntity (object):
    """
    This class allow ArchipelEntity to be taggable.
    """

    def __init__(self, pubsubserver, jid, xmppclient, permission_center, log):
        """
        Initialize the TNTaggableEntity.
        @type pubsubserver: string
        @param pubsubserver: the JID of the pubsub server
        @type jid: string
        @param jid: the JID of the current entity
        @type xmppclient: xmpp.Dispatcher
        @param xmppclient: the entity xmpp client
        @type permission_center: TNPermissionCenter
        @param permission_center: the permission center of the entity
        @type log: TNArchipelLog
        @param log: the logger of the entity
        """
        self.pubSubNodeTags     = None
        self.pubsubserver       = pubsubserver
        self.xmppclient         = xmppclient
        self.permission_center  = permission_center
        self.jid                = jid
        self.log                = log

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
        raise Exception("Subclass of TNTaggableEntity must implement check_acp.")

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
        raise Exception("Subclass of TNTaggableEntity must implement check_perm.")


    ### Pubsub

    def recover_pubsubs(self, origin, user_info, arguments):
        """
        Get the global tag pubsub node.
        Arguments here are used to be HOOK compliant see register_hook of L{TNHookableEntity}
        """
        # getting the tags pubsub node
        tagsNodeName = "/archipel/tags"
        self.pubSubNodeTags = TNPubSubNode(self.xmppclient, self.pubsubserver, tagsNodeName)
        if not self.pubSubNodeTags.recover(wait=True):
            Exception("The pubsub node /archipel/tags must have been created. You can use archipel-tagnode tool to create it.")

    def init_permissions(self):
        """
        Initialize the tag permissions.
        """
        self.permission_center.create_permission("settags", "Authorizes users to modify entity's tags", False)

    def register_handlers(self):
        """
        Initialize the handlers for tags.
        """
        self.xmppclient.RegisterHandler('iq', self.process_tags_iq, ns=ARCHIPEL_NS_TAGS)

    def unregister_handlers(self):
        """
        Unregister the handlers for tags.
        """
        self.xmppclient.UnregisterHandler('iq', self.process_tags_iq, ns=ARCHIPEL_NS_TAGS)

    ### Tags

    def process_tags_iq(self, conn, iq):
        """
        This method is invoked when a ARCHIPEL_NS_TAGS IQ is received.
        It understands IQ of type:
            - settags
        @type conn: xmpp.Dispatcher
        @param conn: ths instance of the current connection that send the stanza
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ
        """
        action = self.check_acp(conn, iq)
        self.check_perm(conn, iq, action, -1)
        if action == "settags":
            reply = self.iq_set_tags(iq)
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed

    def set_tags(self, tags):
        """
        Set the tags of the current entity.
        @type tags: string
        @param tags: the string containing tags separated by ';;'
        """
        current_id = None
        for item in self.pubSubNodeTags.get_items():
            if item.getTag("tag") and item.getTag("tag").getAttr("jid") == self.jid.getStripped():
                current_id = item.getAttr("id")
        if current_id:
            self.pubSubNodeTags.remove_item(current_id, callback=self.did_clean_old_tags, user_info=tags)
        else:
            tagNode = xmpp.Node(tag="tag", attrs={"jid": self.jid.getStripped(), "tags": tags})
            self.pubSubNodeTags.add_item(tagNode)

    def did_clean_old_tags(self, resp, user_info):
        """
        Callback called when old tags has been removed if any.
        @raise Exception: Exception if not implemented
        """
        if resp.getType() == "result":
            tagNode = xmpp.Node(tag="tag", attrs={"jid": self.jid.getStripped(), "tags": user_info})
            self.pubSubNodeTags.add_item(tagNode)
        else:
            raise Exception("Tags unable to set tags. answer is: " + str(resp))

    def iq_set_tags(self, iq):
        """
        Set the current tag.
        @type iq: xmpp.Protocol.IQ
        @param iq: the IQ containing the request
        @rtype: xmpp.Protocol.IQ
        @return: the IQ containing the answer
        """
        try:
            reply = iq.buildReply("result")
            tags = iq.getTag("query").getTag("archipel").getAttr("tags")
            self.set_tags(tags)
        except Exception as ex:
            reply = build_error_iq(self, ex, iq, ARCHIPEL_ERROR_CODE_SET_TAGS)
        return reply