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

import os, sys, commands
import new
import archipel
import utils
from archipelSimpleWebServer import *

config = utils.init_conf(sys.argv[1]);

def load_modules():
    """
    this function load modules
    """
    module_dir      = config.get("General", "modules_dir_name")
    module_dir_path = str(config.get("General" , "modules_dir_base_path")) + "/" + module_dir

    if config.getboolean("General", "general_auto_load_module"):        
        for subdir, dirs, files in os.walk(module_dir_path):
            for module in dirs:
                __import__(module_dir + "." + module, None, locals())
    else:
        for module, should_load in config.items("Modules"):
            if should_load == "yes":
                __import__(module_dir + "." + module, None, locals())
    
                
def main():
    """
    main function of Archipel
    """
    # starting simple web server for Java VNC applet
    port = config.getint("Simple Webserver", "webserver_port")
    httpd = TNThreadedWebServer(port);
    httpd.daemon = True
    httpd.start()

    # initializing the hypervisor XMPP entity
    jid         = config.get("Archipel Hypervisor", "hypervisor_xmpp_jid")
    password    = config.get("Archipel Hypervisor", "hypervisor_xmpp_password")
    hyp = archipel.TNArchipelHypervisor(jid, password, config)
    hyp.connect()
    
    
if __name__ == "__main__":
    try:
        pid = os.fork()
        if pid > 0:
            sys.exit(0)
    except OSError as e:
        os.exit(1)
    
    os.chdir(config.get("General", "general_exec_dir"))
    load_modules();
    os.setsid()
    os.umask(0)
        
    try:
        pid = os.fork()
        if pid > 0:
          sys.exit(0)
    except OSError as e:
        sys.exit(1)
    
    main()