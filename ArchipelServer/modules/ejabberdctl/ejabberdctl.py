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
import uuid
import os, commands
import re
from utils import *
import archipel



class TNEjabberdctl:
    
    def __init__(self, entity, exec_path):
        """
        initialize the module
        @type entity TNArchipelEntity
        @param entity the module entity
        @type entity String
        @param entity the path of the ejabberdctl command
        """
        self.entity             = entity
        self.ejabberdctl_path   = exec_path
        
        # permissions
        self.entity.permission_center.create_permission("ejabberdctl_rosters", "Authorizes user to manage shared roster", False);
        self.entity.permission_center.create_permission("ejabberdctl_users", "Authorizes user to manage XMPP users", False);
    
    
    
    ### XMPP Processing for shared groups
    
    def process_rosters_iq(self, conn, iq):
        """
        this method is invoked when a ARCHIPEL_NS_EJABBERDCTL_ROSTERS IQ is received.
        
        it understands IQ of type:
            - create
            - delete
            - list
            - addusers
            - deleteusers
        
        @type conn: xmpp.Dispatcher
        @param conn: ths instance of the current connection that send the stanza
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ
        """
        action = self.entity.check_acp(conn, iq)
        self.entity.check_perm(conn, iq, action, -1)
        reply = None
        
        if      action == "create":         reply = self.iq_group_create(iq)
        elif    action == "delete":         reply = self.iq_group_delete(iq)
        elif    action == "list":           reply = self.iq_group_list(iq)
        elif    action == "addusers":       reply = self.iq_group_add_users(iq)
        elif    action == "deleteusers":    reply = self.iq_group_delete_users(iq)
        
        if (reply):
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed
    
    
    def iq_group_create(self, iq):
        """
        create a new shared roster
        
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ
        
        @rtype: xmpp.Protocol.Iq
        @return: a ready to send IQ containing the result of the action
        """
        try:
            reply       = iq.buildReply("result")
            groupID     = iq.getTag("query").getTag("archipel").getAttr("id")
            groupName   = iq.getTag("query").getTag("archipel").getAttr("name")
            groupDesc   = iq.getTag("query").getTag("archipel").getAttr("description")
            server      = self.entity.jid.getDomain()
            cmd         = "%s srg-create %s %s \"'%s'\" \"'%s'\" %s" % (self.ejabberdctl_path, groupID, server, groupName, groupDesc, groupID)
            
            log.debug("console command is : %s" % cmd)
            if os.system(cmd):
                raise Exception("EJABBERDCTL command error : %s" % cmd)
            
            log.info("creating a new shared group %s" % groupID)
            
            self.entity.push_change("ejabberdctl:rosters", "create")
        except Exception as ex:
            reply = build_error_iq(self, ex, iq)
        return reply
    
    
    def iq_group_delete(self, iq):
        """
        delete a shared group
        
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ
        
        @rtype: xmpp.Protocol.Iq
        @return: a ready to send IQ containing the result of the action
        """
        try:
            reply       = iq.buildReply("result")
            groupID     = iq.getTag("query").getTag("archipel").getAttr("id")
            server      = self.entity.jid.getDomain()
            cmd         = "%s srg-delete %s %s" % (self.ejabberdctl_path, groupID, server)
            
            log.debug("console command is : %s" % cmd)
            if os.system(cmd):
                raise Exception("EJABBERDCTL command error : %s" % cmd)
            
            log.info("removing a shared group %s" % groupID)
            
            self.entity.push_change("ejabberdctl:rosters", "remove")
        except Exception as ex:
            reply = build_error_iq(self, ex, iq)
        return reply
    
    
    def iq_group_list(self, iq):
        """
        list shared groups
        
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ
        
        @rtype: xmpp.Protocol.Iq
        @return: a ready to send IQ containing the result of the action
        """
        try:
            reply       = iq.buildReply("result")
            server      = self.entity.jid.getDomain()
            cmd         = "%s srg-list %s" % (self.ejabberdctl_path, server)
            groupsNode  = []
            
            log.debug("console command is : %s" % cmd)
            status, output = commands.getstatusoutput(cmd)
            
            if status:
                raise Exception("EJABBERDCTL command error : %s" % cmd)
            groups = output.split()
            
            for group in groups:
                cmd = "%s srg-get-info %s %s" % (self.ejabberdctl_path, group, server)
                status, output = commands.getstatusoutput(cmd)
                gid, displayed_name, description = output.split("\n")
                gid = re.findall('"([^"]*)"', gid)[0]
                displayed_name = re.findall('"([^"]*)"', displayed_name)[0]
                description = re.findall('"([^"]*)"', description)[0]
                info = {"id": gid, "displayed_name": displayed_name, "description": description}
                newNode = xmpp.Node("group", attrs=info)
                
                cmd = "%s srg-get-members %s %s" % (self.ejabberdctl_path, group, server)
                status, output = commands.getstatusoutput(cmd)
                for jid in output.split():
                    newNode.addChild("user", attrs={"jid": jid})
                groupsNode.append(newNode)
            
            reply.setQueryPayload(groupsNode);
            
        except Exception as ex:
            reply = build_error_iq(self, ex, iq)
        return reply
    
    
    def iq_group_add_users(self, iq):
        """
        add a user into a shared group
        
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ
        
        @rtype: xmpp.Protocol.Iq
        @return: a ready to send IQ containing the result of the action
        """
        try:
            reply       = iq.buildReply("result")
            groupID     = iq.getTag("query").getTag("archipel").getAttr("groupid")
            users       = iq.getTag("query").getTag("archipel").getTags("user")
            server      = self.entity.jid.getDomain()
            
            for user in users:
                userJID = xmpp.JID(user.getAttr("jid"))
                cmd = "%s srg-user-add %s %s %s %s" % (self.ejabberdctl_path, userJID.getNode(), userJID.getDomain(), groupID, server)
                commands.getstatusoutput(cmd);
            
            log.info("adding user %s into shared group %s" % (userJID, groupID))
            
            self.entity.push_change("ejabberdctl:rosters", "usersadded")
        except Exception as ex:
            reply = build_error_iq(self, ex, iq)
        return reply
    
    
    def iq_group_delete_users(self, iq):
        """
        delete a user from a shared group
        
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ
        
        @rtype: xmpp.Protocol.Iq
        @return: a ready to send IQ containing the result of the action
        """
        try:
            reply       = iq.buildReply("result")
            groupID     = iq.getTag("query").getTag("archipel").getAttr("groupid")
            users       = iq.getTag("query").getTag("archipel").getTags("user")
            server      = self.entity.jid.getDomain()
            
            for user in users:
                userJID = xmpp.JID(user.getAttr("jid"))
                cmd = "%s srg-user-del %s %s %s %s" % (self.ejabberdctl_path, userJID.getNode(), userJID.getDomain(), groupID, server)
                commands.getstatusoutput(cmd);
                log.info("removing user %s from shared group %s" % (userJID, groupID))
            
            self.entity.push_change("ejabberdctl:rosters", "usersremoved")
        except Exception as ex:
            reply = build_error_iq(self, ex, iq)
        return reply
    
    
    
    ### XMPP Processing for users
    
    def process_users_iq(self, conn, iq):
        """
        this method is invoked when a ARCHIPEL_NS_EJABBERDCTL_USERS IQ is received.
        
        it understands IQ of type:
            - register
            - unregister
            - list
        
        @type conn: xmpp.Dispatcher
        @param conn: ths instance of the current connection that send the stanza
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ
        """
        action = self.entity.check_acp(conn, iq)
        self.entity.check_perm(conn, iq, action, -1)
        reply = None
        
        if      action == "register":   reply = self.iq_users_register(iq)
        elif    action == "unregister": reply = self.iq_users_unregister(iq)
        elif    action == "list":       reply = self.iq_users_list(iq)
        
        if (reply):
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed
    
    
    def iq_users_register(self, iq):
        """
        register some new users
        
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ
        
        @rtype: xmpp.Protocol.Iq
        @return: a ready to send IQ containing the result of the action
        """
        try:
            reply       = iq.buildReply("result")
            users       = iq.getTag("query").getTag("archipel").getTags("user")
            server      = self.entity.jid.getDomain()
            
            for user in users:
                username    = user.getAttr("username")
                password    = user.getAttr("password")
                cmd         = "%s register %s %s %s" % (self.ejabberdctl_path, username, server, password)
                if os.system(cmd):
                    raise Exception("EJABBERDCTL command error : %s" % cmd)
                log.info("registred a new user user %s@%s" % (username, server))
            
            self.entity.push_change("ejabberdctl:users", "registered")
        except Exception as ex:
            reply = build_error_iq(self, ex, iq)
        return reply
    
    
    def iq_users_unregister(self, iq):
        """
        unregister somes users
        
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ
        
        @rtype: xmpp.Protocol.Iq
        @return: a ready to send IQ containing the result of the action
        """
        try:
            reply       = iq.buildReply("result")
            users        = iq.getTag("query").getTag("archipel").getTags("user")
            server      = self.entity.jid.getDomain()
            
            for user in users:
                username    = user.getAttr("username")
                cmd         = "%s unregister %s %s" % (self.ejabberdctl_path, username, server)
                if os.system(cmd):
                    raise Exception("EJABBERDCTL command error : %s" % cmd)
                log.info("unregistred user %s@%s" % (username, server))
            self.entity.push_change("ejabberdctl:users", "unregistered")
        except Exception as ex:
            reply = build_error_iq(self, ex, iq)
        return reply
    
    
    def iq_users_list(self, iq):
        """
        list all registered users
        
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ
        
        @rtype: xmpp.Protocol.Iq
        @return: a ready to send IQ containing the result of the action
        """
        try:
            reply       = iq.buildReply("result")
            server      = self.entity.jid.getDomain()
            cmd         = "%s registered_users %s" % (self.ejabberdctl_path, server)
            nodes       = []
            
            status, output = commands.getstatusoutput(cmd);
            if status:
                raise Exception("EJABBERDCTL command error : %s" % cmd)
            
            users = output.split()
            for user in users:
                nodes.append(xmpp.Node("user", attrs={"jid": "%s@%s" % (user, server)}))
            reply.setQueryPayload(nodes);
        except Exception as ex:
            reply = build_error_iq(self, ex, iq)
        return reply
    
    