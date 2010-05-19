# 
# snapshoting.py
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

from utils import *
import commands
import xmpp
import os
import archipel
from libvirt import *

class TNSnapshoting:
    
    def __init__(self, entity):
        self.entity = entity
        pass
        
    
    def process_iq(self, conn, iq):
        iqType = iq.getTag("query").getAttr("type")
        log(self, LOG_LEVEL_DEBUG, "IQ received from %s with type %s : %s" % (iq.getFrom(), iq.getType(), iqType))
        
        if not self.entity.domain:
            return
        
        if iqType == "take":
            reply = self.__take_snapshot(iq)
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed
            
        if iqType == "delete":
            reply = self.__delete(iq)
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed
            
        if iqType == "get":
            reply = self.__get(iq)
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed
            
        if iqType == "current":
            reply = self.__getcurrent(iq)
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed
        
        if iqType == "revert":
            reply = self.__revert(iq)
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed

    def __take_snapshot(self, iq):
        """
        creating a snapshot

        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ

        @rtype: xmpp.Protocol.Iq
        @return: a ready to send IQ containing the result of the action
        """
        try:
            reply = iq.buildReply('success')
            xmlDesc = iq.getTag('query').getTag('domainsnapshot')
            name = xmlDesc.getTag('name').getData();
            old_status  = self.entity.xmppstatus
            old_show    = self.entity.xmppstatusshow
                        
            log(self, LOG_LEVEL_INFO, "creating snapshot with name %s desc :%s" % (name, xmlDesc))
            
            self.entity.change_presence(presence_show="dnd", presence_status="Snapshoting...")
            self.entity.domain.snapshotCreateXML(str(xmlDesc), 0)
            self.entity.change_presence(presence_show=old_show, presence_status=old_status)
            
            log(self, LOG_LEVEL_INFO, "snapshot with name %s created" % name);
            self.entity.push_change("snapshoting", "taken")
            self.entity.shout("Snapshot", "I've created a snapshot named %s as asked by %s" % (name, iq.getFrom()))
        except Exception as ex:
            self.entity.change_presence(presence_show=old_show, presence_status="Error while snapshoting")
            reply = build_error_iq(self, ex, iq)
        return reply

            
    def __get(self, iq):
        """
        list all a snapshot
        
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ
        
        @rtype: xmpp.Protocol.Iq
        @return: a ready to send IQ containing the result of the action
        """
        try:
            reply = iq.buildReply('success')
            nodes = []
            snapshot_names = self.entity.domain.snapshotListNames(0)
            for snapshot_name in snapshot_names:
                snapshotObject = self.entity.domain.snapshotLookupByName(snapshot_name, 0)
                desc = snapshotObject.getXMLDesc(0)
                n = xmpp.simplexml.NodeBuilder(data=desc).getDom()
                nodes.append(n)
            reply.setQueryPayload(nodes)
        except Exception as ex:
            reply = build_error_iq(self, ex, iq)
        return reply
    
    def __getcurrent(self, iq):
        """
        return current snapshot

        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ

        @rtype: xmpp.Protocol.Iq
        @return: a ready to send IQ containing the result of the action
        """
        try:
            reply = iq.buildReply('success')
            snapshotObject = self.entity.domain.snapshotCurrent(0)
            desc = snapshotObject.getXMLDesc(0)
            n = xmpp.simplexml.NodeBuilder(data=desc).getDom()
            reply.setQueryPayload([n])
        except libvirtError as ex:
            if ex.get_error_code() == VIR_ERR_NO_DOMAIN_SNAPSHOT:
                reply = iq.buildReply('ignore')
            else:
                reply = build_error_iq(self, ex, iq)                
        except Exception as ex:
            reply = build_error_iq(self, ex, iq)
        finally:
            return reply
    
    def __delete(self, iq):
        """
        return current snapshot

        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ

        @rtype: xmpp.Protocol.Iq
        @return: a ready to send IQ containing the result of the action
        """
        try:
            reply = iq.buildReply('success')
            # xmlDesc = iq.getTag('query').getTag('uuid') would be better but not in API at this time.
            name = iq.getTag('query').getAttr('name')
        
            old_status  = self.entity.xmppstatus
            old_show    = self.entity.xmppstatusshow

            log(self, LOG_LEVEL_INFO, "deleting snapshot with name %s" % name)

            self.entity.change_presence(presence_show="dnd", presence_status="Removing snapshot...")
            snapshotObject = self.entity.domain.snapshotLookupByName(name, 0)
            snapshotObject.delete(VIR_DOMAIN_SNAPSHOT_DELETE_CHILDREN);
            self.entity.change_presence(presence_show=old_show, presence_status=old_status)

            log(self, LOG_LEVEL_INFO, "snapshot with name %s deleted" % name);
            self.entity.push_change("snapshoting", "deleted")
            self.entity.shout("Snapshot", "I've deleted the snapshot named %s as asked by %s" % (name, iq.getFrom()))
        except Exception as ex:
            self.entity.change_presence(presence_show=old_show, presence_status="Error while deleting snapshot")
            reply = build_error_iq(self, ex, iq)
        return reply
        
        
    def __revert(self, iq):
        """
        return current snapshot

        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ

        @rtype: xmpp.Protocol.Iq
        @return: a ready to send IQ containing the result of the action
        """
        try:
            reply = iq.buildReply('success')
            # xmlDesc = iq.getTag('query').getTag('uuid') would be better but not in API at this time.
            name = iq.getTag('query').getAttr('name')

            old_status  = self.entity.xmppstatus
            old_show    = self.entity.xmppstatusshow

            log(self, LOG_LEVEL_INFO, "restoring snapshot with name %s" % name)

            self.entity.change_presence(presence_show="dnd", presence_status="Restoring snapshot...")
            snapshotObject = self.entity.domain.snapshotLookupByName(name, 0)
            snapshotObject.revertToSnapshot(0);
            self.entity.change_presence(presence_show=old_show, presence_status=old_status)

            log(self, LOG_LEVEL_INFO, "reverted to snapshot with name %s " % name);
            self.entity.push_change("snapshoting", "restored")
            self.entity.shout("Snapshot", "I've been reverted to the snapshot named %s as asked by %s" % (name, iq.getFrom()))
        except Exception as ex:
            self.entity.change_presence(presence_show=old_show, presence_status="Error while reverting")
            reply = build_error_iq(self, ex, iq)
        return reply
    
    
    