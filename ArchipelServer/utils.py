"""
this module contains some functions that allow objects to use advanced logging
functionalities or others common stuffs
"""
import sys
import datetime
import ConfigParser
import xmpp
import inspect

LOG_LEVEL_DEBUG = 0
"""This level of log is the most verbose"""

LOG_LEVEL_INFO = 1
"""This should be the standard log level"""

LOG_LEVEL_ERROR = 2
"""This level prints only errors. should be use for production"""

LOG_LEVEL = LOG_LEVEL_INFO
"""this allows to set the log level"""

LOG_WRITE_IN_FILE = None
"""If not None, all the logs are writting in this file path."""

LOG_WRITE_IN_STDOUT = False
"""If True, all the logs are writting in stdout."""

LOG_DICT = ["DEBUG", "INFO", "ERROR"]
"""
this list gives the name of log level
    >>> print LOG_DICT[LOG_LEVEL_INFO]
    INFO
"""


COLOR_WHITE = u'\033[0m'
"""
terminal white color
"""
COLOR_ERROR = u'\033[31m'
"""
terminal color for error logs
"""
COLOR_INFO  = u'\033[33m'
"""
terminal color for info logs
"""
COLOR_DEBUG = u'\033[36m'
"""
terminal color for debug logs
"""


COLOR_CLASS_HYPERVISOR      = u'\033[32m'
"""
color for logs written by TNArchipelHypervisor
"""
COLOR_CLASS_VIRTUALMACHINE  = u'\033[34m'
"""
color for logs written by TNArchipelVirtualMachine
"""

COLORING_MAPPING_CLASS      = { "TNArchipelVirtualMachine": COLOR_CLASS_VIRTUALMACHINE, 
                                "TNArchipelHypervisor": COLOR_CLASS_HYPERVISOR , 
                                "TNArchipelHypervisor": COLOR_CLASS_HYPERVISOR}


COLORING_MAPPING_LOG_LEVEL  = { LOG_LEVEL_INFO: COLOR_INFO, 
                                LOG_LEVEL_DEBUG: COLOR_DEBUG, 
                                LOG_LEVEL_ERROR: COLOR_ERROR}

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
        globals()["LOG_LEVEL"] = LOG_LEVEL_DEBUG
    elif logging_level == "info":
        globals()["LOG_LEVEL"] = LOG_LEVEL_INFO
    elif logging_level == "error":
        globals()["LOG_LEVEL"] = LOG_LEVEL_ERROR
    log_file = conf.get("LOGGING", "logging_file_path")
    globals()["LOG_WRITE_IN_FILE"] = log_file
    #globals()["ARCHIPEL_LOG_FILE"] = open(log_file, "a+")
    
    return conf




def log(logger, level, message) :
    """
    this method is used to handle logging event.
    
    example :
        >>> log(self, LOG_LEVEL_INFO, "ressource defined as virt-hyperviseur")
        [INFO ] 2010-02-01 21:29:12.258505 TNArchipelHypervisor.__init__[12447696] : ressource defined as virt-hyperviseur
    
    @type level: string
    @param level: the log level according to the value of L{LOG_DICT}
    @type message: string
    @param message: the message body to enter
    """
    if level < LOG_LEVEL:
        return
    
    class_name      = logger.__class__.__name__
    class_id        = str(id(logger))
    function_name   = sys._getframe(1).f_code.co_name
    current_date    = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    color_class     = COLOR_WHITE
    
    for match, color in COLORING_MAPPING_LOG_LEVEL.items():
        if match == level:
            color_head = color
            break
    
    for match, color in COLORING_MAPPING_CLASS.items():
        if class_name == match:
            color_class = color
            break
            
    # TODO : add a some system to handle colouring management by modules.
    
    
    entry = "{6}[{0}]{7}\t{1} [{4}] {8}{2}.{3}{7}: {5}".format( LOG_DICT[level], 
                                                                current_date, 
                                                                class_name,
                                                                function_name,
                                                                class_id, 
                                                                message.lower(),
                                                                color_head,
                                                                COLOR_WHITE,
                                                                color_class)
    if LOG_WRITE_IN_STDOUT:
        print entry
        
    if LOG_WRITE_IN_FILE:
        ARCHIPEL_LOG_FILE = open(LOG_WRITE_IN_FILE, "a+")
        ARCHIPEL_LOG_FILE.write(entry + "\n")
        ARCHIPEL_LOG_FILE.close();


def build_error_iq(originclass, ex, iq):
    caller = inspect.stack()[2][3];
    log(originclass, LOG_LEVEL_ERROR, "%s: exception raised is : %s" % (caller, ex))
    reply = iq.buildReply('error')
    payload = xmpp.Node("error")
    payload.addData(str(ex))
    reply.setQueryPayload([payload])
    return reply
            
        