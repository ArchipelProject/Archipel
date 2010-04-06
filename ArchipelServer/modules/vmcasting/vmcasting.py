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
from xml.dom import minidom
import urllib

class TNHypervisorVMCasting:
    
    def __init__(self, database_path, repository_path):
        log(self, LOG_LEVEL_INFO, "opening vmcasting database file {0}".format(database_path))
        
        self.repository_path = repository_path;
        self.database_connection = sqlite3.connect(database_path)
        self.cursor = self.database_connection.cursor();
        
        self.cursor.execute("create table if not exists vmcastsourses (name text, comment text, url text)")
        self.cursor.execute("create table if not exists vmcastappliances (name text, comment text, url text, uuid text unique)")
        
        log(self, LOG_LEVEL_INFO, "Database ready.");
        
        
    # this method is called according to the registration below
    def process_iq(self, conn, iq):
        log(self, LOG_LEVEL_DEBUG, "VMCasting IQ received from {0} with type {1}".format(iq.getFrom(), iq.getType()))

        iqType = iq.getTag("query").getAttr("type");

        if iqType == "get":
            reply = self.__get(iq)
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed

        if iqType == "register":
            reply = self.__register(iq)
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed

        if iqType == "unregister":
            reply = self.__unregister(iq)
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed

        if iqType == "download":
            reply = self.__download(iq)
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed
    
    def __get(self, iq):
        reply = iq.buildReply("success");
        try:
            nodes = self.parseRSS()
            reply.setQueryPayload(nodes)
            
        except Exception as ex:
            log(self, LOG_LEVEL_ERROR, "exception raised is : {0}".format(ex))
            reply = iq.buildReply('error')
            payload = xmpp.Node("error")
            payload.addData(str(ex))
            reply.setQueryPayload([payload])
        return reply

    def __register(self, iq):
        reply       = iq.buildReply("success");
        url         = iq.getTag("query").getAttr("url");
        name        = iq.getTag("query").getAttr("name");
        description = iq.getTag("query").getAttr("description");
        
        self.cursor.execute("INSERT INTO vmcastsourses (name, comment, url) VALUES (?,?,?)", (name, description, url));
        
        return reply
        
    def __unregister(self, iq):
        reply = iq.buildReply("success");
        
        url = iq.getTag("query").getAttr("uuid");
        
        self.cursor.execute("DELETE FROM vmcastsourses WHERE url='?'", (url));
        
        return reply
        
    
    def __download(self, iq):
        reply = iq.buildReply("success");
        
        dl_uuid = iq.getTag("query").getAttr("uuid");
        self.cursor.execute("SELECT * FROM vmcastappliances WHERE uuid='?'", (dl_uuid));
        
        for values in self.cursor:
            name, comment, url, uuid = values;
            print "WILL DOWNLOAD " + str(url) + " FROM UUID " + str(uuid);
        
        #urllib.urlretrieve()
        return reply
        
        
    def parseRSS(self):
        sources = self.cursor.execute("SELECT * FROM vmcastsourses");
        nodes = [];
        
        for values in self.cursor:
            name, comment, url = values
            
            source_node = xmpp.Node(tag="source", attrs={"name": name, "description": comment, "url": url});
            content_nodes = [];
            
            f               = urllib.urlopen(url);
            feed_content    = xmpp.simplexml.NodeBuilder(data=str(f.read())).getDom();
            items           = feed_content.getTag("channel").getTags("item");
            
            for item in items:
                name            = str(item.getTag("title").getCDATA());
                description     = str(item.getTag("description").getCDATA()).replace("\n", "").replace("\t", "");
                url             = str(item.getTag("enclosure").getAttr("url"));
                size            = str(item.getTag("enclosure").getAttr("length"));
                pubdate         = str(item.getTag("pubDate").getCDATA());
                uuid            = str(item.getTag("uuid").getCDATA());
                new_node = xmpp.Node(tag="appliance", attrs={"name": name, "description": description, "url": url, "size": size, "date": pubdate, "uuid": uuid})
                content_nodes.append(new_node);
                try:
                    self.cursor.execute("INSERT INTO vmcastappliances VALUES (?,?,?,?)", (name, description, url, uuid));
                except Exception as ex:
                    pass
                self.database_connection.commit();
            
            source_node.setPayload(content_nodes)
            nodes.append(source_node);

        return nodes;
