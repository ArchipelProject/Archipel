#!/usr/bin/python
#
# trinitySimpleWebServer.py
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

import  BaseHTTPServer
from threading import Thread

class TThreadedWebServer(Thread):
    """
    this class is used to run the webserver in a thread.
    """
    def __init__(self, port):
        """
        the contructor of the class
        @type jid: string
        @param jid: the jid of the L{TrinityVM} 
        @type password: string
        @param password: the password associated to the JID
        """
        self.httpd = SimpleWebServer(port);
        Thread.__init__(self)
    
    def run(self):
        """
        overiddes sur super class method. run the server
        """
        self.httpd.run()


class SimpleHTTPHandler(BaseHTTPServer.BaseHTTPRequestHandler):
    server_version  = "MyHandler/1.1"
    server_root     = "./www/"
    
    def do_GET(self):
        parameters  = [];
        options     = {};
        if self.path.find("?") != -1:
            (self.path, request) = self.path.split("?");
            parameters = request.split("&");
        
        for parameter in parameters:
            p, v = parameter.split("=");
            options[p] = v;
        
        if self.path == "/":
            self.path = "index.html";

        try:
            f = open(self.server_root + self.path);
            data = f.read();
            if self.path == "index.html":
                data = data.replace("::PORT::", options["port"])
            self.wfile.write(data);
            f.close()
        except:
            pass;
    
    
class SimpleWebServer:
    """A very very basic webserver..."""

    def __init__(self, port):
        """
        init the web server.
        """
        self.addr = ('', port);
    
    def run(self):
        self.http_server = BaseHTTPServer.HTTPServer(self.addr, SimpleHTTPHandler);
        self.http_server.serve_forever()

        
        
        
            
            
        
        
        