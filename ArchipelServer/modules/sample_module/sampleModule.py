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
        iqType = iq.getTag("query").getAttr("type")
        log(self, LOG_LEVEL_DEBUG, " IQ received from {%s} with type {%s} : {%s}" % (iq.getFrom(), iq.getType(), iqType))
        
        if iqType == "do-something":
            reply = self.__do_something(iq)
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed
            

    def __do_something(self, iq):
        """
        Doing something.

        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ

        @rtype: xmpp.Protocol.Iq
        @return: a ready to send IQ containing the result of the action
        """
        try:
            reply = iq.buildReply('success')
            log(self, LOG_LEVEL_INFO, "I did something!")
            self.entity.push_change("sample", "I_DID_SOMETHING")
            self.entity.shout("Sample", "Hey buddies, you know what ? I did somthing! crazy isn't it ?")
        except Exception as ex:
            reply = build_error_iq(self, ex, iq)
        return reply