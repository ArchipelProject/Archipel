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

FORCE=False
BUILD_CAPPUCCINO=True
BUILD_LPKIT=True
BUILD_TNKIT=True
BUILD_VNCCAPPUCCINO=True
BUILD_STROPHECAPPUCCINO=True
BUILD_GROWLCAPPUCCINO=True
BUILD_ITUNESTABVIEW=True
BUILD_MESSAGEBOARD=True
BUILD_ARCHIPELCLIENT=True
DEPLOY_PATH="/var/www/archipelproject.org/app/"
EXPORT_PATH="/var/www/archipelproject.org/nightlies/"
API_PATH="/var/www/archipelproject.org/api/"


def buildCappuccino():
    os.system("echo \* Starting to build Cappuccino")
    if os.system("cd ./Cappuccino && jake release"):
        if os.system("cd ./Cappuccino && jake clean && jake release"):
            sys.exit(-1)


def buildGrowlCappuccino():
    os.system("echo \* Starting to build GrowlCappuccino")
    if os.system("cd ./GrowlCappuccino && jake release"):
        os.system("echo \* unable to build GrowlCappuccino")
        sys.exit(-2)


def buildiTunesTabView():
    os.system("echo \* Starting to build iTunesTabView")
    if os.system("cd ./iTunesTabView && jake release"):
        os.system("echo \* unable to build iTunesTabView")
        sys.exit(-3)


def buildLPKit():
    os.system("echo \* Starting to build LPKit")
    if os.system("cd ./LPKit && export CONFIGURATION=Release && jake -f myJakeFile build"):
        os.system("echo \* unable to build LPKit")
        sys.exit(-4)


def buildMessageBoard():
    os.system("echo \* Starting to build MessageBoard")
    if os.system("cd ./MessageBoard && jake release"):
        os.system("echo \* unable to build MessageBoard")
        sys.exit(-5)


def buildStropheCappuccino():
    os.system("echo \* Starting to build StropheCappuccino")
    if os.system("cd ./StropheCappuccino && jake release"):
        os.system("echo \* unable to build StropheCappuccino")
        sys.exit(-6)


def buildTNKit():
    os.system("echo \* Starting to build TNKit")
    if os.system("cd ./TNKit && jake release"):
        os.system("echo \* unable to build TNKit")
        sys.exit(-7)


def buildVNCCappuccino():
    os.system("echo \* Starting to build VNCCappuccino")
    if os.system("cd ./VNCCappuccino && jake release"):
        os.system("echo \* unable to build VNCCappuccino")
        sys.exit(-8)


def buildArchipel(export_dir, build):
    os.system("echo \* Starting to build Archipel")
    builddate   = datetime.datetime.now().strftime("%Y%m%d%H%M")
    if os.system("cd ./ArchipelClient && ./buildArchipel -bag --config=release"):
        os.system("echo \* unable to build ArchipelClient. try to clean")
        os.system("cd ./ArchipelClient && ./buildArchipel -Cau")
        if os.system("cd ./ArchipelClient && ./buildArchipel -bag --config=release"):
            os.system("echo \* unable to build ArchipelClient. end of line.")
            sys.exit(-9)
    os.system("cd ./ArchipelClient/Build/Release/ && tar -czf %s/Archipel-nightly-%s-`git rev-parse --short HEAD`-client.tar.gz ./Archipel" % (export_dir, builddate))
    os.system("tar -czf %s/Archipel-nightly-%s-`git rev-parse --short HEAD`-server.tar.gz ./ArchipelServer" % (export_dir, builddate))
    os.system("chown cruise:www-data %sArchipel-nightly-%s-`git rev-parse --short HEAD`-client.tar.gz" % (export_dir, builddate))
    os.system("chown cruise:www-data %sArchipel-nightly-%s-`git rev-parse --short HEAD`-server.tar.gz" % (export_dir, builddate))


def deployArchipel(deploy_dir):
    os.system("echo \* Starting to deploy Archipel into app.archipelproject.org")
    os.system("rm -rf %s/*" % deploy_dir)
    os.system("echo 'deploying new build, please reload in a moment' > %s/index.txt" % deploy_dir)
    os.system("cp -a ./ArchipelClient/Build/Release/Archipel/* %s" % deploy_dir)
    os.system("chown -R cruise:www-data %s/*" % deploy_dir)
    os.system("chmod 755 -R %s/*" % deploy_dir)
    os.system("find %s/* -exec touch {} \;" % deploy_dir)
    os.system("rm -f %s/index.txt" % deploy_dir)

def generateAPI(api_dir):
    os.system("echo \* Starting to generate documentation")
    os.system("rm -rf %s/*" % api_dir)
    
    os.system("echo \* Generating doc for Archipel")
    os.system("mkdir -p %s/archipel" % api_dir)
    os.system("cd ArchipelClient; jake docs")
    os.system("cp -a ArchipelClient/Build/Documentation/html/* %s/archipel/" % api_dir)
    os.system("chown -R cruise:www-data %s/archipel/" % api_dir)
    
    os.system("echo \* Generating doc for StropheCappuccino")
    os.system("mkdir -p %s/strophecappuccino" % api_dir)
    os.system("cd StropheCappuccino; jake docs")
    os.system("cp -a StropheCappuccino/Build/Documentation/html/* %s/strophecappuccino/" % api_dir)
    os.system("chown -R cruise:www-data %s/strophecappuccino/" % api_dir)
    
    os.system("echo \* Generating doc for VNCCappuccino")
    os.system("mkdir -p %s/vnccappuccino" % api_dir)
    os.system("cd VNCCappuccino; jake docs")
    os.system("cp -a VNCCappuccino/Build/Documentation/html/* %s/vnccappuccino/" % api_dir)
    os.system("chown -R cruise:www-data %s/vnccappuccino/" % api_dir)
    
    os.system("echo \* Generating doc for GrowlCappuccino")
    os.system("mkdir -p %s/growlcappuccino" % api_dir)
    os.system("cd GrowlCappuccino; jake docs")
    os.system("cp -a GrowlCappuccino/Build/Documentation/html/* %s/growlcappuccino/" % api_dir)
    os.system("chown -R cruise:www-data %s/growlcappuccino/" % api_dir)
    
    os.system("echo \* Generating doc for iTunesTabView")
    os.system("mkdir -p %s/itunestabview" % api_dir)
    os.system("cd iTunesTabView; jake docs")
    os.system("cp -a iTunesTabView/Build/Documentation/html/* %s/itunestabview/" % api_dir)
    os.system("chown -R cruise:www-data %s/itunestabview/" % api_dir)
    
    os.system("echo \* Generating doc for MessageBoard")
    os.system("mkdir -p %s/messageboard" % api_dir)
    os.system("cd MessageBoard; jake docs")
    os.system("cp -a MessageBoard/Build/Documentation/html/* %s/messageboard/" % api_dir)
    os.system("chown -R cruise:www-data %s/messageboard/" % api_dir)
    
    os.system("echo \* Generating doc for TNKit")
    os.system("mkdir -p %s/tnkit" % api_dir)
    os.system("cd TNKit; jake docs")
    os.system("cp -a TNKit/Build/Documentation/html/* %s/tnkit/" % api_dir)
    os.system("chown -R cruise:www-data %s/tnkit/" % api_dir)
    
    os.system("echo \* Documentation generation complete")



if __name__ == "__main__":
    """
    Simple script that can be run using CruiseControl.rb to make continuous integration
    """
    
    ret, out = commands.getstatusoutput("git log -n1")
    if "#nobuild" in out:
        os.system("echo \* Build skipped according to last commit message (contains #nobuild)")
        sys.exit(0)
    
    if BUILD_CAPPUCCINO or FORCE:        buildCappuccino()
    if BUILD_GROWLCAPPUCCINO or FORCE:   buildGrowlCappuccino()
    if BUILD_ITUNESTABVIEW or FORCE:     buildiTunesTabView()
    if BUILD_LPKIT or FORCE:             buildLPKit()
    if BUILD_MESSAGEBOARD or FORCE:      buildMessageBoard()
    if BUILD_STROPHECAPPUCCINO or FORCE: buildStropheCappuccino()
    if BUILD_TNKIT or FORCE:             buildTNKit()
    if BUILD_VNCCAPPUCCINO or FORCE:     buildVNCCappuccino()
    
    buildArchipel(EXPORT_PATH, BUILD_ARCHIPELCLIENT)
    deployArchipel(DEPLOY_PATH)
    generateAPI(API_PATH)
    
    os.system("echo \* BUILD SUCESSFULL.")
    sys.exit(0)