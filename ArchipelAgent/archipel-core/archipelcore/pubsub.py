# -*- coding: utf-8 -*-
#
# pubsub.py
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

import types
import xmpp


XMPP_PUBSUB_VAR_TITLE                                       = "pubsub#title"
XMPP_PUBSUB_VAR_DELIVER_NOTIFICATION                        = "pubsub#deliver_notifications"
XMPP_PUBSUB_VAR_DELIVER_PAYLOADS                            = "pubsub#deliver_payloads"
XMPP_PUBSUB_VAR_PERSIST_ITEMS                               = "pubsub#persist_items"
XMPP_PUBSUB_VAR_MAX_ITEMS                                   = "pubsub#max_items"
XMPP_PUBSUB_VAR_ITEM_EXPIRE                                 = "pubsub#item_expire"
XMPP_PUBSUB_VAR_ACCESS_MODEL                                = "pubsub#access_model"
XMPP_PUBSUB_VAR_ROSTER_GROUP_ALLOWED                        = "pubsub#roster_groups_allowed"
XMPP_PUBSUB_VAR_PUBLISH_MODEL                               = "pubsub#publish_model"
XMPP_PUBSUB_VAR_PURGE_OFFLINE                               = "pubsub#purge_offline"
XMPP_PUBSUB_VAR_SEND_LAST_PUBLISHED_ITEM                    = "pubsub#send_last_published_item"
XMPP_PUBSUB_VAR_PRESENCE_BASED_DELIVERY                     = "pubsub#presence_based_delivery"
XMPP_PUBSUB_VAR_NOTIFICATION_TYPE                           = "pubsub#notification_type"
XMPP_PUBSUB_VAR_NOTIFY_CONFIG                               = "pubsub#notify_config"
XMPP_PUBSUB_VAR_NOTIFY_DELETE                               = "pubsub#notify_delete"
XMPP_PUBSUB_VAR_NOTIFY_RECTRACT                             = "pubsub#notify_retract"
XMPP_PUBSUB_VAR_NOTIFY_SUB                                  = "pubsub#notify_sub"
XMPP_PUBSUB_VAR_MAX_PAYLOAD_SIZE                            = "pubsub#max_payload_size"
XMPP_PUBSUB_VAR_TYPE                                        = "pubsub#type"
XMPP_PUBSUB_VAR_BODY_XSLT                                   = "pubsub#body_xslt"
XMPP_PUBSUB_VAR_ITEM_REPLY                                  = "pubsub#itemreply"

XMPP_PUBSUB_VAR_ACCESS_MODEL_OPEN                           = "open"
XMPP_PUBSUB_VAR_ACCESS_MODEL_ROSTER                         = "roster"
XMPP_PUBSUB_VAR_ACCESS_MODEL_AUTHORIZE                      = "authorize"
XMPP_PUBSUB_VAR_ACCESS_MODEL_WHITELIST                      = "whitelist"
XMPP_PUBSUB_VAR_SEND_LAST_PUBLISHED_ITEM_NEVER              = "never"
XMPP_PUBSUB_VAR_SEND_LAST_PUBLISHED_ITEM_ON_SUB             = "on_sub"
XMPP_PUBSUB_VAR_SEND_LAST_PUBLISHED_ITEM_ON_SUB_PRESENCE    = "on_sub_and_presence"
XMPP_PUBSUB_VAR_ITEM_REPLY_OWNER                            = "owner"
XMPP_PUBSUB_VAR_ITEM_REPLY_PUBLISHER                        = "publisher"

XMPP_PUBSUB_AFFILIATION_OWNER                              = "owner"
XMPP_PUBSUB_AFFILIATION_PUBLISHER                          = "publisher"
XMPP_PUBSUB_AFFILIATION_PUBLISHERONLY                      = "publisher-only"
XMPP_PUBSUB_AFFILIATION_MEMBER                             = "member"
XMPP_PUBSUB_AFFILIATION_NONE                               = "none"
XMPP_PUBSUB_AFFILIATION_OUTCAST                            = "outcast"


class TNPubSubNode:

    def __init__(self, xmppclient, pubsubserver, nodename):
        """
        Initialize the TNPubSubNode.
        @type xmppclient: xmpp.Dispatcher
        @param xmppclient: the xmppclient connection to user
        @type pubsubserver: string
        @param xmppclient: the string containing the JID of the pubsub server
        @type nodename: string
        @param nodename: the name of the pubsub node
        """
        self.xmppclient     = xmppclient
        self.pubsubserver   = pubsubserver
        self.nodename       = nodename
        self.recovered      = False
        self.content        = None
        self.affiliations   = {}
        self.subscriptions  = []


    ### Node management

    def recover(self, wait=False):
        """
        Get the current pubsub node and wait for response. If not already recovered, ask to server.
        @type wait: Boolean
        @param wait: if True, recovering will be blockant (IE, execution interrupted until recovering)
        @rtype: Boolean
        @return: True in case of success
        """
        try:
            self.retrieve_items(wait=wait)
            return self.retrieve_items(wait=wait)
        except Exception as ex:
            return False

    def retrieve_items(self, callback=None, wait=False):
        """
        Retrieve or update the content of the node.
        @type wait: Boolean
        @param wait: if True, recovering will be blockant (IE, execution interrupted until recovering)
        @rtype: Boolean
        @return: True in case of success
        """
        iq           = xmpp.Iq(typ="get", to=self.pubsubserver)
        iq_pubsub    = iq.addChild(name='pubsub', namespace="http://jabber.org/protocol/pubsub")
        iq_pubsub.addChild(name="items", attrs={"node": self.nodename})

        def _did_retrieve_items(conn, resp, callback=None):
            ret = False
            if resp.getType() == "result":
                self.content = resp.getTag("pubsub").getTag("items").getTags("item")
                self.recovered = True
                ret = True
            if callback:
                callback(resp)
            return ret

        if wait:
            resp = self.xmppclient.SendAndWaitForResponse(iq)
            return _did_retrieve_items(None, resp, callback)
        else:
            self.xmppclient.SendAndCallForResponse(iq, func=_did_retrieve_items, args={"callback": callback})
            return True

    def create(self, callback=None, wait=False):
        """
        Create node on server if not exists.
        @type wait: Boolean
        @param wait: if True, recovering will be blockant (IE, execution interrupted until recovering)
        @rtype: Boolean
        @return: True in case of success
        """
        if self.recovered:
            raise Exception("PUBSUB: can't create. Node %s already exists." % self.nodename)

        iq = xmpp.Iq(typ="set", to=self.pubsubserver)
        iq.addChild(name="pubsub", namespace=xmpp.protocol.NS_PUBSUB).addChild(name="create", attrs={"node": self.nodename})

        def _did_create(conn, resp, callback=None, wait=False):
            ret = False
            if resp.getType() == "result":
                self.recover(wait=wait)
                ret = True
            if callback:
                callback(resp)
            return ret

        if wait:
            resp = self.xmppclient.SendAndWaitForResponse(iq)
            return _did_create(None, resp, callback, wait)
        else:
            self.xmppclient.SendAndCallForResponse(iq, func=_did_create, args={"callback": callback, "wait": wait})
            return True

    def delete(self, callback=None, wait=False):
        """
        Delete the node from server if exists.
        @type wait: Boolean
        @param wait: if True, recovering will be blockant (IE, execution interrupted until recovering)
        @rtype: Boolean
        @return: True in case of success
        """
        if not self.recovered:
            raise Exception("PUBSUB: Can't delete. Node %s doesn't exists." % self.nodename)
        iq = xmpp.Iq(typ="set", to=self.pubsubserver)
        iq.addChild(name="pubsub", namespace=xmpp.protocol.NS_PUBSUB + "#owner").addChild(name="delete", attrs={"node": self.nodename})

        def _did_delete(conn, resp, callback):
            ret = False
            if resp.getType() == "result":
                ret = True
            if callback:
                callback(resp)
            return ret

        if wait:
            resp = self.xmppclient.SendAndWaitForResponse(iq)
            return _did_delete(None, resp, callback)
        else:
            self.xmppclient.SendAndCallForResponse(iq, func=_did_delete, args={"callback": callback})
            return True

    def configure(self, options, callback=None, wait=False):
        """
        Configure the node.
        @type options: dict
        @param options: dictionary containing options: value for the pubsub configuration
        @type wait: Boolean
        @param wait: if True, recovering will be blockant (IE, execution interrupted until recovering)
        @rtype: Boolean
        @return: True in case of success
        """
        if not self.recovered:
            raise Exception("PUBSUB: can't configure. Node %s doesn't exists." % self.nodename)
        iq = xmpp.Iq(typ="set", to=self.pubsubserver)
        pubsub = iq.addChild("pubsub", namespace=xmpp.protocol.NS_PUBSUB + "#owner")
        configure = pubsub.addChild("configure", attrs={"node": self.nodename})
        x = configure.addChild("x", namespace=xmpp.protocol.NS_DATA, attrs={"type": "submit"})
        x.addChild("field", attrs={"var": "FORM_TYPE", "type": "hidden"}).addChild("value").setData("http://jabber.org/protocol/pubsub#node_config")
        for key, value in options.items():
            field = x.addChild("field", attrs={"var": key})
            if type(value) == types.ListType:
                for v in value:
                    field.addChild("value").setData(v)
            else:
                field.addChild("value").setData(str(value))

        def _did_configure(conn, resp, callback):
            ret = False
            if resp.getType() == "result":
                ret = True
            if callback:
                callback(resp)
            return ret

        if wait:
            resp = self.xmppclient.SendAndWaitForResponse(iq)
            return _did_configure(None, resp, callback)
        else:
            self.xmppclient.SendAndCallForResponse(iq, func=_did_configure, args={"callback": callback})
            return True


    ### Item management

    def get_items(self):
        """
        Return an array of all items.
        @rtype: list
        @return: list of pubsub's xmpp.Nonde
        """
        return self.content

    def get_item(self, item_id):
        """
        Return the item with the given item id
        @type item_id: string
        @param item_id: the pubsub node id
        """
        for n in self.content:
            if n.getAttr("id").lower() == item_id.lower():
                return n
        return None

    def add_item(self, itemcontentnode, callback=None, wait=False):
        """
        Add a leaf item xmpp.node to the node and will trigger callback if any
        on server answer.
        @type itemcontentnode: xmpp.Node
        @param itemcontentnode: the node to publish on the pubsub
        @type callback: function
        @param callback: if not None, callback will be called after publication
        """
        if not self.recovered:
            raise Exception("PUBSUB: can't add item. Node %s doesn't exists." % self.nodename)
        iq          = xmpp.Iq(typ="set", to=self.pubsubserver)
        pubsub      = iq.addChild("pubsub", namespace=xmpp.protocol.NS_PUBSUB)
        publish     = pubsub.addChild("publish", attrs={"node": self.nodename})
        item        = publish.addChild("item")
        item.addChild(node=itemcontentnode)

        def _did_publish_item(conn, resp, callback, item):
            ret = False
            if resp.getType() == "result":
                item.setAttr("id", resp.getTag("pubsub").getTag("publish").getTag("item").getAttr("id"))
                self.content.append(item)
                ret = True
            if callback:
                return callback(resp)
            return ret

        if wait:
            resp = self.xmppclient.SendAndWaitForResponse(iq)
            return _did_publish_item(None, resp, callback, item)
        else:
            self.xmppclient.SendAndCallForResponse(iq, func=_did_publish_item, args={"callback": callback, "item": item})
            return True


    def remove_item(self, item_id, callback=None, user_info=None, wait=False):
        """
        Remove an item according to its ID.
        @type item_id: string
        @param item_id: the id of the node to remove
        @type callback: function
        @param callback: if not None, callback will be called after retraction
        @type user_info: Object
        @param user_info: random info to pass to the callback
        """
        iq = xmpp.Iq(typ="set", to=self.pubsubserver)
        pubsub = iq.addChild("pubsub", namespace=xmpp.protocol.NS_PUBSUB)
        retract = pubsub.addChild("retract", attrs={"node": self.nodename})
        item = retract.addChild("item", attrs={"id": item_id})

        for item in self.content:
            if item.getAttr("id") == item_id:
                self.content.remove(item)
                break

        def _did_remove_item(conn, resp, callback, user_info):
            ret = False
            if resp.getType() == "result":
                ret = True
            if callback:
                return callback(resp, user_info)
            return ret

        if wait:
            resp = self.xmppclient.SendAndWaitForResponse(iq)
            return _did_remove_item(None, resp, callback, user_info)
        else:
            self.xmppclient.SendAndCallForResponse(iq, func=_did_remove_item, args={"callback": callback, "user_info": user_info})



    ## Subscription management

    def retrieve_subscriptions(self, callback=None, wait=False):
        """
        Recover the subscriptions
        @type callback: function
        @param callback: if not None, callback will be called after retrieval
        @type wait: Boolean
        @param wait: if True, action will be done in sync mode
        """
        iq  = xmpp.Iq(typ="get", to=self.pubsubserver)
        pubsub = iq.addChild("pubsub", namespace=xmpp.protocol.NS_PUBSUB)
        pubsub.addChild("subscriptions", attrs={"node": self.nodename})

        def _did_retrieve_subscription(conn, resp, callback):
            ret = False
            if resp.getType() == "result":
                self.subscriptions = []
                for subscription in resp.getTag("pubsub").getTag("subscriptions").getTags("subscription"):
                    self.subscriptions.append(subscription.getAttr("subid"))
                ret = True
            return ret

        if wait:
            resp = self.xmppclient.SendAndWaitForResponse(iq)
            return _did_retrieve_subscription(None, resp, callback)
        else:
            self.xmppclient.SendAndCallForResponse(iq, func=_did_retrieve_subscription, args={"callback": callback})
            return True

    def subscribe(self, jid, callback, unique=True, wait=False):
        """
        Subscribe to the node.
        @type jid: xmpp.Protocol.JID
        @param jid: the JID of the subscriber
        @type callback: function
        @param callback: the callback that will be called when an item is published
        @type unique: Boolean
        @param unique: if True, it will subscribe only if no subscription is already done
        @type wait: Boolean
        @param wait: if True, action will be done in sync mode
        """
        self.subscriber_callback = callback
        self.subscriber_jid = jid

        if unique:
            if len(self.subscriptions) == 0:
                self.retrieve_subscriptions(wait=True)
            if not len(self.subscriptions) == 0:
                self.xmppclient.RegisterHandler('message', self._on_pubsub_event, ns=xmpp.protocol.NS_PUBSUB+"#event", typ="headline")
                return;

        iq = xmpp.Iq(typ="set", to=self.pubsubserver)
        pubsub = iq.addChild("pubsub", namespace=xmpp.protocol.NS_PUBSUB)
        pubsub.addChild("subscribe", attrs={"node": self.nodename, "jid": jid.getStripped()})

        def _did_subscribe(conn, resp, callback):
            ret = False
            if resp.getType() == "result":
                self.xmppclient.RegisterHandler('message', self._on_pubsub_event, ns=xmpp.protocol.NS_PUBSUB+"#event", typ="headline")
                ret = True
            return ret

        if wait:
            resp = self.xmppclient.SendAndWaitForResponse(iq)
            return _did_subscribe(None, resp, callback)
        else:
            self.xmppclient.SendAndCallForResponse(iq, func=_did_subscribe, args={"callback": callback})
            return True


        self.xmppclient.send(iq)

    def _on_pubsub_event(self, conn, event):
        """
        Trigger the callback for events.
        """
        def on_retrieve(resp):
            if resp.getType() == "result":
                node = event.getTag("event").getTag("items").getAttr("node")
                if node == self.nodename and self.subscriber_callback and event.getTo().getStripped() == self.subscriber_jid.getStripped():
                    self.subscriber_callback(event)

        self.retrieve_items(callback=on_retrieve)

    def unsubscribe(self, jid, subID, callback=None, wait=False):
        """
        Unsubscribe from a node.
        @type jid: xmpp.JID
        @param jid: the JID of the entity to unsubscribe
        @type subID: String
        @param subID: the subscription ID to remove. If None, all subscriptions will be removed
        @param callback: the callback that will be called when an item is published
        @type wait: Boolean
        @param wait: if True, action will be done in sync mode
        """
        self.subscriber_callback = None
        self.subscriber_jid = None

        def _did_unsubscribe(conn, resp, callback):
            self.xmppclient.UnregisterHandler('message', self._on_pubsub_event, ns=xmpp.protocol.NS_PUBSUB+"#event", typ="headline")

        iq = xmpp.Iq(typ="set", to=self.pubsubserver)
        pubsub = iq.addChild("pubsub", namespace=xmpp.protocol.NS_PUBSUB)
        pubsub.addChild("unsubscribe", attrs={"node": self.nodename, "jid": jid.getStripped(), "subid": subID})

        if wait:
            resp = self.xmppclient.SendAndWaitForResponse(iq)
            return _did_unsubscribe(None, resp, callback)
        else:
            self.xmppclient.SendAndCallForResponse(iq, func=_did_unsubscribe, args={"callback": callback})
            return True


    ## Affilication management

    def fetch_affiliations(self, callback=None, wait=False):
        """
        fetch the affiliations for the node
        @type callback: Function
        @param callback: the callback function
        @type wait: Boolean
        @param wait: if true, wait for answer
        """
        iq = xmpp.Node("iq", attrs={"type": "get", "to": self.pubsubserver})
        pubsubNode = iq.addChild("pubsub", namespace="http://jabber.org/protocol/pubsub#owner")
        affNode = pubsubNode.addChild("affiliations", attrs={"node": self.nodename})

        def _did_fetch_affiliations(conn, resp, callback):
            ret = False
            if resp.getType() == "result":
                self.affiliations = {}
                for affiliation in resp.getTag("pubsub").getTag("affiliations").getTags("affiliation"):
                    self.affiliations[affiliation.getAttr("jid")] = affiliation.getAttr("affiliation")
                ret = True
            if callback:
                return callback(resp)
            return ret

        if wait:
            resp = self.xmppclient.SendAndWaitForResponse(iq)
            return _did_fetch_affiliations(None, resp, callback)
        else:
            self.xmppclient.SendAndCallForResponse(iq, func=_did_fetch_affiliations, args={"callback": callback})
            return True

    def set_affiliation(self, jid, affiliation, callback=None, wait=False):
        """
        set an affiliation for the node
        @type jid: xmpp.JID
        @param jid: the jid to change affiliation
        @type affiliation: String
        @param affiliation: the affiliation
        @type callback: Function
        @param callback: the callback function
        @type wait: Boolean
        @param wait: if true, wait for answer
        """
        iq = xmpp.Node("iq", attrs={"type": "set", "to": self.pubsubserver})
        pubsubNode = iq.addChild("pubsub", namespace="http://jabber.org/protocol/pubsub#owner")
        affNode = pubsubNode.addChild("affiliations", attrs={"node": self.nodename})
        affNode.addChild("affiliation", attrs={"jid": jid.getStripped(), "affiliation": affiliation})

        def _did_set_affiliations(conn, resp, callback, wait):
            ret = False
            if resp.getType() == "result":
                self.fetch_affiliations(wait=wait)
                ret = True
            if callback:
                return callback(resp)
            return ret

        if wait:
            resp = self.xmppclient.SendAndWaitForResponse(iq)
            return _did_set_affiliations(None, resp, callback, wait)
        else:
            self.xmppclient.SendAndCallForResponse(iq, func=_did_set_affiliations, args={"callback": callback, "wait": wait})
            return True
