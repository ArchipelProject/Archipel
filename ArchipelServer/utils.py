"""
this module contains some functions that allow objects to use advanced logging
functionalities or others common stuffs
"""
import sys
import datetime
import ConfigParser
import xmpp
import inspect
import logging
import logging.handlers
import traceback

# XMPP groups
ARCHIPEL_XMPP_GROUP_VM                          = "virtualmachines"
ARCHIPEL_XMPP_GROUP_HYPERVISOR                  = "hypervisors"
ARCHIPEL_XMPP_GROUP_CONTROLLER                  = "controllers"

# Namespaces
ARCHIPEL_NS_LIBVIRT_GENERIC_ERROR               = "libvirt:error:generic"
ARCHIPEL_NS_GENERIC_ERROR                       = "archipel:error:generic"
ARCHIPEL_NS_IQ_PUSH                             = "archipel:push"
ARCHIPEL_NS_SERVICE_MESSAGE                     = "headline"
ARCHIPEL_NS_HYPERVISOR_CONTROL                  = "archipel:hypervisor:control"
ARCHIPEL_NS_VM_CONTROL                          = "archipel:vm:control"
ARCHIPEL_NS_VM_DEFINITION                       = "archipel:vm:definition"

# XMPP shows
ARCHIPEL_XMPP_SHOW_ONLINE                       = "Online"
ARCHIPEL_XMPP_SHOW_RUNNING                      = "Running"
ARCHIPEL_XMPP_SHOW_PAUSED                       = "Paused"
ARCHIPEL_XMPP_SHOW_SHUTDOWNED                   = "Off"
ARCHIPEL_XMPP_SHOW_SHUTOFF                      = "Shutted off"
ARCHIPEL_XMPP_SHOW_ERROR                        = "Error"
ARCHIPEL_XMPP_SHOW_NOT_DEFINED                  = "Not defined"
ARCHIPEL_XMPP_SHOW_CRASHED                      = "Crashed"

# XMPP main loop status
ARCHIPEL_XMPP_LOOP_OFF                          = 0
ARCHIPEL_XMPP_LOOP_ON                           = 1
ARCHIPEL_XMPP_LOOP_RESTART                      = 2
ARCHIPEL_XMPP_LOOP_REMOVE_USER                  = 3

ARCHIPEL_LIBVIRT_SECRET_JID                     = "D52FA978-FD3B-4ED8-9EF9-A1F5B5311E06"
ARCHIPEL_LIBVIRT_SECRET_PASSWORD                = "884DCDDE-81E7-4374-A103-78314A4BDB92"

# errors
ARCHIPEL_NS_ERROR_QUERY_NOT_WELL_FORMED         = -42


ARCHIPEL_LOG_LEVEL                              = 0
ARCHIPEL_LOG_DEBUG                              = 0
ARCHIPEL_LOG_INFO                               = 1
ARCHIPEL_LOG_WARNING                            = 2
ARCHIPEL_LOG_ERROR                              = 3

log = logging.getLogger('archipel')

class TNArchipelLogger:
    def __init__(self, entity, pubsubnode=None, xmppconn=None):
        self.xmppclient = xmppconn
        self.entity     = entity
        self.pubSubNode = pubsubnode
    
    def __log(self, level, msg):
        log = logging.getLogger('archipel')
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
            
        if self.xmppclient and self.pubSubNode:
            log = xmpp.Node(tag="log", attrs={"date": datetime.datetime.now(), "level": str(level)})
            log.setData(msg)
            self.pubSubNode.add_item(log)
    
        
        
    def debug(self, msg):
        self.__log(ARCHIPEL_LOG_DEBUG, msg)
    
    
    def info(self, msg):
        self.__log(ARCHIPEL_LOG_INFO, msg)
    
    
    def warning(self, msg):
        self.__log(ARCHIPEL_LOG_WARNING, msg)
    
    
    def error(self, msg):
        self.__log(ARCHIPEL_LOG_ERROR, msg)
    


class ColorFormatter(logging.Formatter):
    def format(self, record):
        rec = logging.Formatter.format(self, record)
        rec = rec.replace("DEBUG", "\033[35mDEBUG\033[0m")
        rec = rec.replace("INFO", "\033[33mINFO\033[0m")
        rec = rec.replace("WARNING", "\033[32mWARNING\033[0m")
        rec = rec.replace("ERROR", "\033[31mERROR\033[0m")
        rec = rec.replace("CRITICAL", "\033[31mCRITICAL\033[0m")
        rec = rec.replace("$whiteColor", "\033[37m")
        rec = rec.replace("$noColor", "\033[0m")
        return rec
    



def init_conf(path):
    """
    this method intialize the configuration object (that will be passed to all 
    entities) from a given path
    @type path: string
    @param path: teh path of the config file to read
    @return : the ConfigParser object containing the configuration
    """
    conf = ConfigParser.ConfigParser()
    conf.readfp(open(path))
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
    
    logger          = globals()["log"];
    max_bytes       = conf.getint("LOGGING", "logging_max_bytes")
    backup_count    = conf.getint("LOGGING", "logging_backup_count")
    handler         = logging.handlers.RotatingFileHandler(log_file, maxBytes=max_bytes, backupCount=backup_count)
    log_format      = ColorFormatter(conf.get("LOGGING", "logging_formatter", raw=True), conf.get("LOGGING", "logging_date_format", raw=True))
    handler.setFormatter(log_format)
    logger.addHandler(handler)
    logger.setLevel(level)
    
    return conf


def build_error_iq(originclass, ex, iq, code=-1, ns=ARCHIPEL_NS_GENERIC_ERROR):
    traceback.print_exc(file=sys.stdout, limit=20)
    caller = inspect.stack()[1][3];
    log.error("%s.%s: exception raised is : %s" % (originclass, caller, ex))
    reply = iq.buildReply('error')
    reply.setQueryPayload(iq.getQueryPayload())
    error = xmpp.Node("error", attrs={"code": code, "type": "cancel"})
    error.addChild(name=ns.replace(":", "-"), namespace=ns)
    error.addChild(name="text", payload=str(ex))
    reply.addChild(node=error)
    return reply


def build_error_message(originclass, ex):
    caller = inspect.stack()[2][3];
    log.error("%s: exception raised is : %s" % (caller, str(ex)))
    return str(ex)
