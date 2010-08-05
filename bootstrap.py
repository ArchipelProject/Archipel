#!/usr/bin/python

import os, sys


def test_capp():
    return os.path.exists("/usr/local/narwhal/bin/capp")


def build_strophecappuccino():
    print "* Building StropheCappuccino";
    os.system("cd ./StropheCappuccino && export CONFIG=Debug && jake && export CONFIG=Release && jake;")
    print "* StropheCappuccino builded"


def build_growlcappuccino():
    print "* Building GrowlCappuccino";
    os.system("cd ./GrowlCappuccino && export CONFIG=Debug && jake && export CONFIG=Release && jake;")
    print "* GrowlCappuccino builded"


def build_vnccappuccino():
    print "* Building VNCCappuccino";
    os.system("cd ./VNCCappuccino && export CONFIG=Debug && jake && export CONFIG=Release && jake;")
    print "* VNCCappuccino builded"



def build_archipel():
    print "* Building ArchipelClient"
    os.system("cd ./ArchipelClient && ./buildArchipel -bag --config=Release")
    print "* ArchipelClient built"


def apply_cappuccino_frameworks():
    print "* Adding Cappuccino framework"
    os.system("/usr/local/narwhal/bin/capp gen -f ./ArchipelClient")
    print "* Cappuccino added"

if __name__ == "__main__":
    if not test_capp(): 
        print "ERROR: you need cappuccino environment to build Archipel"
        sys.exit(1)
    
    build_growlcappuccino()
    build_vnccappuccino()
    build_strophecappuccino()
    build_archipel()
    apply_cappuccino_frameworks()
    
    print "* build complete"
    
