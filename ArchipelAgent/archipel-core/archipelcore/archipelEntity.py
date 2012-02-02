# -*- coding: utf-8 -*-
#
# archipelEntity.py
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

"""
Contains archipelEntity, the root class of any Archipel XMPP capable entities

This provides basic XMPP features, like connecting, auth...
"""

import datetime
import socket
import sys
import time
import traceback
import xmpp
from pkg_resources import iter_entry_points

from archipelcore.archipelAvatarControllableEntity import TNAvatarControllableEntity
from archipelcore.archipelFileTransferCapableEntity import TNFileTransferCapableEntity
from archipelcore.archipelHookableEntity import TNHookableEntity
from archipelcore.archipelPermissionCenter import TNArchipelPermissionCenter
from archipelcore.archipelRosterQueryableEntity import TNRosterQueryableEntity
from archipelcore.archipelTaggableEntity import TNTaggableEntity
from archipelcore.utils import TNArchipelLogger, build_error_iq

import archipelcore.archipelPermissionCenter
import archipelcore.pubsub


# Errors
ARCHIPEL_NS_ERROR_QUERY_NOT_WELL_FORMED     = -42
ARCHIPEL_ERROR_CODE_MESSAGE                 = -3
ARCHIPEL_ERROR_CODE_GET_PERMISSIONS         = -4
ARCHIPEL_ERROR_CODE_SET_PERMISSIONS         = -5
ARCHIPEL_ERROR_CODE_LIST_PERMISSIONS        = -6
ARCHIPEL_ERROR_CODE_ADD_SUBSCRIPTION        = -8
ARCHIPEL_ERROR_CODE_REMOVE_SUBSCRIPTION     = -9

# Namespace
ARCHIPEL_NS_PERMISSION_ERROR                = "archipel:error:permission"
ARCHIPEL_NS_IQ_PUSH                         = "archipel:push"
ARCHIPEL_NS_SERVICE_MESSAGE                 = "headline"
ARCHIPEL_NS_PERMISSIONS                     = "archipel:permissions"
ARCHIPEL_NS_SUBSCRIPTION                    = "archipel:subscription"

# XMPP main loop status
ARCHIPEL_XMPP_LOOP_OFF                      = 0
ARCHIPEL_XMPP_LOOP_ON                       = 1
ARCHIPEL_XMPP_LOOP_RESTART                  = 2
ARCHIPEL_XMPP_LOOP_REMOVE_USER              = 3


ARCHIPEL_MESSAGING_HELP_MESSAGE = """
You can communicate with me using text commands, just like if you were chatting with your friends. \
I try to understand you as much as I can, but you have to be nice with me.\
Note that you can use more complex sentence than describe into the following list. For example, if you see \
in the command ["how are you"], I'll understand any sentence containing "how are you". Parameters (if any) are separated with spaces.
Note that the text you enter must start with the command: "How are you" works, "Hello, how are you" don't.

For example, you can send command using the following form:
command param1 param2 param3

"""


class TNArchipelEntity (object):
    """
    This class represent a basic XMPP Client.
    """

    def __init__(self, jid, password, configuration, name, auto_register=True, auto_reconnect=True):
        """
        The constructor of the class.
        @type jid: string
        @param jid: the jid of the client.
        @type password: string
        @param password: the password of the JID account.
        @type configuration: Config object
        @param configuration: the configuration object
        @type name: string
        @param name: the name of the entity
        @type auto_register: Boolean
        @param auto_register: if rTue, entity will try to create a XMPP account if needed
        @type auto_reconnect: Boolean
        @param auto_reconnect: if True, entity will try to reconnect if disconnected
        """
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
        self.pubSubNodeAdmins       = None
        self.entity_type            = "not-defined"
        self.plugins                = []
        self.is_unregistering       = False
        self.permission_db_file     = "permissions.sqlite3"
        self.permission_admin_names = dict(map(lambda x: ("STATIC_%s" % x, x), self.configuration.get("GLOBAL", "archipel_root_admins").split()))
        self.permission_center      = TNArchipelPermissionCenter(root_admins=self.permission_admin_names)

        if isinstance(self, TNHookableEntity):
            TNHookableEntity.__init__(self, self.log)
        if isinstance(self, TNAvatarControllableEntity):
            TNAvatarControllableEntity.__init__(self, configuration, self.permission_center, self.xmppclient, self.log)
        if isinstance(self, TNTaggableEntity):
            TNTaggableEntity.__init__(self, self.pubsubserver, self.jid, self.xmppclient, self.permission_center, self.log)
        if isinstance(self, TNRosterQueryableEntity):
            TNRosterQueryableEntity.__init__(self, configuration, self.permission_center, self.xmppclient, self.log)
        if isinstance(self, TNFileTransferCapableEntity):
            TNFileTransferCapableEntity.__init__(self, self.jid, self.xmppclient, self.permission_center, self.log)

        if self.name == "auto":
            self.name = self.resource

        if isinstance(self, TNHookableEntity):
            self.create_hook("HOOK_ARCHIPELENTITY_XMPP_CONNECTED")
            self.create_hook("HOOK_ARCHIPELENTITY_XMPP_DISCONNECTED")
            self.create_hook("HOOK_ARCHIPELENTITY_XMPP_AUTHENTICATED")
            self.create_hook("HOOK_ARCHIPELENTITY_PLUGIN_ALL_LOADED")

            ## recover/create pubsub after connection
            self.register_hook("HOOK_ARCHIPELENTITY_XMPP_AUTHENTICATED", self.recover_pubsubs)

        self.log.info("jid defined as %s" % (str(self.jid)))

        ip_conf = self.configuration.get("GLOBAL", "machine_ip")
        if ip_conf == "auto":
            self.ipaddr = socket.gethostbyname(socket.gethostname())
        else:
            self.ipaddr = ip_conf

    def initialize_modules(self, group):
        """
        This will initialize all plugins.
        @type group: string
        @param group: the name of the entry point group to load
        """
        excluded_plugins = []
        loading_module_policy = self.configuration.get("GLOBAL", "module_loading_policy")
        if not loading_module_policy in ('restrictive', 'permissive'):
           self.log.error("PLUGIN: loading_module_policy in configuration must be set to 'restrictive' or 'permissive'. Consider this as a major failure.")
           return
        for factory_method in iter_entry_points(group=group, name="factory"):
            try:
                method              = factory_method.load()
                plugins             = method(self.configuration, self, group)
                for plugin in plugins:
                    plugin_info     = plugin["info"]

                    if loading_module_policy == "restrictive":
                        if not self.configuration.has_option("MODULES", plugin_info["identifier"]):
                            self.log.info("PLUGIN: plugin %s has not been loaded as it is not defined in configuration and loading mode is restrictive." % plugin_info["identifier"])
                            continue
                        elif not self.configuration.getboolean("MODULES", plugin_info["identifier"]):
                            self.log.info("PLUGIN: plugin %s has not been loaded because it is disabled by configuration." % plugin_info["identifier"])
                            continue
                    elif loading_module_policy == "permissive":
                        if self.configuration.has_option("MODULES", plugin_info["identifier"]):
                            if not self.configuration.getboolean("MODULES", plugin_info["identifier"]):
                                self.log.info("PLUGIN: plugin %s has not been loaded as it is excluded by configuration." % plugin_info["identifier"])
                                continue
                    if plugin_info["configuration-section"]:
                        if not self.configuration.has_section(plugin_info["configuration-section"]):
                            excluded_plugins.append(plugin_info["identifier"])
                            self.log.error("PLUGIN: plugin %s needs configuration section with name [%s]" % (plugin_info["identifier"], plugin_info["configuration-section"]))
                            self.loop_status = ARCHIPEL_XMPP_LOOP_OFF
                        for needed_token in plugin_info["configuration-tokens"]:
                            if not self.configuration.has_option(plugin_info["configuration-section"], needed_token):
                                excluded_plugins.append(plugin_info["identifier"])
                                self.log.error("PLUGIN: plugin %s needs configuration option with name %s" % (plugin_info["identifier"], needed_token))
                                self.loop_status = ARCHIPEL_XMPP_LOOP_OFF
                    self.log.info("PLUGIN: loaded plugin %s " % plugin_info["identifier"])
                    self.plugins.append(plugin)
            except Exception as ex:
                self.log.error("PLUGIN: unable to load plugin %s: %s" % (str(factory_method), str(ex)))
        self.perform_hooks("HOOK_ARCHIPELENTITY_PLUGIN_ALL_LOADED")

    def get_plugin(self, identifier):
        """
        Return the plugin object with given identifier.
        @type identifier: string
        @param identifier: the identifier of the plugin
        @rtype: object
        @return: the requested plugin or None
        """
        for plugin in self.plugins:
            if plugin["info"]["identifier"] == identifier:
                return plugin["plugin"]
        return None

    def check_acp(self, conn, iq):
        """
        Check if iq is a valid ACP and return action. If it's not valid,
        this will terminate the stanza processing and will return to the origin
        client a standard Archipel error IQ.
        @type conn: xmpp connection
        @param conn: the current current XMPP connection
        @type iq: xmpp.Iq
        @param iq: the iq to check
        @rtype: string or none
        @return: if the ACP is valid, it will return the requested action.
        otherwise it'll send ARCHIPEL_NS_ERROR_QUERY_NOT_WELL_FORMED iq to the sender
        and raise xmpp.protocol.NodeProcessed
        """
        try:
            action = iq.getTag("query").getTag("archipel").getAttr("action")
            self.log.info("acp received: from: %s, type: %s, namespace: %s, action: %s" % (iq.getFrom(), iq.getType(), iq.getQueryNS(), action))
            return action
        except Exception as ex:
            reply = build_error_iq(self, ex, iq, ARCHIPEL_NS_ERROR_QUERY_NOT_WELL_FORMED)
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed


    ### vocabulary

    def init_vocabulary(self):
        """
        Initialize the vocabulary.
        """
        if isinstance(self, TNRosterQueryableEntity):
            TNRosterQueryableEntity.init_vocabulary(self)


    ### Permissions

    def init_permissions(self):
        """
        Initializes the permissions.
        Overrides this to add custom permissions.
        """
        self.log.info("initializing permissions of %s" % self.jid)
        if isinstance(self, TNTaggableEntity):
            TNTaggableEntity.init_permissions(self)
        if isinstance(self, TNAvatarControllableEntity):
            TNAvatarControllableEntity.init_permissions(self)
        if isinstance(self, TNFileTransferCapableEntity):
            TNFileTransferCapableEntity.init_permissions(self)

        self.permission_center.create_permission("all", "All permissions are granted", False)
        self.permission_center.create_permission("presence", "Authorizes users to request presences", False)
        self.permission_center.create_permission("message", "Authorizes users to send messages", False)
        self.permission_center.create_permission("permission_get", "Authorizes users to get all permissions", True)
        self.permission_center.create_permission("permission_getown", "Authorizes users to get only own permissions", False)
        self.permission_center.create_permission("permission_list", "Authorizes users to list existing", False)
        self.permission_center.create_permission("permission_set", "Authorizes users to set all permissions", False)
        self.permission_center.create_permission("permission_setown", "Authorizes users to set only own permissions", False)
        self.permission_center.create_permission("subscription_add", "Authorizes users add others in entity roster", False)
        self.permission_center.create_permission("subscription_remove", "Authorizes users remove others in entity roster", False)
        self.log.info("permissions of %s initialized" % self.jid)

    def check_perm(self, conn, stanza, action_name, error_code=-1, prefix=""):
        """
        Check if given from of stanza has a given permission.
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
        self.log.info("Checking permission for action %s%s asked by %s" % (prefix, action_name, stanza.getFrom()))
        if not self.permission_center.check_permission(str(stanza.getFrom().getStripped()), "%s%s" % (prefix, action_name)):
            conn.send(build_error_iq(self, "Cannot use '%s': permission denied" % action_name, stanza, code=error_code, ns=ARCHIPEL_NS_PERMISSION_ERROR))
            raise xmpp.protocol.NodeProcessed


    ### Server connection

    def connect_xmpp(self):
        """
        Initialize the connection to the the XMPP server.
        Exit on any error.
        @rtype: Boolean
        @return: True in case of success
        """
        debug_mode = []
        if self.configuration.has_option("LOGGING", "xmpppy_debug") and self.configuration.getboolean("LOGGING", "xmpppy_debug"):
            debug_mode = ['always', 'nodebuilder']
        self.xmppclient = xmpp.Client(self.jid.getDomain(), debug=debug_mode) #debug=['dispatcher', 'nodebuilder', 'protocol'])
        if self.xmppclient.connect() == "":
            if self.auto_reconnect:
                self.loop_status = ARCHIPEL_XMPP_LOOP_RESTART
                self.log.warning("Unable to connect to XMPP server. Waiting 5 seconds for reconnection")
                time.sleep(5)
                return False
            else:
                self.log.error("Unable to connect to XMPP server. Exiting")
                self.loop_status = ARCHIPEL_XMPP_LOOP_OFF
        self.loop_status = ARCHIPEL_XMPP_LOOP_ON
        self.log.info("Successfully connected to XMPP with JID %s" % str(self.jid))
        self.perform_hooks("HOOK_ARCHIPELENTITY_XMPP_CONNECTED")
        return True

    def auth_xmpp(self):
        """
        Authentify the client to the XMPP server.
        """
        self.log.info("Trying to authentify the client with username %s and resource %s" % (self.jid.getNode(), self.resource))
        result = self.xmppclient.auth(self.jid.getNode(), self.password, self.resource)
        if result == None:
            self.isAuth = False
            if self.auto_register:
                self.log.info("Starting registration, according to propertie auto_register.")
                self.inband_registration()
                return
            self.log.error("Bad authentication or unable to register account. Exiting.")
            self.loop_status = ARCHIPEL_XMPP_LOOP_OFF
            raise Exception("Unable to authenticate user. exiting")
        self.log.info("Successfully authenticated.")
        self.isAuth = True
        self.loop_status = ARCHIPEL_XMPP_LOOP_ON
        self.register_handlers()
        self.roster = self.xmppclient.getRoster()
        self.perform_hooks("HOOK_ARCHIPELENTITY_XMPP_AUTHENTICATED")

    def connect(self):
        """
        Connect and auth to XMPP Server.
        """
        if self.xmppclient and self.xmppclient.isConnected():
            self.log.warning("Trying to connect, but already connected. Ignoring.")
            return
        if self.connect_xmpp():
            self.auth_xmpp()

    def disconnect(self):
        """
        Close the connections from XMPP server.
        """
        if self.xmppclient and self.xmppclient.isConnected():
            self.isAuth = False
            self.loop_status = ARCHIPEL_XMPP_LOOP_OFF
            self.perform_hooks("HOOK_ARCHIPELENTITY_XMPP_DISCONNECTED")
        else:
            self.log.warning("Trying to disconnect, but not connected. Ignoring.")

    ### Pubsub

    def recover_pubsubs(self, origin, user_info, arguments):
        """
        Create or get the current hypervisor pubsub node.
        Arguments here are used to be HOOK compliant see @register_hook
        """
        TNTaggableEntity.recover_pubsubs(self, origin, user_info, arguments)
        # creating/getting the event pubsub node
        eventNodeName = "/archipel/" + self.jid.getStripped() + "/events"
        self.pubSubNodeEvent = archipelcore.pubsub.TNPubSubNode(self.xmppclient, self.pubsubserver, eventNodeName)
        if not self.pubSubNodeEvent.recover(wait=True):
            self.pubSubNodeEvent.create(wait=True)
        self.pubSubNodeEvent.configure({
            archipelcore.pubsub.XMPP_PUBSUB_VAR_ACCESS_MODEL: archipelcore.pubsub.XMPP_PUBSUB_VAR_ACCESS_MODEL_OPEN,
            archipelcore.pubsub.XMPP_PUBSUB_VAR_DELIVER_NOTIFICATION: 1,
            archipelcore.pubsub.XMPP_PUBSUB_VAR_PERSIST_ITEMS: 0,
            archipelcore.pubsub.XMPP_PUBSUB_VAR_NOTIFY_RECTRACT: 0,
            archipelcore.pubsub.XMPP_PUBSUB_VAR_DELIVER_PAYLOADS: 1,
            archipelcore.pubsub.XMPP_PUBSUB_VAR_SEND_LAST_PUBLISHED_ITEM: archipelcore.pubsub.XMPP_PUBSUB_VAR_SEND_LAST_PUBLISHED_ITEM_NEVER
        }, wait=True)
        # creating/getting the log pubsub node
        logNodeName = "/archipel/" + self.jid.getStripped() + "/logs"
        self.pubSubNodeLog = archipelcore.pubsub.TNPubSubNode(self.xmppclient, self.pubsubserver, logNodeName)
        if not self.pubSubNodeLog.recover(wait=True):
            self.pubSubNodeLog.create(wait=True)
        self.pubSubNodeLog.configure({
                archipelcore.pubsub.XMPP_PUBSUB_VAR_ACCESS_MODEL: archipelcore.pubsub.XMPP_PUBSUB_VAR_ACCESS_MODEL_OPEN,
                archipelcore.pubsub.XMPP_PUBSUB_VAR_DELIVER_NOTIFICATION: 1,
                archipelcore.pubsub.XMPP_PUBSUB_VAR_MAX_ITEMS: self.configuration.get("LOGGING", "log_pubsub_max_items"),
                archipelcore.pubsub.XMPP_PUBSUB_VAR_PERSIST_ITEMS: 1,
                archipelcore.pubsub.XMPP_PUBSUB_VAR_NOTIFY_RECTRACT: 0,
                archipelcore.pubsub.XMPP_PUBSUB_VAR_DELIVER_PAYLOADS: 1,
                archipelcore.pubsub.XMPP_PUBSUB_VAR_SEND_LAST_PUBLISHED_ITEM: archipelcore.pubsub.XMPP_PUBSUB_VAR_SEND_LAST_PUBLISHED_ITEM_NEVER
        }, wait=True)

        # Recovering eventual admin account pubsub node
        ## get the admins in pubsub
        adminNodeName = "/archipel/adminaccounts"
        self.pubSubNodeAdmins = archipelcore.pubsub.TNPubSubNode(self.xmppclient, self.pubsubserver, adminNodeName)
        if self.pubSubNodeAdmins.recover(wait=True):
            admins = self.pubSubNodeAdmins.get_items()
            for admin in admins:
                admin_node = admin.getTag("admin")
                admin_id = admin.getAttr("id")
                addition_admin_account = "%s@%s" % (admin_node.getAttr("node"), admin_node.getAttr("domain"))
                self.permission_center.add_admin(admin_id, addition_admin_account)
            self.pubSubNodeAdmins.retrieve_subscriptions(wait=True)
            self.pubSubNodeAdmins.subscribe(self.jid, self.on_new_admin_account_publication)
        else:
            self.log.warning("Unable to find pubsub node %s for getting additional admin accounts. Using only static ones" % adminNodeName)
        self.log.debug("Here is the final admin list: %s" % self.permission_center.admins())

    def remove_pubsubs(self):
        """
        Delete own entity pubsubs.
        """
        self.log.info("Removing pubsub node for log.")
        self.pubSubNodeLog.delete(wait=True)
        self.log.info("Removing pubsub node for events.")
        self.pubSubNodeEvent.delete(wait=True)

    def on_new_admin_account_publication(self, event):
        """
        Called when a new admin accounts as been added to the pubsub
        @type event: xmpp.Node
        @param event: the pubsub event node
        """
        items = event.getTag("event").getTag("items").getTags("item")
        for item in items:
            admin_id = item.getAttr("id")
            admin_account = "%s@%s" % (item.getTag("admin").getAttr("node"), item.getTag("admin").getAttr("domain"))
            self.permission_center.add_admin(admin_id, admin_account)
            #self.push_change("permissions", admin_account)
            self.log.info("Adding %s (%s) as admin account" % (admin_account, admin_id))

        retracts = event.getTag("event").getTag("items").getTags("retract")
        for retract in retracts:
            admin_id = retract.getAttr("id")
            self.permission_center.del_admin(admin_id)
            self.log.info("Removing %s from admin account list" % admin_id)

        #self.push_change("permissions", "admins") # 'admins' will say to the client, that admin list has changed
        self.log.debug("Here is the final admin list: %s" % self.permission_center.admins())


    ### Basic handlers

    def register_handlers(self):
        """
        This method have to be overloaded in order to register handler for
        XMPP events.
        """
        if isinstance(self, TNTaggableEntity):
            TNTaggableEntity.register_handlers(self)
        if isinstance(self, TNAvatarControllableEntity):
            TNAvatarControllableEntity.register_handlers(self)
        if isinstance(self, TNRosterQueryableEntity):
            TNRosterQueryableEntity.register_handlers(self)
        if isinstance(self, TNFileTransferCapableEntity):
            TNFileTransferCapableEntity.register_handlers(self)
        self.xmppclient.RegisterHandler('presence', self.process_presence)
        self.xmppclient.RegisterHandler('message', self.process_message, typ="chat")
        self.xmppclient.RegisterHandler('iq', self.process_permission_iq, ns=ARCHIPEL_NS_PERMISSIONS)
        self.xmppclient.RegisterHandler('iq', self.process_subscription_iq, ns=ARCHIPEL_NS_SUBSCRIPTION)
        for plugin in self.plugins:
            self.log.info("PLUGIN: registering stanza handler for plugin %s" % plugin["info"]["identifier"])
            plugin["plugin"].register_handlers()
        self.log.info("handlers registred")

    def unregister_handlers(self):
        """
        Unregister all XMPP handlers.
        """
        if isinstance(self, TNTaggableEntity):
            TNTaggableEntity.unregister_handlers(self)
        if isinstance(self, TNAvatarControllableEntity):
            TNAvatarControllableEntity.unregister_handlers(self)
        if isinstance(self, TNRosterQueryableEntity):
            TNRosterQueryableEntity.unregister_handlers(self)
        if isinstance(self, TNFileTransferCapableEntity):
            TNFileTransferCapableEntity.unregister_handlers(self)
        self.xmppclient.UnregisterHandler('presence', self.process_presence)
        self.xmppclient.UnregisterHandler('message', self.process_message, typ="chat")
        self.xmppclient.UnregisterHandler('iq', self.process_permission_iq, ns=ARCHIPEL_NS_PERMISSIONS)
        self.xmppclient.UnregisterHandler('iq', self.process_subscription_iq, ns=ARCHIPEL_NS_SUBSCRIPTION)
        for plugin in self.plugins:
            self.log.info("PLUGIN: unregistering stanza handler for plugin %s" % plugin["info"]["identifier"])
            plugin["plugin"].unregister_handlers()
        self.log.info("handlers unregistered")


    ### Presence Management

    def process_presence(self, conn, presence):
        """
        Process presence stanzas.
        @type conn: xmpp.Dispatcher
        @param conn: ths instance of the current connection that send the message
        @type presence: xmpp.Protocol.Iq
        @param presence: the received IQ
        """
        if presence.getFrom().getStripped() == self.jid.getStripped():
            raise xmpp.protocol.NodeProcessed
        if not presence.getType() in ("subscribe", "unsubscribe"):
            raise xmpp.protocol.NodeProcessed
        self.log.info("Presence stanza received from %s: %s" % (presence.getFrom(), presence.getType()))
        # update roster is necessary
        if not self.roster:
            self.roster = self.xmppclient.getRoster()
        typ = presence.getType()
        jid = presence.getFrom()
        self.log.info("Managing subscribtion request with type %s" % presence.getType())
        # check permissions
        if not self.permission_center.check_permission(jid.getStripped(), "presence"):
            if typ == "subscribe":
                self.unsubscribe(jid)
            self.remove_jid(jid)
            raise xmpp.protocol.NodeProcessed
        # if everything is all right, process request
        if typ == "subscribe":
            self.authorize(jid)
        elif typ == "unsubscribe":
            self.remove_jid(jid)
        raise xmpp.protocol.NodeProcessed


    ### Subscription Management

    def process_subscription_iq(self, conn, iq):
        """
        Process presence iq with namespace ARCHIPEL_NS_SUBSCRIPTION.
        This allows to ask entity to subscribe to others users.
        it understands:
            - add
            - remove
        @type conn: xmpp.Dispatcher
        @param conn: the instance of the current connection that send the message
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ
        """
        reply = None
        action = self.check_acp(conn, iq)
        self.check_perm(conn, iq, action, -1, prefix="subscription_")
        if action == "add":
            reply = self.iq_add_subscription(iq)
        elif action == "remove":
            reply = self.iq_remove_subscription(iq)
        if reply:
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed

    def iq_add_subscription(self, iq):
        """
        Add a JID in the entity roster.
        @type iq: xmpp.Protocol.Iq
        @param iq: the IQ containing the request
        """
        try:
            reply = iq.buildReply("result")
            jid = xmpp.JID(iq.getTag("query").getTag("archipel").getAttr("jid"))
            self.log.info("add jid %s into %s's roster" % (str(jid), str(self.jid)))
            self.permission_center.grant_permission_to_user("presence", jid.getStripped())
            self.push_change("permissions", "set")
            self.add_jid(jid)
            self.authorize(jid)
        except Exception as ex:
            reply = build_error_iq(self, ex, iq, ARCHIPEL_ERROR_CODE_ADD_SUBSCRIPTION)
        return reply

    def iq_remove_subscription(self, iq):
        """
        Remove a JID from the entity roster.
        @type iq: xmpp.Protocol.Iq
        @param iq: the IQ containing the request
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


    ### XMPP Utilities

    def change_presence(self, presence_show=None, presence_status=None, callback=None):
        """
        Change the presence of the entity.
        @type presence_show: string
        @param presence_show: the value of the XMPP show
        @type presence_status: string
        @param presence_status: the value of the XMPP status
        """
        self.log.info("status change: %s show:%s" % (presence_status, presence_show))
        pres = xmpp.Presence(status=presence_status, show=presence_show)

        def presence_callback(conn, resp):
            self.xmppstatus     = presence_status
            self.xmppstatusshow = presence_show
            self.log.debug("PRESENCE : I just set change presence. The result is %s" % resp)
            if callback:
                callback(conn, resp)

        self.xmppclient.SendAndCallForResponse(stanza=pres, func=presence_callback)

    def change_status(self, presence_status):
        """
        Change only the status of the entity.
        @type presence_status: string
        @param presence_status: the value of the XMPP status
        """
        self.xmppstatus = presence_status
        pres = xmpp.Presence(status=self.xmppstatus, show=self.xmppstatusshow)
        self.xmppclient.send(pres)

    def push_change(self, namespace, change, content_node=None):
        """
        Push a change using archipel push system.
        This system will change with inclusion of pubsub.
        @type namespace: string
        @param namespace: the namespace of the push. it will be prefixed with @ARCHIPEL_NS_IQ_PUSH
        @type change: string
        @param change: the change value (can be anything, like 'newvm' in the context of the namespace)
        """
        ns = ARCHIPEL_NS_IQ_PUSH + ":" + namespace
        self.log.info("PUSH : pushing %s->%s" % (ns, change))
        push = xmpp.Node(tag="push", attrs={"date": datetime.datetime.now(), "xmlns": ns, "change": change})
        if content_node:
            push.addChild(node=content_node)
        self.pubSubNodeEvent.add_item(push)

    def shout(self, subject, message):
        """
        Send a message to everybody in roster.
        @type subject: string
        @param subject: the xmpp subject of the message
        @type message: string
        @param message: the content of the message
        """
        for barejid in self.roster.getItems():
            if self.jid.getStripped() == barejid:
                continue
            resources = self.roster.getResources(barejid)
            if len(resources) == 0:
                broadcast = xmpp.Message(body=message, typ="headline", to=barejid)
                self.log.info("SHOUTING : shouting message to %s" % (barejid))
                self.xmppclient.send(broadcast)
            else:
                for resource in resources:
                    broadcast = xmpp.Message(body=message, typ="headline", to=barejid + "/" + resource)
                    self.log.info("SHOUTING : shouting message to %s" % (barejid))
                    self.xmppclient.send(broadcast)


    ### XMPP Roster

    def add_jid(self, jid, groups=[]):
        """
        Add a jid to the VM Roster and authorizes it.
        @type jid: xmpp.JID
        @param jid: this jid to add
        """
        self.log.info("adding JID %s to roster of %s" % (str(jid), str(self.jid)))
        if not self.roster:
            self.roster = self.xmppclient.getRoster()
        self.roster.setItem(jid=jid.getStripped(), groups=groups)
        self.subscribe(jid)
        self.push_change("subscription", "added")

    def remove_jid(self, jid):
        """
        Remove a jid from roster and unauthorizes it.
        @type jid: xmpp.JID
        @param jid: this jid to remove
        """
        self.log.info("%s is removing jid %s from it's roster" % (str(self.jid), str(jid)))
        if not self.roster:
            self.roster = self.xmppclient.getRoster()
        self.roster.delItem(jid.getStripped())
        self.push_change("subscription", "removed")

    def subscribe(self, jid):
        """
        Perform a subscription. we do not user the xmpp.roster.Subscribe()
        because it doesn't support the name
        @type jid: xmpp.JID
        @param jid: this jid to remove
        """
        self.log.info("%s is subscribing to jid %s" % (str(self.jid), str(jid)))
        presence = xmpp.Presence(to=jid, typ='subscribe')
        if self.name:
            presence.addChild(name="nick", namespace="http://jabber.org/protocol/nick", payload=self.name)
        self.xmppclient.send(presence)

    def unsubscribe(self, jid):
        """
        Perform a unsubscription.
        @type jid: xmpp.JID
        @param jid: this jid to remove
        """
        self.log.info("%s is unsubscribing from jid %s" % (str(self.jid), str(jid)))
        if not self.roster:
            self.roster = self.xmppclient.getRoster()
        self.roster.Unsubscribe(jid.getStripped())
        self.roster.Unauthorize(jid.getStripped())

    def authorize(self, jid):
        """
        Authorize the given JID.
        @type jid: xmpp.JID
        @param jid: this jid to remove
        """
        self.log.info("%s is authorizing jid %s" % (str(self.jid), str(jid)))
        if not self.roster:
            self.roster = self.xmppclient.getRoster()
        self.roster.Authorize(jid)

    def unauthorize(self, jid):
        """
        Unauthorize the given JID.
        @type jid: xmpp.JID
        @param jid: this jid to remove
        """
        self.log.info("%s is authorizing jid %s" % (str(self.jid), str(jid)))
        if not self.roster:
            self.roster = self.xmppclient.getRoster()
        self.roster.Unauthorize(jid)

    def is_subscribed(self, jid):
        """
        Check if the JID is authorized or not.
        @type jid: string
        @param jid: the jid to check in policy
        @rtype : boolean
        @return: False if not subscribed or True if subscribed
        """
        try:
            subs = self.roster.getSubscription(str(jid))
            self.log.info("Stanza sent from authorized JID %s" % jid)
            if subs in ("both", "to"):
                return True
            return False
        except KeyError:
            self.log.info("Stanza sent from unauthorized JID %s" % jid)
            return False


    ### VCARD management

    def manage_vcard(self):
        """
        Retrieve vCard from server.
        """
        self.log.info("Asking for own vCard.")
        node_iq = xmpp.Iq(typ='get')
        node_iq.addChild(name="vCard", namespace="vcard-temp")
        self.xmppclient.SendAndCallForResponse(stanza=node_iq, func=self.did_receive_vcard)

    def did_receive_vcard(self, conn, vcard):
        """
        Callback of manage_vcard()
        """
        self.vCard = vcard.getTag("vCard")
        if self.vCard and self.vCard.getTag("PHOTO"):
            self.b64Avatar = self.vCard.getTag("PHOTO").getTag("BINVAL").getCDATA()
        self.log.info("Own vcard retrieved")
        self.set_vcard()

    def set_vcard(self, params={}):
        """
        Allows to define a vCard type for the entry.
        set the vcard of the entity
        @type params: dict
        @param params: the parameters of the vCard
        """
        try:
            self.log.info("vCard making started.")
            node_iq     = xmpp.Iq(typ='set', xmlns=None)
            payload     = []
            type_node   = xmpp.Node(tag="ROLE")
            type_node.setData(self.entity_type)
            payload.append(type_node)

            if hasattr(self, "vcard_infos"):
                for key, value in self.vcard_infos.items():
                    node = xmpp.Node(tag=key.upper())
                    node.setData(value)
                    payload.append(node)

            if self.name:
                name_node = xmpp.Node(tag="FN")
                name_node.setData(self.name)
                payload.append(name_node)
            if self.configuration.getboolean("GLOBAL", "use_avatar"):
                if not self.b64Avatar:
                    if params and params["filename"]:
                        self.b64avatar_from_filename(params["filename"])
                    else:
                        self.b64avatar_from_filename(self.default_avatar)
                node_photo_content_type = xmpp.Node(tag="TYPE")
                node_photo_content_type.setData("image/png")
                node_photo_data = xmpp.Node(tag="BINVAL")
                node_photo_data.setData(self.b64Avatar)
                node_photo = xmpp.Node(tag="PHOTO", payload=[node_photo_content_type, node_photo_data])
                payload.append(node_photo)
            node_iq.addChild(name="vCard", payload=payload, namespace="vcard-temp")
            ## updating internal representation of the vCard
            self.vCard = node_iq.getTag("vCard")
            self.xmppclient.SendAndCallForResponse(stanza=node_iq, func=self.send_update_vcard)
            self.log.info("vCard information sent with type: %s" % self.entity_type)
        except Exception as ex:
            self.log.error("Error during setting vCard (set_vcard) using stanza: %s EXCEPTION IS: %s" % (str(node_iq), str(ex)))

    def send_update_vcard(self, conn, presence, photo_hash=None):
        """
        This method is called by set_vcard_entity_type when the update of the
        vCard is OK. It will send the presence stanza to indicates the update of
        the vCard.
        @type conn: xmpp.Dispatcher
        @param conn: ths instance of the current connection that send the message
        @type presence: xmpp.Protocol.Iq
        @param presence: the received IQ
        @type photo_hash: string
        @param photo_hash: the SHA-1 hash of the photo that changes (optionnal)
        """
        node_presence = xmpp.Presence(status=self.xmppstatus, show=self.xmppstatusshow)
        if photo_hash:
            node_photo_sha1 = xmpp.Node(tag="photo")
            node_photo_sha1.setData(photo_hash)
        node_presence.addChild(name="x", namespace='vcard-temp:x:update')
        self.xmppclient.send(node_presence)
        self.log.info("vCard update presence sent.")


    ### Inband registration management

    def inband_registration(self):
        """
        Do a in-band registration if auth fail.
        """
        if not self.auto_register:
            return

        self.log.info("Trying to register with %s to %s" % (self.jid.getNode(), self.jid.getDomain()))
        iq = (xmpp.Iq(typ='set', to=self.jid.getDomain()))
        payload_username = xmpp.Node(tag="username")
        payload_username.addData(self.jid.getNode())
        payload_password = xmpp.Node(tag="password")
        payload_password.addData(self.password)
        iq.setQueryNS("jabber:iq:register")
        iq.setQueryPayload([payload_username, payload_password])
        self.log.info("Registration information sent. Wait for response...")
        resp_iq = self.xmppclient.SendAndWaitForResponse(iq, timeout=5)
        if resp_iq.getType() == "error":
            self.log.error("Unable to register: %s" % str(resp_iq))
            self.log.error("Unable to perform inband registration. Have you activated this in your ejabberd server configuration?")
            self.loop_status = ARCHIPEL_XMPP_LOOP_OFF
            raise Exception("Unable to perform inband registration")
        elif resp_iq.getType() == "result":
            self.log.info("Registration complete.")
            self.loop_status = ARCHIPEL_XMPP_LOOP_RESTART

    def inband_unregistration(self):
        """
        Do a in-band unregistration.
        """
        self.loop_status = ARCHIPEL_XMPP_LOOP_REMOVE_USER

    def process_inband_unregistration(self):
        """
        Perform the inband unregistration. The account will be removed
        from the server, and so, the loop will be interrupted.
        """
        self.is_unregistering = True
        self.remove_pubsubs()
        self.unregister_handlers()
        self.log.info("Trying to unregister.")
        iq = (xmpp.Iq(typ='set', to=self.jid.getDomain()))
        iq.setQueryNS("jabber:iq:register")
        remove_node = xmpp.Node(tag="remove")
        iq.setQueryPayload([remove_node])
        self.log.info("Unregistration information sent. Waiting for response...")
        resp_iq = self.xmppclient.SendAndWaitForResponse(iq)
        if resp_iq.getType() == "result":
            self.log.info("Account removed.")
        else:
            self.log.error("Unable to remove account: %s" % str(resp_iq))
        self.loop_status = ARCHIPEL_XMPP_LOOP_OFF


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
            self.log.info("Chat message received from %s to %s: %s" % (msg.getFrom(), str(self.jid), msg.getBody()))
            reply_stanza = self.filter_message(msg)
            reply = None
            if reply_stanza:
                if self.permission_center.check_permission(str(msg.getFrom().getStripped()), "message"):
                    reply = self.build_reply(reply_stanza, msg)
                else:
                    reply = msg.buildReply("I'm sorry, my parents aren't allowing me to talk to strangers.")
        except Exception as ex:
            reply = msg.buildReply("Cannot process the message: error is %s" % str(ex))
        if reply:
            conn.send(reply)

    def add_message_registrar_item(self, item):
        """
        Register a method described in item.
        The item use the following form:
            {   "commands" :     ["command trigger 1", "command trigger 2"],
                "parameters":   [
                                    {"name": "param1", "description": "the description of the first param"},
                                    {"name": "param2", "description": "the description of the second param"}],
                "method":       self.a_method_to_launch,
                "permissions":   "the permissions in a array you need to process the command",
                "description":  "A general description of the command"}
        The "method" key take any method with type (string)aMethod(raw_command_message). The return string
        will be sent to the requester.
        @type item: dictionnary
        @param item: the dictionnary describing the registrar item
        """
        self.log.debug("Plugin have registered a method %s for commands %s" % (str(item["method"]), str(item["commands"])))
        self.messages_registrar.append(item)

    def add_message_registrar_items(self, items):
        """
        Register an array of item see @add_message_registrar_item
        @type items: array
        @param items: an array of messages_registrar items
        """
        for item in items:
            self.add_message_registrar_item(item)

    def filter_message(self, msg):
        """
        This method filter archipel push messages and archipel service messages.
        @type msg: xmpp.Protocol.Message
        @param msg: the received message
        """
        if not msg.getType() == ARCHIPEL_NS_SERVICE_MESSAGE and not msg.getType() == ARCHIPEL_NS_IQ_PUSH and not msg.getType() == "error" and msg.getBody():
            self.log.info("Message received from %s (%s)" % (msg.getFrom(), msg.getType()))
            reply = msg.buildReply("not prepared")
            me = reply.getFrom()
            me.setResource(self.resource)
            reply.setType("chat")
            return reply
        else:
            self.log.info("Message ignored from %s (%s)" % (msg.getFrom(), msg.getType()))
            return False

    def build_reply(self, reply_stanza, msg):
        """
        Parse the registrar and execute commands if necessary.
        @type reply_stanza: xmpp.Node
        @param reply_stanza: the stanza to use to reply
        @type msg: xmpp.Protocol.Message
        @param msg: the received message
        """
        body = "%s" % msg.getBody().lower()
        reply_stanza.setBody("I'm sorry, I've not understood what you mean. You can type 'help' to get all command I understand.")
        if body.find("help", 0, len("help")) >= 0:
            reply_stanza.setBody(self.build_help(msg))
        else:
            loop = True
            for registrar_item in self.messages_registrar:
                for cmd in registrar_item["commands"]:
                    if body.find(cmd, 0, len(cmd)) >= 0:
                        granted = True
                        if "permissions" in registrar_item:
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
        Build the help message according to the current registrar.
        @type msg: xmpp.Protocol.Message
        @param msg: the received message
        @return the string containing the help message
        """
        resp = ARCHIPEL_MESSAGING_HELP_MESSAGE
        for registrar_item in self.messages_registrar:
            if not "ignore" in registrar_item:
                granted = True
                if "permissions" in registrar_item:
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
        This method is invoked when a ARCHIPEL_NS_PERMISSIONS IQ is received.
        It understands IQ of type:
            - get
            - getown
            - list
            - set
            - setown
        @type conn: xmpp.Dispatcher
        @param conn: ths instance of the current connection that send the stanza
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ
        """
        reply = None
        action = self.check_acp(conn, iq)
        if not action == "getown":
            self.check_perm(conn, iq, action, -1, prefix="permission_")
        if action == "list":
            reply = self.iq_list_permission(iq)
        elif action == "set":
            reply = self.iq_set_permission(iq, onlyown=False)
        elif action == "setown":
            reply = self.iq_set_permission(iq, onlyown=True)
        elif action == "get":
            reply = self.iq_get_permission(iq, onlyown=False)
        elif action == "getown":
            reply = self.iq_get_permission(iq, onlyown=True)
        if reply:
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed

    def iq_set_permission(self, iq, onlyown):
        """
        Set a list of permissions.
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
            perm_targets = []
            for perm in perms:
                perm_type   = perm.getAttr("permission_type")
                perm_target = perm.getAttr("permission_target")
                perm_name   = perm.getAttr("permission_name")
                perm_value  = perm.getAttr("permission_value")
                if perm_type == "role":
                    if perm_value.upper() in ("1", "TRUE", "YES", "Y"):
                        if not self.permission_center.grant_permission_to_role(perm_name, perm_target):
                            errors.append("Cannot grant permission %s on role %s" % (perm_name, perm_target))
                    else:
                        if not self.permission_center.revoke_permission_to_role(perm_name, perm_target):
                            errors.append("Cannot revoke permission %s on role %s" % (perm_name, perm_target))
                elif perm_type == "user":
                    if perm_value.upper() in ("1", "TRUE", "YES", "Y", "OUI", "O"):
                        self.log.info("Granting permission %s to user %s" % (perm_name, perm_target))
                        if not self.permission_center.grant_permission_to_user(perm_name, perm_target):
                            errors.append("Gannot grant permission %s on user %s" % (perm_name, perm_target))
                    else:
                        self.log.info("Revoking permission %s to user %s" % (perm_name, perm_target))
                        if not self.permission_center.revoke_permission_to_user(perm_name, perm_target):
                            errors.append("Cannot revoke permission %s on user %s" % (perm_name, perm_target))
                    if perm_name == "presence":
                        if self.permission_center.check_permission(perm_target, "presence"):
                            self.authorize(xmpp.JID(perm_target))
                        else:
                            self.unauthorize(xmpp.JID(perm_target))
                if not perm_target in perm_targets:
                    perm_targets.append(perm_target)
            if len(errors) > 0:
                reply = build_error_iq(self, str(errors), iq, ARCHIPEL_NS_PERMISSION_ERROR)
            for target in perm_targets:
                self.push_change("permissions", target)
        except Exception as ex:
            reply = build_error_iq(self, ex, iq, ARCHIPEL_ERROR_CODE_SET_PERMISSIONS)
        return reply

    def iq_get_permission(self, iq, onlyown):
        """
        Return the list of permissions of a user.
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
                raise Exception("You cannot get permissions of other users.")
            if perm_type == "user":
                permissions = self.permission_center.get_user_permissions(perm_target)
                if permissions:
                    for perm in permissions:
                        nodes.append(xmpp.Node(tag="permission", attrs={"name": perm.name}))
            reply.setQueryPayload(nodes)
        except Exception as ex:
            reply = build_error_iq(self, ex, iq, ARCHIPEL_ERROR_CODE_GET_PERMISSIONS)
        return reply

    def iq_list_permission(self, iq):
        """
        Return the list of available permissions.
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
            reply.setQueryPayload(nodes)
        except Exception as ex:
            reply = build_error_iq(self, ex, iq, ARCHIPEL_ERROR_CODE_LIST_PERMISSIONS)
        return reply

    ### Loop

    def loop(self):
        """
        This is the main loop of the client.
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
                if str(ex).upper().find('USER REMOVED') > -1:
                    self.log.info("LOOP EXCEPTION: Account has been removed from server.")
                    self.loop_status = ARCHIPEL_XMPP_LOOP_OFF
                else:
                    if  str(ex).upper().find('SYSTEM-SHUTDOWN') > -1:
                        self.log.warning("LOOP EXCEPTION: The XMPP server has been shut down. Waiting 5 second for reconnection")
                    else:
                        self.log.error("LOOP EXCEPTION : Disconnected from server. Trying to reconnect in 5 seconds.")
                        t, v, tr = sys.exc_info()
                        self.log.error("TRACEBACK: %s" % traceback.format_exception(t, v, tr))
                    self.loop_status = ARCHIPEL_XMPP_LOOP_RESTART
                    time.sleep(5.0)

        if self.xmppclient.isConnected():
            self.xmppclient.disconnect()
