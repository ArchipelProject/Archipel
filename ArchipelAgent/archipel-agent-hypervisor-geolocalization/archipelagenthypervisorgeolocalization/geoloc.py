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
import httplib
from archipelcore.archipelPlugin import TNArchipelPlugin

ARCHIPEL_NS_HYPERVISOR_GEOLOC           = "archipel:hypervisor:geolocalization"
ARCHIPEL_ERROR_CODE_LOCALIZATION_GET    = -9001

class TNHypervisorGeolocalization (TNArchipelPlugin):
    
    def __init__(self, configuration, entity, entry_point_group):
        """
        initialize the module
        @type entity TNArchipelEntity
        @param entity the module entity
        """
        TNArchipelPlugin.__init__(self, configuration=configuration, entity=entity, entry_point_group=entry_point_group)
        
        mode    = self.configuration.get("GEOLOCALIZATION", "localization_mode");
        lat     = ""
        lon     = ""
        
        if mode == "auto": 
            service         = self.configuration.get("GEOLOCALIZATION", "localization_service_url")
            request         = self.configuration.get("GEOLOCALIZATION", "localization_service_request")
            method          = self.configuration.get("GEOLOCALIZATION", "localization_service_method")
            root_info_node  = self.configuration.get("GEOLOCALIZATION", "localization_service_response_root_node")
            conn = httplib.HTTPConnection(service)
            conn.request(method, request)
            data_node = xmpp.simplexml.NodeBuilder(data=str(conn.getresponse().read())).getDom()
            lat = data_node.getTagData("Latitude")
            lon = data_node.getTagData("Longitude")
        else:
            lat = self.configuration.getfloat("GEOLOCALIZATION", "localization_latitude")
            lon = self.configuration.getfloat("GEOLOCALIZATION", "localization_longitude")
        
        string = "<gelocalization><Latitude>"+str(lat)+"</Latitude>\n<Longitude>"+str(lon)+"</Longitude></gelocalization>"
        self.localization_information = xmpp.simplexml.NodeBuilder(data=string).getDom()
        
        registrar_item = {  "commands" : ["where are you", "localize"], 
                            "parameters": {}, 
                            "method": self.message_get,
                            "permissions": ["geolocalization_get"],
                            "description": "give my the latitude and longitude." }
        
        self.entity.add_message_registrar_item(registrar_item)
        
        # permissions
        self.entity.permission_center.create_permission("geolocalization_get", "Authorizes user to get the entity location coordinates", False);        
    
    
    ### Plugin interface
    
    def register_for_stanza(self):
        """
        this method will be called by the plugin user when it will be
        necessary to register module for listening to stanza
        """
        self.entity.xmppclient.RegisterHandler('iq', self.process_iq, ns=ARCHIPEL_NS_HYPERVISOR_GEOLOC)
    
    
    @staticmethod
    def plugin_info():
        """
        return inforations about the plugin
        """
        plugin_friendly_name           = "Hypervisor Geolocalization"
        plugin_identifier              = "geolocalization"
        plugin_configuration_section   = "GEOLOCALIZATION"
        plugin_configuration_tokens    = [ "localization_mode", 
                                            "localization_latitude",
                                            "localization_longitude",
                                            "localization_service_url",
                                            "localization_service_request",
                                            "localization_service_method",
                                            "localization_service_response_root_node"]

        return {    "common-name"               : plugin_friendly_name, 
                    "identifier"                : plugin_identifier,
                    "configuration-section"     : plugin_configuration_section,
                    "configuration-tokens"      : plugin_configuration_tokens }
    
    
    ### XMPP Processing
    
    
    def process_iq(self, conn, iq):
        """
        this method is invoked when a ARCHIPEL_NS_HYPERVISOR_GEOLOC IQ is received.
        
        it understands IQ of type:
            - get
        
        @type conn: xmpp.Dispatcher
        @param conn: ths instance of the current connection that send the stanza
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ
        """
        action = self.entity.check_acp(conn, iq)
        self.entity.check_perm(conn, iq, action, -1, prefix="geolocalization_")
        
        if action == "get":
            reply = self.iq_get(iq)
            conn.send(reply)
            self.entity.log.debug("geolocalization information sent. Node processed")
            raise xmpp.protocol.NodeProcessed
    
    
    def iq_get(self, iq):
        reply = iq.buildReply("result")
        try:
            reply.setQueryPayload([self.localization_information])
        except Exception as ex:
            reply = build_error_iq(self, ex, iq, ARCHIPEL_ERROR_CODE_LOCALIZATION_GET)
        return reply
    
    
    def message_get(self, msg):
        lat = self.localization_information.getTagData("Latitude")
        lon = self.localization_information.getTagData("Longitude")
        return "I'm localized at longitude: %s latitude: %s" % (lon, lat)
    
    
    
