# -*- coding: utf-8 -*-
#
# actionscheduler.py
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

import sqlite3
import uuid
import xmpp
from apscheduler.scheduler import Scheduler

from archipelcore.archipelPlugin import TNArchipelPlugin
from archipelcore.utils import build_error_iq


ARCHIPEL_NS_ENTITY_SCHEDULER    = "archipel:entity:scheduler"
ARCHIPEL_SCHED_HYPERVISOR_UID   = "schedule-hypervisor-uid"


class TNActionScheduler (TNArchipelPlugin):
    """
    This plugin allows to create scheduled actions.
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
        self.scheduler = Scheduler()
        self.scheduler.start()
        self.database = sqlite3.connect(self.configuration.get("SCHEDULER", "database"), check_same_thread=False)
        self.database.execute("create table if not exists scheduler (entity_uuid text, job_uuid text, action text, year text, month text, day text, hour text, minute text, second text, comment text, params text)")
        self.database.commit()
        self.cursor = self.database.cursor()
        self.restore_jobs()
        self.supported_actions_for_vm = ("create", "shutdown", "destroy", "suspend", "resume", "reboot", "migrate", "pause")
        self.supported_actions_for_hypervisor = ("alloc", "free")
        # permissions
        self.entity.permission_center.create_permission("scheduler_jobs", "Authorizes user to get the list of task", False)
        self.entity.permission_center.create_permission("scheduler_schedule", "Authorizes user to schedule a task", False)
        self.entity.permission_center.create_permission("scheduler_unschedule", "Authorizes user to unschedule a task", False)
        self.entity.permission_center.create_permission("scheduler_actions", "Authorizes user to get available actions", False)
        # hooks
        if self.entity.__class__.__name__ == "TNArchipelVirtualMachine":
            self.entity.register_hook("HOOK_VM_TERMINATE", method=self.vm_terminate)

    ### Plugin interface

    def register_handlers(self):
        """
        This method will be called by the plugin user when it will be
        necessary to register module for listening to stanza.
        """
        self.entity.xmppclient.RegisterHandler('iq', self.process_iq, ns=ARCHIPEL_NS_ENTITY_SCHEDULER)

    def unregister_handlers(self):
        """
        Unregister the handlers.
        """
        self.entity.xmppclient.UnregisterHandler('iq', self.process_iq, ns=ARCHIPEL_NS_ENTITY_SCHEDULER)

    @staticmethod
    def plugin_info():
        """
        Return informations about the plugin.
        @rtype: dict
        @return: dictionary contaning plugin informations
        """
        plugin_friendly_name           = "Action Scheduler"
        plugin_identifier              = "action_scheduler"
        plugin_configuration_section   = "SCHEDULER"
        plugin_configuration_tokens    = ["database"]
        return {    "common-name"               : plugin_friendly_name,
                    "identifier"                : plugin_identifier,
                    "configuration-section"     : plugin_configuration_section,
                    "configuration-tokens"      : plugin_configuration_tokens }


    ### Persistance

    def delete_job(self, uid):
        """
        Remove a job from the database.
        @type uid: string
        @param uid: the uid of the job to remove
        """
        self.cursor.execute("DELETE FROM scheduler WHERE job_uuid=?", (uid, ))
        self.database.commit()

    def save_jobs(self, uid, action, year, month, day, hour, minute, second, comment, params=None):
        """
        Save a job in the database.
        @type uid: string
        @param uid: the uid of the job
        @type action: string
        @param action: the action
        @type year: string
        @param year: year of execution
        @type month: string
        @param month: month of execution
        @type day: string
        @param day: day of execution
        @type hour: string
        @param hour: hour of execution
        @type minute: string
        @param minute: minute of execution
        @type second: string
        @param second: second of execution
        @type comment: string
        @param comment: comment about the job
        @type params: string
        @param params: random parameter of the job
        """
        entityClass = self.entity.__class__.__name__
        if entityClass == "TNArchipelVirtualMachine":
            entity_uid = self.entity.uuid
        elif entityClass == "TNArchipelHypervisor":
            entity_uid = ARCHIPEL_SCHED_HYPERVISOR_UID
        self.cursor.execute("INSERT INTO scheduler VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", (entity_uid, uid, action, year, month, day, hour, minute, second, comment, params, ))
        self.database.commit()

    def restore_jobs(self):
        """
        Restore the jobs from the database.
        """
        entityClass = self.entity.__class__.__name__
        if entityClass == "TNArchipelVirtualMachine":
            entity_uid = self.entity.uuid
        elif entityClass == "TNArchipelHypervisor":
            entity_uid = ARCHIPEL_SCHED_HYPERVISOR_UID
        self.cursor.execute("SELECT * FROM scheduler WHERE entity_uuid=?", (entity_uid, ))
        for values in self.cursor:
            try:
                entity_uuid, job_uuid, action, year, month, day, hour, minute, second, comment, params = values
                str_date = "%s/%s/%s %s:%s:%s" % (year, month, day, hour, minute, second)
                self.scheduler.add_cron_job(self.do_job_for_vm, year=year, month=month, day=day, hour=hour, minute=minute, second=second, args=[action, job_uuid, str_date, comment])
            except Exception as ex:
                self.entity.log.error("unable to restore a job: %s" % str(ex))

    def vm_terminate(self, origin, user_info, arguments):
        """
        Close the database connection.
        @type origin: TNArchipelEntity
        @param origin: the origin of the hook
        @type user_info: object
        @param user_info: random user information
        @type arguments: object
        @param arguments: runtime argument
        """
        self.database.close()

    ### Jobs

    def get_jod_with_uid(self, uid):
        """
        Get a job with given uid.
        @type uid: string
        @param uid: the uid of the job
        """
        if hasattr(self.scheduler, "get_jobs"):
            jobs = self.scheduler.get_jobs()
        else:
            jobs = self.scheduler.jobs

        for job in jobs:
            if str(job.args[1]) == uid:
                return job
        return None

    def do_job_for_vm(self, action, uid, str_date, comment, param):
        """
        Perform the job.
        @type action: string
        @param action: the action to execute
        @type uid: string
        @param uid: the uid of the job
        @type str_date: string
        @param str_date: the date of the job
        @type comment: string
        @param comment: comment about the job
        @type param: string
        @param param: a random parameter to give to job
        """
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
            if self.entity.libvirt_status == 1:
                self.entity.suspend()
            elif self.entity.libvirt_status == 3:
                self.entity.resume()
        elif action == "migrate":
            pass
        job = self.get_jod_with_uid(uid)
        if not job or not self.scheduler.is_job_active(job):
            self.delete_job(uid)
        self.entity.push_change("scheduler", "jobexecuted")

    def do_job_for_hypervisor(self, action, uid, str_date, comment, param):
        """
        Perform the job.
        @type action: string
        @param action: the action to execute
        @type uid: string
        @param uid: the uid of the job
        @type str_date: string
        @param str_date: the date of the job
        @type comment: string
        @param comment: comment about the job
        @type param: string
        @param param: a random parameter to give to job
        """
        if action == "alloc":
            self.entity.alloc()
        elif action == "free":
            pass #self.entity.free()
        job = self.get_jod_with_uid(uid)
        if not job or not self.scheduler.is_job_active(job):
            self.delete_job(uid)
        self.entity.push_change("scheduler", "jobexecuted")


    ### Process IQ

    def process_iq(self, conn, iq):
        """
        This method is invoked when a ARCHIPEL_NS_VM_SCHEDULER IQ is received.
        It understands IQ of type:
            - jobs
            - schedule
            - unschedule
        @type conn: xmpp.Dispatcher
        @param conn: ths instance of the current connection that send the stanza
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ
        """
        reply = None
        action = self.entity.check_acp(conn, iq)
        self.entity.check_perm(conn, iq, action, -1, prefix="scheduler_")

        if   action == "schedule":
            reply = self.iq_schedule(iq)
        elif action == "unschedule":
            reply = self.iq_unschedule(iq)
        elif action == "jobs":
            reply = self.iq_jobs(iq)
        elif action == "actions":
            reply = self.iq_actions(iq)
        if reply:
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
                func = self.do_job_for_vm
            elif entityClass == "TNArchipelHypervisor":
                func = self.do_job_for_hypervisor
            self.scheduler.add_cron_job(func, year=year, month=month, day=day, hour=hour, minute=minute, second=second, args=[job, uid, str_date, comment, param])
            self.save_jobs(uid, job, year, month, day, hour, minute, second, comment, param)
            self.entity.push_change("scheduler", "scheduled")
        except Exception as ex:
            reply = build_error_iq(self, ex, iq)
        return reply

    def iq_jobs(self, iq):
        """
        Get jobs.
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ
        @rtype: xmpp.Protocol.Iq
        @return: a ready to send IQ containing the result of the action
        """
        try:
            reply = iq.buildReply("result")
            nodes = []
            if hasattr(self.scheduler, "get_jobs"):
                jobs = self.scheduler.get_jobs()
            else:
                jobs = self.scheduler.jobs

            for job in jobs:
                job_node = xmpp.Node(tag="job", attrs={"action": str(job.args[0]), "uid": str(job.args[1]), "date": str(job.args[2]), "comment": job.args[3]})
                nodes.append(job_node)
            reply.setQueryPayload(nodes)
        except Exception as ex:
            reply = build_error_iq(self, ex, iq)
        return reply

    def iq_unschedule(self, iq):
        """
        Unschedule a job.
        @type iq: xmpp.Protocol.Iq
        @param iq: the received IQ
        @rtype: xmpp.Protocol.Iq
        @return: a ready to send IQ containing the result of the action
        """
        try:
            reply = iq.buildReply("result")
            uid = iq.getTag("query").getTag("archipel").getAttr("uid")
            the_job = self.get_jod_with_uid(uid)
            if not the_job:
                raise Exception("job with uid %s doesn't exists" % uid)
            self.delete_job(uid)
            self.scheduler.unschedule_job(the_job)
            self.entity.push_change("scheduler", "unscheduled")
        except Exception as ex:
            reply = build_error_iq(self, ex, iq)
        return reply

    def iq_actions(self, iq):
        """
        Get available actions.
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