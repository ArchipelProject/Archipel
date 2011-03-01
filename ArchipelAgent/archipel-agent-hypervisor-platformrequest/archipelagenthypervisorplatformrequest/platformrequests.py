# 
# snapshoting.py
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

import xmpp
import os
import archipel
from libvirt import *
from pkg_resources import iter_entry_points

from archipelcore.utils import *
from archipelcore.pubsub import *
from archipelcore.archipelPlugin import TNArchipelPlugin
from scorecomputing import TNBasicPlatformScoreComputing


class TNPlatformRequests (TNArchipelPlugin):
    
    def __init__(self, configuration, entity, entry_point_group):
        """
        initialize the module
        @type entity TNArchipelEntity
        @param entity the module entity
        """
        TNArchipelPlugin.__init__(self, configuration=configuration, entity=entity, entry_point_group=entry_point_group)
        
        self.pubsub_request_in_node     = None
        self.pubsub_request_out_node    = None
        self.computing_unit             = None
        
        # get eventual computing unit plugin
        self.load_computing_unit()
        
        # register to the node vmrequest
        self.entity.register_hook("HOOK_ARCHIPELENTITY_XMPP_AUTHENTICATED", self.manage_platform_vm_request)
    
    
    
    ### Plugin interface
    
    def register_for_stanza(self):
        pass
    
    
    @staticmethod
    def plugin_info():
        """
        return inforations about the plugin
        """
        plugin_friendly_name           = "Hypervisor Platform Request"
        plugin_identifier              = "platformrequest"
        plugin_configuration_section   = None
        plugin_configuration_tokens    = []
        
        return {    "common-name"               : plugin_friendly_name, 
                    "identifier"                : plugin_identifier,
                    "configuration-section"     : plugin_configuration_section,
                    "configuration-tokens"      : plugin_configuration_tokens }
    
    
    
    ### Plugin loading
    
    def load_computing_unit(self):
        """
        loads the external computing unit
        """
        for factory_method in iter_entry_points(group="archipel.plugin.platform.computingunit", name="factory"):
            method              = factory_method.load()
            plugin_content      = method()
            self.computing_unit = plugin_content["plugin"]
            self.entity.log.info("PLATFORMREQ: loading computing unit %s" % plugin_content["info"]["common-name"])
            break
        if not self.computing_unit: 
            self.computing_unit = TNBasicPlatformScoreComputing()
            self.entity.log.info("PLATFORMREQ: using default computing unit")
        
    
    
    
    ### Performs platform actions
    
    def perform_virtual_machine_creation(self, request):
        return (self.computing_unit.score(), xmpp.Node("anwser"))
    
    
    
    ### Pubsub management
    
    def manage_platform_vm_request(self, entity, args):
        """
        register to pubsub event node /archipel/platform/requests/in
        and /archipel/platform/requests/out
        """
        nodeVMRequestsInName = "/archipel/platform/requests/in"
        self.entity.log.info("PLATFORMREQ: getting the pubsub node %s" % nodeVMRequestsInName)
        self.pubsub_request_in_node = TNPubSubNode(self.entity.xmppclient, self.entity.pubsubserver, nodeVMRequestsInName)
        self.pubsub_request_in_node.recover()
        self.entity.log.info("PLATFORMREQ: node %s recovered" % nodeVMRequestsInName)
        self.pubsub_request_in_node.subscribe(self.entity.jid.getStripped(), self._handle_request_event)
        self.entity.log.info("PLATFORMREQ: entity %s is now subscribed to events from node %s" % (self.entity.jid, nodeVMRequestsInName))
        
        nodeVMRequestsOutName = "/archipel/platform/requests/out"
        self.entity.log.info("PLATFORMREQ: getting the pubsub node %s" % nodeVMRequestsOutName)
        self.pubsub_request_out_node = TNPubSubNode(self.entity.xmppclient, self.entity.pubsubserver, nodeVMRequestsOutName)
        self.pubsub_request_out_node.recover()
        self.entity.log.info("PLATFORMREQ: node %s recovered" % nodeVMRequestsOutName)
        
    
    
    def _handle_request_event(self, event):
        """
        triggered when a platform wide virtual machine request is received
        """
        items = event.getTag("event").getTag("items").getTags("item")
        
        for item in items:
            item_publisher = xmpp.JID(item.getAttr("publisher"))
            if not item_publisher.getStripped() == self.entity.jid.getStripped():
                try:
                    self.entity.log.info("PLATFORMREQ: received a platform-wide virtual machine request from %s (NOT IMPLEMENTED YET)" % item_publisher)
                    request_uuid = item.getTag("archipel").getAttr("uuid")
                    score, content = self.perform_virtual_machine_creation(item)
                    if score:
                        answer_node = xmpp.Node("archipel", attrs={"uuid": request_uuid, "score": score})
                        answer_node.addChild(node=content)
                        self.pubsub_request_out_node.add_item(answer_node)
                except Exception as ex:
                    self.entity.log.error("PLATFORMREQ: seems that request is not valid (%s) %s" % (str(ex), str(item)))
    
    

