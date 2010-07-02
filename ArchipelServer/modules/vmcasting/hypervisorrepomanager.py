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
# but WITHOUT ANY WARRANTY without even the implied warranty of
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
import urlparse
import os
from threading import Thread
from threading import Timer
import uuid
import vmcastmaker
import time

ARCHIPEL_APPLIANCES_INSTALLED           = 1
ARCHIPEL_APPLIANCES_INSTALLING          = 2
ARCHIPEL_APPLIANCES_NOT_INSTALLED       = 3
ARCHIPEL_APPLIANCES_INSTALLATION_ERROR  = 4

ARCHIPEL_ERROR_CODE_VMCASTS_GET                 = -6001
ARCHIPEL_ERROR_CODE_VMCASTS_REGISTER            = -6002
ARCHIPEL_ERROR_CODE_VMCASTS_UNREGISTER          = -6003
ARCHIPEL_ERROR_CODE_VMCASTS_DOWNLOADAPPLIANCE   = -6004
ARCHIPEL_ERROR_CODE_VMCASTS_DOWNLOADQUEUE       = -6005
ARCHIPEL_ERROR_CODE_VMCASTS_GETAPPLIANCES       = -6006
ARCHIPEL_ERROR_CODE_VMCASTS_DELETEAPPLIANCE     = -6007
ARCHIPEL_ERROR_CODE_VMCASTS_GETINSTALLED        = -6008


class TNApplianceDownloader(Thread):
    """
    implementation of a downloader. This run in a separate thread.
    """
    def __init__(self, url, save_folder, uuid, name, finish_callback):
        """
        initialization of the class
        @type url: string
        @param url: the url to download
        @type save_folder: string
        @param save_folder: the folder where the download will be saved
        @type uuid: string
        @param uuid: the uuid of the appliance to download
        @type name: string
        @param name: the name of the download
        @type finish_callback: method
        @param finish_callback the callback method to execute when a download is finished
        """
        Thread.__init__(self)
        self.url                = url
        self.save_folder        = save_folder
        self.uuid               = uuid
        self.name               = name
        self.finish_callback    = finish_callback
        self.save_path          = self.save_folder + "/" + uuid + ".xvm2"
        self.progress           = 0.0
        self.total_size         = None
    
    
    def run(self):
        """
        main loop of the thread. will start to download
        """
        log.info( "starting to download appliance %s " % self.url)
        urllib.urlretrieve(self.url, self.save_path, self.downloading_callback)
    
    
    def get_progress(self):
        """
        @return: the progress percentage of the download
        """
        return self.progress
    
    
    def get_uuid(self):
        """
        @return: the uuid of the download
        """
        return self.uuid
    
    
    def get_total_size(self):
        """
        @return: the total size in bytes of the download
        """
        if self.total_size:
            return self.total_size
        else:
            return -1
    
    
    def get_name(self):
        """
        @return: the name of the download
        """
        return self.name
    
    
    def stop(self):
        """
        stop the download. NOT IMPLEMENTED
        """
        raise NotImplemented
    
    
    def downloading_callback(self, blocks_count, block_size, total_size):
        """
        internal callback of the download status called by urlretrieve.
        If percentage reach 100, it will call the finish_callback with uuid as parameter
        @type blocks_count: integer
        @param blocks_count: the downloaded number of blocks
        @type block_size: integer
        @param block_size: the size of one block
        @param total_size: the total size in bytes of the file downloaded
        
        """
        self.total_size = total_size
        percentage = (float(blocks_count) * float(block_size)) / float(total_size) * 100
        #print str(float(blocks_count)) +  "*" + str(float(block_size)) + "/"  + str(float(total_size)) + "*"  + "100"
        #print "downloading: " + str(percentage) + "%"
        if percentage >= 100.0:
            self.finish_callback(self.uuid, self.save_path)
        
        self.progress = percentage
    


class TNHypervisorRepoManager:
    """
    Implementation of the module
    """
    def __init__(self, database_path, repository_path, entity, own_repo_params):
        """
        initialize the class
        @type database_path: string
        @param database_path: the path of the sqlite3 database to use
        @type repository_path: string
        @param repository_path: the path of the repository to download and store appliances
        @type entity: TNArchipelHypervisor
        @param entity: the instance of the TNArchipelHypervisor. Will be used for push.
        """
        log.info( "opening vmcasting database file {0}".format(database_path))
        
        self.entity = entity
        self.database_path = database_path
        self.repository_path = repository_path
        self.own_repo_params = own_repo_params
        self.download_queue = {}
        
        self.own_vmcastmaker = vmcastmaker.VMCastMaker(self.own_repo_params["name"], self.own_repo_params["uuid"], 
                                                        self.own_repo_params["description"], self.own_repo_params["lang"], 
                                                        self.own_repo_params["url"], self.own_repo_params["path"])
        
        self.parse_own_repo(loop=False)
        self.parse_timer = Thread(target=self.parse_own_repo)
        self.parse_timer.start()
        
        self.database_connection = sqlite3.connect(database_path, check_same_thread = False)
        self.cursor = self.database_connection.cursor()
        self.cursor.execute("create table if not exists vmcastsources (name text, description text, url text not null unique, uuid text unique)")
        self.cursor.execute("create table if not exists vmcastappliances (name text, description text, url text, uuid text unique not null, status int, source text not null, save_path text)")
        
        log.info( "Database ready.")
    
    
    def parse_own_repo(self, loop=True):
        while True:
            log.debug( "begin to refresh own vmcast feed")
            self.own_vmcastmaker.parseDirectory(self.own_repo_params["path"])
            self.own_vmcastmaker.writeFeed(self.own_repo_params["path"] + "/" + self.own_repo_params["filename"])
            log.debug( "finish to refresh own vmcast feed")
            if not loop:
                break
            time.sleep(self.own_repo_params["refresh"])
        
    def on_download_complete(self, uuid, path):
          """
          callback triggered by a TNApplianceDownloader when download is over
          @type uuid: string
          @param uuid: the uuid of the download
          @type path: string
          @param path: the path of the downloaded file
          """
          self.cursor.execute("UPDATE vmcastappliances SET status=%d, save_path='%s' WHERE uuid='%s'" % (ARCHIPEL_APPLIANCES_INSTALLED, path, uuid))
          
          del self.download_queue[uuid]
          self.database_connection.commit()
          self.entity.push_change("vmcasting", "download_complete", excludedgroups=['vitualmachines'])
          self.entity.shout("vmcast", "I've finished to download appliance %s" % (uuid), excludedgroups=['vitualmachines'])
          self.entity.change_status(self.old_entity_status)
    
    
    def process_iq(self, conn, iq):
        """
        process incoming IQ of type NS_ARCHIPEL_HYPERVISOR_VMCASTING.
        it understands IQ of type:
            - get
            - register
            - unregister
            - downloadappliance
            - downloadqueue
            - getappliances
            - deleteappliance
        
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
        
        if action == "get":
            reply = self.get(iq)
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed
            
        elif action == "register":
            reply = self.register(iq)
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed
            
        elif action == "unregister":
            reply = self.unregister(iq)
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed
            
        elif action == "downloadappliance":
            reply = self.download(iq)
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed
            
        elif action == "downloadqueue":
            reply = self.get_download_queue(iq)
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed
        
        elif action == "getappliances":
            reply = self.get_appliance(iq)
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed   
        
        elif action == "deleteappliance":
            reply = self.delete_appliance(iq)
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed
        
        elif action == "getinstalledappliances":
            reply = self.get_installed_appliances(iq)
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed
    
    
    def get(self, iq):
        """
        get the sources and appliances. Replay parseRSS at each time to be up to date
        
        @type iq: xmpp.Protocol.Iq
        @param iq: the sender request IQ
        @rtype: xmpp.Protocol.Iq
        @return: a ready-to-send IQ containing the results"""
        reply = iq.buildReply("result")
        try:
            nodes = self.parseRSS()
            reply.setQueryPayload(nodes)
        except Exception as ex:
            reply = build_error_iq(self, ex, iq, ARCHIPEL_ERROR_CODE_VMCASTS_GET)
        return reply
    
        
    def register(self, iq):
        """
        register to a new VMCast
        
        @type iq: xmpp.Protocol.Iq
        @param iq: the sender request IQ
        @rtype: xmpp.Protocol.Iq
        @return: a ready-to-send IQ containing the results
        """
        reply       = iq.buildReply("result")
        url         = iq.getTag("query").getTag("archipel").getAttr("url")
        
        try:
            if not url or url=="":
                raise Exception("IncorrectStanza", "Stanza must have url")
            self.cursor.execute("INSERT INTO vmcastsources (url) VALUES ('%s')" % url)
            self.database_connection.commit()
            self.entity.push_change("vmcasting", "register", excludedgroups=['vitualmachines'])
            self.entity.shout("vmcast", "I'm now registred to vmcast %s as asked by %s" % (url, iq.getFrom()), excludedgroups=['vitualmachines'])
        except Exception as ex:
            reply = build_error_iq(self, ex, iq, ARCHIPEL_ERROR_CODE_VMCASTS_REGISTER)
        return reply
    
    
    def unregister(self, iq):
        """
        unregister from a VMCasts and remove all its appliances (not the files)
        
        @type iq: xmpp.Protocol.Iq
        @param iq: the sender request IQ
        @rtype: xmpp.Protocol.Iq
        @return: a ready-to-send IQ containing the results
        """
        reply = iq.buildReply("result")
        
        uuid = iq.getTag("query").getTag("archipel").getAttr("uuid")
        
        try:
            self.cursor.execute("DELETE FROM vmcastsources WHERE uuid='%s'" % uuid)
            self.cursor.execute("DELETE FROM vmcastappliances WHERE source='%s'" % uuid)
            self.database_connection.commit()
            self.entity.push_change("vmcasting", "unregister", excludedgroups=['vitualmachines'])
            self.entity.shout("vmcast", "I'm now unregistred from vmcast %s as asked by %s" % (uuid, iq.getFrom()), excludedgroups=['vitualmachines'])
        except Exception as ex:
            reply = build_error_iq(self, ex, iq, ARCHIPEL_ERROR_CODE_VMCASTS_UNREGISTER)
        return reply
    
    
    def download(self, iq):
        """
        start a download of appliance according to its uuid
        
        @type iq: xmpp.Protocol.Iq
        @param iq: the sender request IQ
        @rtype: xmpp.Protocol.Iq
        @return: a ready-to-send IQ containing the results
        """
        reply = iq.buildReply("result")
        
        dl_uuid = iq.getTag("query").getTag("archipel").getAttr("uuid")
        
        try:
            self.cursor.execute("UPDATE vmcastappliances SET status=%d WHERE uuid='%s'" % (ARCHIPEL_APPLIANCES_INSTALLING, dl_uuid))
            self.cursor.execute("SELECT * FROM vmcastappliances WHERE uuid='%s'" % dl_uuid)
            self.database_connection.commit()
            
            self.entity.push_change("vmcasting", "download_start", excludedgroups=['vitualmachines'])
            
            for values in self.cursor:
                name, description, url, uuid, status, source, path = values
                downloader = TNApplianceDownloader(url, self.repository_path, uuid, name, self.on_download_complete)
                downloader.start()
                self.download_queue[uuid] = downloader
            self.old_entity_status = self.entity.xmppstatus
            self.entity.change_status("Downloading appliance...")
        except Exception as ex:
            reply = build_error_iq(self, ex, iq, ARCHIPEL_ERROR_CODE_VMCASTS_DOWNLOADAPPLIANCE)
        return reply
    
    
    def get_download_queue(self, iq):
        """
        get the state of the download queue.
        
        @type iq: xmpp.Protocol.Iq
        @param iq: the sender request IQ
        @rtype: xmpp.Protocol.Iq
        @return: a ready-to-send IQ containing the results
        """
        reply = iq.buildReply("result") 
        nodes = []
        
        try:
            for uuid, download in self.download_queue.items():
                dl = xmpp.Node(tag="download", attrs={"uuid": download.get_uuid(), "name": download.get_name(), "percentage": download.get_progress(), "total": download.get_total_size()})
                nodes.append(dl)
            
            reply.setQueryPayload(nodes)
        except Exception as ex:
            reply = build_error_iq(self, ex, iq, ARCHIPEL_ERROR_CODE_VMCASTS_DOWNLOADQUEUE)
        return reply
    
    
    def stop_download(self, iq):
        """
        stop a download according to its uuid
        
        @type iq: xmpp.Protocol.Iq
        @param iq: the sender request IQ
        @rtype: xmpp.Protocol.Iq
        @return: a ready-to-send IQ containing the results
        """
        reply = iq.buildReply("result")
        dl_uuid = iq.getTag("query").getTag("archipel").getAttr("uuid")
        self.download_queue[dl_uuid].stop()
        return reply
    
    
    def get_appliance(self, iq):
        """
        get the info about an appliances according to its uuid
        
        @type iq: xmpp.Protocol.Iq
        @param iq: the sender request IQ
        @rtype: xmpp.Protocol.Iq
        @return: a ready-to-send IQ containing the results
        """
        reply = iq.buildReply("result")
        uuid = iq.getTag("query").getTag("archipel").getAttr("uuid")
        
        try:
            self.cursor.execute("SELECT save_path, name, description FROM vmcastappliances WHERE uuid='%s'" % dl_uuid)
            for values in self.cursor:
                path = values[0]
                name = values[1]
                description = values[2]
            
            node = xmpp.Node(tag="appliance", attrs={"path": path, "name": name, "description": description})
            reply.setQueryPayload([node])
        except Exception as ex:
            reply = build_error_iq(self, ex, iq, ARCHIPEL_ERROR_CODE_VMCASTS_GETAPPLIANCES)
        return reply
    
    
    def get_installed_appliances(self, iq):
        """
        get all installed appliances
        
        @type iq: xmpp.Protocol.Iq
        @param iq: the sender request IQ
        @rtype: xmpp.Protocol.Iq
        @return: a ready-to-send IQ containing the results
        """
        reply = iq.buildReply("result")
        uuid = iq.getTag("query").getTag("archipel").getAttr("uuid")
        nodes = []
        try:
            self.cursor.execute("SELECT save_path, name, description FROM vmcastappliances WHERE status=%d" % (ARCHIPEL_APPLIANCES_INSTALLED))
            for values in self.cursor:
                path = values[0]
                name = values[1]
                description = values[2]    
                node = xmpp.Node(tag="appliance", attrs={"path": path, "name": name, "description": description})
                nodes.append(node)
            
            reply.setQueryPayload(nodes)
        except Exception as ex:
            reply = build_error_iq(self, ex, iq, ARCHIPEL_ERROR_CODE_VMCASTS_GETINSTALLED)
        return reply
    
    
    def delete_appliance(self, iq):
        """
        delete an appliance according to its uuid
        
        @type iq: xmpp.Protocol.Iq
        @param iq: the sender request IQ
        @rtype: xmpp.Protocol.Iq
        @return: a ready-to-send IQ containing the results
        """
        
        try:
            reply = iq.buildReply("result")
            uuid = iq.getTag("query").getTag("archipel").getAttr("uuid")
            
            self.cursor.execute("SELECT save_path FROM vmcastappliances WHERE uuid='%s'" % uuid)
            for values in self.cursor:
                path = values[0]
                
            os.remove(path)
            self.cursor.execute("UPDATE vmcastappliances SET status=%d WHERE uuid='%s'" % (ARCHIPEL_APPLIANCES_NOT_INSTALLED, uuid))
            self.database_connection.commit()
            
            self.entity.push_change("vmcasting", "appliancedeleted", excludedgroups=['vitualmachines'])
            self.entity.shout("vmcast", "I've just delete appliance %s as asked by %s" % (uuid, iq.getFrom()), excludedgroups=['vitualmachines'])
            
        except Exception as ex:
            reply = build_error_iq(self, ex, iq, ARCHIPEL_ERROR_CODE_VMCASTS_DELETEAPPLIANCE)
        return reply
    
    
    def parseRSS(self):
        """
        parse the content of the database, update the feed, create the answer node.
        """
        sources = self.cursor.execute("SELECT * FROM vmcastsources")
        nodes = []
        
        tmp_cursor = self.database_connection.cursor()
        
        for values in sources:
            name, description, url, uuid = values
            
            log.debug( "parsing feed with url %s" % url)
            
            source_node = xmpp.Node(tag="source", attrs={"name": name, "description": description, "url": url, "uuid": uuid})
            content_nodes = []
            
            try:
                f = urllib.urlopen(url)
            except Exception as ex:
                tmp_cursor.execute("DELETE FROM vmcastsources WHERE url='%s'" % url)
                self.database_connection.commit()
                self.entity.push_change("vmcasting", "unregister", excludedgroups=['vitualmachines'])
                raise Exception("404", "Feed is not reponding. removed from database.")
            
            try:
                feed_content        = xmpp.simplexml.NodeBuilder(data=str(f.read())).getDom()
                feed_uuid           = feed_content.getTag("channel").getTag("uuid").getCDATA()
                feed_description    = feed_content.getTag("channel").getTag("description").getCDATA()
                feed_name           = feed_content.getTag("channel").getTag("title").getCDATA()
                items               = feed_content.getTag("channel").getTags("item")
                            
                if not feed_uuid or not feed_name:
                    raise
            except:
                tmp_cursor.execute("DELETE FROM vmcastsources WHERE url='%s'" % url)
                self.database_connection.commit()
                raise Exception('Bad format', "URL doesn't seem to contain valid VMCasts. Removed")
            
            try:
                tmp_cursor.execute("UPDATE vmcastsources SET uuid='%s', name='%s', description='%s' WHERE url='%s'" % (feed_uuid, feed_name, feed_description, url))
                self.database_connection.commit()
            except Exception as ex:
                log.debug( "unable to update source because: " + str(ex))
                pass
            
            for item in items:
                name            = str(item.getTag("title").getCDATA())
                description     = str(item.getTag("description").getCDATA()).replace("\n", "").replace("\t", "")
                url             = str(item.getTag("enclosure").getAttr("url"))
                size            = str(item.getTag("enclosure").getAttr("length"))
                pubdate         = str(item.getTag("pubDate").getCDATA())
                uuid            = str(item.getTag("uuid").getCDATA())
                status          = ARCHIPEL_APPLIANCES_NOT_INSTALLED
                
                try:
                    tmp_cursor.execute("INSERT INTO vmcastappliances VALUES (?,?,?,?,?,?,?)", (name, description, url, uuid, status, feed_uuid, '/dev/null'))
                    self.database_connection.commit()
                except Exception as ex:
                    tmp_cursor.execute("SELECT status FROM vmcastappliances WHERE uuid='%s'" % uuid)
                    for values in tmp_cursor:
                        status = values[0]
                    if status == ARCHIPEL_APPLIANCES_INSTALLING and not self.download_queue.has_key(uuid):
                        status = ARCHIPEL_APPLIANCES_INSTALLATION_ERROR
                    
                new_node = xmpp.Node(tag="appliance", attrs={"name": name, "description": description, "url": url, "size": size, "date": pubdate, "uuid": uuid, "status": str(status)})
                content_nodes.append(new_node)
            
            source_node.setPayload(content_nodes)
            nodes.append(source_node)
            
        return nodes
    
