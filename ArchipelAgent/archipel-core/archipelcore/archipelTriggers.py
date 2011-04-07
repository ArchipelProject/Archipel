# -*- coding: utf-8 -*-
#
# archipelTriggers.py
#
# Copyright (C) 2010 Antoine Mercadal <antoine.mercadal@inframonde.eu>
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

import datetime
import xmpp

import archipelcore.pubsub


ARCHIPEL_TRIGGER_MODE_MANUAL    = 0
ARCHIPEL_TRIGGER_MODE_AUTO      = 1

ARCHIPEL_TRIGGER_STATE_OFF      = 0
ARCHIPEL_TRIGGER_STATE_ON       = 1

ARCHIPEL_WATCHER_STATE_OFF      = 0
ARCHIPEL_WATCHER_STATE_ON       = 1


class TNArchipelTrigger:
    """
    This is the representation of a basic trigger
    """

    def __init__(self, entity, name, description=None, mode=ARCHIPEL_TRIGGER_MODE_MANUAL, check_method=None, check_interval=-1):
        """
        The contructor.
        @type entity: TNArchipelEntity
        @param entity: the entity that owns the trigger
        @type name: string
        @param name: the name of the trigger
        @type mode: int
        @param mode: mode of the trigger. if ARCHIPEL_TRIGGER_MODE_MANUAL, state must be change by entity. if ARCHIPEL_TRIGGER_MODE_AUTO, then the check_method param will be played to determine if the trigger is on or off
        @type check_method: function
        @param check_method: the method to use to determine an auto trigger is on or off. This method must return a boolean
        @type check_interval: int
        @param check_interval: the time interval between to run check_method if trigger is auto. if -1, it will be run once.
        """
        self.entity         = entity
        self.name           = name
        self.description    = description
        self.mode           = mode
        self.check_method   = check_method
        self.check_interval = check_interval
        self.nodeName       = "/archipel/trigger/%s/%s" % (self.entity.jid.getStripped(), self.name)
        self.pubSubNode     = archipelcore.pubsub.TNPubSubNode(self.entity.xmppclient, self.entity.pubsubserver, self.nodeName)
        self.state          = ARCHIPEL_TRIGGER_STATE_OFF

        self.init_pubsub_node()

    def init_pubsub_node(self):
        """
        Initialize the pubsubnode. If it doesn't exists, it will be created and configured.
        """
        if not self.pubSubNode.recover(wait=True):
            self.pubSubNode.create(wait=True)
        self.pubSubNode.configure({
            archipelcore.pubsub.XMPP_PUBSUB_VAR_ACCESS_MODEL: archipelcore.pubsub.XMPP_PUBSUB_VAR_ACCESS_MODEL_OPEN,
            archipelcore.pubsub.XMPP_PUBSUB_VAR_MAX_ITEMS: 1,
            archipelcore.pubsub.XMPP_PUBSUB_VAR_PERSIST_ITEMS: 0,
            archipelcore.pubsub.XMPP_PUBSUB_VAR_NOTIFY_RECTRACT: 0,
            archipelcore.pubsub.XMPP_PUBSUB_VAR_DELIVER_PAYLOADS: 1
        }, wait=True)

    def delete_pubsub_node(self):
        """
        Remove the pubsub node.
        """
        self.pubSubNode.delete(wait=True)

    def set_state(self, state):
        """
        Manual set if the trigger is on or off.
        @type state: int
        @param state: ARCHIPEL_TRIGGER_STATE_OFF or ARCHIPEL_TRIGGER_STATE_ON
        """
        triggerNode = xmpp.Node(tag="trigger", attrs={"date": datetime.datetime.now()})

        if self.description:
            descNode    = triggerNode.addChild(name="description")
            descNode.setData(self.description)

        stateNode    = triggerNode.addChild(name="state")
        stateNode.setData(state)

        self.pubSubNode.add_item(triggerNode)


class TNArchipelTriggerWatcher:
    """this is the basic class for using a trigger watcher"""

    def __init__(self, entity, name, targetjid, triggername, triggeronaction=None, triggeroffaction=None):
        self.name               = name
        self.entity             = entity
        self.triggername        = triggername
        self.triggeronaction    = triggeronaction
        self.triggeroffaction   = triggeroffaction
        self.state              = ARCHIPEL_WATCHER_STATE_OFF
        self.nodename           = "/archipel/trigger/%s/%s" % (targetjid.getStripped(), self.triggername)
        self.pubsubNode         = archipelcore.pubsub.TNPubSubNode(self.entity.xmppclient, self.entity.pubsubserver, self.nodename)

    def watch(self):
        self.pubsubNode.subscribe(self.entity.jid, self.on_event)
        self.state = ARCHIPEL_WATCHER_STATE_ON

    def unwatch(self):
        self.pubsubNode.unsubscribe(self.entity.jid.getStripped())
        self.state = ARCHIPEL_WATCHER_STATE_OFF

    def on_event(self, event):
        try:
            state = event.getTag("event").getTag("items").getTag("item").getTag("trigger").getTag("state").getCDATA()
            if int(state) == ARCHIPEL_TRIGGER_STATE_ON:
                if self.triggeronaction: self.triggeronaction()
            else:
                if self.triggeroffaction: self.triggeroffaction()
        except Exception as ex:
            self.entity.log.error("Error in on_event: %s" % str(ex))