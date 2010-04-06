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
import sqlite3


class TNHypervisorVMCasting:
    
    def __init__(self, database_path):
        log(self, LOG_LEVEL_INFO, "opening vmcasting database file {0}".format(database_path))
        
        self.database_connection = sqlite3.connect(database_path)
        self.cursor = self.database_connection.cursor();
        
        self.cursor.execute("create table if not exists vmcastssource (name text, comment text, url text)")
        
        log(self, LOG_LEVEL_INFO, "Database ready.");
        
        
    # this method is called according to the registration below
    def process_iq(self, conn, iq):
        log(self, LOG_LEVEL_DEBUG, "VMCasting IQ received from {0} with type {1}".format(iq.getFrom(), iq.getType()))

        iqType = iq.getTag("query").getAttr("type");

        if iqType == "get":
            reply = self.__vmcasting_get(iq)
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed

        if iqType == "register":
            reply = self.__vmcasting_register(iq)
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed

        if iqType == "unregister":
            reply = self.__vmcasting_unregister(iq)
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed

    
    def __vmcasting_get(self, iq):
        return reply

    def __vmcasting_register(self, iq):
        reply = iq.buildReply("sucessregister");
        return reply
        
    def __vmcasting_unregister(self, iq):
        reply = iq.buildReply("sucessunregister");
        return reply