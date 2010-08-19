#!/usr/bin/python 
# update_xmpp_domain.py
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



import sqlite3, os, sys




def update(dbfile, newdomain):
    db = sqlite3.connect(dbfile)
    c = db.cursor()
    c.execute("select * from virtualmachines")
    
    for vm in c:
        jid, password, date, comment, name = vm
        newjid = jid.split("@")[0] + "@" + newdomain;
        
        db.execute("UPDATE virtualmachines SET jid='%s' WHERE jid='%s'" % (newjid, jid))
    db.commit()
    
    
if __name__ == "__main__":
    if len(sys.argv) != 3:
        print """\
update_xmpp_domain (c) 2010 Antoine Mercadal
This tool allows you to quicky change the domain of all virtual machines in a hypervisor database.
usage: update_xmpp_domain databasefile.sqlite3 newjabberdomain

example: update_xmpp_domain hypervisor.sqlite3 jabber.org"""
        sys.exit(0)
    update(sys.argv[1], sys.argv[2])
    