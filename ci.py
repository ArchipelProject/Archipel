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

def pullSubrepo():
    global BUILD_CAPPUCCINO
    global BUILD_LPKIT
    global BUILD_TNKIT
    global BUILD_VNCCAPPUCCINO
    global BUILD_STROPHECAPPUCCINO
    global BUILD_ITUNESTABVIEW
    global BUILD_MESSAGEBOARD
    global BUILD_GROWLCAPPUCCINO
    
    print "Checking if we need to build Cappuccino..."
    ret, out = commands.getstatusoutput("cd ./Cappuccino; git pull origin master")
    if ret: sys.exit(-421)
    if "Already up-to-date." in out: BUILD_CAPPUCCINO=False
    print "build Cappuccino: %s" % (str(BUILD_CAPPUCCINO))
    
    print "Checking if we need to build LPKit..."
    ret, out = commands.getstatusoutput("cd ./LPKit; git pull origin integ")
    if ret: sys.exit(-422)
    if "Already up-to-date." in out: BUILD_LPKIT=False
    print "build LPKit: %s" % (str(BUILD_LPKIT))
    
    print "Checking if we need to build StropheCappuccino..."
    ret, out = commands.getstatusoutput("cd ./StropheCappuccino; git pull origin master")
    if ret: sys.exit(-423)
    if "Already up-to-date." in out: BUILD_STROPHECAPPUCCINO=False
    print "build StropheCappuccino: %s" % (str(BUILD_STROPHECAPPUCCINO))
    
    print "Checking if we need to build TNKit..."
    ret, out = commands.getstatusoutput("cd ./TNKit; git pull origin master")
    if ret: sys.exit(-424)
    if "Already up-to-date." in out: BUILD_TNKIT=False
    print "build TNKit: %s" % (str(BUILD_TNKIT))
    
    print "Checking if we need to build VNCCappuccino..."
    ret, out = commands.getstatusoutput("cd ./VNCCappuccino; git pull origin master")
    if ret: sys.exit(-425)
    if "Already up-to-date." in out: BUILD_VNCCAPPUCCINO=False
    print "build VNCCappuccino: %s" % (str(BUILD_VNCCAPPUCCINO))
    
    print "Checking if we need to build GrowlCappuccino..."
    ret, out = commands.getstatusoutput("cd ./GrowlCappuccino; git pull origin master")
    if ret: sys.exit(-426)
    if "Already up-to-date." in out: BUILD_GROWLCAPPUCCINO=False
    print "build GrowlCappuccino: %s" % (str(BUILD_GROWLCAPPUCCINO))
    
    print "Checking if we need to build iTunesTabView..."
    ret, out = commands.getstatusoutput("cd ./iTunesTabView; git pull origin master")
    if ret: sys.exit(-427)
    if "Already up-to-date." in out: BUILD_ITUNESTABVIEW=False
    print "build iTunesTabView: %s" % (str(BUILD_ITUNESTABVIEW))
    
    print "Checking if we need to build MessageBoard..."
    ret, out = commands.getstatusoutput("cd ./MessageBoard; git pull origin master")
    if ret: sys.exit(-428)
    if "Already up-to-date." in out: BUILD_MESSAGEBOARD=False    
    print "build MessageBoard: %s" % (str(BUILD_MESSAGEBOARD))


def buildCappuccino():
    if os.system("cd ./Cappuccino && jake release && jake debug"):
        if os.system("cd ./Cappuccino && jake clean && jake release && jake debug"):
            sys.exit(-1)
    


def buildGrowlCappuccino():
    if os.system("cd ./GrowlCappuccino && jake release &&jake debug"):
        print "unable to build GrowlCappuccino";
        sys.exit(-2)


def buildiTunesTabView():
    if os.system("cd ./iTunesTabView && jake release && jake debug"):
        print "unable to build iTunesTabView";
        sys.exit(-3)


def buildLPKit():
    if os.system("cd ./LPKit; export CONFIGURATION=Debug && jake -f myJakeFile build && export CONFIGURATION=Release && jake -f myJakeFile build;"):
        print "unable to build LPKit";
        sys.exit(-4)


def buildMessageBoard():
    if os.system("cd ./MessageBoard; jake release; jake debug"):
        print "unable to build MessageBoard";
        sys.exit(-5)


def buildStropheCappuccino():
    if os.system("cd ./StropheCappuccino; jake release; jake debug"):
        print "unable to build StropheCappuccino";
        sys.exit(-6)


def buildTNKit():
    if os.system("cd ./TNKit; jake release; jake debug"):
        print "unable to build TNKit";
        sys.exit(-7)


def buildVNCCappuccino():
    if os.system("cd ./VNCCappuccino; jake release; jake debug"):
        print "unable to build VNCCappuccino";
        sys.exit(-8)


def buildArchipel(export_dir="/var/www/archipelproject.org/nightlies"):
    folder = "%s/%s" % (export_dir, datetime.datetime.now().strftime("%y%m%d-%H:%M"))
    os.system("mkdir -p %s" % folder)
    if os.system("cd ./ArchipelClient; ./buildArchipel -bag --config=release --export=%s" % folder):
        print "unable to build VNCCappuccino";
        sys.exit(-9)
    


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
    
    if len(sys.argv) > 1: buildArchipel(sys.argv[1])
    else: buildArchipel()
    
    print "BUILD SUCESSFULL."
    sys.exit(0)