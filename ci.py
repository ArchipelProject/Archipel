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

CONFIGURATION="debug"
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
EXPORT_PATH="/var/www/archipelproject.org/nightlies/old/"
API_PATH="/var/www/archipelproject.org/api/"


def buildCappuccino():
    os.system("echo \* Starting to build Cappuccino")
    if os.system("cd ./ArchipelClient/Libraries/Cappuccino && jake release && jake debug"):
        if os.system("cd ./ArchipelClient/Libraries/Cappuccino && jake clean && jake release && jake debug"):
            sys.exit(-1)


def buildGrowlCappuccino():
    os.system("echo \* Starting to build GrowlCappuccino")
    if os.system("cd ./ArchipelClient/Libraries/GrowlCappuccino && jake release && jake debug"):
        os.system("echo \* unable to build GrowlCappuccino")
        sys.exit(-2)


def buildiTunesTabView():
    os.system("echo \* Starting to build iTunesTabView")
    if os.system("cd ./ArchipelClient/Libraries/iTunesTabView && jake release && jake debug"):
        os.system("echo \* unable to build iTunesTabView")
        sys.exit(-3)


def buildLPKit():
    os.system("echo \* Starting to build LPKit")
    if os.system("cd ./ArchipelClient/Libraries/LPKit && export CONFIGURATION=Release && jake -f myJakeFile build  && export CONFIGURATION=Debug && jake -f myJakeFile build"):
        os.system("echo \* unable to build LPKit")
        sys.exit(-4)


def buildMessageBoard():
    os.system("echo \* Starting to build MessageBoard")
    if os.system("cd ./ArchipelClient/Libraries/MessageBoard && jake release && jake debug"):
        os.system("echo \* unable to build MessageBoard")
        sys.exit(-5)


def buildStropheCappuccino():
    os.system("echo \* Starting to build StropheCappuccino")
    if os.system("cd ./ArchipelClient/Libraries/StropheCappuccino && jake release && jake debug"):
        os.system("echo \* unable to build StropheCappuccino")
        sys.exit(-6)


def buildTNKit():
    os.system("echo \* Starting to build TNKit")
    if os.system("cd ./ArchipelClient/Libraries/TNKit && jake release && jake debug"):
        os.system("echo \* unable to build TNKit")
        sys.exit(-7)


def buildVNCCappuccino():
    os.system("echo \* Starting to build VNCCappuccino")
    if os.system("cd ./ArchipelClient/Libraries/VNCCappuccino && jake release && jake debug"):
        os.system("echo \* unable to build VNCCappuccino")
        sys.exit(-8)


def buildArchipel(export_dir, build):
    os.system("echo \* Starting to build Archipel")
    rev = commands.getoutput("git rev-parse --short HEAD");
    builddate   = datetime.datetime.now().strftime("%Y%m%d%H%M")
    # os.system("rm -rf ./ArchipelClient/Build")
    # os.system("cd ./ArchipelClient && ./buildArchipel -Cau --config=%s" % CONFIGURATION)
    # if os.system("cd ./ArchipelClient && ./buildArchipel -bag --config=%s" % CONFIGURATION):
    #     os.system("echo \* unable to build ArchipelClient. end of line.")
    #     sys.exit(-9)
    os.system("cd ./ArchipelClient/Build/%s/ && tar -czf %s/Archipel-nightly-%s-%s-client.tar.gz ./Archipel" % (CONFIGURATION.capitalize(), export_dir, builddate, rev))
    os.system("tar -czf %s/Archipel-nightly-%s-%s-server.tar.gz ./ArchipelServer" % (export_dir, builddate, rev))
    os.system("cd %s/.. && rm -f latest-archipel-server.tar.gz" % (export_dir))
    os.system("cd %s/.. && rm -f latest-archipel-client.tar.gz" % (export_dir))
    os.system("cd %s/.. && ln -s old/Archipel-nightly-%s-%s-server.tar.gz latest-archipel-server.tar.gz" % (export_dir, builddate, rev))
    os.system("cd %s/.. && ln -s old/Archipel-nightly-%s-%s-client.tar.gz latest-archipel-client.tar.gz" % (export_dir, builddate, rev))
    os.system("chown cruise:www-data %sArchipel-nightly-%s-%rev-client.tar.gz" % (export_dir, builddate, rev))
    os.system("chown cruise:www-data %sArchipel-nightly-%s-%s-server.tar.gz" % (export_dir, builddate, rev))


def deployArchipel(deploy_dir):
    os.system("echo \* Starting to deploy Archipel into app.archipelproject.org")
    os.system("rm -rf %s/*" % deploy_dir)
    os.system("echo 'deploying new build, please reload in a moment' > %s/index.txt" % deploy_dir)
    os.system("cp -a ./ArchipelClient/Build/%s/Archipel/* %s" % (CONFIGURATION.capitalize(), deploy_dir))
    os.system("chown -R cruise:www-data %s/*" % deploy_dir)
    os.system("chmod 755 -R %s/*" % deploy_dir)
    os.system("find %s/* -exec touch {} \;" % deploy_dir)
    os.system("rm -f %s/index.txt" % deploy_dir)


def generateAPI(api_dir):
    os.system("echo \* Starting to generate documentation")
    os.system("rm -rf %s/*" % api_dir)
    
    os.system("echo \* Generating doc for ArchipelClient")
    os.system("mkdir -p %s/archipel-client" % api_dir)
    os.system("cd ArchipelClient; jake docs")
    os.system("cp -a ArchipelClient/Build/Documentation/html/* %s/archipel-client/" % api_dir)
    os.system("chown -R cruise:www-data %s/archipel-client/" % api_dir)
    
    os.system("echo \* Generating doc for StropheCappuccino")
    os.system("mkdir -p %s/strophecappuccino" % api_dir)
    os.system("cd ./ArchipelClient/Libraries/StropheCappuccino; jake docs")
    os.system("cp -a ./ArchipelClient/Libraries/StropheCappuccino/Build/Documentation/html/* %s/strophecappuccino/" % api_dir)
    os.system("chown -R cruise:www-data %s/strophecappuccino/" % api_dir)
    
    os.system("echo \* Generating doc for VNCCappuccino")
    os.system("mkdir -p %s/vnccappuccino" % api_dir)
    os.system("cd ./ArchipelClient/Libraries/VNCCappuccino; jake docs")
    os.system("cp -a ./ArchipelClient/Libraries/VNCCappuccino/Build/Documentation/html/* %s/vnccappuccino/" % api_dir)
    os.system("chown -R cruise:www-data %s/vnccappuccino/" % api_dir)
    
    os.system("echo \* Generating doc for GrowlCappuccino")
    os.system("mkdir -p %s/growlcappuccino" % api_dir)
    os.system("cd ./ArchipelClient/Libraries/GrowlCappuccino; jake docs")
    os.system("cp -a ./ArchipelClient/Libraries/GrowlCappuccino/Build/Documentation/html/* %s/growlcappuccino/" % api_dir)
    os.system("chown -R cruise:www-data %s/growlcappuccino/" % api_dir)
    
    os.system("echo \* Generating doc for iTunesTabView")
    os.system("mkdir -p %s/itunestabview" % api_dir)
    os.system("cd ./ArchipelClient/Libraries/iTunesTabView; jake docs")
    os.system("cp -a ./ArchipelClient/Libraries/iTunesTabView/Build/Documentation/html/* %s/itunestabview/" % api_dir)
    os.system("chown -R cruise:www-data %s/itunestabview/" % api_dir)
    
    os.system("echo \* Generating doc for MessageBoard")
    os.system("mkdir -p %s/messageboard" % api_dir)
    os.system("cd ./ArchipelClient/Libraries/MessageBoard; jake docs")
    os.system("cp -a ./ArchipelClient/Libraries/MessageBoard/Build/Documentation/html/* %s/messageboard/" % api_dir)
    os.system("chown -R cruise:www-data %s/messageboard/" % api_dir)
    
    os.system("echo \* Generating doc for TNKit")
    os.system("mkdir -p %s/tnkit" % api_dir)
    os.system("cd ./ArchipelClient/Libraries/TNKit; jake docs")
    os.system("cp -a ./ArchipelClient/Libraries/TNKit/Build/Documentation/html/* %s/tnkit/" % api_dir)
    os.system("chown -R cruise:www-data %s/tnkit/" % api_dir)
    
    os.system("echo \* Generating doc for ArchipelServer")
    os.system("mkdir -p %s/archipel-server" % api_dir)
    os.system("cd ArchipelServer; epydoc .")
    os.system("cp -a ArchipelServer/html/* %s/archipel-server/" % api_dir)
    os.system("chown -R cruise:www-data %s/archipel-server/" % api_dir)
    
    
    os.system("echo \* Documentation generation complete")



if __name__ == "__main__":
    """
    Simple script that can be run using CruiseControl.rb to make continuous integration
    """
    
    ret, out = commands.getstatusoutput("git log -n1")
    if "#nobuild" in out:
        os.system("echo \* Build skipped according to last commit message (contains #nobuild)")
        sys.exit(0)
    
    # if BUILD_CAPPUCCINO or FORCE:        buildCappuccino()
    # if BUILD_GROWLCAPPUCCINO or FORCE:   buildGrowlCappuccino()
    # if BUILD_ITUNESTABVIEW or FORCE:     buildiTunesTabView()
    # if BUILD_LPKIT or FORCE:             buildLPKit()
    # if BUILD_MESSAGEBOARD or FORCE:      buildMessageBoard()
    # if BUILD_STROPHECAPPUCCINO or FORCE: buildStropheCappuccino()
    # if BUILD_TNKIT or FORCE:             buildTNKit()
    # if BUILD_VNCCAPPUCCINO or FORCE:     buildVNCCappuccino()
    # 
    buildArchipel(EXPORT_PATH, BUILD_ARCHIPELCLIENT)
    deployArchipel(DEPLOY_PATH)
    generateAPI(API_PATH)
    
    os.system("echo \* BUILD SUCESSFULL.")
    sys.exit(0)