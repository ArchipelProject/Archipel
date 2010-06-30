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

log = logging.getLogger('archipel')


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
    
    # logging.basicConfig(level=level,
    #                     datefmt=conf.get("LOGGING", "logging_date_format", raw=True),
    #                     format=conf.get("LOGGING", "logging_formatter", raw=True),
    #                     filename=log_file)
    return conf


NS_ARCHIPEL_ERROR_QUERY_NOT_WELL_FORMED =   -42
NS_LIBVIRT_GENERIC_ERROR = "libvirt:error:generic"

def build_error_iq(originclass, ex, iq, code=-1, ns="archipel:error:generic"):
    caller = inspect.stack()[2][3];
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