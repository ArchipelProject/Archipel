# -*- coding: utf-8 -*-
#
# utils.py
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


"""
this module contains some functions that allow objects to use advanced logging
functionalities or others common stuffs
"""

import ConfigParser
import inspect
import logging
import logging.handlers
import os
import xmpp


# Namespaces
ARCHIPEL_NS_GENERIC_ERROR                       = "archipel:error:generic"

ARCHIPEL_LOG_LEVEL                              = 0
ARCHIPEL_LOG_DEBUG                              = 0
ARCHIPEL_LOG_INFO                               = 1
ARCHIPEL_LOG_WARNING                            = 2
ARCHIPEL_LOG_ERROR                              = 3


log = logging.getLogger('archipel')

class TNArchipelLogger:
    """
    archipel logger implt
    """

    def __init__(self, entity, pubsubnode=None, xmppconn=None):
        self.xmppclient = xmppconn
        self.entity     = entity
        self.pubSubNode = pubsubnode

    def __log(self, level, msg):
        log = logging.getLogger('archipel')
        msg = "\033[33m%s.%s (%s)\033[0m::%s" % (self.entity.__class__.__name__, inspect.stack()[2][3],  self.entity.jid, msg)
        if level < ARCHIPEL_LOG_LEVEL:
            return
        elif level == ARCHIPEL_LOG_DEBUG:
            log.debug(msg)
        elif level == ARCHIPEL_LOG_INFO:
            log.info(msg)
        elif level == ARCHIPEL_LOG_WARNING:
            log.warning(msg)
        elif level == ARCHIPEL_LOG_ERROR:
             log.error(msg)

        # if self.xmppclient and self.pubSubNode:
        #     log = xmpp.Node(tag="log", attrs={"date": datetime.datetime.now(), "level": str(level)})
        #     log.setData(msg)
        #     self.pubSubNode.add_item(log)

    def debug(self, msg):
        self.__log(ARCHIPEL_LOG_DEBUG, msg)

    def info(self, msg):
        self.__log(ARCHIPEL_LOG_INFO, msg)

    def warning(self, msg):
        self.__log(ARCHIPEL_LOG_WARNING, msg)

    def error(self, msg):
        self.__log(ARCHIPEL_LOG_ERROR, msg)


class ColorFormatter (logging.Formatter):
    """
    Archipel log formatter
    """
    def format(self, record):
        rec = logging.Formatter.format(self, record)
        rec = rec.replace("DEBUG",      "\033[35mDEBUG   \033[0m")
        rec = rec.replace("INFO",       "\033[32mINFO    \033[0m")
        rec = rec.replace("WARNING",    "\033[33mWARNING \033[0m")
        rec = rec.replace("ERROR",      "\033[31mERROR   \033[0m")
        rec = rec.replace("CRITICAL",   "\033[31mCRITICAL\033[0m")
        rec = rec.replace("$whiteColor",    "\033[37m")
        rec = rec.replace("$noColor",       "\033[0m")
        return rec


def init_conf(paths):
    """
    This method initialize the configuration object (that will be passed to all
    entities) from a given path.
    @type path: List
    @param paths: list of the paths of the config files to read
    @return : the ConfigParser object containing the configuration
    """
    import socket
    conf = ConfigParser.ConfigParser()
    conf.read(paths)
    for section in conf.sections():
        for option in conf.options(section):
            value = conf.get(section, option, raw=True)
            value = value.replace("@HOSTNAME@", socket.gethostname())
            conf.set(section, "%s" % option, value)
    return conf

def init_log(conf):
    """
    Initialize the logger
    @type conf: ConfigParser
    @param conf: the configuration where to read log info
    """
    logging_level = conf.get("LOGGING", "logging_level")
    if logging_level == "debug":
        level = logging.DEBUG
    elif logging_level == "info":
        level = logging.INFO
    elif logging_level == "warning":
        level = logging.WARNING
    elif logging_level == "error":
        level = logging.ERROR
    elif logging_level == "critical":
        level = logging.CRITICAL
    log_file = conf.get("LOGGING", "logging_file_path")
    if not os.path.exists(os.path.dirname(log_file)):
        os.makedirs(os.path.dirname(log_file))
    logger          = globals()["log"]
    max_bytes       = conf.getint("LOGGING", "logging_max_bytes")
    backup_count    = conf.getint("LOGGING", "logging_backup_count")
    handler         = logging.handlers.RotatingFileHandler(log_file, maxBytes=max_bytes, backupCount=backup_count)
    log_format      = ColorFormatter(conf.get("LOGGING", "logging_formatter", raw=True), conf.get("LOGGING", "logging_date_format", raw=True))
    handler.setFormatter(log_format)
    logger.addHandler(handler)
    logger.setLevel(level)

def build_error_iq(originclass, ex, iq, code=-1, ns=ARCHIPEL_NS_GENERIC_ERROR):
    #traceback.print_exc(file=sys.stdout, limit=20)
    caller = inspect.stack()[1][3]
    log.error("%s.%s: exception raised is: '%s' triggered by stanza :\n%s" % (originclass, caller, ex, str(iq)))
    try:
        origin_namespace = iq.getTag("query").getNamespace()
        origin_action = iq.getTag("query").getTag("archipel").getAttr("action")
        text_message = "%s\n\n%s\n%s" % (str(ex), origin_namespace, origin_action)
    except Exception as e:
        log.error("The stanza is not a valid ACP: %s" % str(e))
        text_message = str(ex)
    reply = iq.buildReply('error')
    reply.setQueryPayload(iq.getQueryPayload())
    error = xmpp.Node("error", attrs={"code": code, "type": "cancel"})
    error.addChild(name=ns.replace(":", "-"), namespace=ns)
    error.addChild(name="text", payload=text_message)
    reply.addChild(node=error)
    return reply

def build_error_message(originclass, ex, msg):
    caller = inspect.stack()[3][3]
    log.error("%s: exception raised is: '%s' triggered by message:\n %s" % (caller, str(ex), str(msg)))
    return str(ex)