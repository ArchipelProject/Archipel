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

from pysnmp.entity.rfc3413.oneliner import cmdgen


class TNThreadedHealthCollector(Thread):
    from pysnmp.entity.rfc3413.oneliner import cmdgen
    """
    this class collects hypervisor stats regularly
    """
    def __init__(self, database_file, collection_interval, snmp_agent, snmp_community, snmp_version, snmp_port):
        """
        the contructor of the class
        """
        self.database_file = database_file;
        self.collection_interval = collection_interval;
        
        self.snmp_community     = cmdgen.CommunityData(snmp_agent, snmp_community, snmp_version)
        self.snmp_udptransport  = cmdgen.UdpTransportTarget(('localhost', snmp_port))
        
        # ## uname
        # errorIndication, errorStatus, errorIndex, varBinds = cmdgen.CommandGenerator().getCmd(self.snmp_community, self.snmp_udptransport, (1,3,6,1,2,1,1,1,0))
        # uname = str(varBinds[0][1])
        # uname = uname.split()
        # self.uname_stats = {"krelease": uname[2] , "kname": uname[0] , "machine": uname[1], "os": uname[11]}
        uname = commands.getoutput("uname -rsmo").split();
        self.uname_stats = {"krelease": uname[0] , "kname": uname[1] , "machine": uname[2], "os": uname[3]}
        
        log(self, LOG_LEVEL_INFO, "opening stats database file {0}".format(self.database_file))
        
        self.query_database_connection = sqlite3.connect(self.database_file)
        try:
            self.query_database_connection.execute("create table cpu (collection_date date, idle int)")
            self.query_database_connection.execute("create table memory (collection_date date, free integer, used integer, total integer, swapped integer)")
            self.query_database_connection.execute("create table disk (collection_date date, total int, used int, free int, free_percentage int)")
            self.query_database_connection.execute("create table load (collection_date date, one float, five float, fifteen float)")
            log(self, LOG_LEVEL_INFO, "database schema created.")   
        except Exception as ex:
            log(self, LOG_LEVEL_INFO, "tables seems to be already here. recovering.")
            
        Thread.__init__(self)
    
    
    def get_collected_stats(self, limit=1):
        """
        this method return the current L{TrinityVM} instance
        @rtype: TrinityVM
        @return: the L{TrinityVM} instance
        """        
        log(self, LOG_LEVEL_DEBUG, "Retrieving last "+ str(limit) + " recorded stats data for sending")
        tempdatabase = self.query_database_connection;
        
        query = "select * from cpu, memory, disk, load order by collection_date desc limit " + str(limit);
        
        cpustat_cursor = tempdatabase.cursor();
        cpustat_cursor.execute("select * from cpu order by collection_date desc limit " + str(limit))
        cpu_stats = [];
        for values in cpustat_cursor:
            date, idle = values
            cpu_stats.append({"date": date, "id": idle})
        cpustat_cursor.close();
        
        memstat_cursor = tempdatabase.cursor();
        memstat_cursor.execute("select * from memory order by collection_date desc limit " + str(limit))
        memory_stats = [];
        for values in memstat_cursor:
            date, free, used, total, swapped = values
            memory_stats.append({"date": date, "free": free, "used" : used, "total": total, "swapped": swapped})
        memstat_cursor.close();
        
        diskstat_cursor = tempdatabase.cursor();
        diskstat_cursor.execute("select * from disk order by collection_date desc limit " + str(limit))
        disk_stats = [];
        for values in diskstat_cursor:
            date, total, used, free, free_percentage = values
            disk_stats.append({"date": date, "total": total, "used": used, "free": free, "free_percentage": free_percentage})
        diskstat_cursor.close();
        
        loadstat_cursor = tempdatabase.cursor();
        loadstat_cursor.execute("select * from load order by collection_date desc limit " + str(limit))
        load_stats = [];
        for values in loadstat_cursor:
            date, one, five, fifteen = values
            load_stats.append({"date": date, "one": one, "five": five, "fifteen": fifteen})
        loadstat_cursor.close();
        
        # uptime
        # errorIndication, errorStatus, errorIndex, varBinds = cmdgen.CommandGenerator().getCmd(self.snmp_community, self.snmp_udptransport, (1,3,6,1,2,1,1,3,0))
        # uptime = str(varBinds[0][1])
        # uptime_stats = {"up" : uptime};
        uptime = commands.getoutput("uptime").split("up ")[1].split(",")[0]
        uptime_stats = {"up" : uptime};
                 
        log(self, LOG_LEVEL_DEBUG, "Stat collection terminated");
        return {"cpu": cpu_stats, "memory": memory_stats, "disk": disk_stats, "load": load_stats, "uptime": uptime_stats, "uname": self.uname_stats};
    
    
    def get_memory_stats(self):
        # errorIndication, errorStatus, errorIndex, varBinds = cmdgen.CommandGenerator().bulkCmd(self.snmp_community, self.snmp_udptransport, 0, 25, (1,3,6,1,4,1,2021,4))
        # 
        # for result in varBinds:
        #     oid, value = result[0]
        #     if oid == (1,3,6,1,4,1,2021,4,5,0):
        #         memTotal = int(value);
        #     elif oid == (1,3,6,1,4,1,2021,4,11,0):
        #         memFree = int(value);
        #     elif oid == (1,3,6,1,4,1,2021,4,6,0):
        #         memUsed = int(value);
        #     elif oid == (1,3,6,1,4,1,2021,4,3,0):
        #         swapped = int(value);
        
        file_meminfo    = open('/proc/meminfo');
        meminfo         = file_meminfo.read();
        file_meminfo.close()

        meminfolines    = meminfo.split("\n");
        memTotal        = int(meminfolines[0].split()[1]);
        memFree         = int(meminfolines[1].split()[1]);
        swapped         = int(meminfolines[4].split()[1]);
        memUsed         = memTotal - memFree;
        
        return (datetime.datetime.now(), memFree, memUsed, memTotal, swapped)
    
    
    def get_cpu_stats(self):
        # # CPU idle %
        # errorIndication, errorStatus, errorIndex, varBinds = cmdgen.CommandGenerator().getCmd(self.snmp_community, self.snmp_udptransport, (1,3,6,1,4,1,2021,11,11,0))    
        # cpuPct = int(varBinds[0][1]);
        
        dt      = self.deltaTime(1)
        cpuPct  = (dt[len(dt) - 1] * 100.00 / sum(dt))
        
        return (datetime.datetime.now(), cpuPct)
    
    
    def get_load_stats(self):
        # errorIndication, errorStatus, errorIndex, varBinds = cmdgen.CommandGenerator().bulkCmd(self.snmp_community, self.snmp_udptransport, 0, 25, (1,3,6,1,4,1,2021,10,1,3))
        # for result in varBinds:
        #     oid, value = result[0]
        #     if oid == (1,3,6,1,4,1,2021,10,1,3,1):
        #         load1min = float(str(value));
        #     elif oid == (1,3,6,1,4,1,2021,10,1,3,2):
        #         load5min = float(str(value));
        #     elif oid == (1,3,6,1,4,1,2021,10,1,3,3):
        #         load15min = float(str(value));
        
        load_average = commands.getoutput("uptime").split("load average:")[1].split(", ")
        load1min, load5min, load15min = (float(load_average[0]), float(load_average[1]), float(load_average[2]))
        
        return (datetime.datetime.now(), load1min, load5min, load15min)
    
    
    def get_disk_stats(self):
        # errorIndication, errorStatus, errorIndex, varBinds = cmdgen.CommandGenerator().bulkCmd(self.snmp_community, self.snmp_udptransport, 0, 25, (1,3,6,1,4,1,2021,9,1))
        # for result in varBinds:
        #     oid, value = result[0]
        #     if oid == (1,3,6,1,4,1,2021,9,1,6,1):
        #         total = float(str(value));
        #     elif oid == (1,3,6,1,4,1,2021,9,1,8,1):
        #         used = float(str(value));
        #     elif oid == (1,3,6,1,4,1,2021,9,1,7,1):
        #         free = float(str(value));
        #     elif oid == (1,3,6,1,4,1,2021,9,1,9,1):
        #         freePrct = float(str(value));
        
        disk_free = commands.getoutput("df -h --total | grep total").split();
        total, used, free, freePrct = (disk_free[1], disk_free[2],disk_free[3], disk_free[4])
        
        return (datetime.datetime.now(), total, used, free, freePrct);
    
    def run(self):
        """
        overiddes sur super class method. do the L{TrinityVM} main loop
        """
        self.database_thread_connection = sqlite3.connect(self.database_file)
        while(1):
            log(self, LOG_LEVEL_DEBUG, "starting to collect stats")
            
            self.database_thread_connection.execute("insert into memory values(?,?,?,?,?)", self.get_memory_stats())
            self.database_thread_connection.execute("insert into cpu values(?,?)", self.get_cpu_stats())
            self.database_thread_connection.execute("insert into load values(?,?,?,?)", self.get_load_stats());
            self.database_thread_connection.execute("insert into disk values(?,?,?,?,?)", self.get_disk_stats())
            
            self.database_thread_connection.commit()
            
            log(self, LOG_LEVEL_DEBUG, "Stats collected")
            time.sleep(self.collection_interval);
    
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
