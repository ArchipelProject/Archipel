"""
this module contains some functions that allow objects to use advanced logging
functionalities or others common stuffs
"""
import sys
import datetime
import ctypes
import ConfigParser

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

ARCHIPEL_MODULES_AUTO_LOAD =  True;


COLOR_WHITE = u'\033[0m'
COLOR_ERROR = u'\033[31m'
COLOR_INFO  = u'\033[33m'
COLOR_DEBUG = u'\033[36m'
COLOR_CLASS_HYPERVISOR      = u'\033[32m'
COLOR_CLASS_VIRTUALMACHINE  = u'\033[34m'



def init_conf(path):
    conf = ConfigParser.ConfigParser()
    conf.readfp(open(path))
    logging_level = conf.get("Logging", "logging_level")
    if logging_level == "debug":
        globals()["LOG_LEVEL"] = LOG_LEVEL_DEBUG
    elif logging_level == "info":
        globals()["LOG_LEVEL"] = LOG_LEVEL_INFO
    elif logging_level == "error":
        globals()["LOG_LEVEL"] = LOG_LEVEL_ERROR
    log_file = conf.get("Logging", "logging_file_path")
    globals()["LOG_WRITE_IN_FILE"] = log_file
    
    return conf;


def log(logger, level, message) :
    """
    this method is used to handle logging event.

    example :
        >>> log(self, LOG_LEVEL_INFO, "ressource defined as virt-hyperviseur")
        [INFO ] 2010-02-01 21:29:12.258505 TrinityHypervisor.__init__[12447696] : ressource defined as virt-hyperviseur
        
    
    @type level: string
    @param level: the log level according to the value of L{LOG_DICT}
    @type message: string
    @param message: the message body to enter
    """
    if level >= LOG_LEVEL:
        class_name = logger.__class__.__name__
        class_id = str(id(logger))
        function_name = sys._getframe(1).f_code.co_name
        
        if level == LOG_LEVEL_INFO:
            color_head = COLOR_INFO
        elif level == LOG_LEVEL_DEBUG:
            color_head = COLOR_DEBUG
        elif level == LOG_LEVEL_ERROR:
            color_head = COLOR_ERROR
        
        color_class = COLOR_WHITE
        if class_name == "TNArchipelVirtualMachine":
            color_class = COLOR_CLASS_VIRTUALMACHINE
        elif class_name == "TNArchipelHypervisor":
            color_class = COLOR_CLASS_HYPERVISOR
            
        entry = "{6}[{0}]{7}\t{1} [{4}] {8}{2}.{3}{7}: {5}\033[0m".format(LOG_DICT[level], 
                                                        datetime.datetime.now(), 
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
            f = open(LOG_WRITE_IN_FILE, "a+")
            f.write(entry + "\n")


            
        