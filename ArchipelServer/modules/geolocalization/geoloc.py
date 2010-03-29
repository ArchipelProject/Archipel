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
from utils import *
import archipel
import httplib

NS_ARCHIPEL_HYPERVISOR_GEOLOC = "archipel:hypervisor:geolocalization"

# this method will be call at loading
def __module_init__geoloc(self):
    service = self.configuration.get("Geolocalization", "service_url")
    request = self.configuration.get("Geolocalization", "service_request")
    method  = self.configuration.get("Geolocalization", "service_method")
    root_info_node = self.configuration.get("Geolocalization", "service_response_root_node")
    conn = httplib.HTTPConnection(service);
    conn.request(method, request)
    
    node_loc = xmpp.simplexml.NodeBuilder(data=str(conn.getresponse().read())).getDom();
    self.localization_information = node_loc
    print self.localization_information


def __module_register_stanza__geoloc(self):
    self.xmppclient.RegisterHandler('iq', self.__module__process_geoloc_iq, typ=NS_ARCHIPEL_HYPERVISOR_GEOLOC)


def __module__get_geolocalization(self, iq):
    reply = iq.buildReply('success')
    reply.setQueryPayload([self.localization_information]);
    return reply;
    

def __module__process_geoloc_iq(self, conn, iq):
    """
    this method is invoked when a NS_ARCHIPEL_HYPERVISOR_GEOLOC IQ is received.
    
    it understands IQ of type:
        - get
    
    @type conn: xmpp.Dispatcher
    @param conn: ths instance of the current connection that send the stanza
    @type iq: xmpp.Protocol.Iq
    @param iq: the received IQ
    """
    log(self, LOG_LEVEL_DEBUG, "iq received from {0} with type {1}".format(iq.getFrom(), iq.getType()))
    
    iqType = iq.getTag("query").getAttr("type");
    
    if iqType == "get":
        reply = self.__module__get_geolocalization(iq)
        conn.send(reply)
        log(self, LOG_LEVEL_DEBUG, "geolocalization information sent. Node processed")
        raise xmpp.protocol.NodeProcessed




# finally, we add the methods to the class
setattr(archipel.TNArchipelHypervisor, "__module_init__geoloc", __module_init__geoloc)
setattr(archipel.TNArchipelHypervisor, "__module_register_stanza__geoloc", __module_register_stanza__geoloc)
setattr(archipel.TNArchipelHypervisor, "__module__process_geoloc_iq", __module__process_geoloc_iq)
setattr(archipel.TNArchipelHypervisor, "__module__get_geolocalization", __module__get_geolocalization)