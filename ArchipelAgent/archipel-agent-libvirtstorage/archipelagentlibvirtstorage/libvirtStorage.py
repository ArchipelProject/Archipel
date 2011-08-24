# -*- coding: utf-8 -*-
#
# storage.py
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
import subprocess
import xmpp
import libvirt

from archipelcore.archipelPlugin import TNArchipelPlugin
from archipel.archipelVirtualMachine import ARCHIPEL_ERROR_CODE_VM_MIGRATING
from archipelcore.utils import build_error_iq


ARCHIPEL_NS_STORAGE                         = "archipel:storage"
ARCHIPEL_ERROR_CODE_STORAGE_POOL_LIST       = -11001
ARCHIPEL_ERROR_CODE_STORAGE_POOL_CREATE     = -11002
ARCHIPEL_ERROR_CODE_STORAGE_POOL_DESTROY    = -11003
ARCHIPEL_ERROR_CODE_STORAGE_POOL_INFO       = -11004
ARCHIPEL_ERROR_CODE_STORAGE_POOL_DELETE     = -11005


class TNLibvirtStorageManagement (TNArchipelPlugin):
    """
    Plugin that manages the libvirt storage API
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


    ### Plugin interface

    def register_handlers(self):
        """
        This method will be called by the plugin user when it will be
        necessary to register module for listening to stanza.
        """
        self.entity.xmppclient.RegisterHandler('iq', self.process_iq, ns=ARCHIPEL_NS_STORAGE)

    def unregister_handlers(self):
        """
        Unregister the handlers.
        """
        self.entity.xmppclient.UnregisterHandler('iq', self.process_iq, ns=ARCHIPEL_NS_STORAGE)

    @staticmethod
    def plugin_info():
        """
        Return informations about the plugin.
        @rtype: dict
        @return: dictionary contaning plugin informations
        """
        plugin_friendly_name           = "Libvirt Storage"
        plugin_identifier              = "libvirtstorage"
        plugin_configuration_section   = None
        plugin_configuration_tokens    = []

        return {    "common-name"               : plugin_friendly_name,
                    "identifier"                : plugin_identifier,
                    "configuration-section"     : plugin_configuration_section,
                    "configuration-tokens"      : plugin_configuration_tokens }


    ### Libvirt

    def pool_list(self):
        """
        return a list of names of existing pools
        @rtype: array
        @return: array of all pool names
        """
        return self.entity.libvirt_connection.listDefinedStoragePools()

    def pool_get(self, identifier):
        """
        return information about a given pool
        @type identifier: string
        @param identifier: UUID or Name
        @rtype: virStoragePool
        @return: the current storage pool
        """
        try:
            pool = self.entity.libvirt_connection.storagePoolLookupByName(identifier)
        except libvirt.libvirtError:
            try:
                pool = self.entity.libvirt_connection.storagePoolLookupByUUID(identifier)
            except libvirt.libvirtError:
                raise Exception("Pool with identifier %s not found" % identifier)
        return pool

    def pool_info(self, identifier):
        """
        Return the given pool info
        @type identifier: string
        @param identifier: UUID or name
        @rtype: dict
        @return: dict containing state, capacity, allocation and availability
        """
        pool = self.pool_get(identifier)
        state, capacity, allocation, available = pool.info()
        return {"state": state, "capacity": capacity, "allocation": allocation, "available": available}

    def pool_list_volumes(self, identifier):
        """
        Return all the volumes in a given pool
        @type identifier: string
        @param identifier: UUID or name
        @rtype: array
        @return: array of all volume names
        """
        pool = self.pool_get(identifier)
        return pool.listVolumes()

    def pool_create(self, identifier):
        """
        Create (start) the given pool
        @type identifier: string
        @param identifier: UUID or name
        @rtype: int
        @return: result of libvirt function
        """
        pool = self.pool_get(identifier)
        return pool.create(0)

    def pool_destroy(self, identifier):
        """
        Destroy (stop) the given pool
        @type identifier: string
        @param identifier: UUID or name
        @rtype: int
        @return: result of libvirt function
        """
        pool = self.pool_get(identifier)
        return pool.destroy()

    def pool_xmldesc(self, identifier):
        """
        Return the XML description of the given pool
        @type identifier: string
        @param identifier: UUID or name
        @rtype: xmpp.Node
        @return: the pool's description
        """
        pool = self.pool_get(identifier)
        return xmpp.simplexml.NodeBuilder(data=str(pool.XMLDesc(0))).getDom()

    ### XMPP Processing

    def process_iq(self, conn, iq):
        """
        Invoked when new ARCHIPEL_NS_STORAGE IQ is received.
        It understands IQ of type:
            - pooldefine
            - pooldescription
            - poolcreate
            - pooldestroy
            - pooldelete
            - poollist
            - poolinfo
        @type conn: xmpp.Dispatcher
        @param conn: ths instance of the current connection that send the message
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ
        """
        reply = None
        action = self.entity.check_acp(conn, iq)
        # self.entity.check_perm(conn, iq, action, -1, prefix="storage_")
        if action == "poollist":
            reply = self.iq_poollist(iq)
        elif action == "poolinfo":
            reply = self.iq_poolinfo(iq)
        elif action == "poolcreate":
            reply = self.iq_poolcreate(iq)
        elif action == "pooldestroy":
            reply = self.iq_pooldestroy(iq)
        elif action == "pooldescription":
            reply = self.iq_pooldescription(iq)

        if reply:
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed

    def iq_poollist(self, iq):
        """
        List all available pools
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ
        @rtype: xmpp.Protocol.Iq
        @return: a ready to send IQ containing the result of the action
        """
        try:
            reply = iq.buildReply("result")
            poolNodes = [];
            for poolName in self.pool_list():
                poolNode = xmpp.Node("pool")
                poolNode.setData(poolName)
                poolNodes.append(poolNode)
            reply.setQueryPayload(poolNodes)
        except Exception as ex:
            reply = build_error_iq(self, ex, iq, ARCHIPEL_ERROR_CODE_STORAGE_POOL_LIST)
        return reply

    def iq_poolinfo(self, iq):
        """
        get info of a given pool
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ
        @rtype: xmpp.Protocol.Iq
        @return: a ready to send IQ containing the result of the action
        """
        try:
            reply = iq.buildReply("result")
            identifier = iq.getTag("query").getTag("archipel").getAttr("identifier")
            pool = self.pool_get(identifier)
            poolInfo = self.pool_info(identifier)
            infoNode = xmpp.Node("info", attrs=poolInfo)
            volumeNodes = xmpp.Node("volumes")
            for volumeName in self.pool_list_volumes(identifier):
                volumeNodes.addChild("volume", attrs={"name": volumeName})
            reply.setQueryPayload([infoNode, volumeNodes])
        except Exception as ex:
            reply = build_error_iq(self, ex, iq, ARCHIPEL_ERROR_CODE_STORAGE_POOL_INFO)
        return reply

    def iq_poolcreate(self, iq):
        """
        Create a new storage pool
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ
        @rtype: xmpp.Protocol.Iq
        @return: a ready to send IQ containing the result of the action
        """
        try:
            reply = iq.buildReply("result")
            identifier = iq.getTag("query").getTag("archipel").getAttr("identifier")
            self.pool_create(identifier)
        except Exception as ex:
            reply = build_error_iq(self, ex, iq, ARCHIPEL_ERROR_CODE_STORAGE_POOL_CREATE)
        return reply

    def iq_pooldestroy(self, iq):
        """
        Destroy an existing storage pool
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ
        @rtype: xmpp.Protocol.Iq
        @return: a ready to send IQ containing the result of the action
        """
        try:
            reply = iq.buildReply("result")
            identifier = iq.getTag("query").getTag("archipel").getAttr("identifier")
            self.pool_destroy(identifier)
        except Exception as ex:
            reply = build_error_iq(self, ex, iq, ARCHIPEL_ERROR_CODE_STORAGE_POOL_DESTROY)
        return reply

    def iq_pooldescription(self, iq):
        """
        Return the XML description of a pool
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ
        @rtype: xmpp.Protocol.Iq
        @return: a ready to send IQ containing the result of the action
        """
        try:
            reply = iq.buildReply("result")
            identifier = iq.getTag("query").getTag("archipel").getAttr("identifier")
            description = self.pool_xmldesc(identifier)
            reply.setQueryPayload([description])
        except Exception as ex:
            reply = build_error_iq(self, ex, iq, ARCHIPEL_ERROR_CODE_STORAGE_POOL_DESTROY)
        return reply
