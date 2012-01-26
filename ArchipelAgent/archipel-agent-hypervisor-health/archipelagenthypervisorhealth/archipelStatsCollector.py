# -*- coding: utf-8 -*-
#
# archipelStatsCollector.py
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

import datetime
import sqlite3
import subprocess
import time
import json
from threading import Thread

from archipelcore.utils import log


class TNThreadedHealthCollector (Thread):
    """
    This class collects hypervisor stats regularly.
    """

    def __init__(self, database_file, collection_interval, max_rows_before_purge, max_cached_rows):
        """
        The contructor of the class.
        @type database_file: string
        @param database_file: the path of the database
        @type collection_interval: integer
        @param collection_interval: the intervale between two collection
        @type max_rows_before_purge: integer
        @param max_rows_before_purge: max number of rows that can be stored in database
        @type max_cached_rows: integer
        @param max_cached_rows: max number of rows that are cached into memory
        """
        self.database_file          = database_file
        self.collection_interval    = collection_interval
        self.max_rows_before_purge  = max_rows_before_purge
        self.max_cached_rows        = max_cached_rows
        self.stats_CPU              = []
        self.stats_memory           = []
        self.stats_load             = []
        self.stats_network          = []
        self.current_record         = {}
        self.memoryPageSize         = int(subprocess.Popen(["getconf", "PAGESIZE"], stdout=subprocess.PIPE).communicate()[0])
        uname = subprocess.Popen(["uname", "-rsmo"], stdout=subprocess.PIPE).communicate()[0].split()
        self.uname_stats = {"krelease": uname[0], "kname": uname[1], "machine": uname[2], "os": uname[3]}
        self.database_query_connection = sqlite3.connect(self.database_file)
        self.cursor = self.database_query_connection.cursor()
        self.cursor.execute("create table if not exists cpu (collection_date date, idle int)")
        self.cursor.execute("create table if not exists memory (collection_date date, free integer, used integer, total integer, swapped integer, shared integer)")
        self.cursor.execute("create table if not exists load (collection_date date, one float, five float, fifteen float)")
        self.cursor.execute("create table if not exists network (collection_date date, records text)")
        self.database_query_connection.commit()
        log.info("Database ready.")
        self.recover_stored_stats()
        self.cursor.close()
        Thread.__init__(self)

    def recover_stored_stats(self):
        """
        Recover info from database.
        """
        log.info("Recovering stored statistics. It may take a while...")
        self.cursor.execute("select * from cpu order by collection_date desc limit %d" % self.max_cached_rows)
        for values in self.cursor:
            date, idle = values
            self.stats_CPU.append({"date": date, "id": idle})
        self.stats_CPU.reverse()
        self.cursor.execute("select * from memory order by collection_date desc limit %d" % self.max_cached_rows)
        for values in self.cursor:
            date, free, used, total, swapped, shared = values
            self.stats_memory.append({"date": date, "free": free, "used": used, "total": total, "swapped": swapped, "shared": shared})
        self.stats_memory.reverse()
        self.cursor.execute("select * from load order by collection_date desc limit %d" % self.max_cached_rows)
        for values in self.cursor:
            date, one, five, fifteen = values
            self.stats_load.append({"date": date, "one": one, "five": five, "fifteen": fifteen})
        self.stats_load.reverse()
        self.cursor.execute("select * from network order by collection_date desc limit %d" % self.max_cached_rows)
        for values in self.cursor:
            date, records = values
            self.stats_network.append({"date": date, "records": records})
        self.stats_network.reverse()
        log.info("Statistics recovered.")

    def get_collected_stats(self, limit=1):
        """
        This method returns the current L{TNArchipelVirtualMachine} instance.
        @type limit: integer
        @param limit: the max number of row to get
        @rtype: TNArchipelVirtualMachine
        @return: the L{TNArchipelVirtualMachine} instance
        """
        log.debug("STATCOLLECTOR: Retrieving last "+ str(limit) + " recorded stats data for sending.")
        try:
            uptime = self.get_uptime()
            uptime_stats    = {"up": "%dd %dh" % (uptime[0], uptime[1])} #TODO: it's obvious it would be better to not do this
        except Exception as ex:
            raise Exception("Unable to get uptime.", ex)
        try:
            acpu = self.stats_CPU[-limit:]
        except Exception as ex:
            raise Exception("Unable to get CPU stats.", ex)
        try:
            amem = self.stats_memory[-limit:]
        except Exception as ex:
            raise Exception("Unable to get memory.", ex)
        try:
            anetwork = self.stats_network[-limit:]
        except Exception as ex:
            raise Exception("Unable to get networks.", ex)
        try:
            adisk = sorted(self.get_disk_stats(), cmp=lambda x, y: cmp(x["mount"], y["mount"]))
            totalDisk = self.get_disk_total()
        except Exception as ex:
            raise Exception("Unable to get disks information.", ex)
        try:
            aload = self.stats_load[-limit:]
        except Exception as ex:
            raise Exception("Unable to get disks information.", ex)
        if limit > 1:
            acpu.reverse()
            amem.reverse()
            aload.reverse()
            anetwork.reverse()
        return {"cpu": acpu, "memory": amem, "disk": adisk, "totaldisk": totalDisk,
                "load": aload, "uptime": uptime_stats, "uname": self.uname_stats, "network": anetwork}

    def get_uptime(self):
        """
        Get the uptime from /proc/uptime.
        code taken from http://thesmithfam.org/blog/2005/11/19/python-uptime-script/
        @rtype: tupple
        @return: days, hours, minutes, seconds
        """
        f = open('/proc/uptime')
        contents = f.read().split()
        f.close()
        total_seconds = float(contents[0])
        MINUTE = 60
        HOUR = MINUTE * 60
        DAY = HOUR * 24
        days = int(total_seconds / DAY)
        hours = int((total_seconds % DAY) / HOUR)
        minutes = int((total_seconds % HOUR) / MINUTE)
        seconds = int(total_seconds % MINUTE)
        return (days, hours, minutes, seconds)

    def get_memory_stats(self):
        """
        Get memory stats.
        @rtype: dict
        @return: dictionnary containing the informations
        """
        file_meminfo = open('/proc/meminfo')
        meminfo = file_meminfo.read()
        file_meminfo.close()
        file_pages_sharing = open("/sys/kernel/mm/ksm/pages_sharing")
        pagessharing = file_pages_sharing.read()
        file_pages_sharing.close()
        memshared = int(pagessharing) * self.memoryPageSize / 1024;
        meminfolines = meminfo.split("\n")
        memTotal = int(meminfolines[0].split()[1])
        memFree = int(meminfolines[1].split()[1]) + int(meminfolines[2].split()[1]) + int(meminfolines[3].split()[1])
        swapped = int(meminfolines[4].split()[1])
        memUsed = memTotal - memFree
        return {"date": datetime.datetime.now(), "free": memFree, "used": memUsed, "total": memTotal, "swapped": swapped, "shared": memshared}

    def get_cpu_stats(self):
        """
        Get CPU stats.
        @rtype: dict
        @return: dictionnary containing the informations
        """
        dt = self.deltaTime(1)
        cpuPct = (dt[len(dt) - 1] * 100.00 / sum(dt))
        return {"date": datetime.datetime.now(), "id": cpuPct}

    def get_load_stats(self):
        """
        Get load stats.
        @rtype: dict
        @return: dictionnary containing the informations
        """
        f = open('/proc/loadavg')
        contents = f.read().split()
        f.close()
        load1min = float(contents[0])
        load5min = float(contents[1])
        load15min = float(contents[2])
        return {"date": datetime.datetime.now(), "one": load1min, "five": load5min, "fifteen": load15min}

    def get_disk_stats(self):
        """
        Get drive usage stats.
        @rtype: dict
        @return: dictionnary containing the informations
        """
        output  = subprocess.Popen(["df", "-P"], stdout=subprocess.PIPE).communicate()[0]
        ret     = []
        out     = output.split("\n")[1:-1]
        for l in out:
            cell = l.split()
            ret.append({"partition": cell[0], "blocks": cell[1], "used": int(cell[2]) * 1024, "available": int(cell[3]) * 1024, "capacity": cell[4], "mount": cell[5]})
        return ret

    def get_network_stats(self):
        """
        Get network stats.
        @rtype: dict
        @return: dictionnary containing the informations
        """
        f = open('/proc/net/dev')
        contents = f.read().split('\n')[2:-1]
        f.close()
        records = {}
        ret = {}
        for line in contents:
            dev = line.split(":")[0].replace(" ", "")
            if dev == "lo":
                continue
            if dev.startswith("vnet"):
                continue
            info = line.split(":")[1].split()
            rx = int(info[0])
            tx = int(info[8])
            records[dev] = {"rx": rx, "tx": tx}
            if self.current_record and dev in self.current_record:
                delta_usage = (rx - self.current_record[dev]["rx"]) + (tx - self.current_record[dev]["tx"])
            else:
                delta_usage = 0;
            ret[dev] = delta_usage
        self.current_record = records;
        return {"date": datetime.datetime.now(), "records": json.dumps(ret)}

    def get_disk_total(self):
        """
        Get total size of drive used stats.
        @rtype: dict
        @return: dictionnary containing the informations
        """
        out = subprocess.Popen(["df", "--total", "-P"], stdout=subprocess.PIPE).communicate()[0].split("\n")
        for line in out:
            line = line.split()
            if line[0] == "total":
                disk_total = line
                break
        return {"used": disk_total[2], "available": disk_total[3], "capacity": disk_total[4]}

    def getTimeList(self):
        """
        ignore
        """
        statFile = file('/proc/stat')
        timeList = statFile.readline().split(" ")[2:6]
        statFile.close()
        for i in range(len(timeList)):
            timeList[i] = int(timeList[i])
        return timeList

    def deltaTime(self, interval):
        """
        ignore
        """
        x = self.getTimeList()
        time.sleep(interval)
        y = self.getTimeList()
        for i in range(len(x)):
            y[i] -= x[i]
        return y

    def run(self):
        """
        Overrides super class method. do the L{TNArchipelVirtualMachine} main loop.
        """
        self.database_thread_connection = sqlite3.connect(self.database_file)
        self.database_thread_cursor = self.database_thread_connection.cursor()
        while(1):
            try:
                self.stats_CPU.append(self.get_cpu_stats())
                self.stats_memory.append(self.get_memory_stats())
                self.stats_load.append(self.get_load_stats())
                self.stats_network.append(self.get_network_stats())

                if len(self.stats_CPU) >= self.max_cached_rows:
                    middle = (self.max_cached_rows - 1) / 2

                    self.database_thread_cursor.executemany("insert into memory values(:date, :free, :used, :total, :swapped, :shared)", self.stats_memory[0:middle])
                    self.database_thread_cursor.executemany("insert into cpu values(:date, :id)", self.stats_CPU[0:middle])
                    self.database_thread_cursor.executemany("insert into load values(:date, :one , :five, :fifteen)", self.stats_load[0:middle])
                    self.database_thread_cursor.executemany("insert into network values(:date, :records)", self.stats_network[0:middle])

                    log.info("Stats saved in database file.")

                    if int(self.database_thread_cursor.execute("select count(*) from memory").fetchone()[0]) >= self.max_rows_before_purge * 2:
                        self.database_thread_cursor.execute("delete from cpu where collection_date=(select collection_date from cpu order by collection_date asc limit "+ str(self.max_rows_before_purge) +")")
                        self.database_thread_cursor.execute("delete from memory where collection_date=(select collection_date from memory order by collection_date asc limit "+ str(self.max_rows_before_purge) +")")
                        self.database_thread_cursor.execute("delete from load where collection_date=(select collection_date from load order by collection_date asc limit "+ str(self.max_rows_before_purge) +")")
                        self.database_thread_cursor.execute("delete from network where collection_date=(select collection_date from network order by collection_date asc limit "+ str(self.max_rows_before_purge) +")")
                        log.debug("Old stored stats have been purged from memory.")

                    del self.stats_CPU[0:middle]
                    del self.stats_memory[0:middle]
                    del self.stats_load[0:middle]
                    del self.stats_network[0:middle]
                    log.info("Cached stats have been purged from memory.")

                    self.database_thread_connection.commit()

                time.sleep(self.collection_interval)
            except Exception as ex:
                log.error("Stat collection fails. Exception %s" % str(ex))