#!/usr/bin/python -W ignore::DeprecationWarning
# 
# main.py
# 
# Copyright (C) 2010 Antoine Mercadal <antoine.mercadal@inframonde.eu>
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

import os
import new
import archipel
from archipelSimpleWebServer import *

ARCHIPEL_MODULES_AUTO_LOAD =  True;


# parsing and importing modules;
if ARCHIPEL_MODULES_AUTO_LOAD:
    MODULE_DIR = "modules."
    for subdir, dirs, files in os.walk("./modules"):
        for module in dirs:
            __import__(MODULE_DIR + module, None, locals())

# starting simple web server for Java VNC applet
httpd = TNThreadedWebServer(8088);
httpd.daemon = True
httpd.start()

# initializing the hypervisor XMPP entity
hyp = archipel.TNArchipelHypervisor("hypervisor@pulsar.local", "password")
hyp.connect()
