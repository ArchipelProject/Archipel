#!/usr/bin/python -W ignore::DeprecationWarning

import archipel
from archipelSimpleWebServer import *

httpd = TNThreadedWebServer(8088);
httpd.daemon = True
httpd.start()


hyp = archipel.TNArchipelHypervisor("hypervisor@pulsar.local", "password")
hyp.connect()
