# -*- coding: utf-8 -*-
#
# archipelWebSocket.py
#
# Copyright (C) 2010 Antoine Mercadal <antoine.mercadal@inframonde.eu>
# Copyright, 2011 - Franck Villaume <franck.villaume@trivialdev.com>
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

import socket, ssl, struct
import thread
import threading
from base64 import b64encode, b64decode
from hashlib import md5
from select import select

from archipelcore.utils import log

WEBPROXY_HANDSHAKE = """HTTP/1.1 101 Web Socket Protocol Handshake\r
Upgrade: WebSocket\r
Connection: Upgrade\r
%sWebSocket-Origin: %s\r
%sWebSocket-Location: %s://%s%s\r
%sWebSocket-Protocol: sample\r
\r
%s"""



class TNArchipelWebSocket (threading.Thread):
    """
    Python WebSocket library with support for "wss://" encryption.

    You can make a cert/key with openssl using:
    openssl req -new -x509 -days 365 -nodes -out self.pem -keyout self.pem
    as taken from http://docs.python.org/dev/library/ssl.html#certificates

    Original code from Kanaka (Joel Martin).
    This code has been rewrited by antoine mercadal in order to make a usable class with Archipel.
    """

    def __init__(self, target_host, target_port, listen_host, listen_port, certfile=None, onlySSL=False, base64encode=True):
        """
        Intialize the WebSocket listener.

        @type target_host string
        @param target_host the target VNC host to proxy out
        @type target_port string
        @param target_port the target VNC port to proxy out
        @type listen_host string
        @param listen_host local IP address to listen (0.0.0.0 for all)
        @type certfile string
        @param certfile the path to a valid certificate file for SSL connections
        @type onlySSL boolean
        @param onlySSL if set to true, the socket will *only* accept secure connections
        """
        threading.Thread.__init__(self)

        self.target_port        = target_port
        self.target_host        = target_host
        self.cert               = certfile
        self.listen_host        = listen_host
        self.listen_port        = listen_port
        self.ssl_only           = onlySSL
        self.buffer_size        = 65536
        self.base64encode       = base64encode
        self.clientSockets      = []
        self.policy_response    = """<cross-domain-policy><allow-access-from domain="*" to-ports="*" /></cross-domain-policy>\n"""
        self.server_handshake   = WEBPROXY_HANDSHAKE
        self.lsock              = None
        self.on                 = True

    def __encode(self, buf):
        """
        Encode given buffer to base64.

        @type buf string
        @param buf the buffer to encode
        """
        if self.base64encode:
            buf = b64encode(buf)
        # else:
        #     # Modified UTF-8 encode
        #     buf = buf.decode('latin-1').encode('utf-8').replace("\x00", "\xc4\x80")

        return "\x00%s\xff" % buf

    def __decode(self, buf):
        """
        Decode given buffer from base64.

        @type buf string
        @param buf the buffer to dencode
        """
        if buf.count('\xff') > 1:
            if self.base64encode:
                return [b64decode(d[1:]) for d in buf.split('\xff')]
            else:
                return [d[1:].replace("\xc4\x80", "\x00").decode('utf-8').encode('latin-1') for d in buf.split('\xff')]
        else:
            if self.base64encode:
                return [b64decode(buf[1:-1])]
            else:
                return [buf[1:-1].replace("\xc4\x80", "\x00").decode('utf-8').encode('latin-1')]

    def __parse_handshake(self, handshake):
        """
        Parse the connection handshake.

        @type handshake string
        @param handshake the handshake content
        """
        ret = {}
        req_lines = handshake.split("\r\n")
        if not req_lines[0].startswith("GET "):
            raise Exception("Invalid handshake: no GET request line.")
        ret['path'] = req_lines[0].split(" ")[1]
        for line in req_lines[1:]:
            if line == "": break
            var, val = line.split(": ")
            ret[var] = val

        if req_lines[-2] == "":
            ret['key3'] = req_lines[-1]

        return ret

    def __gen_md5(self, keys):
        """generate a md5 from keys"""
        key1 = keys['Sec-WebSocket-Key1']
        key2 = keys['Sec-WebSocket-Key2']
        key3 = keys['key3']
        spaces1 = key1.count(" ")
        spaces2 = key2.count(" ")
        num1 = int("".join([c for c in key1 if c.isdigit()])) / spaces1
        num2 = int("".join([c for c in key2 if c.isdigit()])) / spaces2

        return md5(struct.pack('>II8s', num1, num2, key3)).digest()

    def __do_handshake(self, sock):
        """
        Perform the handshake
        """
        self.base64encode = True

        # Peek, but don't read the data
        handshake = sock.recv(1024, socket.MSG_PEEK)
        if handshake == "":
            sock.close()
            return False
        elif handshake.startswith("<policy-file-request/>"):
            handshake = sock.recv(1024)
            sock.send(self.policy_response)
            sock.close()
            return False
        elif handshake[0] in ("\x16", "\x80"):
            retsock = ssl.wrap_socket(
                    sock,
                    server_side=True,
                    certfile=self.cert)
            scheme = "wss"
            log.info("WEBSOCKETPROXY: using SSL/TLS.")
        elif self.ssl_only:
            log.info("WEBSOCKETPROXY: Non-SSL connection disallowed.")
            sock.close()
            return False
        else:
            retsock = sock
            scheme = "ws"
            log.info("WEBSOCKETPROXY: using plain (non SSL) socket.")

        handshake = retsock.recv(4096)
        if len(handshake) == 0:
            raise Exception("WEBSOCKETPROXY: client closed during handshake.")
        h = self.__parse_handshake(handshake)

        # Parse client settings from the GET path
        cvars = h['path'].partition('?')[2].partition('#')[0].split('&')
        for cvar in [c for c in cvars if c]:
            name, _, val = cvar.partition('=')
            if name not in ['b64encode']: continue
            value = val and val or True
            self.base64encode = value

        if h.get('key3'):
            trailer = self.__gen_md5(h)
            pre = "Sec-"
        else:
            trailer = ""
            pre = ""

        response = self.server_handshake % (pre, h['Origin'], pre, scheme,
                h['Host'], h['path'], pre, trailer)

        retsock.send(response)
        return retsock

    def __do_proxy(self, client, target, addr):
        """ Proxy WebSocket to normal socket. """
        cqueue = []
        cpartial = ""
        tqueue = []
        rlist = [client, target]

        try:
            while self.on:
                wlist = []
                if tqueue: wlist.append(target)
                if cqueue: wlist.append(client)
                ins, outs, excepts = select(rlist, wlist, [], 1)
                if excepts: raise Exception("Socket exception.")

                if target in outs:
                    dat = tqueue.pop(0)
                    sent = target.send(dat)
                    if sent == len(dat):
                        pass
                    else:
                        tqueue.insert(0, dat[sent:])

                if client in outs:
                    dat = cqueue.pop(0)
                    sent = client.send(dat)
                    if not sent == len(dat):
                        cqueue.insert(0, dat[sent:])

                if target in ins:
                    buf = target.recv(self.buffer_size)
                    if len(buf) == 0: raise Exception("Target closed.")
                    cqueue.append(self.__encode(buf))

                if client in ins:
                    buf = client.recv(self.buffer_size)
                    if len(buf) == 0: raise Exception("Client closed.")
                    if buf == '\xff\x00':
                        raise Exception("WEBSOCKETPROXY: client sent orderly close frame.")
                    elif buf[-1] == '\xff':
                        if cpartial:
                            tqueue.extend(self.__decode(cpartial + buf))
                            cpartial = ""
                        else:
                            tqueue.extend(self.__decode(buf))
                    else:
                        cpartial = cpartial + buf
        except:
            log.info("WEBSOCKETPROXY: client %s disconnected." % str(addr))
            if client: client.close()
            if target: target.close()

    def __proxy_handler(self, client, addr):
        tsock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        tsock.connect((self.target_host, self.target_port))

        thread.start_new_thread(self.__do_proxy, (client, tsock, addr))

    def run(self):
        """
        Start the thread and start to listen for connections.
        All connections will be then threaded again.
        """
        try:
            self.lsock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            self.lsock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
            self.lsock.bind((self.listen_host, self.listen_port))
            self.lsock.listen(100)

            while self.on:
                try:
                    csock       = None
                    startsock   = None

                    log.debug("WEBSOCKETPROXY: waiting for connection on port %s" % self.listen_port)
                    startsock, address = self.lsock.accept()
                    if not self.on: return
                    log.info("WEBSOCKETPROXY: Got client connection from %s" % address[0])
                    csock = self.__do_handshake(startsock)
                    if not csock: continue

                    self.clientSockets.append((csock, startsock))
                    self.__proxy_handler(csock, address[0])
                except Exception as ex:
                    log.error("WEBSOCKETPROXY: connection interrupted: %s" % str(ex))
        except Exception as ex:
            log.error("WEBSOCKETPROXY: can't start listener: %s" % str(ex))
            for c in self.clientSockets:
                if c[0]: c[0].close()
                if c[1] and c[1] != c[0]: c[1].close()
            self.lsock.close()
            self.on = False

        log.info("WEBSOCKETPROXY: Thread exited.")

    def stop(self):
        """
        *Should* stop the thread.
        """
        self.on = False
        for c in self.clientSockets:
            if c[0]: c[0].close()
            if c[1] and c[1] != c[0]: c[1].close()
        socket.create_connection(((self.listen_host, self.listen_port)))
        self.lsock.close()
        log.info("WEBSOCKETPROXY: thread stopped.")