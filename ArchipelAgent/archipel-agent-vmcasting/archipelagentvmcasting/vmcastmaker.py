# -*- coding: utf-8 -*-
#
# vmcastmaker.py
#
# Copyright (C) 2010 Antoine Mercadal <antoine.mercadal@inframonde.eu>
# This file is part of ArchipelProject
# http://archipelproject.org
#
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

import datetime
import os
import uuid


class VMCastMaker:
    def __init__(self, title, uuid, description, language, baseserverurl, basepath):
        self.baseserverurl  = baseserverurl
        self.basepath       = basepath
        self.title          = title
        self.uuid           = uuid
        self.description    = description
        self.language       = language
        self.items          = []

    def init_feed(self):
        self.feed =  "<?xml version='1.0' encoding='utf-8'?>\n"
        self.feed += "   <rss version='2.0'>\n"
        self.feed += "   <channel>\n"
        self.feed += "        <title>" + self.title + "</title>\n"
        self.feed += "        <link>" + self.baseserverurl + "</link>\n"
        self.feed += "        <uuid>" +  self.uuid + "</uuid>\n"
        self.feed += "        <description>" + self.description + "</description>\n"
        self.feed += "        <language>" + self.language +"</language>\n"


    def add_item(self, title, description, link, uuid, dlurl, size):
        self.items.append({ 'title'         : title,
                            'description'   : description,
                            'link'          : link,
                            'uuid'          : uuid,
                            'dlurl'         : dlurl,
                            'size'          : size})

    def makeVMCast(self):
        for item in self.items:
            item_string =   "        <item>\n"
            item_string +=   "            <title>" + item['title'] + "</title>\n"
            item_string +=   "            <link>" + item['link'] + "</link>\n"
            item_string +=   "            <uuid>" + item['uuid'] + "</uuid>\n"
            item_string +=   "            <enclosure url='" + item['dlurl'] + "' length='" + item['size'] + "' type='application/enomalism2-xvm2'/>\n"
            item_string +=   "            <description>\n            <![CDATA[\n                " +item['description'] + "\n            ]]>\n            </description>\n"
            item_string +=   "            <pubDate>" + str(datetime.datetime.now()) + "</pubDate>\n"
            item_string +=   "        </item>\n"
            self.feed += item_string
        self.feed += "    </channel>\n</rss>"
        return self.feed

    def writeFeed(self, path="./rss.xml"):
        f = open(path, "w")
        f.write(self.makeVMCast())
        f.close()

    def parseDirectory(self, path="."):
        self.init_feed()
        self.items = []
        xvm2_files = [x for x in os.listdir(path) if x.endswith('.xvm2')]
        for xvm2_file in xvm2_files:
            size = os.path.getsize(path + "/" + xvm2_file)
            item_uuid = uuid.uuid3(uuid.NAMESPACE_URL, xvm2_file)
            self.add_item(xvm2_file.replace('.xvm2', ''),
                            'Auto imported vmcast',
                            self.baseserverurl,
                            str(item_uuid),
                            self.baseserverurl + "/" + xvm2_file,
                            str(size))