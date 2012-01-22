# -*- coding: utf-8 -*-
#
# scriptutils.py
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


import xmpp
import sys

from archipelcore import pubsub

def success(msg):
    """
    Print a standardized success message
    @type msg: String
    @param msg: the message to print
    """
    print "\033[32mSUCCESS: %s\033[0m" % msg

def error(msg, exit=True, code=1):
    """
    Print a standardized success message
    @type msg: String
    @param msg: the message to print
    @type exit: Boolean
    @param exit: if True, exit after print
    @type code: int
    @param code: the error code
    """
    print "\033[31mERROR: %s\033[0m" % msg
    if exit:
        sys.exit(code)

def msg(msg, exit=True):
    """
    Print a standardized neutral message
    @type msg: String
    @param msg: the message to print
    @type exit: Boolean
    @param exit: if True, exit after print
    """
    print "\033[35mMESSAGE: %s\033[0m" % msg

def warn(msg):
    """
    Print a standardized warning message
    @type msg: String
    @param msg: the message to print
    """
    print "\033[33mWARNING: %s\033[0m" % msg

def connect(jid, password):
    """
    Perform an XMPP connection/auth.
    Exit on any error
    @type jid: xmpp.JID
    @param jid: the JID to use to connect
    @type password: string
    @param password: the password
    @rtype: xmpp.Client
    @return: a ready to use client
    """
    xmppclient = xmpp.Client(jid.getDomain(), debug=[])
    if not xmppclient.connect():
        error("cannot connect to the server. exiting")
    if xmppclient.auth(jid.getNode(), password, "configurator") == None:
        error("bad authentication. exiting")
    return xmppclient

def initialize(options, fill_pubsubserver=True):
    """
    Lazy initialization according to OptionParser options. must contains
    options.jid, options.password and options.pubsubserver
    @type options: parsed arguments
    @param options: options from OptionParser.
    @rtype: xmpp.Client
    @return: ready to use XMPP client
    """
    if not options.jid or not options.password:
        error("you must enter a JID and a PASSWORD. see --help for help")

    JID = xmpp.JID(options.jid)
    xmppclient = connect(JID, options.password)
    if fill_pubsubserver and not options.pubsubserver:
        options.pubsubserver = "pubsub." + JID.getDomain()
    return xmppclient

def check_valid_jid(jid, bare=True):
    """
    Check if given JID is a valid JID
    Exit on any error
    @type jid: xmpp.JID
    @param jid: the JID to check
    @type bare: Boolean
    @param bare: if True, JID is considered as valid only if it's bare JID
    """
    if not jid.getNode() or not jid.getDomain():
        error("JID as to be in form user@domain")
    if bare and jid.getResource():
        error("JID must not has a resource")

def get_pubsub(xmppclient, pubsubserver, nodename, wait=True):
    """
    Returns a ready to use pubsub for further operations
    @type xmppclient: xmpp.Client
    @param xmppclient: a connected/authenticated xmpp client
    @type pubsubserver: String
    @param pubsubserver: pubsub server.
    @type nodename: String
    @param nodename: the name of the node to create
    @rtype: archipelcore.TNPubSubNode
    @return: the pubsub
    """
    pubsubNode = pubsub.TNPubSubNode(xmppclient, pubsubserver, nodename)
    if not pubsubNode.recover(wait=wait):
        error("The pubsub node %s doesn't exist. Create it first" % nodename)
    return pubsubNode

def publish_item(xmppclient, pubsubserver, nodename, item, wait=True):
    """
    Publish a new item to the pubsub node
    @type xmppclient: xmpp.Client
    @param xmppclient: a connected/authenticated xmpp client
    @type pubsubserver: String
    @param pubsubserver: pubsub server.
    @type nodename: String
    @param nodename: the target node name
    @type item: xmpp.Node
    @param item: the item to add
    @rtype: Boolean
    @return: True in case of success
    """
    pubsubNode = get_pubsub(xmppclient, pubsubserver, nodename, wait=True)
    return pubsubNode.add_item(item, wait=wait)

def retract_item(xmppclient, pubsubserver, nodename, refID, wait=True):
    """
    Retract an item from the pubsub node
    @type xmppclient: xmpp.Client
    @param xmppclient: a connected/authenticated xmpp client
    @type pubsubserver: String
    @param pubsubserver: pubsub server.
    @type nodename: String
    @param nodename: the target node name
    @type refID: String
    @param refID: the item ID
    @rtype: Boolean
    @return: True in case of success
    """
    pubsubNode = get_pubsub(xmppclient, pubsubserver, nodename, wait=True)
    return pubsubNode.remove_item(refID, wait=True)

def create_pubsub(xmppclient, pubsubserver, nodename, configuration):
    """
    Create a pubsub node
    @type xmppclient: xmpp.Client
    @param xmppclient: a connected/authenticated xmpp client
    @type pubsub: String
    @param pubsub: pubsub server.
    @type nodename: String
    @param nodename: the name of the node to create
    @type configuration: dict
    @param configuration: pubsub configuration
    """
    pubsubNode = pubsub.TNPubSubNode(xmppclient, pubsubserver, nodename)

    if not pubsubNode.recover(wait=True):
        pubsubNode.create(wait=True)
    else:
        error("The pubsub node %s already exist" % nodename)
    pubsubNode.configure(configuration, wait=True)
    success("pubsub node %s created" % nodename)

def configure_pubsub(xmppclient, pubsubserver, nodename, key, value):
    """
    Configure a specific token for the pubsub
    @type xmppclient: xmpp.Client
    @param xmppclient: a connected/authenticated xmpp client
    @type pubsub: String
    @param pubsub: pubsub server.
    @type nodename: String
    @param nodename: the name of the node to create
    @type key: string
    @param key: the config token name
    @type value: string
    @param value: the value
    """
    pubsubNode = get_pubsub(xmppclient, pubsubserver, nodename, wait=True)
    return pubsubNode.configure({key: value}, wait=True)

def delete_pubsub(xmppclient, pubsubserver, nodename):
    """
    Delete a pubsub node
    @type xmppclient: xmpp.Client
    @param xmppclient: a connected/authenticated xmpp client
    @type pubsub: String
    @param pubsub: pubsub server.
    @type nodename: String
    @param nodename: the name of the node to delete
    """
    pubsubNode = pubsub.TNPubSubNode(xmppclient, pubsubserver, nodename)

    if pubsubNode.recover(wait=True):
        pubsubNode.delete(wait=True)
        success("pubsub node %s deleted" % nodename)
    else:
        error("The pubsub node %s doesn't exist" % nodename)

def send_acp(xmppclient, dest_jid, iq_type, query_ns, action, acp_parameters={}, acp_payload=[], debug=False):
    """
    Simplify the generation of an ACP.
    @type xmppclient: xmpp.Client
    @param xmppclient: a connected/authenticated xmpp client
    @type dest_jid: xmpp.JID
    @param dest_jid: the target entity
    @type iq_type: String
    @param iq_type: the IQ type (get or set)
    @type query_ns: String
    @param query_ns: the namespace of the query (i.e. archipel:hypervisor:control)
    @type action: String
    @param action: the Archipel action (i.e. alloc)
    @type acp_parameters: Dict
    @param acp_parameters: any additional acp parameters (i.e. {"name": "my new VM"})
    @type acp_payload: xmpp.Node
    @param acp_payload: any additional information that should be appended to the <archipel/> tag
    @rtype: xmpp.Node
    @return: the answer stanza
    """
    acp = xmpp.Iq(typ=iq_type, to=dest_jid, queryNS=query_ns)
    acp.getTag("query").addChild("archipel")
    acp.getTag("query").getTag("archipel").setAttr("action", action)

    for k,v in acp_parameters.items():
        acp.getTag("query").getTag("archipel").setAttr(k, v)

    if len(acp_payload) > 0:
        acp.getTag("query").getTag("archipel").setPayload(acp_payload)
    if debug:
        print "sending stanza %s" % str(acp)
    resp = xmppclient.SendAndWaitForResponse(acp)
    return resp

def send_raw_acp(xmppclient, dest_jid, raw_acp_string, debug=False):
    """
    Take a string, convert it to a valid IQ, and send it.
    @type xmppclient: xmpp.Client
    @param xmppclient: a connected/authenticated xmpp client
    @type dest_jid: xmpp.JID
    @param dest_jid: the target entity
    @type raw_acp_string: String
    @param raw_acp_string: the IQ to send
    @rtype: xmpp.Node
    @return: the answer stanza
    """
    acp = xmpp.simplexml.NodeBuilder(data=raw_acp_string).getDom()
    acp = xmpp.Iq(node=acp)
    acp.setTo(dest_jid)
    resp = xmppclient.SendAndWaitForResponse(acp)
    return resp

def xml_print(xml_node):
    """
    This function will prettify an XML node
    @type xml_node: xmpp.Node
    @param xml_node: the node to format
    @rtype: String
    @return: a pretiffied XML string
    """
    import xml.dom.minidom
    elem = xml.dom.minidom.parseString(str(xml_node))
    return elem.toprettyxml(indent="    ").replace("<?xml version=\"1.0\" ?>\n", "")

