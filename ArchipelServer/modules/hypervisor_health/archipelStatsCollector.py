# archipelstatcollector
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

#from pysnmp.entity.rfc3413.oneliner import cmdgen


class TNThreadedHealthCollector(Thread):
    """
    this class collects hypervisor stats regularly
    """
    def __init__(self, database_file, collection_interval, max_rows_before_purge, min_row_before_storing): #, snmp_agent, snmp_community, snmp_version, snmp_port):
        """
        the contructor of the class
        """
        self.database_file          = database_file
        self.collection_interval    = collection_interval
        self.max_rows_before_purge  = max_rows_before_purge
        self.min_row_before_storing = min_row_before_storing
        self.stats_CPU              = []
        self.stats_memory           = []
        self.stats_load             = []
        self.stats_disks            = []
        
        uname = commands.getoutput("uname -rsmo").split()
        self.uname_stats = {"krelease": uname[0] , "kname": uname[1] , "machine": uname[2], "os": uname[3]}
        
        self.database_query_connection = sqlite3.connect(self.database_file)
        self.cursor = self.database_query_connection.cursor()
        
        self.cursor.execute("create table if not exists cpu (collection_date date, idle int)")
        self.cursor.execute("create table if not exists memory (collection_date date, free integer, used integer, total integer, swapped integer)")
        self.cursor.execute("create table if not exists disk (collection_date date, total int, used int, free int, free_percentage int)")
        self.cursor.execute("create table if not exists load (collection_date date, one float, five float, fifteen float)")
        log.info("Database ready.")
        
        self.recover_stored_stats()
        
        
        Thread.__init__(self)
    
    
    def recover_stored_stats(self):
        log.info("recovering stored statistics")
        self.cursor.execute("select * from cpu order by collection_date desc limit %d" % self.max_rows_before_purge)
        for values in self.cursor:
            date, idle = values
            self.stats_CPU.insert(0, {"date": date, "id": idle})
        
        self.cursor.execute("select * from memory order by collection_date desc limit %d" % self.max_rows_before_purge)
        for values in self.cursor:
            date, free, used, total, swapped = values
            self.stats_memory.insert(0, {"date": date, "free": free, "used" : used, "total": total, "swapped": swapped})
        
        self.cursor.execute("select * from load order by collection_date desc limit %d" % self.max_rows_before_purge)
        for values in self.cursor:
            date, one, five, fifteen = values
            self.stats_load.insert(0, {"date": date, "one": one, "five": five, "fifteen": fifteen})
        
        self.cursor.execute("select * from disk order by collection_date desc limit %d" % self.max_rows_before_purge)
        for values in self.cursor:
            date, total, used, free, free_percentage = values
            self.stats_disks.insert(0, {"date": date, "total": total, "used": used, "free": free, "free_percentage": free_percentage})
        log.info("statistics recovered")
    
    
    def get_collected_stats(self, limit=1):
        """
        this method return the current L{TNArchipelVirtualMachine} instance
        @rtype: TNArchipelVirtualMachine
        @return: the L{TNArchipelVirtualMachine} instance
        """        
        #log.debug("Retrieving last "+ str(limit) + " recorded stats data for sending")
        try:
            uptime = commands.getoutput("uptime").split("up ")[1].split(",")[0]
            uptime_stats = {"up" : uptime}
            return {"cpu": self.stats_CPU[0:limit], "memory": self.stats_memory[0:limit], "disk": self.stats_disks[0:limit], "load": self.stats_load[0:limit], "uptime": uptime_stats, "uname": self.uname_stats}
        except Exception as ex:
            log.error("stat recuperation fails. Exception %s" % str(ex))
            return None
    
    
    def get_memory_stats(self):
        file_meminfo    = open('/proc/meminfo')
        meminfo         = file_meminfo.read()
        file_meminfo.close()
        
        meminfolines    = meminfo.split("\n")
        memTotal        = int(meminfolines[0].split()[1])
        memFree         = int(meminfolines[1].split()[1])
        swapped         = int(meminfolines[4].split()[1])
        memUsed         = memTotal - memFree
        
        return {"date": datetime.datetime.now(), "free": memFree, "used" : memUsed, "total": memTotal, "swapped": swapped}
    
    
    def get_cpu_stats(self):
        dt      = self.deltaTime(1)
        cpuPct  = (dt[len(dt) - 1] * 100.00 / sum(dt))
        
        return {"date": datetime.datetime.now(), "id": cpuPct}
    
    
    def get_load_stats(self):
        load_average = commands.getoutput("uptime").split("load average:")[1].split(", ")
        load1min, load5min, load15min = (float(load_average[0]), float(load_average[1]), float(load_average[2]))
        
        return {"date": datetime.datetime.now(), "one": load1min, "five": load5min, "fifteen": load15min}
    
    
    def get_disk_stats(self):
        disk_free = commands.getoutput("df -h --total | grep total").split()
        total, used, free, freePrct = (disk_free[1], disk_free[2],disk_free[3], disk_free[4])
        
        return {"date": datetime.datetime.now(), "total" : total, "used": used, "free": free, "free_percentage": freePrct}
    
    
    def run(self):
        """
        overiddes sur super class method. do the L{TNArchipelVirtualMachine} main loop
        """
        self.database_thread_connection = sqlite3.connect(self.database_file)
        
        while(1):
            try:
                self.stats_CPU.insert(0, self.get_cpu_stats())
                self.stats_memory.insert(0, self.get_memory_stats())
                self.stats_load.insert(0, self.get_load_stats())
                self.stats_disks.insert(0, self.get_disk_stats())
                
                if len(self.stats_CPU) % self.min_row_before_storing == 0:
                    self.database_thread_connection.executemany("insert into memory values(:date, :free, :used, :total, :swapped)", self.stats_memory)
                    self.database_thread_connection.executemany("insert into cpu values(:date, :id)", self.stats_CPU)
                    self.database_thread_connection.executemany("insert into load values(:date, :one , :five, :fifteen)", self.stats_load)
                    self.database_thread_connection.executemany("insert into disk values(:date, :total, :used,:free, :free_percentage)", self.stats_disks)
                    log.info("stats saved in database file")
                    
                    if len(self.stats_CPU) >= self.min_row_before_storing * 2:
                        del self.stats_CPU[(-self.min_row_before_storing - 1)]
                        del self.stats_memory[(-self.min_row_before_storing - 1)]
                        del self.stats_load[(-self.min_row_before_storing - 1)]
                        del self.stats_disks[(-self.min_row_before_storing - 1)]
                        log.info("cached stats have been purged from memory")
                        
                    if int(self.database_thread_connection.execute("select count(*) from memory").fetchone()[0]) >= self.max_rows_before_purge:
                        self.database_thread_connection.execute("delete from cpu where collection_date=(select collection_date from cpu order by collection_date asc limit "+ str(self.max_rows_before_purge) +")")
                        self.database_thread_connection.execute("delete from memory where collection_date=(select collection_date from memory order by collection_date asc limit "+ str(self.max_rows_before_purge) +")")
                        self.database_thread_connection.execute("delete from load where collection_date=(select collection_date from load order by collection_date asc limit "+ str(self.max_rows_before_purge) +")")
                        self.database_thread_connection.execute("delete from disk where collection_date=(select collection_date from disk order by collection_date asc limit "+ str(self.max_rows_before_purge) +")")
                        log.debug("old stored stats have been purged from memory")
                    
                    self.database_thread_connection.commit()
                
                time.sleep(self.collection_interval)
            except Exception as ex:
                log.error("stat collection fails. Exception %s" % str(ex))
            
    def getTimeList(self):
        statFile = file("/proc/stat", "r")
        timeList = statFile.readline().split(" ")[2:6]
        statFile.close()
        for i in range(len(timeList)):
            timeList[i] = int(timeList[i])
        return timeList

    def deltaTime(self, interval)  :
        x = self.getTimeList()
        time.sleep(interval)
        y = self.getTimeList()
        for i in range(len(x))  :
            y[i] -= x[i]
        return y
