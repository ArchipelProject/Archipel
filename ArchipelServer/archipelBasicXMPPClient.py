# 
# archipelBasicXMPPClient.py
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
Contains ArchipelBasicXMPPClient, the root class of any Archipel XMPP capable entities

This provides basic XMPP features, like connecting, auth...
"""
import xmpp
import sys
import socket
from utils import *
import uuid
import os
import base64
import hashlib

LOOP_OFF = 0
"""indicates loop off status"""

LOOP_ON = 1
"""indicates loop on status"""

LOOP_RESTART = 2
"""indicates loop restart status"""


ARCHIPEL_NS_IQ_PUSH = "archipel:push"

class TNArchipelBasicXMPPClient(object):
    """
    this class represent a basic XMPP Client
    """
    def __init__(self, jid, password, configuration, auto_register=True):
        """
        The constructor of the class.
        
        @type jid: string
        @param jid: the jid of the client.
        @type password: string
        @param password: the password of the JID account.
        """
        self.xmppstatus = None;
        self.xmppstatushow = None;
        self.xmppclient = None;
        self.configuration = configuration;
        self.auto_register = auto_register
        self.password = password
        self.jid = xmpp.protocol.JID(jid.lower())
        log(self, LOG_LEVEL_INFO, "jid defined as {0}".format(jid.lower()))
        self.ressource = socket.gethostname()
        log(self, LOG_LEVEL_INFO, "ressource defined as {0}".format(socket.gethostname()))
        self.roster = None
        self.roster_retreived = False;
        self.registered_actions_to_perform_on_connection = [];
        
        # s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        # s.connect(('google.com', 0));
        # ipaddr, other = s.getsockname();
        self.ipaddr = self.configuration.get("GLOBAL", "machine_ip")
        
        for method in self.__class__.__dict__:
            if not method.find("__module_init__") == -1:
                m = getattr(self, method)
                m()
    
    
    
    def _connect_xmpp(self):
        """
        Initialize the connection to the the XMPP server
        
        exit on any error.
        """
        self.xmppclient = xmpp.Client(self.jid.getDomain(), debug=[])
        log(self, LOG_LEVEL_INFO, "client instance initialized")
        
        if self.xmppclient.connect() == "":
            log(self, LOG_LEVEL_ERROR, "unable to connect to XMPP server")
            sys.exit(0)
        log(self, LOG_LEVEL_INFO, "sucessfully connected")
        
        for method in self.__class__.__dict__:
            if not method.find("__module_connection__") == -1:
                m = getattr(self, method)
                m()
                
        self.register_handler();
    
            
    def _auth_xmpp(self):
        """
        Authentify the client to the XMPP server
        """
        log(self, LOG_LEVEL_INFO, "trying to authentify the client")
        if self.xmppclient.auth(self.jid.getNode(), self.password, self.ressource) == None:
            log(self, LOG_LEVEL_ERROR, "bad authentication")
            if (self.auto_register):
                log(self, LOG_LEVEL_DEBUG, "starting registration, according to propertie auto_register")
                self._inband_registration()
                return
            sys.exit(0)
        
        log(self, LOG_LEVEL_INFO, "sucessfully authenticated")
        
        self.xmppclient.sendInitPresence()
        log(self, LOG_LEVEL_INFO, "initial presence sent")   
        
        log(self, LOG_LEVEL_INFO, "roster asked")
        self.roster = self.xmppclient.getRoster()
        self.perform_all_registered_auth_actions();
        self.loop();
    
    
    def _inband_registration(self):
        """
        Do a in-band registration if auth fail
        """    
        if (not self.auto_register):    
            return;
        
        log(self, LOG_LEVEL_DEBUG, "trying to register with {0}:{1} to {2}".format(self.jid.getNode(), self.password, self.jid.getDomain()))
        iq = (xmpp.Iq(typ='set', to=self.jid.getDomain()))    
        payload_username = xmpp.Node(tag="username")
        payload_username.addData(self.jid.getNode())
        payload_password = xmpp.Node(tag="password")
        payload_password.addData(self.password)
        iq.setQueryNS("jabber:iq:register")
        iq.setQueryPayload([payload_username, payload_password])
        
        log(self, LOG_LEVEL_INFO, "registration information sent. wait for response")
        resp_iq = self.xmppclient.SendAndWaitForResponse(iq)
        
        log(self, LOG_LEVEL_INFO, "Registration process response received")
        if resp_iq.getType() == "error":
            log(self, LOG_LEVEL_ERROR, "unable to register : {0}".format(iq))
            sys.exit(0)
            
        elif resp_iq.getType() == "result":
            log(self, LOG_LEVEL_INFO, "the registration complete")
            self.disconnect();
            self.connect();
    
    
    def _inband_unregistration(self):
        """
        Do a in-band unregistration
        """
        log(self, LOG_LEVEL_DEBUG, "trying to unregister")
        iq = (xmpp.Iq(typ='set', to=self.jid.getDomain()))
        iq.setQueryNS("jabber:iq:register")
        
        remove_node = xmpp.Node(tag="remove")
        
        iq.setQueryPayload([remove_node])
        log(self, LOG_LEVEL_DEBUG, "unregistration information sent. waiting for response")
        resp_iq = self.xmppclient.send(iq)
        self.set_loop_status = LOOP_OFF
            
    
    
    def register_handler(self):
        """
        this method have to be overloaded in order to register handler for 
        XMPP events
        """
        self.xmppclient.RegisterHandler('presence', self.__process_presence_unsubscribe, typ="unsubscribe")
        self.xmppclient.RegisterHandler('presence', self.__process_presence_subscribe, typ="subscribe")
        self.xmppclient.RegisterHandler('message', self.__process_message)
        
        for method in self.__class__.__dict__:
            if not method.find("__module_register_stanza__") == -1:
                m = getattr(self, method)
                m()
    
    
    def __process_presence_subscribe(self, conn, presence):
        """
        Invoked when new jabber presence subscription is received.
        
        @type conn: xmpp.Dispatcher
        @param conn: ths instance of the current connection that send the message
        @type presence: xmpp.Protocol.Iq
        @param presence: the received IQ
        """        
        log(self, LOG_LEVEL_DEBUG, "Subscription Presence received from {0} with type {1}".format(presence.getFrom(), presence.getType()))
        #conn.send(xmpp.Presence(to=presence.getFrom(), typ="subscribed"))
        self.add_jid(presence.getFrom())
        
        raise xmpp.NodeProcessed
    
    
    def __process_presence_unsubscribe(self, conn, presence):
        """
        Invoked when new jabber presence unsubscribtion is received.
        
        @type conn: xmpp.Dispatcher
        @param conn: ths instance of the current connection that send the message
        @type presence: xmpp.Protocol.Iq
        @param presence: the received IQ
        """
        log(self, LOG_LEVEL_DEBUG, "Unubscription Presence received from {0} with type {1}".format(presence.getFrom(), presence.getType()))
        #conn.send(xmpp.Presence(to=presence.getFrom(), typ="unsubscribed"))
        self.remove_jid(presence.getFrom())
        
        raise xmpp.NodeProcessed
        
        
    def __process_message(self, conn, msg):
        """
        Handler for incoming message. this method is had to be overidden to treat message.
        
        @type conn: xmpp.Dispatcher
        @param conn: ths instance of the current connection that send the message
        @type msg: xmpp.Protocol.Message
        @param msg: the received message 
        """
        
        if msg.getBody():
            reply = msg.buildReply("Hello. At this time, I do not handle any direct interaction. Have a nice day, Human!");
            conn.send(reply);

    ######################################################################################################
    ### Public method
    ######################################################################################################
        
    def register_actions_to_perform_on_auth(self, method_name, args=[]):
        """
        Allows object to register actions (method of this class) to perform
        when the XMPP Client will be online.
        
        @type method_name: string
        @param method_name: the name of the method to launch
        @type args: Array
        @param args: an array containing the arguments to pass to the method
        """
        self.registered_actions_to_perform_on_connection.append({"name":method_name, "args": args})    
    

    def perform_all_registered_auth_actions(self):
        """
        Parse the all the registered actions for connection, and execute them
        """
        for action in self.registered_actions_to_perform_on_connection:
            if hasattr(self, action["name"]):
                m = getattr(self, action["name"])
                if action["args"] != None:
                    m(action["args"]);
                else:
                    m();
        self.registered_actions_to_perform_on_connection = [];
    
    
    def perform_all_registered_roster_actions(self):
        """
        Parse the all the registered actions for roster, and execute them
        """
        for action in self.registered_actions_to_perform_on_roster_retrieved:
            if hasattr(self, action["name"]):
                m = getattr(self, action["name"])
                if action["args"] != None:
                    m(action["args"]);
                else:
                    m();
        self.registered_actions_to_perform_on_roster_retrieved = [];
    
    
    
    def change_presence(self, presence_show, presence_status):
        self.xmppstatus = presence_status
        self.xmppstatushow = presence_show
        pres = xmpp.Presence(status=presence_status, show=presence_show)
        self.xmppclient.send(pres)
        
    
    
    def connect(self):
        """
        Connect and auth to XMPP Server
        """
        self._connect_xmpp()
        self._auth_xmpp()
    
   
    def disconnect(self):
        """
        Close the connections from XMPP server
        """
        self.xmppclient.disconnect()
    
    
    def push_change(self, namespace, change):
        ns = "archipel:push:" + namespace;
        self.roster = self.xmppclient.getRoster();
        for item in self.roster.getItems():
            push_message = xmpp.Message(typ=ns, to=str(item), attrs={"change": change});
            log(self, LOG_LEVEL_DEBUG, "pushing " + ns + " / " + change + " to item " + str(item))
            self.xmppclient.send(push_message)
    
    
    def add_jid(self, jid, groups=[]):
        """
        Add a jid to the VM Roster and authorizes it
        
        @type jid: string
        @param jid: this jid to add
        """
        log(self, LOG_LEVEL_INFO, "adding JID {0} to roster instance {1}".format(jid, str(id(self))))
        
        if not self.roster:
            self.roster = self.xmppclient.getRoster()
        
        self.roster.Subscribe(jid)
        self.roster.Authorize(jid)
        self.roster.setItem(jid, groups=groups)
        
        self.push_change("subscription", "added");
    
    
    def remove_jid(self, jid):
        """
        Remove a jid from roster and unauthorizes it
        
        @type jid: string
        @param jid: this jid to remove
        """
        #log(self, LOG_LEVEL_INFO, "removing JID {0} from roster".format(jid))
        self.roster.Unsubscribe(jid)
        self.roster.Unauthorize(jid)
        self.roster.delItem(jid)
    
    
    def is_jid_subscribed(self, jid):
          """
          Check if the JID is authorized or not

          @type jid: string
          @param jid: the jid to check in policy
          @rtype : boolean
          @return: False if not subscribed or True if subscribed
          """ 
          try:
              self.roster.getSubscription(str(jid))
              log(self, LOG_LEVEL_DEBUG, "stanza sent form authorized JID {0}".format(jid))
              return True
          except KeyError:
              log(self, LOG_LEVEL_ERROR, "stanza sent form unauthorized JID {0}".format(jid))
              return False
    
              
    def set_vcard_entity_type(self, params):
        """
        allows to define a vCard type for the entry
        
        @type params: dict
        @param params: adict containing at least entity_type keys, and options avatar_file key
        """
        log(self, LOG_LEVEL_DEBUG, "vcard making started");

        node_iq = (xmpp.Iq(typ='set', xmlns=None))
        
        type_node = xmpp.Node(tag="TYPE");
        type_node.setData(params["entity_type"]);
        
        avatar_dir  = self.configuration.get("GLOBAL", "machine_avatar_directory");
        
        try:
            avatar_file = params["avatar_file"];
        except:
            avatar_file = "default.png"
        
        f = open(os.path.join(avatar_dir, avatar_file), "r");
        photo_data = base64.b64encode(f.read());
        f.close()
        
        node_photo_content_type = xmpp.Node(tag="TYPE")
        node_photo_content_type.setData("image/png");
        
        node_photo_data = xmpp.Node(tag="BINVAL")
        node_photo_data.setData(photo_data);
        
        node_photo  = xmpp.Node(tag="PHOTO", payload=[node_photo_content_type, node_photo_data])
        
        node_iq.addChild(name="vCard", payload=[type_node, node_photo], namespace="vcard-temp")
        
        self.xmppclient.SendAndCallForResponse(stanza=node_iq, func=self.send_update_vcard, args={"photo_hash": hashlib.sha224(photo_data).hexdigest()})
        
        log(self, LOG_LEVEL_DEBUG, "vcard information sent with type: {0}".format(params["entity_type"]))        
    
    
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
        node_presence = xmpp.Presence(frm=self.jid, status=self.xmppstatus, show=self.xmppstatushow)
        
        if photo_hash:
            node_photo_sha1 = xmpp.Node(tag="photo")
            node_photo_sha1.setData(photo_hash)
            node_presence.addChild(name="x", namespace='vcard-temp:x:update', payload=[node_photo_sha1]);
        
        self.xmppclient.send(node_presence);
        log(self, LOG_LEVEL_DEBUG, "vcard update presence sent") 
    
    
    def set_loop_status(self, status):
        """
        this method is used to stop the main loop
        
        Possibles values are :
            - on
            - off
            - restart
        @type status: string
        @param status: the status of the main loop
        """
        self.loop_status = status
    

    def loop(self):
        """
        This is the main loop of the client
        MUST HAVE to be change in future (because it's piggy)
        """
        self.loop_status = LOOP_ON
        while True:
            try:
                if self.loop_status == LOOP_ON:
                    self.xmppclient.Process(1)
                elif self.loop_status == LOOP_RESTART:
                    self.disconnect()
                    self.connect()
                    self.loop_status = LOOP_ON
                elif self.loop_status == LOOP_OFF:
                    self.disconnect()
                    break;
            except KeyboardInterrupt:
                 log(self, LOG_LEVEL_INFO, "End of loop forced user action (now disconecting)")
                 sys.exit(0);
            except Exception as ex:
                log(self, LOG_LEVEL_INFO, "End of loop forced by exception (now disconecting) : " + str(ex))
                break;
             
    

