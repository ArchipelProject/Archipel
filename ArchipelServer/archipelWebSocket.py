#!/usr/bin/python

'''
Python WebSocket library with support for "wss://" encryption.

You can make a cert/key with openssl using:
openssl req -new -x509 -days 365 -nodes -out self.pem -keyout self.pem
as taken from http://docs.python.org/dev/library/ssl.html#certificates

this code has been rewrited by antoine mercadal in order to make a usable class
'''


import sys, socket, ssl, struct, traceback
# import os, resource, errno, signal # daemonizing
from base64 import b64encode, b64decode
from hashlib import md5
import threading
import sys, socket, ssl, optparse
from select import select
from utils import *

class TNArchipelWebSocket(threading.Thread):
    
    def __init__(self, target_host, target_port, listen_host, listen_port, certfile=None, onlySSL=False):
        threading.Thread.__init__(self)
        self._stop          = threading.Event()
        self.target_port    = target_port
        self.target_host    = target_host
        self.cert           = certfile;
        self.listen_host    = listen_host
        self.listen_port    = listen_port
        self.ssl_only       = onlySSL
        self.buffer_size    = 65536
        self.csock          = None
        self.startsock      = None
        
        self.client_settings = {
            'b64encode'   : False
        }
        
        self.server_handshake = """HTTP/1.1 101 Web Socket Protocol Handshake\r
Upgrade: WebSocket\r
Connection: Upgrade\r
%sWebSocket-Origin: %s\r
%sWebSocket-Location: %s://%s%s\r
%sWebSocket-Protocol: sample\r
\r
%s"""
        self.policy_response = """<cross-domain-policy><allow-access-from domain="*" to-ports="*" /></cross-domain-policy>\n"""
    
    
    def encode(self, buf):
        if self.client_settings['b64encode']:
            buf = b64encode(buf)
        else:
            # Modified UTF-8 encode
            buf = buf.decode('latin-1').encode('utf-8').replace("\x00", "\xc4\x80")
        
        return "\x00%s\xff" % buf
    
    
    def decode(self, buf):
        """ Parse out WebSocket packets. """
        if buf.count('\xff') > 1:
            if self.client_settings['b64encode']:
                return [b64decode(d[1:]) for d in buf.split('\xff')]
            else:
                # Modified UTF-8 decode
                return [d[1:].replace("\xc4\x80", "\x00").decode('utf-8').encode('latin-1') for d in buf.split('\xff')]
        else:
            if self.client_settings['b64encode']:
                return [b64decode(buf[1:-1])]
            else:
                return [buf[1:-1].replace("\xc4\x80", "\x00").decode('utf-8').encode('latin-1')]
    
    
    def parse_handshake(self, handshake):
        ret = {}
        req_lines = handshake.split("\r\n")
        if not req_lines[0].startswith("GET "):
            raise Exception("Invalid handshake: no GET request line")
        ret['path'] = req_lines[0].split(" ")[1]
        for line in req_lines[1:]:
            if line == "": break
            var, delim, val = line.partition(": ")
            ret[var] = val
            
        if req_lines[-2] == "":
            ret['key3'] = req_lines[-1]
            
        return ret
    
    
    def gen_md5(self, keys):
        key1 = keys['Sec-WebSocket-Key1']
        key2 = keys['Sec-WebSocket-Key2']
        key3 = keys['key3']
        spaces1 = key1.count(" ")
        spaces2 = key2.count(" ")
        num1 = int("".join([c for c in key1 if c.isdigit()])) / spaces1
        num2 = int("".join([c for c in key2 if c.isdigit()])) / spaces2
            
        return md5(struct.pack('>II8s', num1, num2, key3)).digest()
    
    
    def do_handshake(self, sock):
        self.client_settings['b64encode'] = False
        
        # Peek, but don't read the data
        handshake = sock.recv(1024, socket.MSG_PEEK)
        log.info("WEBSOCKETPROXY: Handshake [%s]" % repr(handshake))
        if handshake == "":
            # print "Ignoring empty handshake"
            sock.close()
            return False
        elif handshake.startswith("<policy-file-request/>"):
            handshake = sock.recv(1024)
            # print "Sending flash policy response"
            sock.send(self.policy_response)
            sock.close()
            return False
        elif handshake.startswith("\x16"):
            retsock = ssl.wrap_socket(
                    sock,
                    server_side=True,
                    certfile=self.cert,
                    ssl_version=ssl.PROTOCOL_TLSv1)
            scheme = "wss"
            log.info("WEBSOCKETPROXY: using SSL socket PROTOCOL_TLSv1")
        elif handshake.startswith("\x80"):
            retsock = ssl.wrap_socket(
                    sock,
                    server_side=True,
                    certfile=self.cert,
                    ssl_version=ssl.PROTOCOL_SSLv23)
            scheme = "wss"
            log.info("WEBSOCKETPROXY: using SSL socket PROTOCOL_SSLv23")
        elif self.ssl_only:
            log.info("WEBSOCKETPROXY: Non-SSL connection disallowed")
            sock.close()
            return False
        else:
            retsock = sock
            scheme = "ws"
            log.info("WEBSOCKETPROXY: using plain (non SSL) socket")
        
        handshake = retsock.recv(4096)
        h = self.parse_handshake(handshake)
        
        
        # Parse client settings from the GET path
        cvars = h['path'].partition('?')[2].partition('#')[0].split('&')
        for cvar in [c for c in cvars if c]:
            name, _, val = cvar.partition('=')
            if name not in ['b64encode']: continue
            value = val and val or True
            self.client_settings[name] = value
            # print "  %s=%s" % (name, value)
        
        
        if h.get('key3'):
            trailer = self.gen_md5(h)
            pre = "Sec-"
            # print "  using protocol version 76"
        else:
            trailer = ""
            pre = ""
            # print "  using protocol version 75"
        
        response = self.server_handshake % (pre, h['Origin'], pre, scheme,
                h['Host'], h['path'], pre, trailer)
        
        ## print "sending response:", repr(response)
        retsock.send(response)
        
        return retsock
    
    
    def do_proxy(self, client, target):
        """ Proxy WebSocket to normal socket. """
        cqueue = []
        cpartial = ""
        tqueue = []
        rlist = [client, target]
        
        while True:
            wlist = []
            if tqueue: wlist.append(target)
            if cqueue: wlist.append(client)
            ins, outs, excepts = select(rlist, wlist, [], 1)
            if excepts: raise Exception("Socket exception")
                
            if target in outs:
                dat = tqueue.pop(0)
                sent = target.send(dat)
                if sent == len(dat):
                    pass
                else:
                    tqueue.insert(0, dat[sent:])
                ##if rec: rec.write("Target send: %s\n" % map(ord, dat))
                
            if client in outs:
                dat = cqueue.pop(0)
                sent = client.send(dat)
                if not sent == len(dat):
                    cqueue.insert(0, dat[sent:])
                    ##if rec: rec.write("Client send partial: %s\n" % repr(dat[0:send]))
                
            if target in ins:
                buf = target.recv(self.buffer_size)
                if len(buf) == 0: raise Exception("Target closed")
                
                cqueue.append(self.encode(buf))
                ##if rec: rec.write("Target recv (%d): %s\n" % (len(buf), map(ord, buf)))
                
            if client in ins:
                buf = client.recv(self.buffer_size)
                if len(buf) == 0: raise Exception("Client closed")
                
                if buf[-1] == '\xff':
                    ##if rec: rec.write("Client recv (%d): %s\n" % (len(buf), repr(buf)))
                    if cpartial:
                        tqueue.extend(self.decode(cpartial + buf))
                        cpartial = ""
                    else:
                        tqueue.extend(self.decode(buf))
                else:
                    ##if rec: rec.write("Client recv partial (%d): %s\n" % (len(buf), repr(buf)))
                    cpartial = cpartial + buf
    
    
    def proxy_handler(self, client):
        # print "Connecting to: %s:%s" % (self.target_host, self.target_port)
        tsock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        tsock.connect((self.target_host, self.target_port))
        
        try:
            self.do_proxy(client, tsock)
        except:
            if tsock: tsock.close()
            raise
    
    
    def run(self):
        # if self.settings['daemon']: daemonize()
        # print "NOVNC : server started"
        try:
            lsock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            lsock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
            lsock.bind((self.listen_host, self.listen_port))
            lsock.listen(100)
            
            while True:
                try:
                    self.csock = self.startsock = None
                    # print 'waiting for connection on port %s' % self.listen_port
                    #FIXME : log.debug this
                    log.info("WEBSOCKETPROXY: waiting for connection on port %s" % self.listen_port)
                    startsock, address = lsock.accept()
                    # print 'Got client connection from %s' % address[0]
                    log.info("WEBSOCKETPROXY: Got client connection from %s" % address[0])
                    self.csock = self.do_handshake(startsock)
                    if not self.csock: continue
                
                    self.proxy_handler(self.csock)
                
                except Exception as ex:
                    log.warn("WEBSOCKETPROXY: connection interrupted: %s" % str(ex))
                    #print "Ignoring exception:"
                    #print traceback.format_exc()
                    if self.csock: self.csock.close()
                    if self.startsock and self.startsock != self.csock: self.startsock.close()
        except Exception as ex:
            log.error("WEBSOCKETPROXY: loop exception: %s" % str(ex))
    
    def stop(self):
        log.info("WEBSOCKETPROXY: thread stopped")
        if self.csock : self.csock.close()
        if self.startsock and self.startsock != self.csock: self.startsock.close()
        self._stop.set()

