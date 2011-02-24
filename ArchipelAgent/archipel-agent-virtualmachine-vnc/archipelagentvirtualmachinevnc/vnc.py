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
from archipelcore.archipelPlugin import TNArchipelPlugin

from archipelWebSocket import *

ARCHIPEL_NS_VNC                 = "archipel:virtualmachine:vnc"
ARCHIPEL_ERROR_CODE_VM_VNC      = -1010


class TNArchipelVNC (TNArchipelPlugin):
    
    def __init__(self, configuration, entity, entry_point_group):
        """
        initialize the module
        @type entity TNArchipelEntity
        @param entity the module entity
        """
        TNArchipelPlugin.__init__(self, configuration=configuration, entity=entity, entry_point_group=entry_point_group)
        
        self.novnc_proxy = None
        
        # vocabulary
        registrar_item = {  "commands" : ["vnc", "screen"], 
                            "parameters": [],
                            "method": self.message_vncdisplay,
                            "permissions": ["vncdisplay"],
                            "description": "I'll show my VNC port" }
        self.entity.add_message_registrar_item(registrar_item)
        
        # permissions
        self.entity.permission_center.create_permission("vnc_display", "Authorizes users to access the vnc display port", False)    
        
        # hooks
        self.entity.register_hook("HOOK_VM_CREATE", self.create_novnc_proxy)
        self.entity.register_hook("HOOK_VM_CRASH", self.stop_novnc_proxy)
        self.entity.register_hook("HOOK_VM_STOP", self.stop_novnc_proxy)
        self.entity.register_hook("HOOK_VM_DESTROY", self.stop_novnc_proxy)
        self.entity.register_hook("HOOK_VM_TERMINATE", self.stop_novnc_proxy)
        self.entity.register_hook("HOOK_XMPP_DISCONNECT", self.stop_novnc_proxy)
        self.entity.register_hook("HOOK_VM_INITIALIZE", self.awake_from_initialization)
    
    
    
    ### Plugin interface
    
    def register_for_stanza(self):
        """
        this method will be called by the plugin user when it will be
        necessary to register module for listening to stanza
        """
        self.entity.xmppclient.RegisterHandler('iq', self.process_iq, ns=ARCHIPEL_NS_VNC)
    
    
    @staticmethod
    def plugin_info():
        """
        return inforations about the plugin
        """
        plugin_friendly_name           = "Virtual Machine VNC Screen"
        plugin_identifier              = "vnc"
        plugin_configuration_section   = "VNC"
        plugin_configuration_tokens    = [  "vnc_certificate_file",
                                            "vnc_only_ssl"]
        
        return {    "common-name"               : plugin_friendly_name, 
                    "identifier"                : plugin_identifier,
                    "configuration-section"     : plugin_configuration_section,
                    "configuration-tokens"      : plugin_configuration_tokens }
    
    
    
    ### Utilities
    
    def awake_from_initialization(self, entity, args):
        """
        will create or not the proxy according to the recovered status of the vm
        """
        if self.entity.domain:
            dominfo = self.entity.domain.info()
            if dominfo[0] == VIR_DOMAIN_RUNNING or dominfo[0] == VIR_DOMAIN_BLOCKED:
                self.create_novnc_proxy(None, None)
    
    
    def create_novnc_proxy(self, entity, args):
        """
        create a noVNC proxy on port vmpport + 1000 (so noVNC proxy is 6900 for VNC port 5900 etc)
        """
        if not self.entity.libvirt_connection.getType() == ARCHIPEL_HYPERVISOR_TYPE_QEMU: 
            self.entity.log.warning("aborting the VNC proxy creation cause current hypervisor %s doesn't support it." % self.entity.libvirt_connection.getType())
            return
        
        current_vnc_port        = self.vncdisplay()["direct"]
        novnc_proxy_port        = self.vncdisplay()["proxy"]
        self.entity.log.info("NOVNC: current proxy port is %d" % novnc_proxy_port)
        
        cert = self.configuration.get("VNC", "vnc_certificate_file")
        if cert.lower() in ("none", "no", "false"): cert = None
        self.entity.log.info("virtual machine vnc proxy is using certificate %s" % str(cert))
        onlyssl = self.configuration.getboolean("VNC", "vnc_only_ssl")
        self.entity.log.info("virtual machine vnc proxy accepts only SSL connection %s" % str(onlyssl))
        self.novnc_proxy = TNArchipelWebSocket("127.0.0.1", current_vnc_port, "0.0.0.0", novnc_proxy_port, certfile=cert, onlySSL=onlyssl)
        self.novnc_proxy.start()
        self.entity.push_change("virtualmachine:vnc", "websocketvncstart", excludedgroups=['vitualmachines'])
    
    
    def stop_novnc_proxy(self, entity, args):
        """
        stops the current novnc websocket proxy is any.
        """
        if self.novnc_proxy:
            self.entity.log.info("stopping novnc proxy")
            self.novnc_proxy.stop()
            self.entity.push_change("virtualmachine:vnc", "websocketvncstop", excludedgroups=['vitualmachines'])
    
    
    
    ### XMPP Processing
    
    def process_iq(self, conn, iq):
        """
        this method is invoked when a ARCHIPEL_NS_VNC IQ is received.
        
        it understands IQ of type:
            - vncdisplay
        
        @type conn: xmpp.Dispatcher
        @param conn: ths instance of the current connection that send the stanza
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ
        """
        action = self.entity.check_acp(conn, iq)    
        self.entity.check_perm(conn, iq, action, -1, prefix="vnc_")
        
        if not self.entity.domain: raise xmpp.protocol.NodeProcessed
        
        elif action == "vncdisplay":    reply = self.iq_vncdisplay(iq)
        
        if reply:
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed
    
    
    def vncdisplay(self):
        """
        return an dist containing VNC informations
        """
        xmldesc = self.entity.domain.XMLDesc(0)
        xmldescnode = xmpp.simplexml.NodeBuilder(data=xmldesc).getDom()
        directport = int(xmldescnode.getTag(name="devices").getTag(name="graphics").getAttr("port"))
        if directport == -1:
            return {"direct"        : -1, 
                    "proxy"         : -1, 
                    "onlyssl"       : False, 
                    "supportssl"    : False}
        proxyport = directport + 1000
        supportSSL = self.configuration.get("VNC", "vnc_certificate_file")
        if supportSSL.lower() in ("none", "no", "false"): 
            supportSSL = False
        else: 
            supportSSL = True
        return {"direct"        : directport, 
                "proxy"         : proxyport, 
                "onlyssl"       : self.configuration.getboolean("VNC", "vnc_only_ssl"), 
                "supportssl"    : supportSSL}
    
    
    def iq_vncdisplay(self, iq):
        """
        get the VNC display used in the virtual machine.
        
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ
        
        @rtype: xmpp.Protocol.Iq
        @return: a ready to send IQ containing the result of the action
        """
        reply = iq.buildReply("result")
        try:
            if not self.entity.domain:
                return iq.buildReply('ignore')
            ports = self.vncdisplay()
            payload = xmpp.Node("vncdisplay", attrs={"port": str(ports["direct"]), "proxy": str(ports["proxy"]), "host": self.entity.ipaddr, "onlyssl": str(ports["onlyssl"]), "supportssl": str(ports["supportssl"])})
            reply.setQueryPayload([payload])
        except libvirtError as ex:
            reply = build_error_iq(self, ex, iq, ex.get_error_code(), ns=ARCHIPEL_NS_LIBVIRT_GENERIC_ERROR)
        except Exception as ex:
            reply = build_error_iq(self, ex, iq, ARCHIPEL_ERROR_CODE_VM_VNC)
        return reply
    
    
    def message_vncdisplay(self, msg):
        """
        handle message vnc display order
        """
        try:
            ports = self.vncdisplay()
            return "you can connect to my screen at %s:%s" % (self.entity.ipaddr, ports["direct"])
        except Exception as ex:
            return build_error_message(self, ex)
    

