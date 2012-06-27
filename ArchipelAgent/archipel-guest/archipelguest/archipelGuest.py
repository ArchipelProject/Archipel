# -*- coding: utf-8 -*-
#
# archipelGuest.py
#
# Copyright (C) 2010 Antoine Mercadal <antoine.mercadal@inframonde.eu>
# Copyright, 2011 - Franck Villaume <franck.villaume@trivialdev.com>
# Copyright (C) 2012 Parspooyesh - Behrooz Shabani <everplays@gmail.com>
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

"""
Contains L{TNArchipelGuest}, singleton entity for guest os
"""
import xmpp
import subprocess
from threading import Thread

from archipelcore.archipelEntity import TNArchipelEntity
from archipelcore.archipelHookableEntity import TNHookableEntity
from archipelcore.archipelTaggableEntity import TNTaggableEntity
from archipelcore.utils import build_error_iq

# Namespace
ARCHIPEL_NS_GUEST_CONTROL                  = "archipel:guest:control"

# XMPP shows
ARCHIPEL_XMPP_SHOW_ONLINE                       = "Online"

class TNArchipelGuest(TNArchipelEntity, TNHookableEntity, TNTaggableEntity):
    """
    This class represents a Guest XMPP Capable.
    """
    def __init__(self, jid, password, configuration):
        """
        This is the constructor of the class.
        @type jid: string
        @param jid: the jid of the hypervisor
        @type password: string
        @param password: the password associated to the JID
        @type configuration: ConfigParser
        @param configuration: configuration object
        """
        TNArchipelEntity.__init__(self, jid, password, configuration, 'auto')
        self.log.info("starting archipel-agent")

        self.xmppserveraddr             = self.jid.getDomain()
        self.entity_type                = "guest"

        self.log.info("Server address defined as %s" % self.xmppserveraddr)

        # module inits
        self.initialize_modules('archipel.plugin.guest')

    ### Utilities

    def register_handlers(self):
        """
        lets register our iq handler
        """
        TNArchipelEntity.register_handlers(self)
        self.xmppclient.RegisterHandler('iq', self.process_iq, ns=ARCHIPEL_NS_GUEST_CONTROL)

    def unregister_handlers(self):
        """
        hmm, seems that we must unregister our iq handler
        """
        TNArchipelEntity.unregister_handlers(self)
        self.xmppclient.UnregisterHandler('iq', self.process_iq, ns=ARCHIPEL_NS_GUEST_CONTROL)

    ### XMPP Processing

    def process_iq(self, conn, iq):
        """
        This method is invoked when a ARCHIPEL_NS_GUEST_CONTROL IQ is received.
        It understands IQ of type:
            - exec
        @type conn: xmpp.Dispatcher
        @param conn: ths instance of the current connection that send the stanza
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ
        """
        reply = None
        action = self.check_acp(conn, iq)

        if action == "exec":
            reply = self.iq_exec(iq)
        if reply:
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed

    def iq_exec(self, iq):
        self.log.info('processing: '+str(iq))
        response = 'direct execution is not allowed'
        if iq.getFrom().getStripped().lower()==self.jid.getStripped().replace('-agent', '').lower():
            p = subprocess.Popen(iq.getTag("query").getTag("archipel").getData(), stdout=subprocess.PIPE)
            response, stderr = p.communicate()
        result = iq.buildReply('result')
        result.setQueryNS(ARCHIPEL_NS_GUEST_CONTROL)
        query = result.getTag("query")
        archipel = query.addChild('archipel')
        archipel.setAttr('action', 'exec')
        archipel.setAttr('executor', iq.getTag("query").getTag("archipel").getAttr("executor"))
        archipel.addData(response)
        self.log.info('responsing: '+str(result))
        return result

