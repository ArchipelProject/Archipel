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
    log_format      = logging.Formatter(conf.get("LOGGING", "logging_formatter", raw=True), conf.get("LOGGING", "logging_date_format", raw=True))
    
    handler.setFormatter(log_format)
    logger.addHandler(handler)
    logger.setLevel(level)
    
    # logging.basicConfig(level=level,
    #                     datefmt=conf.get("LOGGING", "logging_date_format", raw=True),
    #                     format=conf.get("LOGGING", "logging_formatter", raw=True),
    #                     filename=log_file)
    return conf



def build_error_iq(originclass, ex, iq):
    caller = inspect.stack()[2][3];
    log(originclass, LOG_LEVEL_ERROR, "%s: exception raised is : %s" % (caller, ex))
    reply = iq.buildReply('error')
    payload = xmpp.Node("error")
    payload.addData(str(ex))
    reply.setQueryPayload([payload])
    return reply
            
        