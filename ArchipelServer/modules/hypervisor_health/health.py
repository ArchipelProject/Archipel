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
from archipelStatsCollector import *

NS_ARCHIPEL_HYPERVISOR_HEALTH = "trinity:hypervisor:health"


######################################################################################################
### Registring of the stanza
######################################################################################################

def __module_init__health_module(self):
    self.collector = TNThreadedHealthCollector(self.configuration.get("Module Health", "health_database_path"));
    self.collector.daemon = True;
    self.collector.start();


def __module_register_stanza__heatlh_module(self):
    self.xmppclient.RegisterHandler('iq', self.__process_iq_trinity_health, typ=NS_ARCHIPEL_HYPERVISOR_HEALTH)


######################################################################################################
### Health definition
######################################################################################################
def __process_iq_trinity_health(self, conn, iq):
    """
    this method is invoked when a NS_ARCHIPEL_HYPERVISOR_HEALTH IQ is received.
    
    it understands IQ of type:
        - alloc
        - free
    
    @type conn: xmpp.Dispatcher
    @param conn: ths instance of the current connection that send the stanza
    @type iq: xmpp.Protocol.Iq
    @param iq: the received IQ
    """
    log(self, LOG_LEVEL_DEBUG, "iq received from {0} with type {1}".format(iq.getFrom(), iq.getType()))
    
    iqType = iq.getTag("query").getAttr("type");
    
    if iqType == "history":
        reply = self.__healthinfo_history(iq)
        conn.send(reply)
        log(self, LOG_LEVEL_DEBUG, "stats IQ sent. Node processed")
        raise xmpp.protocol.NodeProcessed
        
    if iqType == "info":
        reply = self.__healthinfo(iq)
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
        limit = int(iq.getTag("query").getAttr("limit"))
        nodes = [];
        stats = self.collector.get_collected_stats(limit);
        
        log(self, LOG_LEVEL_DEBUG, "converting stats into XML node")
        rows = [];
        i = 0;
        for i in range(limit):
            statNode = xmpp.Node("stat");
            statNode.addChild("memory", attrs={"free" : stats["memory"][i]["free"], "used": stats["memory"][i]["used"], "total": stats["memory"][i]["total"], "swapped": stats["memory"][i]["swapped"]} );
            statNode.addChild("cpu", attrs={"id": stats["cpu"][i]["id"]});
            statNode.addChild("disk", attrs={"total" : stats["disk"][i]["total"], "used":  stats["disk"][i]["used"], "free":  stats["disk"][i]["free"], "used-percentage":  stats["disk"][i]["free_percentage"]});
            nodes.append(statNode);
        
        log(self, LOG_LEVEL_DEBUG, "conversion done. returning IQ for sending")
        reply = iq.buildReply('success')    
        reply.setQueryPayload(nodes)
    except Exception as ex:
        log(self, LOG_LEVEL_ERROR, "exception raised is : {0}".format(ex))
        reply = iq.buildReply('error')
        payload = xmpp.Node("error", attrs={})
        payload.addData(str(ex))
        reply.setQueryPayload([payload])
        
        
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
    nodes = []
    stats = self.collector.get_collected_stats(1);
    
    mem_free_node = xmpp.Node("memory", attrs={"free" : stats["memory"][0]["free"], "used": stats["memory"][0]["used"], "total": stats["memory"][0]["total"], "swapped": stats["memory"][0]["swapped"]} );
    nodes.append(mem_free_node)
    
    cpu_node = xmpp.Node("cpu", attrs={"id": stats["cpu"][0]["id"]});
    nodes.append(cpu_node)
    
    disk_free_node = xmpp.Node("disk", attrs={"total" : stats["disk"][0]["total"], "used":  stats["disk"][0]["used"], "free":  stats["disk"][0]["free"], "used-percentage":  stats["disk"][0]["free_percentage"]});
    nodes.append(disk_free_node);
    
    load_node = xmpp.Node("load", attrs={"one" : stats["load"][0]["one"], "five" : stats["load"][0]["five"], "fifteen" : stats["load"][0]["fifteen"]});
    nodes.append(load_node)
    
    uptime_node = xmpp.Node("uptime", attrs={"up" : stats["uptime"]["up"]});
    nodes.append(uptime_node)
    
    uname_node = xmpp.Node("uname", attrs={"krelease": stats["uname"]["krelease"] , "kname": stats["uname"]["kname"] , "machine":stats["uname"]["machine"], "os": stats["uname"]["os"]});
    nodes.append(uname_node)   
    
    reply = iq.buildReply('success')    
    reply.setQueryPayload(nodes)
    
    return reply



setattr(archipel.TNArchipelHypervisor, "__module_init__health_module", __module_init__health_module)
setattr(archipel.TNArchipelHypervisor, "__module_register_stanza__heatlh_module", __module_register_stanza__heatlh_module)
setattr(archipel.TNArchipelHypervisor, "__process_iq_trinity_health", __process_iq_trinity_health)
setattr(archipel.TNArchipelHypervisor, "__healthinfo_history", __healthinfo_history)
setattr(archipel.TNArchipelHypervisor, "__healthinfo", __healthinfo)

