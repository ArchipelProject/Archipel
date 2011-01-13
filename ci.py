#!/usr/bin/python
# 
# ci.py
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

import os, sys, datetime, commands

BUILD_CAPPUCCINO=True
BUILD_LPKIT=True
BUILD_TNKIT=True
BUILD_VNCCAPPUCCINO=True
BUILD_STROPHECAPPUCCINO=True
BUILD_GROWLCAPPUCCINO=True
BUILD_ITUNESTABVIEW=True
BUILD_MESSAGEBOARD=True
BUILD_ARCHIPELCLIENT=True
DEPLOY_PATH="/var/www/archipelproject.org/nightlies/"

def pullSubrepo():
    global BUILD_CAPPUCCINO
    global BUILD_LPKIT
    global BUILD_TNKIT
    global BUILD_VNCCAPPUCCINO
    global BUILD_STROPHECAPPUCCINO
    global BUILD_ITUNESTABVIEW
    global BUILD_MESSAGEBOARD
    global BUILD_GROWLCAPPUCCINO
    
    os.system("echo Checking if we need to build Cappuccino...")
    ret, out = commands.getstatusoutput("cd ./Cappuccino && git pull origin master")
    if ret: sys.exit(-421)
    if "Already up-to-date." in out: BUILD_CAPPUCCINO=False
    os.system("echo build Cappuccino: %s" % (str(BUILD_CAPPUCCINO)))
    
    os.system("echo Checking if we need to build LPKit...")
    ret, out = commands.getstatusoutput("cd ./LPKit && git pull origin integ")
    if ret: sys.exit(-422)
    if "Already up-to-date." in out: BUILD_LPKIT=False
    os.system("echo build LPKit: %s" % (str(BUILD_LPKIT)))
    
    os.system("echo Checking if we need to build StropheCappuccino...")
    ret, out = commands.getstatusoutput("cd ./StropheCappuccino && git pull origin master")
    if ret: sys.exit(-423)
    if "Already up-to-date." in out: BUILD_STROPHECAPPUCCINO=False
    os.system("echo build StropheCappuccino: %s" % (str(BUILD_STROPHECAPPUCCINO)))
    
    os.system("echo Checking if we need to build TNKit...")
    ret, out = commands.getstatusoutput("cd ./TNKit && git pull origin master")
    if ret: sys.exit(-424)
    if "Already up-to-date." in out: BUILD_TNKIT=False
    os.system("echo build TNKit: %s" % (str(BUILD_TNKIT)))
    
    os.system("echo Checking if we need to build VNCCappuccino...")
    ret, out = commands.getstatusoutput("cd ./VNCCappuccino && git pull origin master")
    if ret: sys.exit(-425)
    if "Already up-to-date." in out: BUILD_VNCCAPPUCCINO=False
    os.system("echo build VNCCappuccino: %s" % (str(BUILD_VNCCAPPUCCINO)))
    
    os.system("echo Checking if we need to build GrowlCappuccino...")
    ret, out = commands.getstatusoutput("cd ./GrowlCappuccino && git pull origin master")
    if ret: sys.exit(-426)
    if "Already up-to-date." in out: BUILD_GROWLCAPPUCCINO=False
    os.system("echo build GrowlCappuccino: %s" % (str(BUILD_GROWLCAPPUCCINO)))
    
    os.system("echo Checking if we need to build iTunesTabView...")
    ret, out = commands.getstatusoutput("cd ./iTunesTabView && git pull origin master")
    if ret: sys.exit(-427)
    if "Already up-to-date." in out: BUILD_ITUNESTABVIEW=False
    os.system("echo build iTunesTabView: %s" % (str(BUILD_ITUNESTABVIEW)))
    
    os.system("echo Checking if we need to build MessageBoard...")
    ret, out = commands.getstatusoutput("cd ./MessageBoard && git pull origin master")
    if ret: sys.exit(-428)
    if "Already up-to-date." in out: BUILD_MESSAGEBOARD=False    
    os.system("echo build MessageBoard: %s" % (str(BUILD_MESSAGEBOARD)))
    
    os.system("echo Checking if we need to build ArchipelClient...")
    ret, out = commands.getstatusoutput("git pull origin master")
    if ret: sys.exit(-428)
    if "Already up-to-date." in out: BUILD_ARCHIPELCLIENT=False    
    os.system("echo build ArchipelClient: %s" % (str(BUILD_ARCHIPELCLIENT)))
    

def buildCappuccino():
    if os.system("cd ./Cappuccino && jake release && jake debug"):
        if os.system("cd ./Cappuccino && jake clean && jake release && jake debug"):
            sys.exit(-1)
    


def buildGrowlCappuccino():
    if os.system("cd ./GrowlCappuccino && jake release &&jake debug"):
        os.system("echo unable to build GrowlCappuccino")
        sys.exit(-2)


def buildiTunesTabView():
    if os.system("cd ./iTunesTabView && jake release && jake debug"):
        os.system("echo unable to build iTunesTabView")
        sys.exit(-3)


def buildLPKit():
    if os.system("cd ./LPKit && export CONFIGURATION=Debug && jake -f myJakeFile build && export CONFIGURATION=Release && jake -f myJakeFile build"):
        os.system("echo unable to build LPKit")
        sys.exit(-4)


def buildMessageBoard():
    if os.system("cd ./MessageBoard && jake release && jake debug"):
        os.system("echo unable to build MessageBoard")
        sys.exit(-5)


def buildStropheCappuccino():
    if os.system("cd ./StropheCappuccino && jake release && jake debug"):
        os.system("echo unable to build StropheCappuccino")
        sys.exit(-6)


def buildTNKit():
    if os.system("cd ./TNKit && jake release && jake debug"):
        os.system("echo unable to build TNKit")
        sys.exit(-7)


def buildVNCCappuccino():
    if os.system("cd ./VNCCappuccino && jake release && jake debug"):
        os.system("echo unable to build VNCCappuccino")
        sys.exit(-8)


def buildArchipel(export_dir, build):
    token   = datetime.datetime.now().strftime("%y%m%d-%H-%M")
    folder  = "%s/%s" % (export_dir, token)
    os.system("mkdir -p %s" % folder)
    if build: cmd = "cd ./ArchipelClient && ./buildArchipel -bag --config=release --export=%s" % folder
    else: cmd = "cd ./ArchipelClient && ./buildArchipel --config=release --export=%s" % folder
    if os.system(cmd):
        os.system(" echo unable to build ArchipelClient")
        sys.exit(-9)
    os.system("tar -czf %s/Archipel-nightly-%s.tar.gz %s" % (export_dir, token, folder))
    os.system("rm -f %s/latest-build" % (export_dir))
    os.system("ln -s %s/Archipel-nightly-%s.tar.gz %s/latest-build" % (export_dir, token, export_dir))
    os.system("rm -rf %s" % (folder))
    os.system("chown cruise:www-data %s/Archipel-nightly-%s.tar.gz)" % (export_dir, token))
    os.system("chown cruise:www-data %s/latest-build)" % (export_dir))


if __name__ == "__main__":
    """
    Simple script that can be run using CruiseControl.rb to make continuous integration
    """
    pullSubrepo()
    
    if BUILD_CAPPUCCINO:        buildCappuccino()
    if BUILD_GROWLCAPPUCCINO:   buildGrowlCappuccino()
    if BUILD_ITUNESTABVIEW:     buildiTunesTabView()
    if BUILD_LPKIT:             buildLPKit()
    if BUILD_MESSAGEBOARD:      buildMessageBoard()
    if BUILD_STROPHECAPPUCCINO: buildStropheCappuccino()
    if BUILD_TNKIT:             buildTNKit()
    if BUILD_VNCCAPPUCCINO:     buildVNCCappuccino()
    
    buildArchipel(DEPLOY_PATH, BUILD_ARCHIPELCLIENT)
    
    os.system("echo BUILD SUCESSFULL.")
    sys.exit(0)