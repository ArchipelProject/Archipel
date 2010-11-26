# 
# archipelEntity.py
# 
# Copyright (C) 2010 Antoine Mercadal <antoine.mercadal@inframonde.eu>
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

"""
Contains archipelEntity, the root class of any Archipel XMPP capable entities

This provides basic XMPP features, like connecting, auth...
"""
import xmpp
import sys
import glob
from utils import *
import uuid
import os
import socket
import base64
import hashlib
import time
import threading
import traceback
import datetime
import pubsub
import sqlite3
import archipelPermissionCenter


ARCHIPEL_ERROR_CODE_AVATARS             = -1
ARCHIPEL_ERROR_CODE_SET_AVATAR          = -2
ARCHIPEL_ERROR_CODE_MESSAGE             = -3
ARCHIPEL_ERROR_CODE_GET_PERMISSIONS     = -4
ARCHIPEL_ERROR_CODE_SET_PERMISSIONS     = -5
ARCHIPEL_ERROR_CODE_LIST_PERMISSIONS    = -6
ARCHIPEL_ERROR_CODE_SET_TAGS            = -7
ARCHIPEL_ERROR_CODE_ADD_SUBSCRIPTION    = -8
ARCHIPEL_ERROR_CODE_REMOVE_SUBSCRIPTION = -9


ARCHIPEL_MESSAGING_HELP_MESSAGE = """
You can communicate with me using text commands, just like if you were chatting with your friends. \
I try to understand you as much as I can, but you have to be nice with me.\
Note that you can use more complex sentence than describe into the following list. For example, if you see \
in the command ["how are you"], I'll understand any sentence containing "how are you". Parameters (if any) are separated with spaces.

For example, you can send command using the following form:
command param1 param2 param3

"""


class TNArchipelEntity:
    """
    this class represent a basic XMPP Client
    """
    def __init__(self, jid, password, configuration, name, auto_register=True, auto_reconnect=True):
        """
        The constructor of the class.
        
        @type jid: string
        @param jid: the jid of the client.
        @type password: string
        @param password: the password of the JID account.
        """
        self.registered_actions_to_perform_on_connection = []
        self.name                   = name
        self.xmppstatus             = None
        self.xmppstatusshow         = None
        self.xmppclient             = None
        self.vCard                  = None
        self.password               = password
        self.jid                    = jid
        self.resource               = self.jid.getResource()
        self.roster                 = None
        self.roster_retreived       = False
        self.configuration          = configuration
        self.auto_register          = auto_register
        self.auto_reconnect         = auto_reconnect
        self.messages_registrar     = []
        self.isAuth                 = False
        self.loop_status            = ARCHIPEL_XMPP_LOOP_OFF
        self.pubsubserver           = self.configuration.get("GLOBAL", "xmpp_pubsub_server")
        self.log                    = TNArchipelLogger(self)
        self.pubSubNodeEvent        = None
        self.pubSubNodeLog          = None
        self.pubSubNodeTags         = None
        self.hooks                  = {}
        self.b64Avatar              = None
        self.default_avatar         = "default.png"
        self.entity_type            = "not-defined"
        self.permission_center      = None
        
        if self.name == "auto":
            self.name = self.resource
        
        log.info("jid defined as %s" % (str(self.jid)))
        
        ip_conf = self.configuration.get("GLOBAL", "machine_ip")
        if ip_conf == "auto":
            self.ipaddr = socket.gethostbyname(socket.gethostname())
        else:
            self.ipaddr = ip_conf
    
    
    def initialize_modules(self):
        """
        this will initializes all loaded modules
        """
        for method in self.__class__.__dict__:
            if not method.find("__module_init__") == -1:
                m = getattr(self, method)
                m()
    
    
    def check_acp(self, conn, iq):
        """check is iq is a valid ACP and return action"""
        try:
            action = iq.getTag("query").getTag("archipel").getAttr("action")
            log.info("ACP RECEIVED: from: %s, type: %s, namespace: %s, action: %s" % (iq.getFrom(), iq.getType(), iq.getQueryNS(), action))
            return action
        except Exception as ex:
            reply = build_error_iq(self, ex, iq, ARCHIPEL_NS_ERROR_QUERY_NOT_WELL_FORMED)
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed
        
    
    
    
    ### Permissions
    
    def init_permissions(self):
        """
        Initializes the permissions
        overrides this to add custom permissions
        """
        self.permission_center.create_permission("all", "All permissions are granted", False);
        self.permission_center.create_permission("presence", "Authorizes users to request presences", False);
        self.permission_center.create_permission("message", "Authorizes users to send messages", False);
        self.permission_center.create_permission("getavatars", "Authorizes users to get entity avatars list", False);
        self.permission_center.create_permission("setavatar", "Authorizes users to set entity's avatar", False);
        self.permission_center.create_permission("settags", "Authorizes users to modify entity's tags", False);
        self.permission_center.create_permission("permission_get", "Authorizes users to get all permissions", True);
        self.permission_center.create_permission("permission_getown", "Authorizes users to get only own permissions", False);
        self.permission_center.create_permission("permission_list", "Authorizes users to list existing", False);
        self.permission_center.create_permission("permission_set", "Authorizes users to set all permissions", False);
        self.permission_center.create_permission("permission_setown", "Authorizes users to set only own permissions", False);
        self.permission_center.create_permission("subscription_add", "Authorizes users add others in entity roster", False);
        self.permission_center.create_permission("subscription_remove", "Authorizes users remove others in entity roster", False);
    
    
    def check_perm(self, conn, stanza, action_name, error_code=-1, prefix=""):
        """
        check if given from of stanza has a given permission
        
        @type conn: xmpp.Dispatcher
        @param conn: ths instance of the current connection that send the message
        @type stanza: xmpp.Node
        @param stanza: the original stanza
        @type action_name: string
        @param action_name: the name of action to check permission
        @type error_code: int
        @param error_code: the return code of permission denied
        @type prefix: string
        @param prefix: the prefix of action_name (for example if permission if health_get and action is get, you can give 'health_' as prefix)
        """
        if not self.permission_center.check_permission(str(stanza.getFrom().getStripped()), "%s%s" % (prefix, action_name)):
            conn.send(build_error_iq(self, "Cannot use '%s': permission denied" % action_name, stanza, code=error_code, ns=ARCHIPEL_NS_PERMISSION_ERROR))
            raise xmpp.protocol.NodeProcessed
    
    
    
    ### Server connection
    
    def connect_xmpp(self):
        """
        Initialize the connection to the the XMPP server
        
        exit on any error.
        """
        self.xmppclient = xmpp.Client(self.jid.getDomain(), debug=[]) #debug=['dispatcher', 'nodebuilder', 'protocol'])
        if self.xmppclient.connect() == "":
            log.error("unable to connect to XMPP server")
            if self.auto_reconnect:
                self.loop_status = ARCHIPEL_XMPP_LOOP_RESTART
                return False
            else:
                sys.exit(-1)
        
        self.loop_status = ARCHIPEL_XMPP_LOOP_ON
        log.info("sucessfully connected")
        return True
    
    
    def auth_xmpp(self):
        """
        Authentify the client to the XMPP server
        """
        log.info("trying to authentify the client")
        if self.xmppclient.auth(self.jid.getNode(), self.password, self.resource) == None:
            self.isAuth = False
            if (self.auto_register):
                log.info("starting registration, according to propertie auto_register")
                self.inband_registration()
                return
            log.error("bad authentication. exiting")
            sys.exit(0)
        
        self.recover_pubsubs()
        self.register_handler()
        self.xmppclient.sendInitPresence()
        self.roster = self.xmppclient.getRoster()
        self.isAuth = True
        self.get_vcard()
        self.perform_all_registered_auth_actions()
        self.loop_status = ARCHIPEL_XMPP_LOOP_ON
        log.info("sucessfully authenticated")
    
    
    def connect(self):
        """
        Connect and auth to XMPP Server
        """
        if self.xmppclient and self.xmppclient.isConnected():
            return
        
        if self.connect_xmpp():
            self.auth_xmpp()
    
    
    def disconnect(self):
        """Close the connections from XMPP server"""
        if self.xmppclient and self.xmppclient.isConnected():
            self.isAuth = False
            self.loop_status = ARCHIPEL_XMPP_LOOP_OFF
    
    
    
    ### Pubsub
    
    def recover_pubsubs(self):
        """
        create or get the current hypervisor pubsub node.
        """
        # creating/gettingthe event pubsub node
        eventNodeName = "/archipel/" + self.jid.getStripped() + "/events"
        self.pubSubNodeEvent = pubsub.TNPubSubNode(self.xmppclient, self.pubsubserver, eventNodeName)
        
        if not self.pubSubNodeEvent.recover():
            self.pubSubNodeEvent.create()
        self.pubSubNodeEvent.configure({
            pubsub.XMPP_PUBSUB_VAR_ACCESS_MODEL: pubsub.XMPP_PUBSUB_VAR_ACCESS_MODEL_OPEN,
            pubsub.XMPP_PUBSUB_VAR_DELIVER_NOTIFICATION: 1,
            pubsub.XMPP_PUBSUB_VAR_PERSIST_ITEMS: 0,
            pubsub.XMPP_PUBSUB_VAR_NOTIFY_RECTRACT: 0,
            pubsub.XMPP_PUBSUB_VAR_DELIVER_PAYLOADS: 1,
            pubsub.XMPP_PUBSUB_VAR_SEND_LAST_PUBLISHED_ITEM: pubsub.XMPP_PUBSUB_VAR_SEND_LAST_PUBLISHED_ITEM_NEVER
        })
        
        # creating/getting the log pubsub node
        logNodeName = "/archipel/" + self.jid.getStripped() + "/logs"
        self.pubSubNodeLog = pubsub.TNPubSubNode(self.xmppclient, self.pubsubserver, logNodeName)
        if not self.pubSubNodeLog.recover():
            self.pubSubNodeLog.create()
        self.pubSubNodeLog.configure({
                pubsub.XMPP_PUBSUB_VAR_ACCESS_MODEL: pubsub.XMPP_PUBSUB_VAR_ACCESS_MODEL_OPEN,
                pubsub.XMPP_PUBSUB_VAR_DELIVER_NOTIFICATION: 1,
                pubsub.XMPP_PUBSUB_VAR_MAX_ITEMS: self.configuration.get("LOGGING", "log_pubsub_max_items"),
                pubsub.XMPP_PUBSUB_VAR_PERSIST_ITEMS: 1,
                pubsub.XMPP_PUBSUB_VAR_NOTIFY_RECTRACT: 0,
                pubsub.XMPP_PUBSUB_VAR_DELIVER_PAYLOADS: 1,
                pubsub.XMPP_PUBSUB_VAR_SEND_LAST_PUBLISHED_ITEM: pubsub.XMPP_PUBSUB_VAR_SEND_LAST_PUBLISHED_ITEM_NEVER
        })
        
        # creating/getting the tags pubsub node
        tagsNodeName = "/archipel/tags"
        self.pubSubNodeTags = pubsub.TNPubSubNode(self.xmppclient, self.pubsubserver, tagsNodeName)
        if not self.pubSubNodeTags.recover():
            Exception("the pubsub node /archipel/tags must have been created. You can use arch-tagnode tool to create it.")        
    
    
    def remove_pubsubs(self):
        log.info("removing pubsub node for log")
        self.pubSubNodeLog.delete(nowait=False)
        
        log.info("removing pubsub node for events")
        self.pubSubNodeEvent.delete(nowait=False)
    
    
    
    ### Hooks management
    
    def create_hook(self, hookname):
        """register a new hook"""
        self.hooks[hookname] = []
        log.info("HOOK: creating hook with name %s" % hookname)
        return True
    
    
    def remove_hook(self, hookname):
        """unregister an existing hook"""
        if self.hooks.has_key(hookname):
            del self.hooks[hookname]
            log.info("HOOK: removing hook with name %s" % hookname)
            return True
        return False
    
    
    def register_hook(self, hookname, m):
        """register a method that will be triggered by a hook"""
        if self.hooks.has_key(hookname):
            self.hooks[hookname].append(m)
            log.info("HOOK: registering hook method %s for hook name %s" % (m.__name__, hookname))
            return True
        return False
        
    def unregister_hook(self, hookname, m):
        """unregister a method from a hook"""
        if self.hooks.has_key(hookname):
            self.hooks[hookname].remove(m)
            log.info("HOOK: unregistering hook method %s for hook name %s" % (m.__name__, hookname))
            return True
        return False
    
    def perform_hooks(self, hookname, args=None):
        log.info("HOOK: going to run methods for hook %s" % hookname)
        for m in self.hooks[hookname]:
            try:
                log.info("HOOK: performing method %s registered in hook with name %s" % (m.__name__, hookname))
                m(self, args)
            except Exception as ex:
                log.error("HOOK: error during performing method %s for hookname %s: %s" % (m.__name__, hookname, str(ex)))
    
    
    ### Server registration
     
    
    
    
    ### Basic handlers
    
    def register_handler(self):
        """
        this method have to be overloaded in order to register handler for 
        XMPP events
        """
        self.xmppclient.RegisterHandler('presence', self.process_presence)
        self.xmppclient.RegisterHandler('message', self.process_message, typ="chat")
        self.xmppclient.RegisterHandler('iq', self.process_avatar_iq, ns=ARCHIPEL_NS_AVATAR)
        self.xmppclient.RegisterHandler('iq', self.process_tags_iq, ns=ARCHIPEL_NS_TAGS)
        self.xmppclient.RegisterHandler('iq', self.process_permission_iq, ns=ARCHIPEL_NS_PERMISSIONS)
        self.xmppclient.RegisterHandler('iq', self.process_subscription_iq, ns=ARCHIPEL_NS_SUBSCRIPTION)
        
        log.info("handlers registred")
        
        for method in self.__class__.__dict__:
            if not method.find("__module_register_stanza__") == -1:
                m = getattr(self, method)
                m()
    
    
    
    ### Presence Management
    
    def process_presence(self, conn, presence):
        """
        process presence stanzas
        
        @type conn: xmpp.Dispatcher
        @param conn: ths instance of the current connection that send the message
        @type presence: xmpp.Protocol.Iq
        @param presence: the received IQ
        """
        log.info("Subscription Presence ask by %s to %s: %s" % (str(presence.getFrom().getStripped()), self.jid.getStripped(), str(presence.getType())))
        
        # update roster is necessary
        if not self.roster:
            self.roster = self.xmppclient.getRoster()
        
        typ = presence.getType()
        jid = presence.getFrom()
        
        # check permissions
        if not self.permission_center.check_permission(jid.getStripped(), "presence"):
            
            if typ == "subscribe":
                self.unsubscribe(jid)
            self.remove_jid(jid)
            raise xmpp.protocol.NodeProcessed
        
        # if everything is all right, process request
        if typ == "subscribe":
            self.add_jid(jid)
        elif typ == "unsubscribe":
            self.remove_jid(jid)
        raise xmpp.protocol.NodeProcessed
    
    
    
    ### Subscription Management
    
    def process_subscription_iq(self, conn, iq):
        """
        process presence iq with namespace ARCHIPEL_NS_SUBSCRIPTION. 
        this allows to ask entity to subscribe to others users
        
        it understands:
            - add
            - remove
        
        @type conn: xmpp.Dispatcher
        @param conn: ths instance of the current connection that send the message
        @type presence: xmpp.Protocol.Iq
        @param presence: the received IQ
        """
        
        action = self.check_acp(conn, iq)
        self.check_perm(conn, iq, action, -1, prefix="subscription_")
        
        if action == "add":         reply = self.iq_add_subscription(iq)
        elif action == "remove":    reply = self.iq_remove_subscription(iq)
        
        conn.send(reply)
        raise xmpp.protocol.NodeProcessed
    
    
    def iq_add_subscription(self, iq):
        """
        add a JID in the entity roster
        """
        try:
            reply = iq.buildReply("result")
            jid = xmpp.JID(iq.getTag("query").getTag("archipel").getAttr("jid"))
            log.info("add jid %s into %s's roster" %  (str(jid), str(self.jid)))
            self.permission_center.grant_permission_to_user("presence", jid.getStripped())
            self.push_change("permissions", "set")
            self.add_jid(jid)
        except Exception as ex:
            reply = build_error_iq(self, ex, iq, ARCHIPEL_ERROR_CODE_ADD_SUBSCRIPTION)
        return reply
    
    
    def iq_remove_subscription(self, iq):
        """
        remove a JID from the entity roster
        """
        try:
            reply = iq.buildReply("result")
            jid = xmpp.JID(iq.getTag("query").getTag("archipel").getAttr("jid"))
            self.permission_center.revoke_permission_to_user("presence", jid.getStripped())
            self.push_change("permissions", "set")
            self.remove_jid(jid)
        except Exception as ex:
            reply = build_error_iq(self, ex, iq, ARCHIPEL_ERROR_CODE_REMOVE_SUBSCRIPTION)
        return reply
    
    
    
    ### Register actions on auth
    
    def register_actions_to_perform_on_auth(self, method_name, args=[], persistant=True):
        """
        Allows object to register actions (method of this class) to perform
        when the XMPP Client will be online.
        
        @type method_name: string
        @param method_name: the name of the method to launch
        @type args: Array
        @param args: an array containing the arguments to pass to the method
        """
        log.info("registering action to perform on auth :%s" % method_name)
        
        if self.isAuth:
            log.info("performing action right now, because we are already authenticated")
            
            if persistant:
                self.registered_actions_to_perform_on_connection.append({"name":method_name, "args": args, "persistant": persistant})
            
            if hasattr(self, method_name):
                m = getattr(self, method_name)
                if args and len(args) > 0:
                    m(args)
                else:
                    m()
        else:
            self.registered_actions_to_perform_on_connection.append({"name":method_name, "args": args, "persistant": persistant})
    
    
    def perform_all_registered_auth_actions(self):
        """
        Parse the all the registered actions for connection, and execute them
        """
        if not self.isAuth:
            return
        
        log.debug("going to perform action to perform on auth: %s" % str(self.registered_actions_to_perform_on_connection))
        
        actions_to_purge = []
        
        for action in self.registered_actions_to_perform_on_connection:
            log.debug("performing action %s" % str(action))
            if hasattr(self, action["name"]):
                m = getattr(self, action["name"])
                if action["args"] != None:
                    m(action["args"])
                else:
                    m()
            if not action["persistant"]:
                actions_to_purge.append(action)
        
        for oneshot_action in actions_to_purge:
            log.debug("purging non persistant action %s" % str(oneshot_action))
            self.registered_actions_to_perform_on_connection.remove(oneshot_action)
        
        log.debug("all registred actions have been done")
    
    
    
    ### XMPP Utilities
    
    def change_presence(self, presence_show=None, presence_status=None):
        """
        change the presence of the entity
        """
        self.xmppstatus     = presence_status
        self.xmppstatusshow = presence_show
        
        log.info("status change: %s show:%s" % (self.xmppstatus, self.xmppstatusshow))
        
        pres = xmpp.Presence(status=self.xmppstatus, show=self.xmppstatusshow)
        #self.mass_sender.stanzas.append(pres)
        self.xmppclient.send(pres) 
    
    
    def change_status(self, presence_status):
        """
        change only the status of the entity
        """
        self.xmppstatus = presence_status
        pres = xmpp.Presence(status=self.xmppstatus, show=self.xmppstatusshow)
        #self.mass_sender.stanzas.append(pres)
        self.xmppclient.send(pres)
    
    
    def push_change(self, namespace, change, excludedgroups=None):
        """
        push a change using archipel push system.
        this system will change with inclusion of pubsub
        """
        ns = ARCHIPEL_NS_IQ_PUSH + ":" + namespace
        
        log.info("PUSH : pushing %s->%s" % (ns, change))
        
        push = xmpp.Node(tag="push", attrs={"date": datetime.datetime.now(), "xmlns": ns, "change": change})
        self.pubSubNodeEvent.add_item(push)
    
    
    def shout(self, subject, message, excludedgroups=None):
        """send a message to evrybody in roster"""
        
        for barejid in self.roster.getItems():
            excluded = False
            if excludedgroups:
                for excludedgroup in excludedgroups:
                    groups = self.roster.getGroups(barejid)
                    if groups and excludedgroup in groups:
                        excluded = True
                        break
            
            if not excluded:
                resources = self.roster.getResources(barejid)
                for resource in resources:
                    broadcast = xmpp.Message(body=message, typ="headline", to=barejid + "/" + resource)
                    log.info("SHOUTING : shouting message to %s" % (barejid))
                    self.xmppclient.send(broadcast)
    
    
    
    ### XMPP Roster
    
    def add_jid(self, jid, groups=[]):
        """
        Add a jid to the VM Roster and authorizes it
        
        @type jid: xmpp.JID
        @param jid: this jid to add
        """
        log.info("adding JID %s to roster of %s" % (str(jid), str(self.jid)))
        
        if not self.roster: self.roster = self.xmppclient.getRoster()
        self.roster.setItem(jid=jid.getStripped(), groups=groups)
        if not self.roster.getItem(jid.getStripped()) or self.roster.getSubscription(jid.getStripped()) in ("to", "none"):
            self.subscribe(jid)
            self.authorize(jid)
        self.push_change("subscription", "added")
    
    
    def remove_jid(self, jid):
        """
        Remove a jid from roster and unauthorizes it
        
        @type jid: xmpp.JID
        @param jid: this jid to remove
        """
        log.info("%s is removing jid %s from it's roster" % (str(self.jid), str(jid)))
        
        if not self.roster: self.roster = self.xmppclient.getRoster()
        self.roster.delItem(jid.getStripped())
        self.push_change("subscription", "removed")
    
    
    def subscribe(self, jid):
        """
        perform a subscription. we do not user the xmpp.roster.Subscribe()
        because it doesn't support the name
        
        @type jid: xmpp.JID
        @param jid: this jid to remove
        """
        log.info("%s is subscribing to jid %s" % (str(self.jid), str(jid)))
        
        presence = xmpp.Presence(to=jid, typ='subscribe')
        if self.name: presence.addChild(name="nick", namespace="http://jabber.org/protocol/nick", payload=self.name)
        self.xmppclient.send(presence)
    
    
    def unsubscribe(self, jid):
        """
        perform a unsubscription.
        
        @type jid: xmpp.JID
        @param jid: this jid to remove
        """
        log.info("%s is unsubscribing from jid %s" % (str(self.jid), str(jid)))
        
        if not self.roster: self.roster = self.xmppclient.getRoster()
        self.roster.Unsubscribe(jid.getStripped())
        self.roster.Unauthorize(jid.getStripped())
    
    
    def authorize(self, jid):
        """
        authorize the given JID
        
        @type jid: xmpp.JID
        @param jid: this jid to remove
        """
        log.info("%s is authorizing jid %s" % (str(self.jid), str(jid)))
        
        if not self.roster: self.roster = self.xmppclient.getRoster()
        self.roster.Authorize(jid);
    
    
    def unauthorize(self, jid):
        """
        unauthorize the given JID
        
        @type jid: xmpp.JID
        @param jid: this jid to remove
        """
        log.info("%s is authorizing jid %s" % (str(self.jid), str(jid)))
        
        if not self.roster: self.roster = self.xmppclient.getRoster()
        self.roster.Unauthorize(jid);
    
    
    def is_subscribed(self, jid):
        """
        Check if the JID is authorized or not
        
        @type jid: string
        @param jid: the jid to check in policy
        @rtype : boolean
        @return: False if not subscribed or True if subscribed
        """ 
        try:
            subs = self.roster.getSubscription(str(jid))
            log.info("stanza sent form authorized JID {0}".format(jid))
            if subs in ("both", "to"): return True
            else: return False
        except KeyError:
            log.info("stanza sent form unauthorized JID {0}".format(jid))
            return False
    
    
    
    ### VCARD management
    
    def get_vcard(self):
        """
        retrieve vCard from server
        """
        log.info("asking for own vCard")
        node_iq = xmpp.Iq(typ='get', frm=self.jid)
        node_iq.addChild(name="vCard", namespace="vcard-temp")
        self.xmppclient.SendAndCallForResponse(stanza=node_iq, func=self.did_receive_vcard)
    
    
    def did_receive_vcard(self, conn, vcard):
        """
        callback of get_vcard()
        """
        self.vCard = vcard.getTag("vCard")
        if self.vCard and self.vCard.getTag("PHOTO"):
            self.b64Avatar = self.vCard.getTag("PHOTO").getTag("BINVAL").getCDATA()
        log.info("own vcard retrieved")
    
    
    def set_vcard(self, params=None):
        """
        allows to define a vCard type for the entry
        
        @type params: dict
        @param params: adict containing at least option avatar_file key
        """
        log.info("vcard making started")
        
        node_iq = xmpp.Iq(typ='set', xmlns=None)
        
        type_node = xmpp.Node(tag="TYPE")
        type_node.setData(self.entity_type)
        
        name_node = None
        if self.name:
            name_node = xmpp.Node(tag="NAME")
            name_node.setData(self.name)
        
        if (self.configuration.getboolean("GLOBAL", "use_avatar")):
            if not self.b64Avatar:
                photo_data = self.b64avatar_from_filename(self.default_avatar)
            else:
                photo_data = self.b64Avatar
        
            node_photo_content_type = xmpp.Node(tag="TYPE")
            node_photo_content_type.setData("image/png")
                    
            node_photo_data = xmpp.Node(tag="BINVAL")
            node_photo_data.setData(photo_data)
        
            if self.vCard and self.vCard.getTag("PHOTO"):
                old_photo_binval = self.vCard.getTag("PHOTO").getTag("BINVAL").getCDATA()
                if old_photo_binval == photo_data:
                    log.info("vCard photo hasn't change.")
                    self.send_update_vcard(None, None, hashlib.sha224(photo_data).hexdigest())
            
            node_photo  = xmpp.Node(tag="PHOTO", payload=[node_photo_content_type, node_photo_data])
            node_iq.addChild(name="vCard", payload=[type_node, node_photo, name_node], namespace="vcard-temp")
            self.xmppclient.SendAndCallForResponse(stanza=node_iq, func=self.send_update_vcard, args={"photo_hash": hashlib.sha224(photo_data).hexdigest()})
        else:
            node_iq.addChild(name="vCard", payload=[type_node, name_node], namespace="vcard-temp")
            self.xmppclient.SendAndCallForResponse(stanza=node_iq, func=self.send_update_vcard)
        
        log.info("vcard information sent with type: {0}".format(self.entity_type))        
    
    
    def send_update_vcard(self, conn, presence, photo_hash=None):
        """
        this method is called by set_vcard_entity_type when the update of the
        vCard is OK. It will send the presence stanza to indicates the update of 
        the vCard
        
        @type conn: xmpp.Dispatcher
        @param conn: ths instance of the current connection that send the message
        @type presence: xmpp.Protocol.Iq
        @param presence: the received IQ
        @type photo_hash: string
        @param photo_hash: the SHA-1 hash of the photo that changes (optionnal)
        """
        node_presence = xmpp.Presence(frm=self.jid, status=self.xmppstatus, show=self.xmppstatusshow)
        
        if photo_hash:
            node_photo_sha1 = xmpp.Node(tag="photo")
            node_photo_sha1.setData(photo_hash)
            node_presence.addChild(name="x", namespace='vcard-temp:x:update', payload=[node_photo_sha1])
        
        self.xmppclient.send(node_presence)
        log.info("vcard update presence sent") 
    
    
    
    ### Inband registration management
    
    def inband_registration(self):
        """
        Do a in-band registration if auth fail
        """
        if not self.auto_register:
            return
        
        log.info("trying to register with %s to %s" % (self.jid.getNode(), self.jid.getDomain()))
        iq = (xmpp.Iq(typ='set', to=self.jid.getDomain()))    
        payload_username = xmpp.Node(tag="username")
        payload_username.addData(self.jid.getNode())
        payload_password = xmpp.Node(tag="password")
        payload_password.addData(self.password)
        iq.setQueryNS("jabber:iq:register")
        iq.setQueryPayload([payload_username, payload_password])
        
        log.info("registration information sent. wait for response")
        resp_iq = self.xmppclient.SendAndWaitForResponse(iq)
        
        if resp_iq.getType() == "error":
            log.error("unable to register : %s" % str(resp_iq))
            sys.exit(-1)
            
        elif resp_iq.getType() == "result":
            log.info("the registration complete")
            self.loop_status = ARCHIPEL_XMPP_LOOP_RESTART
    
    
    def inband_unregistration(self):
        """
        Do a in-band unregistration
        """
        self.loop_status = ARCHIPEL_XMPP_LOOP_REMOVE_USER
    
    
    def process_inband_unregistration(self):
        self.remove_pubsubs()
        
        log.info("trying to unregister")
        iq = (xmpp.Iq(typ='set', to=self.jid.getDomain()))
        iq.setQueryNS("jabber:iq:register")
        
        remove_node = xmpp.Node(tag="remove")
        
        iq.setQueryPayload([remove_node])
        log.info("unregistration information sent. waiting for response")
        resp_iq = self.xmppclient.SendAndWaitForResponse(iq)
        log.info("account removed!")
        self.loop_status = ARCHIPEL_XMPP_LOOP_OFF
    
    
    
    ### Avatars
    
    def get_available_avatars(self, supported_file_extensions=["png", "jpg", "jpeg", "gif"]):
        """
        return a stanza with a list of availables avatars
        encoded in base64
        """
        path = self.configuration.get("GLOBAL", "machine_avatar_directory")
        resp = xmpp.Node("avatars")
        
        for ctype in supported_file_extensions:
            for img in glob.glob(os.path.join(path, "*.%s" % ctype)):
                f = open(img, 'r')
                data = base64.b64encode(f.read())
                f.close()
                node_img = resp.addChild(name="avatar", attrs={"name": img.split("/")[-1], "content-type": "image/%s" % ctype})
                node_img.setData(data)
        
        return resp
    
    
    def set_avatar(self, name):
        """
        change the current avatar of the entity.
        @type name string
        @param name the file name of avatar. base path is the configuration key "machine_avatar_directory"
        """
        name = name.replace("..", "").replace("/", "").replace("\\", "").replace(" ", "_")
        self.b64Avatar = self.b64avatar_from_filename(name)
        self.set_vcard()
    
    
    def b64avatar_from_filename(self, image):
        avatar_dir  = self.configuration.get("GLOBAL", "machine_avatar_directory")
        f = open(os.path.join(avatar_dir, image), "r")
        photo_data = base64.b64encode(f.read())
        f.close()
        return photo_data
    
    
    def process_avatar_iq(self, conn, iq):
        """
        this method is invoked when a ARCHIPEL_NS_AVATAR IQ is received.
        
        it understands IQ of type:
            - alloc
            - free
        
        @type conn: xmpp.Dispatcher
        @param conn: ths instance of the current connection that send the stanza
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ
        """
        action = self.check_acp(conn, iq)        
        self.check_perm(conn, iq, action, -1)
        
        if action == "getavatars":
            reply = self.iq_get_available_avatars(iq)
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed
        
        elif action == "setavatar":
            reply = self.iq_set_available_avatars(iq)
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed
    
    
    def iq_get_available_avatars(self, iq):
        """
        return a list of availables avatars
        """
        try:
            reply = iq.buildReply("result")
            reply.setQueryPayload([self.get_available_avatars()])
        except Exception as ex:
            reply = build_error_iq(self, ex, iq, ARCHIPEL_ERROR_CODE_AVATARS)
        return reply
    
    
    def iq_set_available_avatars(self, iq):
        """
        set the current avatars of the virtual machine
        """
        try:
            reply = iq.buildReply("result")
            avatar = iq.getTag("query").getTag("archipel").getAttr("avatar")
            self.set_avatar(avatar)
        except Exception as ex:
            reply = build_error_iq(self, ex, iq, ARCHIPEL_ERROR_CODE_SET_AVATAR)
        return reply
    
    
    
    ### Tags
    
    def process_tags_iq(self, conn, iq):
        """
        this method is invoked when a ARCHIPEL_NS_TAGS IQ is received.
        
        it understands IQ of type:
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
            conn.send(reply);
            raise xmpp.protocol.NodeProcessed
    
    
    def set_tags(self, tags):
        """
        set the tags of the current entity
        
        @type tags String
        @param tags the string containing tags separated by ';;'
        """
        current_id = None;
        for item in self.pubSubNodeTags.get_items():
            if item.getTag("tag") and item.getTag("tag").getAttr("jid") == self.jid.getStripped():
                current_id = item.getAttr("id");
        if current_id:
            self.pubSubNodeTags.remove_item(current_id, callback=self.did_clean_old_tags, user_info=tags)
        else:
            tagNode = xmpp.Node(tag="tag", attrs={"jid": self.jid.getStripped(), "tags": tags})
            self.pubSubNodeTags.add_item(tagNode);
    
    
    def did_clean_old_tags(self, resp, user_info):
        """
        callback called when old tags has been removed if any
        """
        if resp.getType() == "result":
            tagNode = xmpp.Node(tag="tag", attrs={"jid": self.jid.getStripped(), "tags": user_info})
            self.pubSubNodeTags.add_item(tagNode);
        else:
            raise Exception("Tags unable to set tags. answer is: " + str(resp))
    
    
    def iq_set_tags(self, iq):
        """
        set the current tags
        """
        try:
            reply = iq.buildReply("result")
            tags = iq.getTag("query").getTag("archipel").getAttr("tags")
            self.set_tags(tags)
        except Exception as ex:
            reply = build_error_iq(self, ex, iq, ARCHIPEL_ERROR_CODE_SET_TAGS)
        return reply
    
    
    
    ### XMPP Message registrars
    
    def process_message(self, conn, msg):
        """
        Handler for incoming message.
        
        @type conn: xmpp.Dispatcher
        @param conn: ths instance of the current connection that send the message
        @type msg: xmpp.Protocol.Message
        @param msg: the received message 
        """
        try:
            log.info("chat message received from %s to %s: %s" % (msg.getFrom(), str(self.jid), msg.getBody()))
            
            reply_stanza = self.filter_message(msg)
            reply = None
            
            if reply_stanza:
                if self.permission_center.check_permission(str(msg.getFrom().getStripped()), "message"):
                     reply = self.build_reply(reply_stanza, msg)
                else:
                   reply = msg.buildReply("I'm sorry, my parents aren't allowing me to talk to strangers")
        except Exception as ex:
            reply = msg.buildReply("Cannot process the message: error is %s" % str(ex))
        
        if reply:
            conn.send(reply)
    
    
    def add_message_registrar_item(self, item):
        """
        Register a method described in item
        the item use the following form:
        
        {  "commands" :     ["command trigger 1", "command trigger 2"], 
            "parameters":   [
                                {"name": "param1", "description": "the description of the first param"}, 
                                {"name": "param2", "description": "the description of the second param"}
                            ], 
            "method":       self.a_method_to_launch,
            "permissions":   "the permissions in a array you need to process the command",
            "description":  "A general description of the command"
        }
        
        The "method" key take any method with type (string)aMethod(raw_command_message). The return string
        will be sent to the requester
        
        @type item: dictionnary
        @param item: the dictionnary describing the registrar item
        """
        log.debug("module have registred a method %s for commands %s" % (str(item["method"]), str(item["commands"])))
        self.messages_registrar.append(item)
    
    
    def add_message_registrar_items(self, items):
        """
        register an array of item see @add_message_registrar_item
        
        @type item: array
        @param item: an array of messages_registrar items
        """
        for item in items:
            self.add_message_registrar_item(item)
    
    
    def filter_message(self, msg):
        """
        this method filter archipel push messages and archipel service messages
        
        @type conn: xmpp.Dispatcher
        @param conn: ths instance of the current connection that send the message
        @type msg: xmpp.Protocol.Message
        @param msg: the received message
        """
        if not msg.getType() == ARCHIPEL_NS_SERVICE_MESSAGE and not msg.getType() == ARCHIPEL_NS_IQ_PUSH and not msg.getType() == "error" and msg.getBody():
            log.info("message received from %s (%s)" % (msg.getFrom(), msg.getType()))
            reply = msg.buildReply("not prepared")
            me = reply.getFrom()
            me.setResource(self.resource)
            reply.setType("chat")
            return reply
        else:
            log.info("message ignored from %s (%s)" % (msg.getFrom(), msg.getType()))
            return False
    
    
    def build_reply(self, reply_stanza, msg):
        """
        parse the registrar and execute commands if necessary
        """
        
        body = "%s" % msg.getBody().lower()
        reply_stanza.setBody("not understood")
        
        if body.find("help") >= 0:
            reply_stanza.setBody(self.build_help(msg))
        else:
            loop = True
            for registrar_item in self.messages_registrar:
                for cmd in registrar_item["commands"]:
                    if body.find(cmd) >= 0:
                        granted  = True
                        if registrar_item.has_key("permissions"):
                            granted = self.permission_center.check_permissions(msg.getFrom().getStripped(), registrar_item["permissions"])
                        
                        if granted:
                            m = registrar_item["method"]
                            resp = m(msg)
                            reply_stanza.setBody(resp)
                        else:
                            reply_stanza.setBody("Sorry, you do not have the needed permission to execute this command.")
                        loop = False
                        break
                if not loop:
                    break
        
        return reply_stanza
    
    
    def build_help(self, msg):
        """
        build the help message according to the current registrar
        
        @return the string containing the help message
        """
        resp = ARCHIPEL_MESSAGING_HELP_MESSAGE
        for registrar_item in self.messages_registrar:
            if not registrar_item.has_key("ignore"):
                
                granted = True
                if registrar_item.has_key("permissions"):
                    granted = self.permission_center.check_permissions(msg.getFrom().getStripped(), registrar_item["permissions"])
                
                if granted:
                    cmds = str(registrar_item["commands"])
                    desc = registrar_item["description"]
                    params = registrar_item["parameters"]
                    params_string = ""
                    for p in params:
                        params_string += "%s: %s\n" % (p["name"], p["description"])
                
                    if params_string == "":
                        params_string = "No parameters"
                    else:
                        params_string = params_string[:-1]
                
                    resp += "%s: %s\n%s\n\n" % (cmds, desc, params_string)
        
        return resp
    
    
    
    ### Permission IQ
    
    def process_permission_iq(self, conn, iq):
        """
        this method is invoked when a ARCHIPEL_NS_PERMISSIONS IQ is received.
        
        it understands IQ of type:
            - list
            - get
            - set
            
        @type conn: xmpp.Dispatcher
        @param conn: ths instance of the current connection that send the stanza
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ
        """
        action = self.check_acp(conn, iq)
        if not action == "getown":
            self.check_perm(conn, iq, action, -1, prefix="permission_")
                
        if action == "list":
            reply = self.iq_list_permission(iq)
            conn.send(reply);
            raise xmpp.protocol.NodeProcessed
        
        if action == "set":
            reply = self.iq_set_permission(iq, onlyown=False)
            conn.send(reply);
            raise xmpp.protocol.NodeProcessed
        
        if action == "setown":
            reply = self.iq_set_permission(iq, onlyown=True)
            conn.send(reply);
            raise xmpp.protocol.NodeProcessed
        
        elif action == "get":
            reply = self.iq_get_permission(iq, onlyown=False)
            conn.send(reply);
            raise xmpp.protocol.NodeProcessed
        
        elif action == "getown":
            reply = self.iq_get_permission(iq, onlyown=True)
            conn.send(reply);
            raise xmpp.protocol.NodeProcessed
    
    
    def iq_set_permission(self, iq, onlyown):
        """
        set a list of permission
        
        @type iq: xmpp.Node
        @param iq: the original request IQ
        @type onlyown: Boolean
        @param onlyown: if True, will raise an exception if user trying to set permission for other user
        """
        try:
            reply   = iq.buildReply("result")
            errors  = []
            perms   = iq.getTag("query").getTag("archipel").getTags(name="permission")
            
            if onlyown:
                for perm in perms:
                    if not perm.getAttr("permission_target") == iq.getFrom().getStripped():
                        raise Exception("You cannot set permissions of other users")
            
            perm_targets = [];
            for perm in perms:
                perm_type   = perm.getAttr("permission_type")
                perm_target = perm.getAttr("permission_target")
                perm_name   = perm.getAttr("permission_name")
                perm_value  = perm.getAttr("permission_value")
                
                if perm_type == "role":
                    if perm_value.upper() in ("1", "TRUE", "YES", "Y"):
                        if not self.permission_center.grant_permission_to_role(perm_name, perm_target):
                            errors.append("cannot grant permission %s on role %s" % (perm_name, perm_target))
                    else:
                        if not self.permission_center.revoke_permission_to_role(perm_name, perm_target):
                            errors.append("cannot revoke permission %s on role %s" % (perm_name, perm_target))
            
                elif perm_type == "user":
                    if perm_value.upper() in ("1", "TRUE", "YES", "Y", "OUI", "O"):
                        log.info("granting permission %s to user %s" % (perm_name, perm_target))
                        if not self.permission_center.grant_permission_to_user(perm_name, perm_target):
                            errors.append("cannot grant permission %s on user %s" % (perm_name, perm_target))
                    else:
                        log.info("revoking permission %s to user %s" % (perm_name, perm_target))
                        if not self.permission_center.revoke_permission_to_user(perm_name, perm_target):
                            errors.append("cannot revoke permission %s on user %s" % (perm_name, perm_target))
                    
                    if perm_name == "presence":
                        if self.permission_center.check_permission(perm_target, "presence"):
                            self.authorize(xmpp.JID(perm_target))
                        else:
                            self.unauthorize(xmpp.JID(perm_target))
                if not perm_target in perm_targets:
                        perm_targets.append(perm_target);
                    
            if len(errors) > 0:
                reply =  build_error_iq(self, str(errors), iq, ARCHIPEL_NS_PERMISSION_ERROR)
            
            for target in perm_targets:
                self.push_change("permissions", target)
            
        except Exception as ex:
            reply = build_error_iq(self, ex, iq, ARCHIPEL_ERROR_CODE_SET_PERMISSIONS)
        return reply
    
    
    def iq_get_permission(self, iq, onlyown):
        """
        return the list of permissions of a user
        
        @type iq: xmpp.Node
        @param iq: the original request IQ
        @type onlyown: Boolean
        @param onlyown: if True, will raise an exception if user trying to set permission for other user
        """
        try:
            reply = iq.buildReply("result")
            nodes = []
            perm_type   = iq.getTag("query").getTag("archipel").getAttr("permission_type")
            perm_target = iq.getTag("query").getTag("archipel").getAttr("permission_target")
            
            if onlyown and not perm_target == iq.getFrom().getStripped():
                raise Exception("You cannot get permissions of other users")
                
            if perm_type == "user":
                permissions = self.permission_center.get_user_permissions(perm_target)
                if permissions:
                    for perm in permissions:
                        nodes.append(xmpp.Node(tag="permission", attrs={"name": perm.name}))
            reply.setQueryPayload(nodes);
            
        except Exception as ex:
            reply = build_error_iq(self, ex, iq, ARCHIPEL_ERROR_CODE_GET_PERMISSIONS)
        return reply
    
    
    def iq_list_permission(self, iq):
        """
        return the list of available permission
        @type iq: xmpp.Node
        @param iq: the original request IQ
        """
        
        try:
            reply = iq.buildReply("result")
            nodes = []
                        
            permissions = self.permission_center.get_permissions()
            if permissions:
                for perm in permissions:
                    nodes.append(xmpp.Node(tag="permission", attrs={"name": perm.name, "default": perm.defaultValue, "description": perm.description}))
            reply.setQueryPayload(nodes);
            
        except Exception as ex:
            reply = build_error_iq(self, ex, iq, ARCHIPEL_ERROR_CODE_LIST_PERMISSIONS)
        return reply
    
    
    
    ### Loop
    
    def loop(self):
        """
        This is the main loop of the client
        """
        while not self.loop_status == ARCHIPEL_XMPP_LOOP_OFF:
            try:
                if self.loop_status == ARCHIPEL_XMPP_LOOP_REMOVE_USER:
                    self.process_inband_unregistration()
                    return
                    
                if self.loop_status == ARCHIPEL_XMPP_LOOP_ON:
                    if self.xmppclient.isConnected():
                        self.xmppclient.Process(3)
                        
                elif self.loop_status == ARCHIPEL_XMPP_LOOP_RESTART:
                    if self.xmppclient.isConnected():
                        self.xmppclient.disconnect()
                    time.sleep(1.0)
                    self.connect()
            except Exception as ex:
                log.info("GREPME: Loop exception : %s. Loop status is now %d" % (ex, self.loop_status))
                traceback.print_exc(file=sys.stdout, limit=20)
                
                if str(ex).find('User removed') > -1: # ok, there is something I haven't understood with exception...
                    log.info("GREPME : Account has been removed from server")
                    self.loop_status = ARCHIPEL_XMPP_LOOP_OFF
                    
                elif self.auto_reconnect:
                    log.info("GREPME : Disconnected from server. Trying to reconnect in 5 five seconds")
                    self.loop_status = ARCHIPEL_XMPP_LOOP_RESTART
                    time.sleep(5.0)
                    
                else:
                    log.error("GREPME : End of loop forced by exception : %s" % str(ex))
                    self.loop_status = ARCHIPEL_XMPP_LOOP_OFF
                print traceback.extract_stack()
                
                
        if self.xmppclient.isConnected():
            self.xmppclient.disconnect()
    




