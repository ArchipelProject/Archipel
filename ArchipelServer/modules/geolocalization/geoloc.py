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
    def __init__(self, conf, entity):
        mode = conf.get("GEOLOCALIZATION", "localization_mode");
        self.entity = entity
        lat = ""
        lon = ""
        if mode == "auto": 
            service         = conf.get("GEOLOCALIZATION", "localization_service_url")
            request         = conf.get("GEOLOCALIZATION", "localization_service_request")
            method          = conf.get("GEOLOCALIZATION", "localization_service_method")
            root_info_node  = conf.get("GEOLOCALIZATION", "localization_service_response_root_node")
            conn = httplib.HTTPConnection(service)
            conn.request(method, request)
            data_node = xmpp.simplexml.NodeBuilder(data=str(conn.getresponse().read())).getDom()
            lat = data_node.getTagData("Latitude")
            lon = data_node.getTagData("Longitude")
        else:
            lat = conf.getfloat("GEOLOCALIZATION", "localization_latitude")
            lon = conf.getfloat("GEOLOCALIZATION", "localization_longitude")
        
        string = "<gelocalization><Latitude>"+str(lat)+"</Latitude>\n<Longitude>"+str(lon)+"</Longitude></gelocalization>"
        self.localization_information = xmpp.simplexml.NodeBuilder(data=string).getDom()
        
        registrar_item = {  "commands" : ["where are you", "localize"], 
                            "parameters": {}, 
                            "method": self._module__get_geolocalization_string,
                            "description": "give my the latitude and longitude." }
        
        self.entity.add_message_registrar_item(registrar_item)
    
    
    def _module__get_geolocalization(self, iq):
        reply = iq.buildReply("result")
        try:
            reply.setQueryPayload([self.localization_information])
        except Exception as ex:
            reply = build_error_iq(self, ex, iq)
        return reply
    
    def _module__get_geolocalization_string(self, msg):
        lat = self.localization_information.getTagData("Latitude")
        lon = self.localization_information.getTagData("Longitude")
        return "I'm localized at longitude: %s latitude: %s" % (lon, lat)
    
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
        
        action = iq.getTag("query").getAttr("action")
        log.debug( "iq received from %s with type %s" % (iq.getFrom(), action))
        
        if action == "get":
            reply = self._module__get_geolocalization(iq)
            conn.send(reply)
            log.debug( "geolocalization information sent. Node processed")
            raise xmpp.protocol.NodeProcessed
    

