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
from archipel.utils import *
import archipel.core



class TNSampleModule:
    
    def __init__(self, entity):
        """
        initialize the module
        @type entity TNArchipelEntity
        @param entity the module entity
        """
        self.entity = entity
        
        # permissions
        self.entity.permission_center.create_permission("sample_do-something", "Authorizes user to do something", False);
    
    
    def process_iq(self, conn, iq):
        """
        this method is invoked when a ARCHIPEL_NS_SAMPLE IQ is received.
        
        it understands IQ of type:
            - do-something
        
        @type conn: xmpp.Dispatcher
        @param conn: ths instance of the current connection that send the stanza
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ
        """
        action = self.entity.check_acp(conn, iq)
        self.entity.check_perm(conn, iq, action, -1)
        
        if action == "do-something":
            reply = self.iq_do_something(iq)
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed
    
    
    
    ### XMPP Processing
    
    
    def iq_do_something(self, iq):
        """
        Do something.
        
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ
        
        @rtype: xmpp.Protocol.Iq
        @return: a ready to send IQ containing the result of the action
        """
        try:
            reply = iq.buildReply("result")
            self.entity.log.info("I did something!")
            self.entity.push_change("sample", "I_DID_SOMETHING")
            self.entity.shout("Sample", "Hey buddies, you know what ? I did somthing! crazy isn't it ?")
        except Exception as ex:
            reply = build_error_iq(self, ex, iq)
        return reply
    
