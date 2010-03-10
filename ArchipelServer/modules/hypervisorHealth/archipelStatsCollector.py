#!/usr/bin/python
#
# trinitystatcollector
# 
# archipelStatsCollector.py
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

import sqlite3
import datetime
import commands
import time
from threading import Thread
from utils import *

class TNThreadedHealthCollector(Thread):
    """
    this class collects hypervisor stats regularly
    """
    def __init__(self, database_file="statscollection.sqlite3"):
        """
        the contructor of the class
        """
        self.database_file = database_file;
        self.query_database_connection = None;
        
        Thread.__init__(self)
    
    
    def get_collected_stats(self, limit=1):
        """
        this method return the current L{TrinityVM} instance
        @rtype: TrinityVM
        @return: the L{TrinityVM} instance
        """
        if not self.query_database_connection:
            self.query_database_connection = sqlite3.connect(self.database_file);
        
        log(self, LOG_LEVEL_DEBUG, "Retrieving last "+ str(limit) + " recorded stats data for sending")
        tempdatabase = self.query_database_connection;
        
        cpustat_cursor = tempdatabase.cursor();
        cpustat_cursor.execute("select * from cpu order by collection_date desc limit " + str(limit))
        cpu_stats = [];
        for values in cpustat_cursor:
            date, used, system, idle, wa, st = values
            cpu_stats.append({"date": date, "us": used, "sy": system, "id": idle, "wa": wa, "st": st})
        
        memstat_cursor = tempdatabase.cursor();
        memstat_cursor.execute("select * from memory order by collection_date desc limit " + str(limit))
        memory_stats = [];
        for values in memstat_cursor:
            date, free, used, total, swapped = values
            memory_stats.append({"date": date, "free": free, "used" : used, "total": total, "swapped": swapped})
        
        diskstat_cursor = tempdatabase.cursor();
        diskstat_cursor.execute("select * from disk order by collection_date desc limit " + str(limit))
        disk_stats = [];
        for values in diskstat_cursor:
            date, total, used, free, free_percentage = values
            disk_stats.append({"date": date, "total": total, "used": used, "free": free, "free_percentage": free_percentage})
    
        loadstat_cursor = tempdatabase.cursor();
        loadstat_cursor.execute("select * from load order by collection_date desc limit " + str(limit))
        load_stats = [];
        for values in loadstat_cursor:
            date, one, five, fifteen = values
            load_stats.append({"date": date, "one": one, "five": five, "fifteen": fifteen})
        
        
        uptime = commands.getoutput("uptime").split("up ")[1].split(",")[0]
        uptime_stats = {"up" : uptime};

        uname = commands.getoutput("uname -rsmo").split();
        uname_stats = {"krelease": uname[0] , "kname": uname[1] , "machine": uname[2], "os": uname[3]}
        
        log(self, LOG_LEVEL_DEBUG, "Stat collection terminated");
        return {"cpu": cpu_stats, "memory": memory_stats, "disk": disk_stats, "load": load_stats, "uptime": uptime_stats, "uname": uname_stats};
    
    
    def run(self):
        """
        overiddes sur super class method. do the L{TrinityVM} main loop
        """    
        log(self, LOG_LEVEL_INFO, "opening stats database file {0}".format(self.database_file))
        self.database = sqlite3.connect(self.database_file)
        
        try:
            self.database.execute("create table cpu (collection_date date, us integer, sy integer, id integer, wa integer, st integer)")
            self.database.execute("create table memory (collection_date date, free integer, used integer, total integer, swapped integer)")
            self.database.execute("create table disk (collection_date date, total text, used text, free text, free_percentage text)")
            self.database.execute("create table load (collection_date date, one float, five float, fifteen float)")
            log(self, LOG_LEVEL_INFO, "database schema created.")   
        except Exception as ex:
            log(self, LOG_LEVEL_INFO, "tables seems to be already here. recovering.")
            
        while(1):
            vmstat = commands.getoutput("vmstat 1 2").split("\n")[3].split();
            free = commands.getoutput("free").split("\n")[1].split();
            
            self.database.execute("insert into memory values(?,?,?,?,?)", (datetime.datetime.now(), int(vmstat[3]), int(free[2]), int(free[1]), int(vmstat[2])))
            self.database.execute("insert into cpu values(?,?,?,?,?,?)", (datetime.datetime.now(), int(vmstat[12]), int(vmstat[13]), int(vmstat[14]), int(vmstat[15]), int(vmstat[16])))

            disk_free = commands.getoutput("df -h --total | grep total").split();
            self.database.execute("insert into disk values(?,?,?,?,?)", (datetime.datetime.now(), disk_free[1], disk_free[2],disk_free[3], disk_free[4]))

            load_average = commands.getoutput("uptime").split("load average:")[1].split(", ")
            self.database.execute("insert into load values(?,?,?,?)", (datetime.datetime.now(), float(load_average[0]), float(load_average[1]), float(load_average[2])))
            
            self.database.commit()
            time.sleep(3);
