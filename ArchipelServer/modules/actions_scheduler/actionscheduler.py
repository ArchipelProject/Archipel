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
import uuid
import sqlite3
from apscheduler.scheduler import Scheduler

ARCHIPEL_SCHED_HYPERVISOR_UID = "schedule-hypervisor-uid"

class TNActionScheduler:
    
    def __init__(self, entity, db_file):
        self.entity = entity
        self.scheduler = Scheduler()
        self.scheduler.start()
        
        self.database = sqlite3.connect(db_file, check_same_thread=False);
        self.database.execute("create table if not exists scheduler (entity_uuid text, job_uuid text, action text, year text, month text, day text, hour text, minute text, second text, comment text, params text)")
        self.database.commit()
        self.cursor = self.database.cursor()
        self.restore_jobs()
        self.supported_actions_for_vm = ("create", "shutdown", "destroy", "suspend", "resume", "reboot", "migrate", "pause")
        self.supported_actions_for_hypervisor = ("alloc", "free")
    
    
    def save_jobs(self, uid, action, year, month, day, hour, minute, second, comment, params=None):
        entityClass = self.entity.__class__.__name__
        if entityClass == "TNArchipelVirtualMachine":
            entity_uid = self.entity.uuid
        elif entityClass == "TNArchipelHypervisor":
            entity_uid = ARCHIPEL_SCHED_HYPERVISOR_UID
        self.cursor.execute("INSERT INTO scheduler VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", (entity_uid, uid, action, year, month, day, hour, minute, second, comment, params,))
        self.database.commit()
    
    
    
    ######################################################################################################
    ### Persistance
    ###################################################################################################### 
    
    def delete_job(self, uid):
        self.cursor.execute("DELETE FROM scheduler WHERE job_uuid=?", (uid,))
        self.database.commit()
    
    
    def restore_jobs(self):
        entityClass = self.entity.__class__.__name__
        if entityClass == "TNArchipelVirtualMachine":
            entity_uid = self.entity.uuid
        elif entityClass == "TNArchipelHypervisor":
            entity_uid = ARCHIPEL_SCHED_HYPERVISOR_UID
        self.cursor.execute("SELECT * FROM scheduler WHERE entity_uuid=?", (entity_uid,))
        for values in self.cursor:
            entity_uuid, job_uuid, action, year, month, day, hour, minute, second, comment, params = values
            str_date = "%s/%s/%s %s:%s:%s" % (year, month, day, hour, minute, second)
            self.scheduler.add_cron_job(self.__do_job_for_vm, year=year, month=month, day=day, hour=hour, minute=minute, second=second, args=[action, job_uuid, str_date, comment])
    
    
    
    ######################################################################################################
    ### Jobs
    ###################################################################################################### 
    
    def get_jod_with_uid(self, uid):
        for job in self.scheduler.jobs:
            if str(job.args[1]) == uid:
                return job;
        return None;
    
    
    def __do_job_for_vm(self, action, uid, str_date, comment, param):
        if action == "create":
            self.entity.create()
        elif action == "shutdown":
            self.entity.shutdown()
        elif action == "destroy":
            self.entity.destroy()
        elif action == "suspend":
            self.entity.suspend()
        elif action == "resume":
            self.entity.resume()
        elif action == "pause":
            if self.entity.libvirt_status == 1: self.entity.suspend()
            elif self.entity.libvirt_status == 3: self.entity.resume()
        elif action == "migrate":
            pass
        
        job = self.get_jod_with_uid(uid)
        if not job or not self.scheduler.is_job_active(job):
            self.delete_job(uid);
        
        self.entity.push_change("scheduler", "jobexecuted");
    

    def __do_job_for_hypervisor(self, action, uid, str_date, comment, param):
        if action == "alloc":
            self.entity.alloc()
        elif action == "free":
            pass #self.entity.free()
        
        job = self.get_jod_with_uid(uid)
        if not job or not self.scheduler.is_job_active(job):
            self.delete_job(uid);
        
        self.entity.push_change("scheduler", "jobexecuted");
    


    ######################################################################################################
    ### Process IQ
    ###################################################################################################### 
        
    def process_iq(self, conn, iq):
        """
        this method is invoked when a ARCHIPEL_NS_VM_SCHEDULER IQ is received.
        
        it understands IQ of type:
            - jobs
            - schedule
            - unschedule
        
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
        
        if action == "schedule":
            reply = self.iq_schedule(iq)
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed
        elif action == "unschedule":
            reply = self.iq_unschedule(iq)
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed
        elif action == "jobs":
            reply = self.iq_jobs(iq)
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed
        elif action == "actions":
            reply = self.iq_actions(iq)
            conn.send(reply)
            raise xmpp.protocol.NodeProcessed
    
        
    def iq_schedule(self, iq):
        """
        Schedule a task.

        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ

        @rtype: xmpp.Protocol.Iq
        @return: a ready to send IQ containing the result of the action
        """
        try:
            reply = iq.buildReply("result")
            job = iq.getTag("query").getTag("archipel").getAttr("job")
            entityClass = self.entity.__class__.__name__
            param = None
            
            if entityClass == "TNArchipelVirtualMachine" and not job in self.supported_actions_for_vm:
                raise Exception("action %s is not valid" % job)
            elif entityClass == "TNArchipelHypervisor" and not job in self.supported_actions_for_hypervisor:
                raise Exception("action %s is not valid" % job)
            
            year = iq.getTag("query").getTag("archipel").getAttr("year")
            month = iq.getTag("query").getTag("archipel").getAttr("month")
            day = iq.getTag("query").getTag("archipel").getAttr("day")
            hour = iq.getTag("query").getTag("archipel").getAttr("hour")
            minute = iq.getTag("query").getTag("archipel").getAttr("minute")
            second = iq.getTag("query").getTag("archipel").getAttr("second")
            comment = iq.getTag("query").getTag("archipel").getAttr("comment")
            if iq.getTag("query").getTag("archipel").has_attr("param"):
                param = iq.getTag("query").getTag("archipel").getAttr("param")
            
            uid = str(uuid.uuid1())
            
            str_date = "%s-%s-%s @ %s : %s : %s" % (year, month, day, hour, minute, second)
            
            if entityClass == "TNArchipelVirtualMachine":
                func = self.__do_job_for_vm
            elif entityClass == "TNArchipelHypervisor":
                func = self.__do_job_for_hypervisor
            
            self.scheduler.add_cron_job(func, year=year, month=month, day=day, hour=hour, minute=minute, second=second, args=[job, uid, str_date, comment, param])
            
            self.save_jobs(uid, job, year, month, day, hour, minute, second, comment, param)
            
            self.entity.push_change("scheduler", "scheduled")
        except Exception as ex:
            reply = build_error_iq(self, ex, iq)
        return reply
    
    
    def iq_jobs(self, iq):
        """
        gets jobs

        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ

        @rtype: xmpp.Protocol.Iq
        @return: a ready to send IQ containing the result of the action
        """
        try:
            reply = iq.buildReply("result")
            nodes = [];
            for job in self.scheduler.jobs:
                job_node = xmpp.Node(tag="job", attrs={"action": str(job.args[0]), "uid": str(job.args[1]), "date": str(job.args[2]), "comment": job.args[3]})
                nodes.append(job_node)
            
            reply.setQueryPayload(nodes)
        except Exception as ex:
            reply = build_error_iq(self, ex, iq)
        return reply

    
    
    def iq_unschedule(self, iq):
        """
        gets jobs

        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ

        @rtype: xmpp.Protocol.Iq
        @return: a ready to send IQ containing the result of the action
        """
        try:
            reply = iq.buildReply("result")
            uid = iq.getTag("query").getTag("archipel").getAttr("uid")
            the_job = self.get_jod_with_uid(uid);
            if not the_job:
                raise Exception("job with uid %s doesn't exists" % uid)
            
            self.delete_job(uid);
            self.scheduler.unschedule_job(the_job);
            self.entity.push_change("scheduler", "unscheduled")
        except Exception as ex:
            reply = build_error_iq(self, ex, iq)
        return reply
    
    
    def iq_actions(self, iq):
        """
        get available actions

        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ

        @rtype: xmpp.Protocol.Iq
        @return: a ready to send IQ containing the result of the action
        """
        try:
            reply = iq.buildReply("result")
            entityClass = self.entity.__class__.__name__
            
            if entityClass == "TNArchipelVirtualMachine":
                actions = self.supported_actions_for_vm
            elif entityClass == "TNArchipelHypervisor":
                actions = self.supported_actions_for_hypervisor
            
            nodes = []
            for action in actions:
                action_node = xmpp.Node(tag="action")
                action_node.setData(action)
                nodes.append(action_node)
            reply.setQueryPayload(nodes)
        except Exception as ex:
            reply = build_error_iq(self, ex, iq)
        return reply
    
        
        
