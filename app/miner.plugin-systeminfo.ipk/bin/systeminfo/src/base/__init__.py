# -*- coding: utf-8 -*-
import os
import sys
import json
import urllib2
import string
from os.path import dirname, abspath
import logging
import subprocess
import platform
import re
import uuid
import time
from time import sleep
import datetime
from datetime import datetime
import multiprocessing
import hashlib
from hashlib import md5
import copy
import size
import flow_collect
import nat_type


logger = logging.getLogger(__name__)
# clock ticks per second... jiffies (HZ)
'''
     global var
'''
JIFFIES_PER_SEC = os.sysconf('SC_CLK_TCK')
PAGE_SIZE = os.sysconf('SC_PAGE_SIZE')
INTERVAL = 1



class Message(object):
    
    def __init__(self, cmd_type, act=None, seq="", cmd="", result = []):
        self.type = cmd_type
        self.act = act
        self.sn = self.get_sn()
        self.seq = seq
        self.cmd = cmd
        self.result = result
        self.report_time = self.get_date()
        
    def get_salt(self):
        return uuid.UUID(int = uuid.getnode()).hex[-12:]
        
    def get_sn(self): 
        sn = "-999999"
        try:
            with open("/tmp/miner_sn") as fd:
                sn = fd.readline().strip()
            return  sn
        except Exception as e:
            logger.error("get serial number failed")
            return sn
    
    def set_seq(self, seq):
        self.seq = seq
        
    def set_cmd(self, cmd):
        self.cmd = cmd
    
    def get_date(self):
        date_format = '%Y-%m-%d %H:%M:%S'
        return datetime.now().strftime(date_format)
        
    def write_json(self):
        data = {"type": self.type, "sn": self.sn, "seq": self.seq,
                "cmd": self.cmd, "result": self.result,
                 "report_time": self.report_time, "act": self.act}
        return json.dumps(data)


def calc_size(input):
    if not (input.endswith("M") or input.endswith("G") or input.endswith("K") or input.endswith("T")):
        raise TypeError("Input must end with M or G or K or T")
    size = float(input.rstrip("[MGKT]"))
    if input.endswith("M"):
        return int(size * 1000)
    elif input.endswith("G"):
        return int(size * 1000 * 1000)
    elif input.endswith("T"):
        return int(size * 1000 * 1000 * 1000)
    else:
        return int(size)
    
    
class MachineInfo(object):
    
    def __init__(self, role = "machine", flow= 0, conn = 0):
        self.cpu_num = None
        self.cpu_online = None
        self.cpu_freq = None
        self.cpu_arch = None
        self.cpu_used = None
        self.mem_total = None
        self.mem_used = None
        self.hd_total = None
        self.disk_used = None
        self.uptime = None
        self.flow = flow
        self.conn = conn
        self.nat_type = None
        self.is_upnp = None
        self.in_ip = None
        self.ex_ip = None 
        self.fs_type = None 
    
    def get_cpuinfo(self):
        nb_cpu = 0
        cpu_online = 0
        cpu_hz = 0
        cpu_hz_flag = True
        cpu_arch = str(platform.machine())
        sys_fs_cpu_path = "/sys/devices/system/cpu/" 
        try:
            for dir in os.listdir(sys_fs_cpu_path):
                m = re.search("cpu[0-9]+", dir)
                if m:
                    nb_cpu += 1
                    sys_fs_spec_cpu = os.path.join(sys_fs_cpu_path, m.group(0))
                    sys_fs_cpu_online = os.path.join(sys_fs_spec_cpu, "online")
                    with open(sys_fs_cpu_online) as cpu_online:
                        online = int(cpu_online.readline().strip())
                        if online:
                            sys_fs_cpu_freq = os.path.join(sys_fs_spec_cpu, "cpufreq/cpuinfo_cur_freq")
                            if cpu_hz_flag:
                                cpu_hz = int(file(sys_fs_cpu_freq).readline().strip())
                                cpu_hz_flag = False
            
        except Exception as e:
            logger.error("get cpu info failed, reason: {0}".format(str(e)))  
            return (nb_cpu, cpu_online, cpu_hz, cpu_arch)              
        cpu_online = int(multiprocessing.cpu_count())
        return (nb_cpu, cpu_online, cpu_hz, cpu_arch)
    
    def get_meminfo(self):
        #python version > 2.6
        #generate meminfo dict
        meminfo = {i.split()[0].rstrip(':'): int(i.split()[1]) for i in open('/proc/meminfo')}
        return meminfo
    
    def get_memtotal(self, meminfo):
        mem_total = meminfo.get("MemTotal", "")
        return mem_total
    
    def get_memused(self, meminfo):
        mem_total = meminfo.get("MemTotal", "")
        mem_free = meminfo.get("MemFree", "")
        mem_used = mem_total - mem_free
        return mem_used
        
    def get_usb_disk(self):
        partitions = []
        with open("/proc/partitions") as disks:
            for disk in disks:
                m = re.search("sd.[0-9]+", disk)
                if m:
                    partitions.append(m.group(0))
        return partitions
    
    def get_hdinfo(self):
        disk_total = 0
        disk_used = 0
        fs_type = None
        partitions = self.get_usb_disk()
        for partition in partitions:
            path = "/dev/" + partition
            command = "df -Th " + path
            try:
                hd_info = subprocess.check_output(command, shell=True).strip()
            except Exception as e:
                logger.error("get disk info failed, reason: {0}".format(str(e)))
                continue
            hd_info = hd_info.split("\n")[1]
            hd_info = hd_info.split()
            try:
                disk_total += calc_size(hd_info[2])
                disk_used += calc_size(hd_info[3])
                fs_type = hd_info[1]              
            except TypeError as e:
                logger.error("calc size failed, reason: {0}".format(str(e)))
                continue
        return (disk_total, disk_used, fs_type)
        
    def get_disktotal(self, hd_info):
        return hd_info[0]
    
    def get_diskused(self, hd_info):
        return hd_info[1]
    
    def get_fstype(self, hd_info):
        return hd_info[2]
    
    def get_uptime(self):
        uptime = ""
        with open("/proc/uptime") as fd:
            uptime = fd.readline().split()[0]
        return int(float(uptime))
    
    def get_time_list(self):
        with open("/proc/stat") as stat_file:
            time_list = stat_file.readline().strip().split()[1:]
        ret = [int(i) for i in time_list]
        return ret 
        
    def get_cpuused(self):
        start = self.get_time_list()
        sleep(INTERVAL)
        end = self.get_time_list()
        ret = [end[i] - start[i] for i,_ in enumerate(start)]
        cpu_percentage = 100 - (ret[3] * 100.0 / sum(ret))
        return round(cpu_percentage, 2)       

    def info(self):
        cpu_info = self.get_cpuinfo()
        if cpu_info:
            self.cpu_num = cpu_info[0]
            self.cpu_online = cpu_info[1]
            self.cpu_freq = cpu_info[2]
            self.cpu_arch = cpu_info[3]
        self.cpu_used = self.get_cpuused()
        mem_info = self.get_meminfo()
        if mem_info:
            self.mem_total = self.get_memtotal(mem_info)
            self.mem_used = self.get_memused(mem_info)
        hd_info = self.get_hdinfo()
        if hd_info: 
            self.hd_total = self.get_disktotal(hd_info)
            self.disk_used = self.get_diskused(hd_info)
            self.fs_type = self.get_fstype(hd_info)
        self.uptime = self.get_uptime()
        self.flow = flow_collect.flow_diff()
        self.is_upnp,  self.in_ip, self.ex_ip, self.nat_type  = nat_type.gen_nat_upnp_info()
        data = {"cpu_num": self.cpu_num, "cpu_online": self.cpu_online,
                "cpu_freq": self.cpu_freq, "cpu_arch": self.cpu_arch,
                "mem_total": self.mem_total, "hd_total": self.hd_total, 
                "cpu_used": self.cpu_used, "mem_used": self.mem_used, 
                "hd_used": self.disk_used, "uptime": self.uptime, 
                "flow": self.flow, "conn": self.conn,
                "nat_type": self.nat_type, "is_upnp": self.is_upnp,
                "in_ip": self.in_ip, "ex_ip": self.ex_ip,
                "fs_type": self.fs_type}
        return data

        
def update_data(url, data, headers=None):
    host = "xyajs.data.p2cdn.com"
    if headers:
        headers = headers
    else:
        headers = headers = {"Host": host, "Content-Type": "Application/json"}
    request = urllib2.Request(url, headers=headers)
    for retry in xrange(5):
        try:
            response = urllib2.urlopen(request, data.write_json(), timeout = 10)
            res =response.read()
            logger.warn("api: {0}, data: {1} response: {2}".format(url, data.write_json(), str(res)))
            return res
        except Exception as e:
            if retry >= 4:
                logger.error("request api {0} failed, error: {1}".format(url, str(e)))
                return -1
            sleep(0.5 * retry)
            continue
          
def update_machineinfo(ip_addr):
    mac_info =  MachineInfo().info()
    url = "http://%s/o_galaxy_monitor_cycle" % ip_addr
    res = []
    res.append(mac_info)
    data = Message("reportinforeq", "machine", result = res)
    sn = data.get_sn()
    return update_data(url, data)

'''
   test
'''
if __name__ == "__main__":
    print update_machineinfo()
    print get_task()
