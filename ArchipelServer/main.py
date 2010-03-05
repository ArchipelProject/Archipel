#!/usr/bin/python -W ignore::DeprecationWarning

import os
import new
import archipel
from archipelSimpleWebServer import *

 
MODULE_DIR = "modules."

for subdir, dirs, files in os.walk("./modules"):
    for module in dirs:
        __import__(MODULE_DIR + module, None, locals())

httpd = TNThreadedWebServer(8088);
httpd.daemon = True
httpd.start()


hyp = archipel.TNArchipelHypervisor("hypervisor@pulsar.local", "password")
hyp.connect()
