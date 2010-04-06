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
from threading import Thread

class TNApplianceDownloader(Thread):
    def __init__(self, url, save_path, uuid):
        self.url = url;
        self.uuid = uuid
        self.save_path = save_path
        self.progress = 0.0;
        Thread.__init__(self)
    
    def run(self):
        urllib.urlretrieve(self.url, self.save_path, self.downloading_callback)
    
    def get_progress(self):
        return self.progress;
        
    def downloading_callback(self, blocks_count, block_size, total_size):
           percentage = (float(blocks_count) * float(block_size)) / float(total_size) * 100;
           print "downloaded " + str(percentage) + "%"
           self.progress = percentage;
    
class TNHypervisorVMCasting:
    
    def __init__(self, database_path, repository_path, entity):
        log(self, LOG_LEVEL_INFO, "opening vmcasting database file {0}".format(database_path))
        
        self.entity = entity
        self.repository_path = repository_path;
        self.download_queue = {};
        self.database_connection = sqlite3.connect(database_path)
        self.cursor = self.database_connection.cursor();
        
        self.cursor.execute("create table if not exists vmcastsourses (name text, comment text, url text)")
        self.cursor.execute("create table if not exists vmcastappliances (name text, comment text, url text, uuid text unique)")
        
        log(self, LOG_LEVEL_INFO, "Database ready.");
        
        
    # this method is called according to the registration below
    def process_iq(self, conn, iq):
        iqType = iq.getTag("query").getAttr("type");
        
        log(self, LOG_LEVEL_DEBUG, "VMCasting IQ received from {0} with type {1} / {2}".format(iq.getFrom(), iq.getType(), iqType))
        
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
            
        if iqType == "downloadprogress":
            reply = self.__get_download_progress(iq)
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
        
        print "SELECT * FROM vmcastappliances WHERE uuid='?'"
        self.cursor.execute("SELECT * FROM vmcastappliances WHERE uuid='%s'" % dl_uuid);
        
        for values in self.cursor:
            name, comment, url, uuid = values;
            downloader = TNApplianceDownloader(url, self.repository_path + "/" + uuid + ".xvm2", uuid);
            downloader.daemon = True;
            downloader.start();
            self.download_queue[uuid] = downloader;
            
        return reply
    
    
    
    def __get_download_progress(self, iq):
        reply = iq.buildReply("success"); 
        dl_uuid = iq.getTag("query").getAttr("uuid");
        
        reply.setAttr('progress', str(self.download_queue[dl_uuid].get_progress()));

        
        return reply;
    
    
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
    
