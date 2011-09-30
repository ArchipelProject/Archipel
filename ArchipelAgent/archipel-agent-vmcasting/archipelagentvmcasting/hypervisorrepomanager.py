# -*- coding: utf-8 -*-
#
# hypervisorrepomanager.py
#
# Copyright (C) 2010 Antoine Mercadal <antoine.mercadal@inframonde.eu>
# Copyright, 2011 - Franck Villaume <franck.villaume@trivialdev.com>
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

import os
import sqlite3
import time
import urllib
import vmcastmaker
import xmpp
from threading import Thread

from archipelcore.archipelPlugin import TNArchipelPlugin
from archipelcore.utils import build_error_iq


ARCHIPEL_NS_HYPERVISOR_VMCASTING        = "archipel:hypervisor:vmcasting"
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

ARCHIPEL_DOWNLOAD_SUCCESS                       = 1
ARCHIPEL_DOWNLOAD_ERROR                         = 2


class TNApplianceDownloader (Thread):
    """
    Implementation of a downloader. This run in a separate thread.
    """

    def __init__(self, url, save_folder, uuid, name, logger, finish_callback):
        """
        Initialization of the class.
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
        self.logger             = logger
        self.error              = False

    def run(self):
        """
        Main loop of the thread. Will start to download.
        """
        try:
            self.logger.info("TNApplianceDownloader: starting to download appliance %s into %s" % (self.url, self.save_path))
            urllib.urlretrieve(self.url, self.save_path, self.downloading_callback)
            if self.error:
                self.finish_callback(ARCHIPEL_DOWNLOAD_ERROR, self.uuid, None)
        except Exception as ex:
            self.logger.error("Unable to download %s at path %s: %s" % (self.url, self.save_path, str(ex)))
            self.finish_callback(ARCHIPEL_DOWNLOAD_ERROR, self.uuid, None)

    def get_progress(self):
        """
        @rtype: float
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
        Stop the download. NOT IMPLEMENTED
        """
        raise NotImplemented

    def downloading_callback(self, blocks_count, block_size, total_size):
        """
        Internal callback of the download status called by urlretrieve.
        If percentage reach 100, it will call the finish_callback with uuid as parameter.
        @type blocks_count: integer
        @param blocks_count: the downloaded number of blocks
        @type block_size: integer
        @param block_size: the size of one block
        @param total_size: the total size in bytes of the file downloaded
        """
        if total_size <= 0:
            self.error = True # avoid calling several time the callback if error
            return;
        self.total_size = total_size
        percentage = (float(blocks_count) * float(block_size)) / float(total_size) * 100
        if percentage >= 100.0:
            self.finish_callback(ARCHIPEL_DOWNLOAD_SUCCESS, self.uuid, self.save_path)
        self.progress = percentage


class TNHypervisorRepoManager (TNArchipelPlugin):
    """
    Implementation of the plugin.
    """

    def __init__(self, configuration, entity, entry_point_group):
        """
        Initialize the class.
        @type configuration: string
        @param configuration: the configuration object
        @type entity: TNArchipelHypervisor
        @param entity: the instance of the TNArchipelHypervisor. Will be used for push.
        @type entry_point_group: string
        @param entry_point_group: the entry point group name
        """
        TNArchipelPlugin.__init__(self, configuration=configuration, entity=entity, entry_point_group=entry_point_group)
        self.database_path          = self.configuration.get("VMCASTING", "vmcasting_database_path")
        self.repository_path        = self.configuration.get("VMCASTING", "repository_path")
        self.download_queue         = {}
        if not os.path.exists(self.repository_path):
            os.makedirs(self.repository_path)
        if not os.path.exists(self.configuration.get("VMCASTING", "own_vmcast_path")):
            os.makedirs(self.configuration.get("VMCASTING", "own_vmcast_path"))
        self.entity.log.info("TNHypervisorRepoManager: opening vmcasting database file %s" % self.database_path)
        self.own_vmcastmaker = vmcastmaker.VMCastMaker(self.configuration.get("VMCASTING", "own_vmcast_name").replace("$HOSTAME", self.entity.resource),
                                                        self.configuration.get("VMCASTING", "own_vmcast_uuid"),
                                                        self.configuration.get("VMCASTING", "own_vmcast_description").replace("$HOSTAME", self.entity.resource),
                                                        self.configuration.get("VMCASTING", "own_vmcast_lang"),
                                                        self.configuration.get("VMCASTING", "own_vmcast_url"),
                                                        self.configuration.get("VMCASTING", "own_vmcast_path"))
        self.parse_own_repo(loop=False)
        self.parse_timer = Thread(target=self.parse_own_repo)
        self.database_connection = sqlite3.connect(self.database_path, check_same_thread = False)
        self.cursor = self.database_connection.cursor()
        self.cursor.execute("create table if not exists vmcastsources (name text, description text, url text not null unique, uuid text unique)")
        self.cursor.execute("create table if not exists vmcastappliances (name text, description text, url text, uuid text unique not null, status int, source text not null, save_path text)")
        self.entity.log.info("TNHypervisorRepoManager: Database ready.")
        # permissions
        self.entity.permission_center.create_permission("vmcasting_get", "Authorizes user to get registered VMCast feeds", False)
        self.entity.permission_center.create_permission("vmcasting_register", "Authorizes user to register to a VMCast feed", False)
        self.entity.permission_center.create_permission("vmcasting_unregister", "Authorizes user to unregister from a VMCast feed", False)
        self.entity.permission_center.create_permission("vmcasting_downloadappliance", "Authorizes user to download an appliance from a feed", False)
        self.entity.permission_center.create_permission("vmcasting_downloadqueue", "Authorizes user to see the download queue", False)
        self.entity.permission_center.create_permission("vmcasting_getappliances", "Authorizes user to get all availables appliances", False)
        self.entity.permission_center.create_permission("vmcasting_deleteappliance", "Authorizes user to delete an installed appliance", False)
        self.entity.permission_center.create_permission("vmcasting_getinstalledappliances", "Authorizes user to get all installed appliances", False)
        # Hook registration
        self.entity.register_hook("HOOK_ARCHIPELENTITY_XMPP_AUTHENTICATED", method=self.repo_parse_hook)


    ### Hook

    def repo_parse_hook(self, origin=None, user_info=None, parameters=None):
        """
        Start the parser on connection
        @type origin: L{TNArchipelEntity}
        @param origin: the origin of the hook
        @type user_info: object
        @param user_info: random user info
        @type parameters: object
        @param parameters: runtime arguments
        """
        self.parse_timer.start()


    ### Plugin interface

    def register_handlers(self):
        """
        This method will be called by the plugin user when it will be
        necessary to register module for listening to stanza.
        """
        self.entity.xmppclient.RegisterHandler('iq', self.process_iq, ns=ARCHIPEL_NS_HYPERVISOR_VMCASTING)

    def unregister_handlers(self):
        """
        Unregister the handlers.
        """
        self.entity.xmppclient.UnregisterHandler('iq', self.process_iq, ns=ARCHIPEL_NS_HYPERVISOR_VMCASTING)

    @staticmethod
    def plugin_info():
        """
        Return informations about the plugin.
        @rtype: dict
        @return: dictionary contaning plugin informations
        """
        plugin_friendly_name           = "Hypervisor VMCasts"
        plugin_identifier              = "hypervisor_vmcasts"
        plugin_configuration_section   = "VMCASTING"
        plugin_configuration_tokens    = [   "vmcasting_database_path",
                                            "repository_path",
                                            "own_vmcast_path",
                                            "own_vmcast_name",
                                            "own_vmcast_uuid",
                                            "own_vmcast_description",
                                            "own_vmcast_lang",
                                            "own_vmcast_url",
                                            "own_vmcast_path",
                                            "own_vmcast_refresh_interval"]
        return {    "common-name"               : plugin_friendly_name,
                    "identifier"                : plugin_identifier,
                    "configuration-section"     : plugin_configuration_section,
                    "configuration-tokens"      : plugin_configuration_tokens }


    ### RSS Utilities

    def parse_own_repo(self, loop=True):
        """
        Periodically parse the repository to build the RSS.
        @type loop: boolean
        @param loop: if True will do it periodically
        """
        while True:
            self.entity.log.debug("TNHypervisorRepoManager: begin to refresh own vmcast feed")
            self.own_vmcastmaker.parseDirectory(self.configuration.get("VMCASTING", "own_vmcast_path"))
            self.own_vmcastmaker.writeFeed("%s/%s" % (self.configuration.get("VMCASTING", "own_vmcast_path"), self.configuration.get("VMCASTING", "own_vmcast_file_name")))
            self.entity.log.debug("TNHypervisorRepoManager: finish to refresh own vmcast feed")
            if not loop:
                break
            time.sleep(self.configuration.getint("VMCASTING", "own_vmcast_refresh_interval"))

    def on_download_complete(self, code, uuid, path):
        """
        Callback triggered by a TNApplianceDownloader when download is over.
        @type uuid: string
        @param uuid: the uuid of the download
        @type path: string
        @param path: the path of the downloaded file
        """
        if code == ARCHIPEL_DOWNLOAD_SUCCESS:
            self.cursor.execute("UPDATE vmcastappliances SET status=%d, save_path='%s' WHERE uuid='%s'" % (ARCHIPEL_APPLIANCES_INSTALLED, path, uuid))
            self.entity.log.info("appliance %s is sucessfully downloaded")
            self.entity.push_change("vmcasting", "download_complete")
            self.entity.shout("vmcast", "I've finished to download appliance %s" % (uuid))
        else:
            self.cursor.execute("UPDATE vmcastappliances SET status=%d, save_path='' WHERE uuid='%s'" % (ARCHIPEL_APPLIANCES_INSTALLATION_ERROR, uuid))
            self.database_connection.commit()
            self.entity.log.error("appliance %s cannot be downloaded")
            self.entity.push_change("vmcasting", "download_error")
            self.entity.shout("vmcast", "Unable to download the applicance %s" % (uuid))
        self.database_connection.commit()
        del self.download_queue[uuid]
        self.entity.change_status(self.old_entity_status)


    def getFeed(self, data):
        """
        Get the feed.
        @type data: string
        @param data: RSS data
        @rtype: tupple
        @return: tupple that contains info on the feed
        """
        feed_content        = xmpp.simplexml.NodeBuilder(data=str(data)).getDom()
        feed_uuid           = feed_content.getTag("channel").getTag("uuid").getCDATA()
        feed_description    = feed_content.getTag("channel").getTag("description").getCDATA()
        feed_name           = feed_content.getTag("channel").getTag("title").getCDATA()
        items               = feed_content.getTag("channel").getTags("item")
        return (feed_content, feed_uuid, feed_description, feed_name, items)

    def parseRSS(self):
        """
        Parse the content of the database, update the feed, create the answer node.
        """
        sources = self.cursor.execute("SELECT * FROM vmcastsources")
        nodes = []
        tmp_cursor = self.database_connection.cursor()
        content = []
        ## this will avoid to parse two times the content of the cursor if we udpate
        for values in sources:
            content.append(values)

        for values in content:
            name, description, url, uuid = values
            self.entity.log.debug("TNHypervisorRepoManager: parsing feed with url %s" % url)
            source_node = xmpp.Node(tag="source", attrs={"name": name, "description": description, "url": url, "uuid": uuid})
            content_nodes = []
            try:
                f = urllib.urlopen(url)
            except Exception as ex:
                continue
            try:
                feed_content, feed_uuid, feed_description, feed_name, items = self.getFeed(f.read())
            except:
                tmp_cursor.execute("DELETE FROM vmcastsources WHERE url='%s'" % url)
                self.database_connection.commit()
                raise Exception('Bad format', "URL doesn't seem to contain valid VMCasts. Removed.")
            try:
                self.database_connection.execute("UPDATE vmcastsources SET uuid='%s', name='%s', description='%s' WHERE url='%s'" % (feed_uuid, feed_name, feed_description, url))
                self.database_connection.commit()
            except Exception as ex:
                self.entity.log.debug("TNHypervisorRepoManager: unable to update source because: " + str(ex))
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


    ### XMPP handlers

    def process_iq(self, conn, iq):
        """
        Process incoming IQ of type ARCHIPEL_NS_HYPERVISOR_VMCASTING.
        It understands IQ of type:
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
        reply = None
        action = self.entity.check_acp(conn, iq)
        self.entity.check_perm(conn, iq, action, -1, prefix="vmcasting_")
        if action == "get":
            reply = self.iq_get(iq)
        elif action == "register":
            reply = self.iq_register(iq)
        elif action == "unregister":
            reply = self.iq_unregister(iq)
        elif action == "downloadappliance":
            reply = self.iq_download(iq)
        elif action == "downloadqueue":
            reply = self.iq_get_download_queue(iq)
        elif action == "getappliances":
            reply = self.iq_get_appliance(iq)
        elif action == "deleteappliance":
            reply = self.iq_delete_appliance(iq)
        elif action == "getinstalledappliances":
            reply = self.iq_get_installed_appliances(iq)
        if reply:
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed

    def iq_get(self, iq):
        """
        Get the sources and appliances. Replay parseRSS at each time to be up to date.

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

    def iq_register(self, iq):
        """
        Register to a new VMCast.
        @type iq: xmpp.Protocol.Iq
        @param iq: the sender request IQ
        @rtype: xmpp.Protocol.Iq
        @return: a ready-to-send IQ containing the results
        """
        reply = iq.buildReply("result")
        url = iq.getTag("query").getTag("archipel").getAttr("url")
        try:
            if not url or url == "":
                raise Exception("IncorrectStanza", "Stanza must have url: %s" % str(iq))
            try:
                f = urllib.urlopen(url)
            except:
                raise Exception("The given url doesn't exist. Can't register.")
            try:
                self.getFeed(f.read())
            except:
                raise Exception("The given url doesn't contains a valid VMCast feed. Can't register.")
            self.cursor.execute("INSERT INTO vmcastsources (url) VALUES ('%s')" % url)
            self.database_connection.commit()
            self.parseRSS()
            self.entity.push_change("vmcasting", "register")
            self.entity.shout("vmcast", "I'm now registred to vmcast %s as asked by %s" % (url, iq.getFrom()))
        except Exception as ex:
            reply = build_error_iq(self, ex, iq, ARCHIPEL_ERROR_CODE_VMCASTS_REGISTER)
        return reply

    def iq_unregister(self, iq):
        """
        Unregister from a VMCasts and remove all its appliances (not the files).
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
            self.entity.push_change("vmcasting", "unregister")
            self.entity.shout("vmcast", "I'm now unregistred from vmcast %s as asked by %s" % (uuid, iq.getFrom()))
        except Exception as ex:
            reply = build_error_iq(self, ex, iq, ARCHIPEL_ERROR_CODE_VMCASTS_UNREGISTER)
        return reply

    def iq_download(self, iq):
        """
        Start a download of appliance according to its uuid.
        @type iq: xmpp.Protocol.Iq
        @param iq: the sender request IQ
        @rtype: xmpp.Protocol.Iq
        @return: a ready-to-send IQ containing the results
        """
        reply = iq.buildReply("result")
        dl_uuid = iq.getTag("query").getTag("archipel").getAttr("uuid")
        try:
            self.cursor.execute("UPDATE vmcastappliances SET status=%d WHERE uuid='%s'" % (ARCHIPEL_APPLIANCES_INSTALLING, dl_uuid))
            self.database_connection.commit()
            self.cursor.execute("SELECT * FROM vmcastappliances WHERE uuid='%s'" % dl_uuid)
            self.old_entity_status = self.entity.xmppstatus
            self.entity.push_change("vmcasting", "download_start")
            name, description, url, uuid, status, source, path = self.cursor.fetchone()
            downloader = TNApplianceDownloader(url, self.repository_path, uuid, name, self.entity.log, self.on_download_complete)
            self.download_queue[uuid] = downloader
            downloader.daemon  = True
            downloader.start()
            self.entity.change_status("Downloading appliance...")
        except Exception as ex:
            reply = build_error_iq(self, ex, iq, ARCHIPEL_ERROR_CODE_VMCASTS_DOWNLOADAPPLIANCE)
        return reply

    def iq_get_download_queue(self, iq):
        """
        Get the state of the download queue.
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

    def iq_stop_download(self, iq):
        """
        Stop a download according to its uuid.
        @type iq: xmpp.Protocol.Iq
        @param iq: the sender request IQ
        @rtype: xmpp.Protocol.Iq
        @return: a ready-to-send IQ containing the results
        """
        reply = iq.buildReply("result")
        dl_uuid = iq.getTag("query").getTag("archipel").getAttr("uuid")
        self.download_queue[dl_uuid].stop()
        return reply

    def iq_get_appliance(self, iq):
        """
        Get the info about an appliances according to its uuid.
        @type iq: xmpp.Protocol.Iq
        @param iq: the sender request IQ
        @rtype: xmpp.Protocol.Iq
        @return: a ready-to-send IQ containing the results
        """
        reply = iq.buildReply("result")
        uuid = iq.getTag("query").getTag("archipel").getAttr("uuid")
        try:
            self.cursor.execute("SELECT save_path, name, description FROM vmcastappliances WHERE uuid='%s'" % uuid)
            path, name, description = self.cursor.fetchone()
            node = xmpp.Node(tag="appliance", attrs={"path": path, "name": name, "description": description})
            reply.setQueryPayload([node])
        except Exception as ex:
            reply = build_error_iq(self, ex, iq, ARCHIPEL_ERROR_CODE_VMCASTS_GETAPPLIANCES)
        return reply

    def iq_get_installed_appliances(self, iq):
        """
        Get all installed appliances.
        @type iq: xmpp.Protocol.Iq
        @param iq: the sender request IQ
        @rtype: xmpp.Protocol.Iq
        @return: a ready-to-send IQ containing the results
        """
        reply = iq.buildReply("result")
        nodes = []
        try:
            self.cursor.execute("SELECT save_path, name, description FROM vmcastappliances WHERE status=%d" % (ARCHIPEL_APPLIANCES_INSTALLED))
            for values in self.cursor:
                path, name, description = values
                node = xmpp.Node(tag="appliance", attrs={"path": path, "name": name, "description": description})
                nodes.append(node)
            reply.setQueryPayload(nodes)
        except Exception as ex:
            reply = build_error_iq(self, ex, iq, ARCHIPEL_ERROR_CODE_VMCASTS_GETINSTALLED)
        return reply

    def iq_delete_appliance(self, iq):
        """
        Delete an appliance according to its uuid.
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
            self.entity.push_change("vmcasting", "appliancedeleted")
            self.entity.shout("vmcast", "I've just delete appliance %s as asked by %s" % (uuid, iq.getFrom()))
        except Exception as ex:
            reply = build_error_iq(self, ex, iq, ARCHIPEL_ERROR_CODE_VMCASTS_DELETEAPPLIANCE)
        return reply