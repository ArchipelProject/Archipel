# -*- coding: utf-8 -*-
#
# vnc.py
#
# Copyright (C) 2010 Antoine Mercadal <antoine.mercadal@inframonde.eu>
# This file is part of ArchipelProject
# http://archipelproject.org
#
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

import libvirt
import xmpp

from archipelcore.archipelPlugin import TNArchipelPlugin
from archipelcore.utils import build_error_iq, build_error_message
import archipel.archipelLibvirtEntity

from websockify import WebSocketProxy


ARCHIPEL_NS_VNC                 = "archipel:virtualmachine:vnc"
ARCHIPEL_ERROR_CODE_VM_VNC      = -1010


class TNArchipelVNC (TNArchipelPlugin):

    def __init__(self, configuration, entity, entry_point_group):
        """
        Initialize the plugin.
        @type configuration: Configuration object
        @param configuration: the configuration
        @type entity: L{TNArchipelEntity}
        @param entity: the entity that owns the plugin
        @type entry_point_group: string
        @param entry_point_group: the group name of plugin entry_point
        """
        TNArchipelPlugin.__init__(self, configuration=configuration, entity=entity, entry_point_group=entry_point_group)
        self.novnc_proxy = None
        # vocabulary
        registrar_item = {  "commands" : ["vnc", "screen"],
                            "parameters": [],
                            "method": self.message_display,
                            "permissions": ["vnc_display"],
                            "description": "I'll show my VNC port" }
        self.entity.add_message_registrar_item(registrar_item)
        # permissions
        self.entity.permission_center.create_permission("vnc_display", "Authorizes users to access the vnc display port", False)
        # hooks
        self.entity.register_hook("HOOK_VM_CREATE", method=self.create_novnc_proxy)
        self.entity.register_hook("HOOK_VM_CRASH", method=self.stop_novnc_proxy)
        self.entity.register_hook("HOOK_VM_STOP", method=self.stop_novnc_proxy)
        self.entity.register_hook("HOOK_VM_DESTROY", method=self.stop_novnc_proxy)
        self.entity.register_hook("HOOK_VM_TERMINATE", method=self.stop_novnc_proxy)
        self.entity.register_hook("HOOK_VM_MIGRATED", method=self.stop_novnc_proxy)
        self.entity.register_hook("HOOK_VM_INITIALIZE", method=self.awake_from_initialization)

        self.websocket_verbose = False
        if self.configuration.has_option("VNC", "vnc_enable_websocket_debug"):
            self.websocket_verbose = self.configuration.getboolean("VNC", "vnc_enable_websocket_debug")


    ### Plugin interface

    def register_handlers(self):
        """
        This method will be called by the plugin user when it will be
        necessary to register module for listening to stanza.
        """
        self.entity.xmppclient.RegisterHandler('iq', self.process_iq, ns=ARCHIPEL_NS_VNC)

    def unregister_handlers(self):
        """
        Unregister the handlers.
        """
        self.entity.xmppclient.UnregisterHandler('iq', self.process_iq, ns=ARCHIPEL_NS_VNC)

    @staticmethod
    def plugin_info():
        """
        Return informations about the plugin.
        @rtype: dict
        @return: dictionary contaning plugin informations
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

    def awake_from_initialization(self, origin, user_info, parameters):
        """
        Will create or not the proxy according to the recovered status of the vm.
        @type origin: L{TNArchipelEntity}
        @param origin: the origin of the hook
        @type user_info: object
        @param user_info: random user info
        @type parameters: object
        @param parameters: runtime argument
        """
        if self.entity.domain:
            dominfo = self.entity.domain.info()
            if dominfo[0] == libvirt.VIR_DOMAIN_RUNNING or dominfo[0] == libvirt.VIR_DOMAIN_BLOCKED:
                self.create_novnc_proxy()

    def create_novnc_proxy(self, origin=None, user_info=None, parameters=None):
        """
        Create a noVNC proxy on port vmpport + 1000 (so noVNC proxy is 6900 for VNC port 5900 etc).
        @type origin: L{TNArchipelEntity}
        @param origin: the origin of the hook
        @type user_info: object
        @param user_info: random user info
        @type parameters: object
        @param parameters: runtim argument
        """
        if not self.entity.is_hypervisor((archipel.archipelLibvirtEntity.ARCHIPEL_HYPERVISOR_TYPE_QEMU)):
            self.entity.log.warning("Aborting the VNC proxy creation cause current hypervisor %s doesn't support it." % self.entity.libvirt_connection.getType())
            return
        infos = self.display()
        if not infos:
            return
        current_vnc_port = infos["direct"]
        novnc_proxy_port = infos["proxy"]
        self.entity.log.info("NOVNC: current proxy port is %d" % novnc_proxy_port)
        cert = self.configuration.get("VNC", "vnc_certificate_file")
        if cert.lower() in ("none", "no", "false"):
            cert = None
        self.entity.log.info("Virtual machine vnc proxy is using certificate %s" % str(cert))
        onlyssl = self.configuration.getboolean("VNC", "vnc_only_ssl")
        self.entity.log.info("Virtual machine vnc proxy accepts only SSL connection %s" % str(onlyssl))

        self.novnc_proxy = WebSocketProxy(target_host="127.0.0.1", target_port=current_vnc_port,
                                            listen_host="0.0.0.0", listen_port=novnc_proxy_port, cert=cert, ssl_only=onlyssl,
                                            wrap_cmd=None, wrap_mode="exit", verbose=self.websocket_verbose)
        self.novnc_proxy.start()
        self.entity.push_change("virtualmachine:vnc", "websocketvncstart")

    def stop_novnc_proxy(self, origin=None, user_info=None, parameters=None):
        """
        Stop the current novnc websocket proxy if any.
        @type origin: L{TNArchipelEntity}
        @param origin: the origin of the hook
        @type user_info: object
        @param user_info: random user info
        @type parameters: object
        @param parameters: runtime argument
        """
        if self.novnc_proxy:
            self.entity.log.info("Stopping novnc proxy.")
            self.novnc_proxy.stop()
            self.novnc_proxy = None
            self.entity.push_change("virtualmachine:vnc", "websocketvncstop")


    ### XMPP Processing

    def process_iq(self, conn, iq):
        """
        This method is invoked when a ARCHIPEL_NS_VNC IQ is received.
        It understands IQ of type:
            - display
        @type conn: xmpp.Dispatcher
        @param conn: ths instance of the current connection that send the stanza
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ
        """
        reply = None
        action = self.entity.check_acp(conn, iq)
        self.entity.check_perm(conn, iq, action, -1, prefix="vnc_")
        if not self.entity.domain:
            raise xmpp.protocol.NodeProcessed
        elif action == "display":
            reply = self.iq_display(iq)
        if reply:
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed

    def display(self):
        """
        Return an dist containing VNC informations.
        @rtype: dict
        @return: dict containing the information about VNC screen
        """
        xmldesc = self.entity.domain.XMLDesc(0)
        xmldescnode = xmpp.simplexml.NodeBuilder(data=xmldesc).getDom()
        try:
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
        except Exception as ex:
            return None

    def iq_display(self, iq):
        """
        Get the VNC display used in the virtual machine.
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ
        @rtype: xmpp.Protocol.Iq
        @return: a ready to send IQ containing the result of the action
        """
        reply = iq.buildReply("result")
        try:
            if not self.entity.domain:
                return iq.buildReply('ignore')
            ports = self.display()
            if not ports:
                payload = xmpp.Node("display", attrs={})
            else:
                payload = xmpp.Node("display", attrs={"port": str(ports["direct"]), "proxy": str(ports["proxy"]), "host": self.entity.ipaddr, "onlyssl": str(ports["onlyssl"]), "supportssl": str(ports["supportssl"])})
            reply.setQueryPayload([payload])
        except libvirt.libvirtError as ex:
            reply = build_error_iq(self, ex, iq, ex.get_error_code(), ns=archipel.archipelLibvirtEntity.ARCHIPEL_NS_LIBVIRT_GENERIC_ERROR)
        except Exception as ex:
            reply = build_error_iq(self, ex, iq, ARCHIPEL_ERROR_CODE_VM_VNC)
        return reply

    def message_display(self, msg):
        """
        Handle message vnc display order.
        @type msg: xmpp.Protocol.Message
        @param msg: the request message
        @rtype: string
        @return: the answer
        """
        try:
            ports = self.display()
            return "You can connect to my screen at %s:%s" % (self.entity.ipaddr, ports["direct"])
        except Exception as ex:
            return build_error_message(self, ex, msg)