# -*- coding: utf-8 -*-
#
# virtualmachineagent.py
#
# Copyright (C) 2012 parspooyesh <everplays@gmail.com>
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

import xmpp
from archipelcore.archipelPlugin import TNArchipelPlugin
from archipelcore.utils import build_error_iq

ARCHIPEL_ERROR_CODE_VIRTUALMACHINEAGENT_EXEC = -10001

# Namespace
ARCHIPEL_NS_GUEST_CONTROL                  = "archipel:guest:control"

class TNVirtualMachineAgent(TNArchipelPlugin):
    """
    this module enables user to send commands to archipelguest running on guest os
    """
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
        self.entity.add_vm_definition_hook(self.add_net_switch_to_definition)

    def add_net_switch_to_definition(self, sender, xmldesc):
        """
        adds network switches if GUEST.enabled configuration is true
        @type sender: xmpp.JID
        @param sender: the jid that edited definition
        @type xmldesc: xmpp.Node
        @param xmldesc: xml definition that is going to be sent to libvirt
        @rtype: xmpp.Node
        @return: xml definition
        """
        self.entity.log.info('GUEST.enabled: '+str(self.configuration.getboolean("GUEST", "enabled")))
        if self.configuration.getboolean("GUEST", "enabled"):
            shouldBeAdded = False
            name = xmldesc.getTag('name').getData()
            hostname = 'user,hostname=%s.%s' % (name, self.entity.jid.getDomain())
            # check if we already have added switch
            commandline = xmldesc.getTag('commandline', namespace='qemu')
            if commandline == None:
                # add commandline tag, if we don't have any
                shouldBeAdded = True
                commandline = xmldesc.addChild(name='qemu:commandline', attrs={
                    "xmlns:qemu": 'http://libvirt.org/schemas/domain/qemu/1.0'})
            else:
                # if we have commandline tag, check for args to be like:
                # 0: -net
                # 1: nic,model=virtio,addr=0xf
                # 2: -net
                # 3: user,hostname=...
                hasSwitches = 0
                for arg in commandline.getTags('arg', namespace='qemu'):
                    if arg.getAttr('value') == '-net' and (hasSwitches == 0 or hasSwitches == 2):
                        hasSwitches += 1
                        continue
                    if hasSwitches == 1:
                        if arg.getAttr('value')=='nic,model=virtio,addr=0xf':
                            hasSwitches += 1
                            continue
                    if hasSwitches == 3:
                        if arg.getAttr('value')==hostname:
                            hasSwitches += 1
                            break
                    hasSwitches = 0
                if hasSwitches < 4:
                    shouldBeAdded = True
            if shouldBeAdded:
                commandline.addChild(name='qemu:arg', attrs={'value': '-net'})
                commandline.addChild(name='qemu:arg', attrs={'value': 'nic,model=virtio,addr=0xf'})
                commandline.addChild(name='qemu:arg', attrs={'value': '-net'})
                commandline.addChild(name='qemu:arg', attrs={'value': hostname })
        return xmldesc

    def register_handlers(self):
        """
        lets register our stanza handlers
        """
        TNArchipelPlugin.register_handlers(self)
        self.entity.xmppclient.RegisterHandler('message', self.process_message, typ="chat")
        self.entity.xmppclient.RegisterHandler('iq', self.process_iq, ns=ARCHIPEL_NS_GUEST_CONTROL)

    def unregister_handlers(self):
        """
        hmm, seems we have to unregister our handlers
        """
        TNArchipelEntity.unregister_handlers(self)
        self.entity.xmppclient.UnregisterHandler('message', self.process_message, typ="chat")
        self.entity.xmppclient.UnregisterHandler('iq', self.process_iq, ns=ARCHIPEL_NS_GUEST_CONTROL)

    @staticmethod
    def plugin_info():
        """
        Return informations about the plugin.
        @rtype: dict
        @return: dictionary contaning plugin informations
        """
        return {    "common-name"               : "Virtual Machine Agent",
                    "identifier"                : "virtualmachineguestagent",
                    "configuration-section"     : 'GUEST',
                    "configuration-tokens"      : ['enabled']}

    def process_iq(self, conn, iq):
        """
        processes iq messages with archipel:guest:control
        @type conn: xmpp.Dispatcher
        @param conn: instance of connection that sent message
        @type iq: xmpp.Protocol.Iq
        @param iq: received Iq stanza
        """
        reply = None
        action = self.entity.check_acp(conn, iq)

        if action == "exec":
            reply = self.iq_exec(iq)
        if reply:
            conn.send(reply)
            raise xmpp.NodeProcessed

    def iq_exec(self, iq):
        """
        processes iq with exec type and returns the stanza that should be sent
        @type id: xmpp.Protocol.Iq
        @param id: received iq
        @rtype: xmpp.Protocol
        @return: the stanza that should be sent or None if we've not processes the stanza
        """
        # if we've received iq from agent running in guest os it has to be result of
        # a executed command, so tunnel result back to user as message
        # TODO: if we received an Iq from agent running in guest and jid has permission
        # to send us Iq, we should tunnel his/her command to agent and sent it back as Iq
        # when we received result Iq
        reply = None
        try:
            if str(iq.getFrom()).lower() == (self.entity.uuid+"-agent@"+self.entity.jid.getDomain()+"/guestagent").lower():
                archipel = iq.getTag("query").getTag("archipel")
                reply = xmpp.protocol.Message(archipel.getAttr('executor'), archipel.getData())
        except Exception as ex:
            reply = build_error_iq(self, ex, iq, ARCHIPEL_ERROR_CODE_VIRTUALMACHINEAGENT_EXEC)
        return reply

    def process_message(self, conn, msg):
        """
        processes messages that start with !exec as command that should be run on guest os
        @type conn: xmpp.Dispatcher
        @param conn: instance of connection that sent message
        @type msg: xmpp.Protocol.Message
        @param msg: received message stanza
        """
        body = str(msg.getBody())
        if body.find("!exec") == 0 and self.entity.permission_center.check_permission(str(msg.getFrom().getStripped()), "message"):
            runIq = self.exec_msg(msg)
            self.entity.log.info('sending: '+str(runIq))
            conn.send(runIq)
            raise xmpp.NodeProcessed

    def exec_msg(self, msg):
        """
        makes an Iq stanza to agent running on guest to run the command
        @type msg: xmpp.Protocol.Message
        @param msg: message that starts with !exec
        @rtype: xmpp.Protocol
        @return: the stanza that must be sent
        """
        body = msg.getBody()
        command = body.replace('!exec', '').strip()
        executor = msg.getFrom()
        return self.execute(command, executor)

    def execute(self, command, executor):
        """
        generates an Iq get to agent running on guest
        @type command: String
        @param command: the command that should be executed on guest machine
        @type executor: String
        @param executor: the jid that sent the command (will be used for sending result back)
        @rtype: xmpp.protocol.Iq
        @return: generated Iq stanza
        """
        to = xmpp.JID(self.entity.uuid+'-agent@'+self.entity.jid.getDomain()+'/guestagent')
        iq = xmpp.protocol.Iq(typ='get', to=to)
        iq.setQueryNS(ARCHIPEL_NS_GUEST_CONTROL);
        query = iq.getTag("query");
        archipel = query.addChild('archipel', attrs={
            "executor": executor,
            "action": "exec"});
        archipel.addData(command)
        return iq

