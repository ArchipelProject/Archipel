#!/usr/bin/python
# archipelModuleHypervisorTest.py
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


# we need to import the package containing the class to surclass
import xmpp
from archipelcore.utils import *
import archipel
from archipelcore.archipelPlugin import TNArchipelPlugin
import commands
import sqlite3

ARCHIPEL_NS_OOM_KILLER = "archipel:vm:oom"


class TNOOMKiller (TNArchipelPlugin):
    
    def __init__(self, configuration, entity, entry_point_group):
        """
        initialize the module
        @type entity TNArchipelEntity
        @param entity the module entity
        """
        TNArchipelPlugin.__init__(self, configuration=configuration, entity=entity, entry_point_group=entry_point_group)
        
        self.entity.register_hook("HOOK_VM_INITIALIZE", method=self.vm_initialized)
        self.entity.register_hook("HOOK_VM_CREATE", method=self.vm_create)
        self.entity.register_hook("HOOK_VM_TERMINATE", method=self.vm_terminate)
        
        self.database = sqlite3.connect(self.configuration.get("OOMKILLER", "database"), check_same_thread=False)
        self.database.execute("create table if not exists oomkiller (uuid text unique, adjust int)")
        self.database.commit()
        self.cursor = self.database.cursor()
        self.entity.log.info("module oom killer initialized")
        
        # permissions
        self.entity.permission_center.create_permission("oom_getadjust", "Authorizes user to get OOM values", False)
        self.entity.permission_center.create_permission("oom_setadjust", "Authorizes user to set OOM values", False)
    
    
    
    ### Module implementation
    
    def register_for_stanza(self):
        """
        this method will be called by the plugin user when it will be
        necessary to register module for listening to stanza
        """
        self.entity.xmppclient.RegisterHandler('iq', self.process_iq, ns=ARCHIPEL_NS_OOM_KILLER)
    
    
    def plugin_info(self):
        """
        return the plugin information
        """
        return plugin_info(self.plugin_entry_point_group)
    
    
    @staticmethod
    def plugin_info():
        """
        return inforations about the plugin
        """
        plugin_friendly_name           = "Virtual Machine OOM Killer"
        plugin_identifier              = "oomkiller"
        plugin_configuration_section   = "OOMKILLER"
        plugin_configuration_tokens    = ["database"]

        return {    "common-name"               : plugin_friendly_name, 
                    "identifier"                : plugin_identifier,
                    "configuration-section"     : plugin_configuration_section,
                    "configuration-tokens"      : plugin_configuration_tokens }

    
    ### Hooks
    
    def vm_create(self, origin, user_info, parameters):
        oom_info = self.get_oom_info()
        self.entity.log.info("OOM value retrieved %s" % str(oom_info))
        self.set_oom_info(oom_info["adjust"], oom_info["score"])
        self.entity.log.info("oom valuee for vm with uuid %s have been restored" % self.entity.uuid)
    
    
    def vm_terminate(self, origin, user_info, parameters):
        self.cursor.execute("DELETE FROM oomkiller WHERE uuid=?", (self.entity.uuid,))
        self.database.commit()
        self.cursor.close()
        self.database.close()
        self.entity.log.info("oom information for vm with uuid %s has been removed" % self.entity.uuid)
    
    
    def vm_initialized(self, origin, user_info, parameters):
        oom_info = self.get_oom_info()
        self.set_oom_info(oom_info["adjust"], oom_info["score"])
        self.entity.log.info("oom information for vm with uuid %s have been removed" % self.entity.uuid)
    
    
    
    
    ### OOM information management
    
    
    def get_oom_info(self):
        """
        get the OOM info from database
        """
        adj_value = 0
        score_value = 0
        self.cursor.execute("SELECT adjust FROM oomkiller WHERE uuid=?", (self.entity.uuid,))
        for values in self.cursor:
            adj_value = values[0]
            score_value = 0
        return {"adjust": adj_value, "score": score_value}
    
    
    def set_oom_info(self, adjust, score):
        """
        set the OOM info both on file if exists and on database
        """
        try:
            pid = int(commands.getoutput("ps -ef | grep kvm | grep %s | grep -v grep" % self.entity.uuid).split()[1])
            f = open("/proc/%d/oom_adj" % pid, "w")
            f.write(str(adjust))
            f.close()
        except Exception as ex:
            self.entity.log.warning("No valid PID. storing value only on database: " + str(ex))
        try:
            self.cursor.execute("INSERT INTO oomkiller VALUES (?, ?)", (self.entity.uuid, int(adjust),))
        except:
            self.cursor.execute("UPDATE oomkiller SET adjust=? WHERE uuid=?", (int(adjust), self.entity.uuid,))
        self.database.commit()
    
    
    
    
    ### XMPP handlers
    
    
    def process_iq(self, conn, iq):
        """
        this method is invoked when a ARCHIPEL_NS_OOM_KILLER IQ is received.
        
        it understands IQ of type:
            - do-something
            
        @type conn: xmpp.Dispatcher
        @param conn: ths instance of the current connection that send the stanza
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ
        """
        reply = None
        action = self.entity.check_acp(conn, iq)
        self.entity.check_perm(conn, iq, action, -1, prefix="oom_")
        
        if action == "getadjust":   reply = self.iq_oom_get_adjust(iq)
        elif action == "setadjust": reply = self.iq_oom_set_adjust(iq)
        
        if reply:
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed    
    
    
    def iq_oom_get_adjust(self, iq):
        """
        return the value of the oom_adjust of the virtual machine
        
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ

        @rtype: xmpp.Protocol.Iq
        @return: a ready to send IQ containing the result of the action
        """
        try:
            reply = iq.buildReply("result")
            oom_info = self.get_oom_info()
            adj_node = xmpp.Node(tag="oom", attrs={"adjust": oom_info["adjust"], "score": oom_info["score"]})
            reply.setQueryPayload([adj_node])
        except Exception as ex:
            reply = build_error_iq(self, ex, iq)
        return reply
    
    
    def iq_oom_set_adjust(self, iq):
        """
        set the adjust value of oom killer from -16:15 plus special -17 value that disable oom killer for the process
        the lower the value his the higher the likelihood of killing the process

        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ

        @rtype: xmpp.Protocol.Iq
        @return: a ready to send IQ containing the result of the action
        """
        try:
            reply = iq.buildReply("result")
            value = iq.getTag("query").getTag("archipel").getAttr("adjust")
            self.set_oom_info(value, 0)
            self.entity.push_change("oom", "adjusted")
        except Exception as ex:
            reply = build_error_iq(self, ex, iq)
        return reply
    
    
