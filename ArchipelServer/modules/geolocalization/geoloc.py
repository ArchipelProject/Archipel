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


class TNHypervisorGeolocalization:
    def __init__(self, service, request, method, root_info_node):
        conn = httplib.HTTPConnection(service);
        conn.request(method, request)

        node_loc = xmpp.simplexml.NodeBuilder(data=str(conn.getresponse().read())).getDom();
        self.localization_information = node_loc
        
        
        
    def __module__get_geolocalization(self, iq):
        reply = iq.buildReply('success')
        reply.setQueryPayload([self.localization_information]);
        return reply;
    

    def process_iq(self, conn, iq):
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
