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

ARCHIPEL_ERROR_CODE_SNAPSHOT_TAKE       = -2001
ARCHIPEL_ERROR_CODE_SNAPSHOT_GET        = -2002
ARCHIPEL_ERROR_CODE_SNAPSHOT_CURRENT    = -2003
ARCHIPEL_ERROR_CODE_SNAPSHOT_DELETE     = -2004
ARCHIPEL_ERROR_CODE_SNAPSHOT_REVERT     = -2005
ARCHIPEL_ERROR_CODE_SNAPSHOT_NO_DRIVE   = -2006


class TNSnapshoting:
    
    def __init__(self, entity):
        self.entity = entity
        pass
    
    
    def process_iq(self, conn, iq):
        """
        this method is invoked when a ARCHIPEL_NS_SNAPSHOTING IQ is received.
        
        it understands IQ of type:
            - take
            - delete
            - get
            - current
            - revert
        
        @type conn: xmpp.Dispatcher
        @param conn: ths instance of the current connection that send the stanza
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ
        """
        try:
            action = iq.getTag("query").getTag("archipel").getAttr("action")
            log.info("IQ RECEIVED: from: %s, type: %s, namespace: %s, action: %s" % (iq.getFrom(), iq.getType(), iq.getQueryNS(), action))
        except Exception as ex:
            reply = build_error_iq(self, ex, iq, ARCHIPEL_NS_ERROR_QUERY_NOT_WELL_FORMED)
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed
        
        if not self.entity.domain:
            raise xmpp.protocol.NodeProcessed
        
        elif action == "take":
            reply = self.take_snapshot(iq)
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed
            
        elif action == "delete":
            reply = self.delete(iq)
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed
            
        elif action == "get":
            reply = self.get(iq)
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed
            
        elif action == "current":
            reply = self.getcurrent(iq)
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed
        
        elif action == "revert":
            reply = self.revert(iq)
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed
    
    
    def take_snapshot(self, iq):
        """
        creating a snapshot
        
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ
        
        @rtype: xmpp.Protocol.Iq
        @return: a ready to send IQ containing the result of the action
        """
        reply = iq.buildReply("result")
        try:
            xmlDesc     = iq.getTag('query').getTag("archipel").getTag('domainsnapshot')
            name        = xmlDesc.getTag('name').getData();
            old_status  = self.entity.xmppstatus
            old_show    = self.entity.xmppstatusshow
            
            try:
                devices_node = self.entity.definition.getTag('devices')
                disk_nodes = devices_node.getTags('disk', attrs={'type': 'file'})
                if not disk_nodes:
                    raise
            except:
                return build_error_iq(self, Exception("Virtual machine hasn't any drive to snapshot"), iq, code=ARCHIPEL_ERROR_CODE_SNAPSHOT_NO_DRIVE)
                
            log.info("creating snapshot with name %s desc :%s" % (name, xmlDesc))
            
            self.entity.change_presence(presence_show="dnd", presence_status="Snapshoting...")
            self.entity.domain.snapshotCreateXML(str(xmlDesc), 0)
            self.entity.change_presence(presence_show=old_show, presence_status=old_status)
            
            log.info("snapshot with name %s created" % name);
            self.entity.push_change("snapshoting", "taken", excludedgroups=['vitualmachines'])
            self.entity.shout("Snapshot", "I've created a snapshot named %s as asked by %s" % (name, iq.getFrom()), excludedgroups=['vitualmachines'])
        except libvirtError as ex:
            self.entity.change_presence(presence_show=old_show, presence_status="Error while snapshoting")
            reply = build_error_iq(self, ex, iq, ex.get_error_code(), ns=ARCHIPEL_NS_LIBVIRT_GENERIC_ERROR)
            try:
                snapshotObject = self.entity.domain.snapshotLookupByName(name, 0)
                snapshotObject.delete(VIR_DOMAIN_SNAPSHOT_DELETE_CHILDREN);
            except:
                pass
        except Exception as ex:
            self.entity.change_presence(presence_show=old_show, presence_status="Error while snapshoting")
            reply = build_error_iq(self, ex, iq, ARCHIPEL_ERROR_CODE_SNAPSHOT_TAKE)
            try:
                snapshotObject = self.entity.domain.snapshotLookupByName(name, 0)
                snapshotObject.delete(VIR_DOMAIN_SNAPSHOT_DELETE_CHILDREN);
            except:
                pass
            
        return reply
    
    
    def get(self, iq):
        """
        list all a snapshot
        
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ
        
        @rtype: xmpp.Protocol.Iq
        @return: a ready to send IQ containing the result of the action
        """
        try:
            reply = iq.buildReply("result")
            nodes = []
            if self.entity.domain.hasCurrentSnapshot(0):
                snapshot_names = self.entity.domain.snapshotListNames(0)
                for snapshot_name in snapshot_names:
                    snapshotObject = self.entity.domain.snapshotLookupByName(snapshot_name, 0)
                    desc = snapshotObject.getXMLDesc(0)
                    n = xmpp.simplexml.NodeBuilder(data=desc).getDom()
                    nodes.append(n)
            reply.setQueryPayload(nodes)
        except libvirtError as ex:
            reply = build_error_iq(self, ex, iq, ex.get_error_code(), ns=ARCHIPEL_NS_LIBVIRT_GENERIC_ERROR)
        except Exception as ex:
            reply = build_error_iq(self, ex, iq, ARCHIPEL_ERROR_CODE_SNAPSHOT_GET)
        return reply
    
    
    def getcurrent(self, iq):
        """
        return current snapshot
        
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ
        
        @rtype: xmpp.Protocol.Iq
        @return: a ready to send IQ containing the result of the action
        """
        try:
            reply = iq.buildReply("result")
            if self.entity.domain.hasCurrentSnapshot(0):
                snapshotObject = self.entity.domain.snapshotCurrent(0)
                desc = snapshotObject.getXMLDesc(0)
                n = xmpp.simplexml.NodeBuilder(data=desc).getDom()
                reply.setQueryPayload([n])
        except libvirtError as ex:
            if ex.get_error_code() == VIR_ERR_NO_DOMAIN_SNAPSHOT:
                reply = iq.buildReply("result")
            else:
                reply = build_error_iq(self, ex, iq, ex.get_error_code(), ns=ARCHIPEL_NS_LIBVIRT_GENERIC_ERROR)
        except Exception as ex:
            reply = build_error_iq(self, ex, iq, ARCHIPEL_ERROR_CODE_SNAPSHOT_CURRENT)
        return reply
    
    
    def delete(self, iq):
        """
        return current snapshot
        
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ
        
        @rtype: xmpp.Protocol.Iq
        @return: a ready to send IQ containing the result of the action
        """
        try:
            reply = iq.buildReply("result")
            # xmlDesc = iq.getTag('query').getTag('uuid') would be better but not in API at this time.
            name = iq.getTag('query').getTag("archipel").getAttr('name')
            
            old_status  = self.entity.xmppstatus
            old_show    = self.entity.xmppstatusshow
            
            log.info("deleting snapshot with name %s" % name)
            
            self.entity.change_presence(presence_show="dnd", presence_status="Removing snapshot...")
            snapshotObject = self.entity.domain.snapshotLookupByName(name, 0)
            snapshotObject.delete(VIR_DOMAIN_SNAPSHOT_DELETE_CHILDREN);
            self.entity.change_presence(presence_show=old_show, presence_status=old_status)
            
            log.info("snapshot with name %s deleted" % name);
            self.entity.push_change("snapshoting", "deleted", excludedgroups=['vitualmachines'])
            self.entity.shout("Snapshot", "I've deleted the snapshot named %s as asked by %s" % (name, iq.getFrom()), excludedgroups=['vitualmachines'])
        except libvirtError as ex:
            self.entity.change_presence(presence_show=old_show, presence_status="Error while deleting snapshot")
            reply = build_error_iq(self, ex, iq, ex.get_error_code(), ns=ARCHIPEL_NS_LIBVIRT_GENERIC_ERROR)
        except Exception as ex:
            self.entity.change_presence(presence_show=old_show, presence_status="Error while deleting snapshot")
            reply = build_error_iq(self, ex, iq, ARCHIPEL_ERROR_CODE_SNAPSHOT_DELETE)
        return reply
    
    
    def revert(self, iq):
        """
        return current snapshot
        
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ
        
        @rtype: xmpp.Protocol.Iq
        @return: a ready to send IQ containing the result of the action
        """
        try:
            reply = iq.buildReply("result")
            # xmlDesc = iq.getTag('query').getTag('uuid') would be better but not in API at this time.
            name = iq.getTag('query').getTag("archipel").getAttr('name')
            
            old_status  = self.entity.xmppstatus
            old_show    = self.entity.xmppstatusshow
            
            log.info("restoring snapshot with name %s" % name)
            
            self.entity.change_presence(presence_show="dnd", presence_status="Restoring snapshot...")
            snapshotObject = self.entity.domain.snapshotLookupByName(name, 0)
            self.entity.domain.revertToSnapshot(snapshotObject, 0);
            
            log.info("reverted to snapshot with name %s " % name);
            self.entity.push_change("snapshoting", "restored", excludedgroups=['vitualmachines'])
            self.entity.shout("Snapshot", "I've been reverted to the snapshot named %s as asked by %s" % (name, iq.getFrom()), excludedgroups=['vitualmachines'])
        except libvirtError as ex:
            self.entity.change_presence(presence_show=old_show, presence_status="Error while reverting")
            reply = build_error_iq(self, ex, iq, ex.get_error_code(), ns=ARCHIPEL_NS_LIBVIRT_GENERIC_ERROR)
        except Exception as ex:
            self.entity.change_presence(presence_show=old_show, presence_status="Error while reverting")
            reply = build_error_iq(self, ex, iq, ARCHIPEL_ERROR_CODE_SNAPSHOT_REVERT)
        return reply
    
