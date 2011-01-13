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

import os, sys, datetime

def pullSubrepo():
    if os.system("cd Cappuccino; git pull"): sys.exit(-42)
    if os.system("cd LPKit; git pull"): sys.exit(-42)
    if os.system("cd StropheCappuccino; git pull"): sys.exit(-42)
    if os.system("cd TNKit; git pull"): sys.exit(-42)
    if os.system("cd VNCCappuccino; git pull"): sys.exit(-42)
    if os.system("cd GrowlCappuccino; git pull"): sys.exit(-42)
    if os.system("cd iTunesTabView; git pull"): sys.exit(-42)
    if os.system("cd MessageBoard; git pull"): sys.exit(-42)
    


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
    if os.system("cd ./LPKit; export CONFIG=Debug && jake -f myJakeFile build && export CONFIG=Release && jake -f myJakeFile build;"):
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


def buildArchipel(export_dir="/var/www/archipelproject.org/nigthlies"):
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
    buildCappuccino()
    buildGrowlCappuccino()
    buildiTunesTabView()
    buildLPKit()
    buildMessageBoard()
    buildStropheCappuccino()
    buildTNKit()
    buildVNCCappuccino()
    if len(sys.argv) > 1: buildArchipel(sys.argv[1])
    else: buildArchipel()
    sys.exit(0)