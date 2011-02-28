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

from archipelcore.utils import *
from archipelcore.pubsub import *
from archipelcore.archipelPlugin import TNArchipelPlugin


class TNPlatformRequests (TNArchipelPlugin):
    
    def __init__(self, configuration, entity, entry_point_group):
        """
        initialize the module
        @type entity TNArchipelEntity
        @param entity the module entity
        """
        TNArchipelPlugin.__init__(self, configuration=configuration, entity=entity, entry_point_group=entry_point_group)
        
        self.pubsub_vmrequestnode = None
        
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
    
    
    
    ### Utilities
    
    
    def perform_virtual_machine_creation(self, request):
        return (True, xmpp.Node("anwser"))
    
    
    def manage_platform_vm_request(self, entity, args):
        """
        register to pubsub event node /archipel/platform/vmrequests
        """
        nodeVMRequestsName = "/archipel/platform/vmrequests"
        self.entity.log.info("getting the pubsub node %s" % nodeVMRequestsName)
        self.pubsub_vmrequestnode = TNPubSubNode(self.entity.xmppclient, self.entity.pubsubserver, nodeVMRequestsName)
        self.pubsub_vmrequestnode.recover()
        self.entity.log.info("node %s recovered" % nodeVMRequestsName)
        self.pubsub_vmrequestnode.subscribe(self.entity.jid.getStripped(), self._handle_vmrequest_event)
        self.entity.log.info("entity %s is now subscribed to events from node %s" % (self.entity.jid, nodeVMRequestsName))
        
    
    
    def _handle_vmrequest_event(self, event):
        """
        triggered when a platform wide virtual machine request is received
        """
        items = event.getTag("event").getTag("items").getTags("item")
        
        for item in items:
            item_publisher = xmpp.JID(item.getAttr("publisher"))
            if not item_publisher.getStripped() == self.entity.jid.getStripped():
                try:
                    self.entity.log.info("received a platform-wide virtual machine request from %s (NOT IMPLEMENTED YET)" % item_publisher)
                    request_uuid = item.getTag("archipel").getAttr("uuid")
                    answer, content = self.perform_virtual_machine_creation(item)
                    if answer:
                        answer_node = xmpp.Node("archipel", attrs={"uuid": request_uuid})
                        answer_node.addChild(node=content)
                        self.pubsub_vmrequestnode.add_item(answer_node)
                except Exception as ex:
                    self.entity.log.error("seems that request is not valid (%s) %s" % (str(ex), str(item)))
                
        
        ## RTO
    
    

