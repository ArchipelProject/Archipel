# -*- coding: utf-8 -*-
#
# archipelCentralAgent.py
#
# Copyright (C) 2013 Nicolas Ochem <nicolas.ochem@free.fr>
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
Contains L{TNArchipelCentralAgent}, the entities used for central agent.
"""

import datetime
import random
import sqlite3
from threading import Thread
from Queue import Queue

from archipelcore.archipelAvatarControllableEntity import TNAvatarControllableEntity
from archipelcore.archipelEntity import TNArchipelEntity
from archipelcore.archipelHookableEntity import TNHookableEntity
from archipelcore.archipelTaggableEntity import TNTaggableEntity
from archipelcore.pubsub import TNPubSubNode
from archipelcore.utils import build_error_iq
from archipelcore import xmpp

# this pubsub is subscribed by all hypervisors and carries the keepalive messages
# for the central agent
ARCHIPEL_KEEPALIVE_PUBSUB                = "/archipel/centralagentkeepalive"
ARCHIPEL_NS_CENTRALAGENT                 = "archipel:centralagent"

ARCHIPEL_ERROR_CODE_CENTRALAGENT         = 123

# XMPP shows
ARCHIPEL_XMPP_SHOW_ONLINE                       = "Online"

class TNDBController(Thread):
    """
    This class reprensent the database controller. The main purpose is to handle
    better concurency read/write by setting up a Queue. This is a workaround to
    avoid sqlite3 to segfault from time to time.
    """
    def __init__(self, db, log):
        super(TNDBController, self).__init__()
        self.db = db
        self.requets = Queue()
        self.name = self.__class__.__name__
        self.start()
        self.log = log

    def run(self):
        conn = sqlite3.connect(self.db)
        cursor = conn.cursor()
        while True:
            request, arg, results = self.requets.get()
            if request == '--close connection--':
                break
            try:
                cursor.execute(request, arg)
                conn.commit()
            except Exception as ex:
                self.log.error("Error while executing sql statement %s with %s (%s)" % (request, arg, ex))
                continue
            if results:
                for record in cursor:
                    results.put(record)
                results.put('--no more results--')
        conn.close()

    def execute(self, request, arg=None, results=None):
        self.requets.put((request, arg or tuple(), results))

    def select(self, request, arg=None):
        results = Queue()
        self.execute(request, arg, results)
        while True:
            record = results.get()
            if record == '--no more results--':
                break
            yield record

    def close(self):
        self.execute('--close connection--')


class TNArchipelCentralAgent (TNArchipelEntity, TNHookableEntity, TNAvatarControllableEntity, TNTaggableEntity):
    """
    This class represents a Central Agent XMPP Capable. This is a XMPP client
    which manages a central database containing all hypervisors and all vms
    in the system, and send regular pings to all hypervisors.
    """

    def __init__(self, jid, password, configuration):
        """
        This is the constructor of the class.
        @type jid: string
        @param jid: the jid of the hypervisor
        @type password: string
        @param password: the password associated to the JID
        """
        TNArchipelEntity.__init__(self, jid, password, configuration, "central-agent")
        self.log.info("Starting Archipel central agent")

        self.xmppserveraddr               = self.jid.getDomain()
        self.entity_type                  = "central-agent"
        self.default_avatar               = self.configuration.get("CENTRALAGENT", "central_agent_default_avatar")
        self.libvirt_event_callback_id    = None
        self.vcard_infos                  = {}
        self.keepalive_interval           = 10
        self.hypervisor_timeout_threshold = 60
        self.hypervisor_check_interval    = 30
        self.vcard_infos["TITLE"]         = "Central agent"

        self.log.info("Server address defined as %s" % self.xmppserveraddr)

        if self.configuration.get("CENTRALAGENT", "keepalive_interval"):
            self.keepalive_interval = int(self.configuration.get("CENTRALAGENT", "keepalive_interval"))

        if self.configuration.get("CENTRALAGENT", "hypervisor_timeout_threshold"):
            self.hypervisor_timeout_threshold = int(self.configuration.get("CENTRALAGENT", "hypervisor_timeout_threshold"))

        if self.configuration.get("CENTRALAGENT", "hypervisor_check_interval"):
            self.hypervisor_check_interval = int(self.configuration.get("CENTRALAGENT", "hypervisor_check_interval"))

        # start the permission center
        self.permission_db_file = self.configuration.get("CENTRALAGENT", "centralagent_permissions_database_path")
        self.permission_center.start(database_file=self.permission_db_file)
        self.init_permissions()

        # action on auth
        self.register_hook("HOOK_ARCHIPELENTITY_XMPP_AUTHENTICATED", method=self.hook_xmpp_authenticated)
        self.register_hook("HOOK_ARCHIPELENTITY_XMPP_AUTHENTICATED", method=self.manage_vcard_hook)

        # create hooks
        self.create_hook("HOOK_CENTRALAGENT_VM_REGISTERED")
        self.create_hook("HOOK_CENTRALAGENT_VM_UNREGISTERED")
        self.create_hook("HOOK_CENTRALAGENT_HYP_REGISTERED")
        self.create_hook("HOOK_CENTRALAGENT_HYP_UNREGISTERED")

        self.central_agent_jid_val = None
        self.xmpp_authenticated    = False
        self.is_central_agent      = False
        self.salt                  = random.random()
        self.database              = TNDBController(self.configuration.get("CENTRALAGENT", "database"), self.log)

        # defining the structure of the keepalive pubsub event
        self.keepalive_event      = xmpp.Node("event",attrs={"type":"keepalive","jid":self.jid})
        self.last_keepalive_heard = datetime.datetime.now()
        self.last_hyp_check       = datetime.datetime.now()
        self.required_stats_xml   = None

        # module inits
        self.initialize_modules('archipel.plugin.core')
        self.initialize_modules('archipel.plugin.centralagent')

        module_platformrequest = self.configuration.get("MODULES", "platformrequest")

        if module_platformrequest:
            required_stats = self.get_plugin("platformrequest").computing_unit.required_stats
            self.required_stats_xml = xmpp.Node("required_stats")

            for stat in required_stats:
                self.log.debug("CENTRALAGENT: stat : %s" % stat)
                self.required_stats_xml.addChild("stat", attrs=stat)

            self.keepalive_event.addChild(node = self.required_stats_xml)

    ### Utilities

    def init_permissions(self):
        """
        Initialize the permissions.
        """
        TNArchipelEntity.init_permissions(self)

    def register_handlers(self):
        """
        This method will be called by the plugin user when it will be
        necessary to register module for listening to stanza.
        """
        TNArchipelEntity.register_handlers(self)
        self.xmppclient.RegisterHandler('iq', self.process_iq_for_centralagent, ns=ARCHIPEL_NS_CENTRALAGENT)

    def unregister_handlers(self):
        """
        Unregister the handlers.
        """
        TNArchipelEntity.unregister_handlers(self)
        self.xmppclient.UnregisterHandler('iq', self.process_iq_for_centralagent, ns=ARCHIPEL_NS_CENTRALAGENT)

    def process_iq_for_centralagent(self, conn, iq):
        """
        This method is invoked when a ARCHIPEL_NS_CENTRALAGENT IQ is received.
        It understands IQ of type:
            - read_hypervisors
            - read_vms
            - get_existing_vms_instances
            - register_hypervisors
            - register_vms
            - update_vms
            - update_hypervisors
            - unregister_hypervisors
            - unregister_vms
        @type conn: xmpp.Dispatcher
        @param conn: ths instance of the current connection that send the stanza
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ
        """
        reply = None
        action = self.check_acp(conn, iq)
        if action == "read_hypervisors":
            reply = self.iq_read_hypervisors(iq)
        elif action == "read_vms":
            reply = self.iq_read_vms(iq)
        elif action == "get_existing_vms_instances":
            reply = self.iq_get_existing_vms_instances(iq)
        elif action == "register_hypervisors":
            reply = self.iq_register_hypervisors(iq)
        elif action == "register_vms":
            reply = self.iq_register_vms(iq)
        elif action == "update_vms":
            reply = self.iq_update_vms(iq)
        elif action == "update_vms_domain":
            reply = self.iq_update_vms_domain(iq)
        elif action == "update_hypervisors":
            reply = self.iq_update_hypervisors(iq)
        elif action == "unregister_hypervisors":
            reply = self.iq_unregister_hypervisors(iq)
        elif action == "unregister_vms":
            reply = self.iq_unregister_vms(iq)
        if reply:
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed

    ### Pubsub management

    def hook_xmpp_authenticated(self, origin=None, user_info=None, arguments=None):
        """
        Triggered when we are authenticated. Initializes everything.
        @type origin: L{TNArchipelEnity}
        @param origin: the origin of the hook
        @type user_info: object
        @param user_info: random user information
        @type arguments: object
        @param arguments: runtime argument
        """

        self.xmpp_authenticated  = True
        status = "%s" % ARCHIPEL_XMPP_SHOW_ONLINE
        self.change_presence(self.xmppstatusshow, status)

        self.is_central_agent    = False

        self.central_agent_mode  = self.configuration.get("CENTRALAGENT", "centralagent")
        self.ping_hypervisors    = self.configuration.getboolean("CENTRALAGENT", "ping_hypervisors")
        # 2 possible modes :
        # - auto          : default mode of operation. If there is no other central agent detected,
        #                   the node is acting as central agent. If 2 central agents are declared
        #                   at the same time, an election is performed.
        # - force         : will always be central agent. centralized model when one hypervisor is always online.
        #                   Warning : be sure there is only 1 otherwise they will fight with each other.
        self.log.debug("CENTRALAGENT: Mode %s" % self.central_agent_mode)
        self.central_keepalive_pubsub = TNPubSubNode(self.xmppclient, self.pubsubserver, ARCHIPEL_KEEPALIVE_PUBSUB)
        self.central_keepalive_pubsub.recover()
        self.central_keepalive_pubsub.subscribe(self.jid, self.handle_central_keepalive_event)
        self.log.info("CENTRALAGENT: entity %s is now subscribed to events from node %s" % (self.jid, ARCHIPEL_KEEPALIVE_PUBSUB))

        self.change_presence("away", "Standby")

        if self.central_agent_mode == "force":
            self.become_central_agent()
        elif self.central_agent_mode == "auto":
            self.last_keepalive_heard = datetime.datetime.now()
            self.last_hyp_check = datetime.datetime.now()

    def become_central_agent(self):
        """
        triggered when becoming active central agent
        """
        self.is_central_agent = True
        self.manage_database()
        initial_keepalive = xmpp.Node("event",attrs={"type":"keepalive","jid":self.jid})
        initial_keepalive.setAttr("force_update","true")
        initial_keepalive.setAttr("salt",self.salt)
        initial_keepalive.setAttr("keepalive_interval", self.keepalive_interval)
        initial_keepalive.setAttr("hypervisor_timeout_threshold", self.hypervisor_timeout_threshold)

        if self.required_stats_xml:
            initial_keepalive.addChild(node=self.required_stats_xml)

        self.central_keepalive_pubsub.add_item(initial_keepalive)
        self.log.debug("CENTRALAGENT: initial keepalive sent")
        self.last_keepalive_sent = datetime.datetime.now()
        self.last_hyp_check      = datetime.datetime.now()
        self.change_presence("","Active")

    def central_agent_jid(self):
        """
        Returns the jid of the central agent. In case we are a VM, query hypervisor.
        """
        return self.central_agent_jid_val

    def keepalive_event_with_date(self):
        """
        Returns the keepalive event with current date, to send to the pubsub
        so that all ping calculations are based on central agent date.
        """
        keepalive_event = self.keepalive_event
        keepalive_event.setAttr("keepalive_interval", self.keepalive_interval)
        keepalive_event.setAttr("hypervisor_timeout_threshold", self.hypervisor_timeout_threshold)

        return keepalive_event


    def handle_central_keepalive_event(self,event):
        """
        Called when the central agents announce themselves.
        @type event: xmpp.Node
        @param event: the pubsub event node
        """
        items = event.getTag("event").getTag("items").getTags("item")

        for item in items:
            central_announcement_event = item.getTag("event")
            event_type                 = central_announcement_event.getAttr("type")

            if event_type == "keepalive":
                keepalive_jid = xmpp.JID(central_announcement_event.getAttr("jid"))
                if self.is_central_agent and keepalive_jid != self.jid:
                    # detect another central agent
                    self.log.warning("CENTRALAGENT: another central agent detected, performing election")
                    keepalive_salt = float(central_announcement_event.getAttr("salt"))

                    if keepalive_salt > self.salt:
                        self.log.debug("CENTRALAGENT: stepping down")
                        self.change_presence("away","Standby")
                        self.is_central_agent = False
                    else:
                        self.log.debug("CENTRALAGENT: election won")
                        return

                self.central_agent_jid_val = keepalive_jid
                self.last_keepalive_heard  = datetime.datetime.now()

    def iq_read_hypervisors(self,iq):
        """
        Called when the central agent receives a hypervisor read event.
        @type iq: xmpp.Iq
        @param iq: received Iq
        """
        try:
            read_event      = iq.getTag("query").getTag("archipel").getTag("event")
            columns         = read_event.getAttr("columns")
            where_statement = read_event.getAttr("where_statement")
            reply           = iq.buildReply("result")
            entries         = self.read_hypervisors(columns, where_statement)
            for entry in self.pack_entries(entries):
                reply.addChild(node = entry)
        except Exception as ex:
            reply = build_error_iq(self, ex, iq, ARCHIPEL_ERROR_CODE_CENTRALAGENT)
        return reply

    def iq_read_vms(self,iq):
        """
        Called when the central agent receives a vms read event.
        @type iq: xmpp.Iq
        @param iq: received Iq
        """
        try:
            read_event      = iq.getTag("query").getTag("archipel").getTag("event")
            columns         = read_event.getAttr("columns")
            where_statement = read_event.getAttr("where_statement")
            reply           = iq.buildReply("result")
            entries         = self.read_vms(columns, where_statement)
            for entry in self.pack_entries(entries):
                reply.addChild(node = entry)
        except Exception as ex:
            reply = build_error_iq(self, ex, iq, ARCHIPEL_ERROR_CODE_CENTRALAGENT)
        return reply

    def iq_get_existing_vms_instances(self,iq):
        """
        Called when the central agent receives a request to check if entities
        are already defined elsewhere
        @type iq: xmpp.Iq
        @param iq: received Iq
        """
        try:
            entries    = self.unpack_entries(iq)
            self.log.debug("CENTRALAGENT: iq_get_existing_vms_instances : iq : %s, entries : %s" % (iq, entries))
            origin_hyp = iq.getFrom()
            reply      = iq.buildReply("result")
            entries    = self.get_existing_vms_instances(entries, origin_hyp)
            for entry in self.pack_entries(entries):
                reply.addChild(node = entry)
        except Exception as ex:
            reply = build_error_iq(self, ex, iq, ARCHIPEL_ERROR_CODE_CENTRALAGENT)
        return reply

    def iq_register_hypervisors(self,iq):
        """
        Called when the central agent receives a hypervisor registration event.
        @type iq: xmpp.Iq
        @param iq: received Iq
        """
        try:
            reply   = iq.buildReply("result")
            entries = self.unpack_entries(iq)
            self.register_hypervisors(entries)
            self.perform_hooks("HOOK_CENTRALAGENT_HYP_REGISTERED", entries)
        except Exception as ex:
            reply = build_error_iq(self, ex, iq, ARCHIPEL_ERROR_CODE_CENTRALAGENT)
        return reply

    def iq_register_vms(self,iq):
        """
        Called when the central agent receives a vms registration event.
        @type iq: xmpp.Iq
        @param iq: received Iq
        """
        try:
            reply   = iq.buildReply("result")
            entries = self.unpack_entries(iq)
            self.register_vms(entries)
            self.perform_hooks("HOOK_CENTRALAGENT_VM_REGISTERED", entries)
        except Exception as ex:
            reply = build_error_iq(self, ex, iq, ARCHIPEL_ERROR_CODE_CENTRALAGENT)
        return reply

    def iq_update_vms(self,iq):
        """
        Called when the central agent receives a vms update event.
        @type iq: xmpp.Iq
        @param iq: received Iq
        """
        try:
            reply   = iq.buildReply("result")
            entries = self.unpack_entries(iq)
            self.update_vms(entries)
        except Exception as ex:
            reply = build_error_iq(self, ex, iq, ARCHIPEL_ERROR_CODE_CENTRALAGENT)
        return reply

    def iq_update_vms_domain(self,iq):
        """
        Called when the central agent receives a vm domain update event.
        @type iq: xmpp.Iq
        @param iq: received Iq
        """
        try:
            reply   = iq.buildReply("result")
            entries = self.unpack_entries(iq)
            entries = self.update_vms_domain(entries)
            for entry in self.pack_entries(entries):
                reply.addChild(node = entry)
        except Exception as ex:
            reply = build_error_iq(self, ex, iq, ARCHIPEL_ERROR_CODE_CENTRALAGENT)
        return reply

    def iq_update_hypervisors(self,iq):
        """
        Called when the central agent receives a vms update event.
        @type iq: xmpp.Iq
        @param iq: received Iq
        """
        try:
            reply   = iq.buildReply("result")
            entries = self.unpack_entries(iq)
            self.update_hypervisors(entries)
        except Exception as ex:
            reply = build_error_iq(self, ex, iq, ARCHIPEL_ERROR_CODE_CENTRALAGENT)
        return reply

    def iq_unregister_hypervisors(self,iq):
        """
        Called when the central agent receives a hypervisor unregistration event.
        @type iq: xmpp.Iq
        @param iq: received Iq
        """
        try:
            reply   = iq.buildReply("result")
            entries = self.unpack_entries(iq)
            self.unregister_hypervisors(entries)
            self.perform_hooks("HOOK_CENTRALAGENT_HYP_UNREGISTERED", entries)
        except Exception as ex:
            reply = build_error_iq(self, ex, iq, ARCHIPEL_ERROR_CODE_CENTRALAGENT)
        return reply

    def iq_unregister_vms(self,iq):
        """
        Called when the central agent receives a vms registration event.
        @type iq: xmpp.Iq
        @param iq: received Iq
        """
        try:
            reply       = iq.buildReply("result")
            in_entries  = self.unpack_entries(iq)
            out_entries = self.unregister_vms(in_entries)
            self.perform_hooks("HOOK_CENTRALAGENT_VM_UNREGISTERED", out_entries)
            for entry in self.pack_entries(out_entries):
                reply.addChild(node = entry)
        except Exception as ex:
            reply = build_error_iq(self, ex, iq, ARCHIPEL_ERROR_CODE_CENTRALAGENT)
        return reply

    def read_hypervisors(self, columns, where_statement):
        """
        Reads list of hypervisors in central db.
        """
        read_statement = "select %s from hypervisors" % columns
        if where_statement:
            read_statement += " where %s" % where_statement
        rows = self.database.select(read_statement)
        ret = []
        for row in rows:
            ret.append({"jid":row[0], "last_seen":row[1], "status":row[2]})
        return ret

    def read_vms(self, columns, where_statement):
        """
        Read list of vms in central db.
        """
        read_statement = "select %s from vms" % columns
        if where_statement:
            read_statement += " where %s" % where_statement
        rows = self.database.select(read_statement)
        ret = []
        for row in rows:
            if columns == "*":
                ret.append({"uuid":row[0], "parker":row[1], "creation_date":row[2], "domain":row[3], "hypervisor":row[4]})
            else:
                res = {}
                i = 0
                for col in columns.split(","):
                    res[col]=row[i]
                    i+=1
                ret.append(res)
        return ret

    def get_existing_vms_instances(self, entries, origin_hyp):
        """
        Based on a list of vms, and an hypervisor, return list of vms which
        are defined in another, currently running, hypervisor.
        """
        uuids = []
        ret = []

        for entry in entries:
            uuids.append(entry["uuid"])

        read_statement = "select vms.uuid from vms join hypervisors on hypervisors.jid=vms.hypervisor"
        read_statement += " where vms.uuid in (%s)" % ','.join("?"*len(uuids))
        read_statement += " and hypervisors.jid != '%s'" % origin_hyp
        read_statement += " and hypervisors.status='Online'"

        self.log.debug("CENTRALAGENT: Check if vm uuids %s exist elsewhere " % uuids)
        for row in self.database.select(read_statement, uuids):
            ret.append({"uuid":row[0]})
        self.log.debug("CENTRALAGENT: We found %s on %s vms existing on others hypervistors." % (len(ret), len(uuids)))
        return ret

    def read_parked_vms(self, entries):
        """
        Based on a list of vms, and an hypervisor, return list of vms which
        are parked (have no hypervisor, or have a hypervisor which is not online)
        """
        uuids = []
        ret = []

        for entry in entries:
            uuids.append(entry["uuid"])

        read_statement = "select uuid, domain from vms"
        read_statement += " where uuid in (%s)" % ','.join("?"*len(uuids))
        read_statement += " and (hypervisor='None' or hypervisor not in (select jid from hypervisors where status='Online'))"

        self.log.debug("CENTRALDB: Get parked vms from database")
        for row in self.database.select(read_statement, uuids):
            ret.append({"uuid":row[0], "domain":row[1]})
        self.log.debug("CENTRALDB: We found %s parked vms" % len(ret))
        return ret

    def register_hypervisors(self,entries):
        """
        Register a list of hypervisors into central db.
        @type entries: List
        @param entries: list of hypervisors
        """
        for entry in entries:
            entry['last_seen'] = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S.%f")
        self.db_commit("insert into hypervisors values(:jid, :last_seen, :status, :stat1, :stat2, :stat3)", entries)

    def register_vms(self,entries):
        """
        Register a list of vms into central db.
        @type entries: List
        @param entries: list of vms
        """
        self.db_commit("insert into vms values(:uuid, :parker, :creation_date, :domain, :hypervisor)",entries)

    def update_vms(self,entries):
        """
        Update a list of vms in central db.
        @type entries: List
        @param entries: list of vms
        """
        update_snipplets=[]
        for key,val in entries[0].iteritems():
            if key!="uuid":
                update_snipplets.append("%s=:%s" % (key, key))
        command = "update vms set %s where uuid=:uuid" % (", ".join(update_snipplets))
        self.db_commit(command, entries)

    def update_vms_domain(self,entries):
        """
        Update a list of vms domain in central db.
        Performs extra checks compared to a raw update.
        @type entries: List
        @param entries: list of vms
        """
        results        = []
        parked_vms_ret = self.read_parked_vms(entries)
        parked_vms     = {}
        for ret in parked_vms_ret:
            parked_vms[ret["uuid"]] = {"domain":xmpp.simplexml.NodeBuilder(data=ret["domain"]).getDom()}
        entries_to_commit = []

        for i in range(len(entries)):
            entry = entries[i]
            error = False
            for key,val in entry.iteritems():
                if key == "domain":
                    new_domain = xmpp.simplexml.NodeBuilder(data=val).getDom()
                if key == "uuid":
                    uuid = val
            if uuid not in parked_vms.keys():
                result = "ERROR: There is no virtual machine parked with uuid %s" % uuid
                error = True
            else:
                old_domain    = parked_vms[uuid]["domain"]
                previous_uuid = old_domain.getTag("uuid").getData()
                previous_name = old_domain.getTag("name").getData()
                new_uuid      = ""
                new_name      = ""
                if new_domain.getTag("uuid"):
                    new_uuid = new_domain.getTag("uuid").getData()
                if new_domain.getTag("name"):
                    new_name = new_domain.getTag("name").getData()

                if not previous_uuid.lower() == new_uuid.lower():
                    result = "ERROR: UUID of new description must be the same (was %s, is %s)" % (previous_uuid, new_uuid)
                    error = True
                if not previous_name.lower() == new_name.lower():
                    result = "ERROR: Name of new description must be the same (was %s, is %s)" % (previous_name, new_name)
                    error = True
                if not new_name or new_name == "":
                    result = "ERROR: Missing name information"
                    error = True
                if not new_uuid or new_uuid == "":
                    result = "ERROR: Missing UUID information"
                    error = True
                if not error:
                    # all checks ok, performing update
                    if new_domain.getTag('description'):
                        new_domain.delChild("description")
                    previous_description = old_domain.getTag("description")
                    self.log.debug("CENTRALAGENT: previous description : %s" % str(previous_description))
                    new_domain.addChild(node=old_domain.getTag("description"))
                    result = "Central database updated with new information"
                    entries_to_commit.append({"uuid": uuid, "domain": str(new_domain)})
                results.append({"result": result, "uuid": uuid, "error": error})

        if len(entries_to_commit) >0 :
            command = "update vms set domain=:domain where uuid=:uuid"
            self.db_commit(command, entries_to_commit)
        return results

    def update_hypervisors(self,entries):
        """
        Update a list of hypervisors in central db.
        @type entries: List
        @param entries: list of vms
        """
        update_snipplets=[]
        for entry in entries:
            entry['last_seen'] = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S.%f")

        for key, val in entries[0].iteritems():
            if key!="jid":
                update_snipplets.append("%s=:%s" % (key, key))
        command = "update hypervisors set %s where jid=:jid" % (", ".join(update_snipplets))
        self.db_commit(command, entries)

    def unregister_hypervisors(self,entries):
        """
        Unregister a list of hypervisors from central db.
        @type entries: List
        @param entries: list of hypervisors
        """
        self.db_commit("delete from hypervisors where jid=:jid, last_seen=:last_seen, status=:status",entries)

    def unregister_vms(self, entries):
        """
        Unregister a list of vms from central db.
        @type entries: List
        @param entries: list of vms
        """
        # first, we extract jid so that the hypervisor can unregister them
        uuids = []
        for entry in entries:
            uuids.append(entry["uuid"])
        where_statement = "uuid = '"
        where_statement += "' or uuid='".join(uuids)
        where_statement += "'"

        # list of vms which have been found in central db, including uuid and jid
        cleaned_entries = self.read_vms("uuid,domain", where_statement)
        for i in range(len(cleaned_entries)):
            domain_xml =  cleaned_entries[i]["domain"]
            if domain_xml != "None":
                domain = xmpp.simplexml.NodeBuilder(data=cleaned_entries[i]["domain"]).getDom()
                cleaned_entries[i]["jid"] = xmpp.JID(domain.getTag("description").getData().split("::::")[0])
                del(cleaned_entries[i]["domain"])


        self.db_commit("delete from vms where uuid=:uuid",cleaned_entries)
        return cleaned_entries

    def unpack_entries(self, iq):
        """
        Unpack the list of entries from iq for database processing.
        @type iq: xmpp.Iq
        @param event: received Iq
        """
        central_database_event = iq.getTag("query").getTag("archipel").getTag("event")
        entries=[]
        for entry in central_database_event.getChildren():
            entry_dict={}
            for entry_val in entry.getChildren():
                entry_dict[entry_val.getAttr("key")]=entry_val.getAttr("value")
            entries.append(entry_dict)
        return entries

    def pack_entries(self, entries):
        """
        Pack the list of entries to send to remote entity.
        @rtype: list
        @return: list of xmpp nodes, one per entry
        @type entries: list
        @param entries: list of dict entities
        """
        packed_entries = []
        for entry in entries:
            entryTag = xmpp.Node(tag="entry")
            for key,value in entry.iteritems():
                entryTag.addChild("item",attrs={"key":key,"value":value})
            packed_entries.append(entryTag)
        return packed_entries

    def db_commit(self, command, entries):
        if self.is_central_agent:
            self.log.debug("CENTRALAGENT: commit '%s' with entries %s" % (command, entries))
            for entry in entries:
                self.database.execute(command, entry)
        else:
            raise Exception("CENTRALAGENT: we are not central agent")

    def check_hyps(self):
        """
        Check that hypervisors are alive.
        """
        self.log.debug("CENTRALAGENT: Checking hypervisors state")
        now                  = datetime.datetime.now()
        rows                 = self.database.select("select jid,last_seen,status from hypervisors;")
        hypervisor_to_update = []

        for row in rows:
            jid, last_seen, status = row
            last_seen_date = datetime.datetime.strptime(last_seen, "%Y-%m-%d %H:%M:%S.%f")
            if (now - last_seen_date).days*86400 + (now - last_seen_date).seconds > self.hypervisor_timeout_threshold and status == "Online":
                self.log.warning("CENTRALAGENT: Hypervisor %s timed out" % jid)
                hypervisor_to_update.append({"jid": jid, "status": "Unreachable"})
            elif (now - last_seen_date).days*86400 + (now - last_seen_date).seconds <= self.hypervisor_timeout_threshold and status == "Unreachable":
                self.log.info("CENTRALAGENT: Hypervisor %s is back up Online" % jid)
                hypervisor_to_update.append({"jid": jid, "status": "Online"})

        if hypervisor_to_update:
            self.update_hypervisors(hypervisor_to_update)

        self.last_hyp_check = datetime.datetime.now()

    ### Database Management

    def manage_database(self):
        """
        Create and / or recover the parking database
        """
        self.database.execute("create table if not exists vms (uuid text unique on conflict replace, parker string, creation_date date, domain string, hypervisor string)")
        self.database.execute("create table if not exists hypervisors (jid text unique on conflict replace, last_seen date, status string, stat1 int, stat2 int, stat3 int)")
        self.database.execute("update vms set hypervisor='None';")

    ### Event loop

    def on_xmpp_loop_tick(self):

        if self.xmpp_authenticated:

            if not self.is_central_agent and self.central_agent_mode == "auto":
                self.become_central_agent()
            elif self.is_central_agent: # we are central agent
                if (datetime.datetime.now() - self.last_keepalive_sent).seconds >= self.keepalive_interval:
                    self.central_keepalive_pubsub.add_item(self.keepalive_event_with_date())
                    self.last_keepalive_sent = datetime.datetime.now()

                if self.ping_hypervisors:
                    if (datetime.datetime.now() - self.last_hyp_check).seconds >= self.hypervisor_check_interval:
                        self.check_hyps()
