#! /usr/bin/python
# 
# publish.py
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

import sys, os
import getopt


HELP = """\
publish (c) 2010 Antoine Mercadal
This tool will allow you to build and/or upload all archipel official plugins

usage :
    publish [--help | -h] [--build | -b] [--upload | -u] 

    --build, -b     : build the bdist_egg target
    --upload, -u    : upload to pypi using your .pypirc
    --register, -r  : register to pypi using your .pypirc
    --help, -h      : shows this message

"""

PATH    = os.path.dirname(os.path.realpath(__file__))
os.chdir(PATH)
print "working on %s" % PATH

def clean_build(notexit=False):
    os.system('find %s -name "*.egg-info" -type d -exec rm -rf "{}" \;' % PATH)
    os.system('find %s -name "build" -type d -exec rm -rf "{}" \;' % PATH)
    os.system('find %s -name "dist" -type d -exec rm -rf "{}" \;' % PATH)
    print "cleaned"
    if not notexit: sys.exit(0)


def devinstallation(path):
    for plugin_folder in os.listdir(path):  
        if os.path.isdir(plugin_folder):
            cmd = "easy_install -m %s ; easy_install -H None -f %s -U -a --no-deps %s" % (plugin_folder, PATH, plugin_folder)
            #print cmd
            os.system(cmd)
    
def process(path, build, upload, register, clean, devinstall):
    if clean or devinstall: clean_build(devinstall)
    if devinstall: devinstallation(path)
    
    for plugin_folder in os.listdir(path):
        if os.path.isdir(plugin_folder) and plugin_folder.startswith("archipel-agent"):
            os.chdir(plugin_folder)
            if register:                os.system("python setup.py register")
            if build and not upload:    os.system("python setup.py bdist_egg")
            elif build and upload:      os.system("python setup.py bdist_egg upload")
            elif build and register:    os.system("python setup.py bdist_egg upload")
            os.chdir("..")

if __name__ == "__main__":
    build       = False
    upload      = False
    register    = False
    clean       = False
    devinstall  = False
    try:
        opts, args = getopt.getopt(sys.argv[1:], "hburcd", ["help", "build", "upload", "register", "clean", "devinstall"])
        for o, a in opts:
            if o in ("--build", "-b"):      build = True
            if o in ("--upload", "-u"):     upload = True
            if o in ("--register", "-r"):   register = True
            if o in ("--clean", "-c"):      clean = True
            if o in ("--devinstall", "-d"): devinstall = True
            if o in ("-h", "--help"):
                print HELP
                sys.exit(0)
    except Exception as ex:
        print "\033[31mERROR: %s \n\033[0m" % str(ex)
    
        
        
    process(PATH, build, upload, register, clean, devinstall)
    
