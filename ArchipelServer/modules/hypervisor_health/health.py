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
from utils import *
import archipel
import commands
import xmpp
import os
import traceback
from archipelStatsCollector import *

ARCHIPEL_ERROR_CODE_HEALTH_HISTORY  = -8001
ARCHIPEL_ERROR_CODE_HEALTH_INFO     = -8002
ARCHIPEL_ERROR_CODE_HEALTH_LOG      = -8003

class TNHypervisorHealth:
    def __init__(self, entity, db_file,collection_interval, max_rows_before_purge, max_cached_rows, log_file): #, snmp_agent, snmp_community, snmp_version, snmp_port):
        self.collector = TNThreadedHealthCollector(db_file,collection_interval, max_rows_before_purge, max_cached_rows)#, snmp_agent, snmp_community, snmp_version, snmp_port)
        # self.collector.daemon = True
        self.logfile = log_file
        self.collector.start()
        self.entity = entity
    
        
    def process_iq(self, conn, iq):
        """
        this method is invoked when a ARCHIPEL_NS_HYPERVISOR_HEALTH IQ is received.
        
        it understands IQ of type:
            - alloc
            - free
        
        @type conn: xmpp.Dispatcher
        @param conn: ths instance of the current connection that send the stanza
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ
        """
        action = self.entity.check_acp(conn, iq)
        self.entity.check_perm(conn, iq, action, -1)
        
        if action == "history":
            reply = self.__healthinfo_history(iq)
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed
        
        elif action == "info":
            reply = self.__healthinfo(iq)
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed
            
        elif action == "logs":
            reply = self.__get_logs(iq)
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed
    
    
    def __healthinfo_history(self, iq):
        """
        get a range of old stat history according to the limit parameters in iq node
        
        @type iq: xmpp.Protocol.Iq
        @param iq: the sender request IQ
        @rtype: xmpp.Protocol.Iq
        @return: a ready-to-send IQ containing the results        
        """
        try:
            reply = iq.buildReply("result")
            log.debug("converting stats into XML node")
            
            limit = int(iq.getTag("query").getTag("archipel").getAttr("limit"))
            nodes = []
            stats = self.collector.get_collected_stats(limit)
            
            number_of_rows = limit
            if number_of_rows > len(stats["memory"]):
                number_of_rows = len(stats["memory"])
            
            for i in range(number_of_rows):
                statNode = xmpp.Node("stat")
                statNode.addChild("memory", attrs={"free" : stats["memory"][i]["free"], "used": stats["memory"][i]["used"], "total": stats["memory"][i]["total"], "swapped": stats["memory"][i]["swapped"]} )
                statNode.addChild("cpu", attrs={"id": stats["cpu"][i]["id"]})
                statNode.addChild("disk", attrs={"total" : stats["disk"][i]["total"], "used":  stats["disk"][i]["used"], "free":  stats["disk"][i]["free"], "used-percentage":  stats["disk"][i]["free_percentage"]})
                statNode.addChild("load", attrs={"one" : stats["load"][i]["one"], "five":  stats["load"][i]["five"], "fifteen":  stats["load"][i]["fifteen"]})
                nodes.append(statNode)
            
            reply.setQueryPayload(nodes)
        except Exception as ex:
            reply = build_error_iq(self, ex, iq, ARCHIPEL_ERROR_CODE_HEALTH_HISTORY)
        return reply


    def __healthinfo(self, iq):
        """
        send information about the hypervisor health info
        
        @type iq: xmpp.Protocol.Iq
        @param iq: the sender request IQ
        @rtype: xmpp.Protocol.Iq
        @return: a ready-to-send IQ containing the results        
        """
        # TODO : add some ACL here later
        try:
            reply = iq.buildReply("result") 
            
            nodes = []
            stats = self.collector.get_collected_stats(1)
            
            if not stats:
                reply = build_error_iq(self, "Unable to get stats. see hypervisor log", iq)
            else:
                mem_free_node = xmpp.Node("memory", attrs={"free" : stats["memory"][0]["free"], "used": stats["memory"][0]["used"], "total": stats["memory"][0]["total"], "swapped": stats["memory"][0]["swapped"]} )
                nodes.append(mem_free_node)
                
                cpu_node = xmpp.Node("cpu", attrs={"id": stats["cpu"][0]["id"]})
                nodes.append(cpu_node)
                
                disk_free_node = xmpp.Node("disk", attrs={"total" : stats["disk"][0]["total"], "used":  stats["disk"][0]["used"], "free":  stats["disk"][0]["free"], "used-percentage":  stats["disk"][0]["free_percentage"]})
                nodes.append(disk_free_node)
                
                load_node = xmpp.Node("load", attrs={"one" : stats["load"][0]["one"], "five" : stats["load"][0]["five"], "fifteen" : stats["load"][0]["fifteen"]})
                nodes.append(load_node)
                
                uptime_node = xmpp.Node("uptime", attrs={"up" : stats["uptime"]["up"]})
                nodes.append(uptime_node)
                
                uname_node = xmpp.Node("uname", attrs={"krelease": stats["uname"]["krelease"] , "kname": stats["uname"]["kname"] , "machine":stats["uname"]["machine"], "os": stats["uname"]["os"]})
                nodes.append(uname_node)   
                
                reply.setQueryPayload(nodes)
        except Exception as ex:
            reply = build_error_iq(self, ex, iq, ARCHIPEL_ERROR_CODE_HEALTH_INFO)
        return reply
    
    
    
    def __get_logs(self, iq):
        """
        read the hypervisor's log file
        
        @type iq: xmpp.Protocol.Iq
        @param iq: the sender request IQ
        @rtype: xmpp.Protocol.Iq
        @return: a ready-to-send IQ containing the results        
        """
        
        try:
            reply = iq.buildReply("result")
            limit = int(iq.getTag("query").getTag("archipel").getAttr("limit"))
            output = commands.getoutput("tail -n %d %s" % (limit, self.logfile));
            nodes = []
            for line in output.split("\n"):
                infos = line.split("::")
                log_node = xmpp.Node("log", attrs={"level": infos[0], "date": infos[1], "file": infos[2], "method": infos[3]})
                log_node.setData(infos[4]);
                nodes.append(log_node)
                
            reply.setQueryPayload(nodes)
        except Exception as ex:
            reply = build_error_iq(self, ex, iq, ARCHIPEL_ERROR_CODE_HEALTH_LOG)
        return reply
    


