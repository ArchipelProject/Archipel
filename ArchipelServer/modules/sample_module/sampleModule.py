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



class TNSampleModule:
    
    def __init__(self):
        #internal module initialization
        pass

    def process_iq(self, conn, iq):
        """
        this method is invoked when a NS_ARCHIPEL_SAMPLE IQ is received.
        
        it understands IQ of type:
            - do-something
        
        @type conn: xmpp.Dispatcher
        @param conn: ths instance of the current connection that send the stanza
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ
        """
        try:
            action = iq.getTag("query").getTag("archipel").getAttr("action")
            log.info( "IQ RECEIVED: from: %s, type: %s, namespace: %s, action: %s" % (iq.getFrom(), iq.getType(), iq.getQueryNS(), action))
        except Exception as ex:
            reply = build_error_iq(self, ex, iq, NS_ARCHIPEL_ERROR_QUERY_NOT_WELL_FORMED)
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed
        
        if action == "do-something":
            reply = self.__do_something(iq)
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed
            

    def __do_something(self, iq):
        """
        Do something.

        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ

        @rtype: xmpp.Protocol.Iq
        @return: a ready to send IQ containing the result of the action
        """
        try:
            reply = iq.buildReply("result")
            log.info( "I did something!")
            self.entity.push_change("sample", "I_DID_SOMETHING")
            self.entity.shout("Sample", "Hey buddies, you know what ? I did somthing! crazy isn't it ?")
        except Exception as ex:
            reply = build_error_iq(self, ex, iq)
        return reply