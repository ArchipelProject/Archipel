#!/usr/bin/python
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
import getopt
import archipel
import utils
from archipelSimpleWebServer import *




def load_modules():
    """
    this function load modules
    """
    module_dir      = config.get("GLOBAL", "modules_dir_name")
    module_dir_path = str(config.get("GLOBAL" , "modules_dir_base_path")) + "/" + module_dir

    if config.getboolean("GLOBAL", "general_auto_load_module"):        
        for subdir, dirs, files in os.walk(module_dir_path):
            for module in dirs:
                __import__(module_dir + "." + module, None, locals())
    else:
        for module, should_load in config.items("MODULES"):
            if should_load == "True":
                __import__(module_dir + "." + module, None, locals())
    
                
def main():
    """
    main function of Archipel
    """
    # starting simple web server for Java VNC applet
    port = config.getint("WEBSERVER", "webserver_port")
    httpd = TNThreadedWebServer(port)
    httpd.start()

    # initializing the hypervisor XMPP entity
    jid         = config.get("HYPERVISOR", "hypervisor_xmpp_jid")
    password    = config.get("HYPERVISOR", "hypervisor_xmpp_password")
    database    = config.get("HYPERVISOR", "hypervisor_database_path")
    
    hyp = archipel.TNArchipelHypervisor(jid, password, config, database)
    hyp.connect()
    hyp.loop()
    
    
if __name__ == "__main__":
    opts, args = getopt.getopt(sys.argv[1:], "hn", ["nofork", "config=", "help"])
    
    configPath = "/etc/archipel/archipel.conf"
    fork = True
    
    for o, a in opts:
        if o in ("--config"):
            configPath = a
        if o in ("-n", "--nofork"):
            fork = False
        if o in ("-h", "--help"):
            print """\
Archipel Daemon (c) 2010 Antoine Mercadal

usage: runarchipel.py [--nofork] [--config=</path/to/conf>]

Options :
    * --nofork : run archipel in the current process. Do not fork. This is for testing.
    * --config : The path of the config file to use. Default is /etc/archipel/archipel.conf
"""
            
            sys.exit(0)
    
    if fork:
        try:
            pid = os.fork()
            if pid > 0:
                sys.exit(0)
        except OSError as e:
            os.exit(1)
    
    config = utils.init_conf(configPath)
    os.chdir(config.get("GLOBAL", "general_exec_dir"))
    load_modules()

    if fork:
        os.setsid()
        os.umask(0)
        
        try:
            pid = os.fork()
            if pid > 0:
              sys.exit(0)
        except OSError as e:
            sys.exit(1)
    
    main()