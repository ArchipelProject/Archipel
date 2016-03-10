# -*- coding: utf-8 -*-
#
# centraldb.py
#
# Copyright (C) 2013 Nicolas Ochem (nicolas.ochem@free.fr)
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

import datetime
import random

from archipelcore.archipelPlugin import TNArchipelPlugin
from archipelcore.pubsub import TNPubSubNode
from archipelcore import xmpp
from threading import Timer

# this pubsub is subscribed by all hypervisors and carries the keepalive messages
# for the central agent
ARCHIPEL_KEEPALIVE_PUBSUB                = "/archipel/centralagentkeepalive"

ARCHIPEL_NS_CENTRALAGENT                 = "archipel:centralagent"

ARCHIPEL_ERROR_CODE_CENTRALAGENT         = 123

ARCHIPEL_CENTRAL_AGENT_TIMEOUT           = 120

class TNTasks(object):
    """Timed jobs tasker"""
    def __init__(self, log):
        super(TNTasks, self).__init__()
        self.tasks = {}
        self.log = log

    def add(self, interval, func, kwargs={}):
        if func.__name__ in self.tasks:
            if self.tasks[func.__name__].isAlive():
                if int(self.tasks[func.__name__].interval) < int(interval):
                    return

        delay = float(interval * random.random())
        self.log.debug("CENTRALDB: [Task %s ] is delayed to %ss to avoid storm." % (func.__name__, int(delay)))
        self.tasks[func.__name__] = Timer(delay, func, kwargs=kwargs)
        self.tasks[func.__name__].start()


class TNCentralDb (TNArchipelPlugin):
    """
    This contains the necessary interfaces to interact with central agent and central db
    """

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
        TNArchipelPlugin.__init__(self, configuration=configuration, entity=entity, entry_point_group=entry_point_group)

        if self.entity.__class__.__name__ == "TNArchipelHypervisor":
            self.entity.register_hook("HOOK_ARCHIPELENTITY_XMPP_AUTHENTICATED", method=self.hypervisor_hook_xmpp_authenticated)

        if self.entity.__class__.__name__ == "TNArchipelVirtualMachine":
            self.entity.register_hook("HOOK_VM_DEFINE", method=self.hook_vm_event)
            self.entity.register_hook("HOOK_VM_TERMINATE", method=self.hook_vm_terminate)

        self.central_agent_jid_val = None
        self.last_keepalive_heard = None
        self.keepalive_interval = int(ARCHIPEL_CENTRAL_AGENT_TIMEOUT * 2)
        self.hypervisor_timeout_threshold = int(ARCHIPEL_CENTRAL_AGENT_TIMEOUT)
        self.delayed_tasks = TNTasks(self.entity.log)

        self.xmpp_authenticated    = False
        self.required_statistics        = []

    ### Hooks
    def hook_vm_event(self, origin=None, user_info=None, arguments=None):
        """
        Called when a VM definition or change of definition occurs.
        This will advertise definition to the central agent
        """
        xmldesc = None

        if self.entity.definition:
            xmldesc = self.entity.xmldesc(mask_description=False)

        vm_info=[{"uuid":self.entity.uuid,"parker":None,"creation_date":None,"domain":xmldesc,"hypervisor":self.entity.hypervisor.jid}]
        self.register_vms(vm_info)

    def hook_vm_terminate(self, origin=None, user_info=None, arguments=None):
        """
        Called when a VM termination occurs.
        This will advertise undefinition to the central agent.
        """
        self.unregister_vms([{"uuid":self.entity.uuid}], None)

    ### Pubsub management

    def hypervisor_hook_xmpp_authenticated(self, origin=None, user_info=None, arguments=None):
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
        self.central_keepalive_pubsub = TNPubSubNode(self.entity.xmppclient, self.entity.pubsubserver, ARCHIPEL_KEEPALIVE_PUBSUB)
        self.central_keepalive_pubsub.recover()
        self.central_keepalive_pubsub.subscribe(self.entity.jid, self.handle_central_keepalive_event)
        self.entity.log.info("CENTRALDB: entity %s is now subscribed to events from node %s" % (self.entity.jid, ARCHIPEL_KEEPALIVE_PUBSUB))
        self.last_keepalive_heard = datetime.datetime.now()

    def central_agent_jid(self):
        """
        Returns the jid of the central agent. In case we are a VM, query hypervisor.
        """
        # this could happen under heavy processing
        if self.last_keepalive_heard and (datetime.datetime.now() - self.last_keepalive_heard).seconds > ARCHIPEL_CENTRAL_AGENT_TIMEOUT:
            return None

        if self.entity.__class__.__name__ == "TNArchipelHypervisor":
            return self.central_agent_jid_val
        else:
            return self.entity.hypervisor.get_plugin("centraldb").central_agent_jid_val

    def handle_central_keepalive_event(self,event):
        """
        Called when the central agent sends a keepalive.
        @type event: xmpp.Node
        @param event: the pubsub event node
        """
        items = event.getTag("event").getTag("items").getTags("item")

        for item in items:
            central_announcement_event = item.getTag("event")
            event_type                 = central_announcement_event.getAttr("type")

            if event_type == "keepalive":
                old_central_agent_jid = self.central_agent_jid()
                self.entity.log.debug("CENTRALDB: Keepalive heard : %s " % str(item))
                keepalive_jid              = xmpp.JID(central_announcement_event.getAttr("jid"))

                if central_announcement_event.getAttr("keepalive_interval"):
                    self.keepalive_interval           = int(central_announcement_event.getAttr("keepalive_interval"))

                if central_announcement_event.getAttr("hypervisor_timeout_threshold"):
                    self.hypervisor_timeout_threshold = int(central_announcement_event.getAttr("hypervisor_timeout_threshold"))

                self.central_agent_jid_val = keepalive_jid
                self.last_keepalive_heard  = datetime.datetime.now()

                self.delayed_tasks.add((self.hypervisor_timeout_threshold - self.keepalive_interval)*2/3, self.push_statistics_to_centraldb)

                if old_central_agent_jid == None:
                    self.delayed_tasks.add(self.keepalive_interval, self.handle_first_keepalive, {'keepalive_jid':keepalive_jid})

                if central_announcement_event.getAttr("force_update") == "true" or keepalive_jid != old_central_agent_jid:
                    self.delayed_tasks.add(self.keepalive_interval, self.push_vms_in_central_db, {'central_announcement_event':central_announcement_event})

    def push_statistics_to_centraldb(self):
        """
        each time we hear a keepalive, we push relevant statistics to central db
        """
        stats_results = {"jid":str(self.entity.jid)}

        if len(self.required_statistics) > 0 :
            stat_num = 0
            for stat in self.required_statistics:
                stat_num += 1
                value = eval("self.entity.get_plugin('hypervisor_health').collector.stats_%s" % stat["major"])[-1][stat["minor"]]
                stats_results["stat%s" % stat_num] = value

            self.entity.log.debug("CENTRALDB: updating central db with %s" % stats_results)

        self.update_hypervisors([stats_results])


    def handle_first_keepalive(self, keepalive_jid):
        """
        this is the first keepalive. We query hypervisors that have vm entities somewhere else
        then we trigger method manage_persistence to instantiate vm entities.
        """
        vms_from_local_db = self.entity.get_vms_from_local_db()

        if len(vms_from_local_db) > 0:
            dbCommand = xmpp.Node(tag="event", attrs={"jid":self.entity.jid})

            for vm in vms_from_local_db:
                entryTag = xmpp.Node(tag="entry")
                uuid     = xmpp.JID(vm["string_jid"]).getNode()
                entryTag.addChild("item",attrs={"key":"uuid","value": uuid})
                dbCommand.addChild(node=entryTag)

            iq = xmpp.Iq(typ="set", queryNS=ARCHIPEL_NS_CENTRALAGENT, to=keepalive_jid)
            iq.getTag("query").addChild(name="archipel", attrs={"action":"get_existing_vms_instances"})
            iq.getTag("query").getTag("archipel").addChild(node=dbCommand)

            def _get_existing_vms_instances_callback(conn, packed_vms):
                existing_vms_entities = self.unpack_entries(packed_vms)
                self.entity.manage_persistence(vms_from_local_db, existing_vms_entities)

            self.entity.xmppclient.SendAndCallForResponse(iq, _get_existing_vms_instances_callback)

        else:
            # update status to Online(0)
            self.entity.manage_persistence()


    def push_vms_in_central_db(self, central_announcement_event):
        """
        there is a new central agent, or we just started.
        Consequently, we re-populate central database
        since we are using "on conflict replace" mode of sqlite, inserting an existing uuid will overwrite it.
        """
        vm_table = []
        for vm,vmprops in self.entity.virtualmachines.iteritems():
            if vmprops.definition:
                vm_table.append({"uuid":vmprops.uuid,"parker":None,"creation_date":None,"domain":vmprops.definition,"hypervisor":self.entity.jid})

        if len(vm_table) >= 1:
            self.register_vms(vm_table)

        self.register_hypervisors([{"jid":self.entity.jid, "status":"Online", "last_seen": datetime.datetime.now(), "stat1":0, "stat2":0, "stat3":0}])

        # parsing required statistics to be pushed to central agent
        self.required_statistics = []
        if central_announcement_event.getTag("required_stats"):
            for required_stat in central_announcement_event.getTag("required_stats").getChildren():
                self.required_statistics.append({"major":required_stat.getAttr("major"),"minor":required_stat.getAttr("minor")})

    ### Database Management

    #### read commands

    def read_hypervisors(self, columns, where_statement, callback):
        """
        List vm in database.
        @type table: list
        @param table: the list of hypervisors to insert
        """
        self.read_from_db("read_hypervisors", columns, where_statement, callback)

    def read_vms(self, columns, where_statement, callback):
        """
        Registers a list of vms into central database.
        @type table: list
        @param table: the list of vms to insert
        """
        self.read_from_db("read_vms", columns, where_statement, callback)

    #### write commands

    def register_hypervisors(self,table):
        """
        Registers a list of hypervisors into central database.
        @type table: list
        @param table: the list of hypervisors to insert
        """
        self.commit_to_db("register_hypervisors",table, None)

    def register_vms(self,table):
        """
        Registers a list of vms into central database.
        @type table: list
        @param table: the list of vms to insert
        """
        self.commit_to_db("register_vms",table, None)

    def unregister_hypervisors(self,table):
        """
        Unregisters a list of hypervisors from central database.
        @type table: list
        @param table: the list of hypervisors to remove
        """
        self.commit_to_db("unregister_hypervisors",table, None)

    def unregister_vms(self,table,callback):
        """
        Unregisters a list of vms from central database.
        @type table: list
        @param table: the list of vms to remove
        @type callback: func
        @para callback: will return  list of vms actually unregistered
        """
        self.commit_to_db("unregister_vms",table, callback)

    def update_vms(self,table):
        """
        Update a set of vms in central database.
        @type table: list
        @param table: the list of vms to update. Must contain the "uuid" attribute as
                      this is the one used for key in the update statement.
        """
        self.commit_to_db("update_vms",table, None)

    def update_vms_domain(self,table,callback):
        """
        Update a set of vms in central database.
        Performs additional checks for domain update when vm is offline.
        @type table: list
        @param table: the list of vms to update. Must contain the "uuid" attribute as
                      this is the one used for key in the update statement.
        """
        self.commit_to_db("update_vms_domain",table, callback)

    def update_hypervisors(self,table):
        """
        Update a set of hypervisors in central database.
        @type table: list
        @param table: the list of hypervisors to update. Must contain the "jid" attribute as
                      this is the one used for key in the update statement.
        """
        self.commit_to_db("update_hypervisors",table, None)

    def commit_to_db(self,action,table,callback):
        """
        Sends a command to active central agent for execution
        @type command: string
        @param command: the sql command to execute
        @type table: table
        @param command: the table of dicts of values associated with the command.
        """

        def commit_to_db_callback(conn, resp):
            if callback:
                unpacked_entries = self.unpack_entries(resp)
                callback(unpacked_entries)

        central_agent_jid = self.central_agent_jid()

        if central_agent_jid:
            dbCommand = xmpp.Node(tag="event", attrs={"jid":self.entity.jid})
            for entry in table:
                entryTag = xmpp.Node(tag="entry")
                for key,value in entry.iteritems():
                    entryTag.addChild("item",attrs={"key":key,"value":value})

                dbCommand.addChild(node=entryTag)


            iq = xmpp.Iq(typ="set", queryNS=ARCHIPEL_NS_CENTRALAGENT, to=central_agent_jid)
            iq.getTag("query").addChild(name="archipel", attrs={"action":action})
            iq.getTag("query").getTag("archipel").addChild(node=dbCommand)
            self.entity.log.debug("CENTRALDB [%s]: \n%s" % (action.upper(), iq))
            self.entity.xmppclient.SendAndCallForResponse(iq, commit_to_db_callback)
        else:
            self.entity.log.warning("CENTRALDB: cannot commit to db because we have not detected any central agent")

    def read_from_db(self,action,columns, where_statement, callback):
        """
        Send a select statement to central db.
        @type command: string
        @param command: the sql command to execute
        @type columns: string
        @param columns: the list of database columns to return
        @type where_statement: string
        @param where_statement: for database reads, provides "where" constraint
        """

        def _read_from_db_callback(conn, resp):
            unpacked_entries = self.unpack_entries(resp)
            self.entity.log.debug("CENTRALDB: read %s entries from db response" % len(unpacked_entries))
            callback(unpacked_entries)

        central_agent_jid = self.central_agent_jid()

        if central_agent_jid:
            dbCommand = xmpp.Node(tag="event", attrs={"jid":self.entity.jid})
            if where_statement:
                dbCommand.setAttr("where_statement", where_statement)

            if columns:
                dbCommand.setAttr("columns", columns)

            self.entity.log.debug("CENTRALDB: Asking central db for [%s] %s %s" % (action.upper(), columns, where_statement))
            iq = xmpp.Iq(typ="set", queryNS=ARCHIPEL_NS_CENTRALAGENT, to=central_agent_jid)
            iq.getTag("query").addChild(name="archipel", attrs={"action":action})
            iq.getTag("query").getTag("archipel").addChild(node=dbCommand)
            self.entity.xmppclient.SendAndCallForResponse(iq, _read_from_db_callback)
        else:
            self.entity.log.warning("CENTRALDB: cannot read from db because we have not detected any central agent")

    def unpack_entries(self, iq):
        """
        Unpack the list of entries from iq for database processing.
        @type iq: xmpp.Iq
        @param event: received Iq
        """
        entries=[]

        for entry in iq.getChildren():
            entry_dict = {}
            for entry_val in entry.getChildren():
                if entry_val.getAttr("key"):
                     entry_dict[entry_val.getAttr("key")]=entry_val.getAttr("value")
            if entry_dict != {} :
                entries.append(entry_dict)
        return entries


    ### Plugin information

    @staticmethod
    def plugin_info():
        """
        Return informations about the plugin.
        @rtype: dict
        @return: dictionary contaning plugin informations
        """
        plugin_friendly_name         = "Central db"
        plugin_identifier            = "centraldb"
        plugin_configuration_section = "CENTRALDB"
        plugin_configuration_tokens  = []
        return {"common-name": plugin_friendly_name,
                "identifier": plugin_identifier,
                "configuration-section": plugin_configuration_section,
                "configuration-tokens": plugin_configuration_tokens}


