# 
# archipelSimpleWebServer.py
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

from utils import *
import BaseHTTPServer
from threading import Thread
import os

class SimpleHTTPHandler(BaseHTTPServer.BaseHTTPRequestHandler):
    """
    Simple request handlers used by TNArchipelWebServer
    """
    server_version  = "ArchipelSimpleWebServer/1.1"
    
    def log_message(self, format, *args):
        # we do not want to log anything from here
        pass
    
    
    def parse_options(self):
        """
        Parse the parameters from the request string
        @return: a dict of parameters
        """
        parameters  = []
        options     = {}
        
        if self.path.find("?") != -1:
            (self.path, request) = self.path.split("?")
            parameters = request.split("&")
        for parameter in parameters:
            p, v = parameter.split("=")
            options[p] = v
        return options
    
    
    def do_GET(self):
        """
        perform the GET requests.
        if asked path is /, then use index.html and consider this is the VNC applet page.
        """
        log.debug("WEBSERVER: GET request received : %s" % self.path)
        
        options = self.parse_options()
        
        if self.path == "/":
            self.path = "index.html"
        
        try:
            # check if files exists
            if not os.path.exists(self.server.server_root +"/"+ self.path):
                self.send_response(404)
                self.end_headers()
                return;
                
            f = open(self.server.server_root +"/"+ self.path)
            data = f.read()
            f.close()
            
            if self.path == "index.html":
                data = data.replace("::PORT::", options["port"])
                if options.has_key("scaling"):
                    data = data.replace("::SCALE::", options["scaling"])
                else:
                    data = data.replace("::SCALE::", "100")
            
            self.send_response(200)
            self.send_header("Content-Length", os.path.getsize(self.server.server_root +"/"+ self.path))
            self.end_headers()
            self.wfile.write(data)
            
        except Exception as ex:
            self.send_response(500)
            self.end_headers()
            log.error("WEBSERVER: exception during processing GET request: %s" % str(ex))
    
    
class TNArchipelWebServer(BaseHTTPServer.HTTPServer, Thread):
    """A very very basic webserver"""

    def __init__(self, ipaddr, port, server_root):
        """
        init the web server.
        """
        self.server_root = server_root;
        BaseHTTPServer.HTTPServer.__init__(self, (ipaddr, port), SimpleHTTPHandler)
        Thread.__init__(self)
        
    
    def run(self):
        while True:
            try:
                self.serve_forever()
            except Exception as ex:
                log.error("web server crashed because (restarting...): %s" % str(ex))
        