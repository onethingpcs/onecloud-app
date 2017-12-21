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
from datetime import datetime
import multiprocessing
import hashlib
from hashlib import md5
import copy
import size
import flow_collect
import pickle


logger = logging.getLogger(__name__)
# clock ticks per second... jiffies (HZ)
'''
     global var
'''
JIFFIES_PER_SEC = os.sysconf('SC_CLK_TCK')
PAGE_SIZE = os.sysconf('SC_PAGE_SIZE')
INTERVAL = 1
PROC_INFO = "/var/run/.procinfo"



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


class AppInfo(object):
    
    def __init__(self):
        self.appinfo = []
           
    """
    docker client api stats
    langs: go
    
    func (s *containerStats) Display(w io.Writer) error {
    s.mu.RLock()
    defer s.mu.RUnlock()
    if s.err != nil {
        return s.err
    }
    fmt.Fprintf(w, "%s\t%.2f%%\t%s/%s\t%.2f%%\t%s/%s\n",
        s.Name,
        s.CPUPercentage,
        units.HumanSize(s.Memory), units.HumanSize(s.MemoryLimit),
        s.MemoryPercentage,
        units.HumanSize(s.NetworkRx), units.HumanSize(s.NetworkTx))
    return nil
    }
    
    parse this output in below
    
    """  
    def get_sourceinfo(self, stats):
        source_info = stats.split("\n")[1]
        source_info = re.sub("  +", ",", source_info)
        try:
            cpu_info, mem_info, _, net_info = source_info.split(",")[1:5]
            mem_usage, mem_limit = mem_info.split("/")
            cpu_info = cpu_info.rstrip("%")
            net_rx, net_tx = net_info.split("/")
            net_rx = size.calc_size(net_rx)
            net_tx = size.calc_size(net_tx)
            mem_usage = size.calc_size(mem_usage)
            mem_limit = size.calc_size(mem_limit)
        except TypeError as e:
            logger.error("calc size error, reazon: {0}".format(str(e)))
            return(0, 0, 0, 0, 0)
        return (cpu_info, net_rx, net_tx, mem_usage, mem_limit)
        
    def get_imageinfo(self):
        command = "docker ps"
        try:
            ret = subprocess.check_output(command, shell=True)
        except Exception as e:
            logger.error("get app info failed, reason: {0}".format(str(e)))
            return
        lineno = 0
        ports = ""
        version = "latest"
        for line in ret.split("\n"):
            if line:
                lineno += 1
                if lineno > 1:
                    line = re.sub("  +", ",", line)
                    elts = line.split(",")
                    if len(elts) < 7:
                        ID, image, command, created, status, names = elts[:]
                        comm = "docker stats %s --no-stream" % names
                        try:
                            stats = subprocess.check_output(comm, shell=True)
                            cpu, net_rx, net_tx, mem_usage, mem_limit = self.get_sourceinfo(stats)
                        except Exception as e:
                            logger.error("get container source info failed, reason: {0}".format(str(e)))
                            return
                    else:
                        ID, image, command, created, status, ports, names = elts[:]
                        comm = "docker stats %s --no-stream" % names
                        try:
                            stats = subprocess.check_output(comm, shell=True)
                            cpu, net_rx, net_tx, mem_usage, mem_limit = self.get_sourceinfo(stats)
                        except Exception as e:
                            logger.error("get container source info failed, reason: {0}".format(str(e)))
                            return
                    if ":" in image:
                        image, version = image.split(":")
                    container_ret = {"image": image, "command": command.strip('"'),
                                     "created": created, "status": status,
                                     "ports": ports, "names": names,
                                     "version": version, "flow": -1,
                                     "id": ID, "cpu": cpu, "net_rx": net_rx, "net_tx": net_tx,
                                     "mem_usage": mem_usage, "mem_limit": mem_limit}
                    self.appinfo.append(container_ret)
    
    def info(self):
        return self.appinfo
 
 
class Process(object):
    
    def __init__(self, proc_name):
        self.proc_name = proc_name
        self.proc_info = None
        self.cpu_usage = None
        self.rss = None
        self.bin_md5 = None
        self.start_time = None
    
    def get_pids(self):
        pids = []
        try:
            for dir in os.listdir("/proc"):
                pid = re.search("[0-9]+", dir)
                if pid:
                   #cmdline contain some non printable character
                   #need to filter these c, do not support unicode
                   #https://stackoverflow.com/questions/92438/stripping-non-printable-characters-from-a-string-in-python
                    try:
                        cmdline = open(os.path.join("/proc", pid.group(0), "comm")).readline().strip()
                    except IOError as e:
                        continue
                    cmdline_printable = filter(lambda x: x in string.printable, cmdline)
                    if self.proc_name == cmdline_printable:
                        pids.append(pid.group(0))
        except Exception as e:
            logger.error("get proc_name's pids failed, reason:{0}".format(str(e)))
            return pids
        return pids               
    
    def read_cpu(self, pid):
        try:
            with open("/proc/%s/stat" % pid) as stat_file:
                cpu_time = [int(cpu_time) for cpu_time in stat_file.readline().split()[13:17]]
                return sum(cpu_time)
        except Exception as e:
            logger.error("get {0} stat failed, reason: {1}".format(pid, str(e)))  
            return 0
         
    def get_proc_cpuusage(self, pids):
        cpu_usage = 0
        if pids:
           start = [self.read_cpu(pid) for pid in pids]
           sleep(INTERVAL)
           end = [self.read_cpu(pid) for pid in pids]
           cpu_time = [100 *((end[i] - start[i]) / float(JIFFIES_PER_SEC)) for i,_ in enumerate(start)]
           cpu_usage = sum(cpu_time)
        return round(cpu_usage, 2)
           
    def get_rss(self, pids):
        logger.debug('getting rss for pids')
        rss = 0
        for p in pids:
            try:
                statm = open('/proc/' + p + '/statm', 'rt').readline().split()
            except:
                logger.warning('get statm failed for pid: ' + p)
                continue
            rss += int(statm[1])
        rss *= PAGE_SIZE
        return rss
    
    def calc_md5(self, pids):
        v_md5 = None
        for pid in pids:
            try:
                bin_abs_path = os.readlink("/proc/" + pid + "/exe")
                v_md5 = str(md5(open(bin_abs_path).read()).hexdigest())
                break
            except Exception as e:
                logger.error("read command bin path failed, reason: {0}".format(str(e))) 
        return v_md5
    
    def formattime(self, epoch):
        t = time.localtime(epoch)
        date_format = '%Y-%m-%d %H:%M:%S'
        return time.strftime(date_format, t)
       
    def read_starttime(self, pids):
        """
        btime: system boot time in epoch(from 1970)
        stime: application start time from system boot time, in jiffies (HZ)
        """
        start_time = 0 
        try:
            pid = pids[0]
            p = re.compile(r"^btime (\d+)$", re.MULTILINE)
            m = p.search(open("/proc/stat").read())
            btime = int(m.groups()[0]) #system start time
            stime = int(open("/proc/%s/stat" % pid).readline().split()[21]) / JIFFIES_PER_SEC
            start_time = btime + stime
        except Exception as e:
            logger.error("calc start time failed, error reason: {0}".format(str(e)))
            return self.formattime(start_time)
        return self.formattime(start_time)      
    
    def info(self):
        pids = self.get_pids()
        self.cpu_usage = self.get_proc_cpuusage(pids)
        self.rss = self.get_rss(pids)
        self.bin_md5 = self.calc_md5(pids)
        self.start_time = self.read_starttime(pids)
        data = {"proc_name": self.proc_name, "cpu_usage": self.cpu_usage,
                "rss": self.rss, "bin_md5": self.bin_md5, "start_time": self.start_time}
        return data

                
def str_hash(src_str):    
    try:
        from hashlib import md5
        return str(md5(src_str).hexdigest())
    except ImportError as e:
        import md5
        return str(md5.new(src_str).hexdigest())

def gen_sign(data, uri, user="miner", key="kfjheiof8e75e85be0859ba29f0cbnka" ):
    t = str(int(time.time()))
    s = "%s&%s&%s&%s&%s" % (user, t, uri, data.write_json(), key)
    token = str_hash(s)
    sign = "sign=%s-%s-%s" % (user, t, token)
    return sign

def request_api(url, data, headers=None):
    host = "docker-report.live.p2cdn.com"
    if headers:
        headers = headers
    else:
        headers = headers = {"Host": host, "Content-Type": "Application/json"}
    request = urllib2.Request(url, headers=headers)
    for retry in xrange(5):
        try:
            response = urllib2.urlopen(request, data.write_json(), timeout = 10)
            res =response.read()
            logger.warn("api: {0}, response: {1}".format(url, str(res)))
            return json.loads(res)
        except Exception as e:
            if retry >= 4:
                logger.error("request api {0} failed, error: {1}".format(url, str(e)))
                return None
            sleep(0.5 * retry)
            continue
        
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

def save_proc_info_loop(master_addr):
    while True:
        info = get_proc_info(master_addr)
        write_proc_info(info)
        sleep(60*10.0)

       
def get_proc_info(master_addr):
    data = Message("pullcmdrsp")
    sn = data.get_sn()
    uri = "/miner/monitorparam"
    sign = gen_sign(data, uri)
    url = "http://%s%s?%s&sn=%s" % (master_addr, uri, sign, sn)
    return request_api(url, data)

def write_proc_info(data):
    try:
        with open(PROC_INFO, "wb+") as fd:
            pickle.dump(data, fd)
    except Exception as e:
        logger.error("write process info failed, reason: {0}".format(str(e)))
        pass

def read_proc_info():
    data = None
    try:
        with open(PROC_INFO, "rb+") as fd:
            data = pickle.load(fd)   
    except Exception as e:
        logger.error("read process info failed, reason: {0}".format(str(e))) 
    return data   

def get_disk_usage(path):
    logger.debug('getting disk usage for path')
    usage = 0
    if os.path.isdir(path):
        try:
            comm = "du -sh %s" % path
            usage = subprocess.check_output(comm, shell=True).strip().split()[0]
            usage = size.calc_du_size(usage)
        except Exception as e:
            logger.error("get disk usage failed for path: " + path)
    return usage

def is_path_writeable(path):
    is_writeable = "False"
    if os.path.isdir(path):
        try:
            with open(os.path.join(path, "test"), "w+") as test_file:
                test_file.write("test")
                is_writeable = "True"
        except Exception as e:
            logger.error("write test failed, path {0}, reason: {1}".format(path, str(e)))
            return is_writeable
    return is_writeable

def is_path_exist(path):
    if os.path.isdir(path):
        return "True"
    return "False"

def formattime(epoch):
    t = time.localtime(epoch)
    date_format = '%Y-%m-%d %H:%M:%S'
    return time.strftime(date_format, t)

def get_path_stat(path):
    if os.path.isdir(path):
        stat = os.stat(path)
        uid = stat.st_uid
        gid = stat.st_gid
        mtime = int(stat.st_mtime)
        mtime = formattime(mtime)
        return (uid, gid, mtime)
    else:
        return (None, None, None)

def update_appinfo(ip_addr):
    url = "http://%s/direct_report_app" % ip_addr
    appinfo = AppInfo()
    appinfo.get_imageinfo()
    container_ret = appinfo.info()
    data = Message("reportinforeq", act = "container", result = container_ret)
    sn = data.get_sn()
    return request_api(url, data)

def update_proc_info(ip_addr, proc_names):
    url = "http://%s/o_galaxy_monitor_cycle" % ip_addr
    ret = []
    for proc_name in proc_names:
        proc_info = Process(proc_name)
        ret.append(proc_info.info())
    data = Message("reportinforeq", "ipk", result = ret)
    sn = data.get_sn()
    return update_data(url, data)

def update_path_info(ip_addr, paths):
    url = "http://%s/o_galaxy_monitor_cycle" % ip_addr
    ret = []
    path_info = {"path": None, "usage": 0,
                 "is_exist": None, "is_writeable": None,
                 "uid": None, "gid": None, "mtime": None}
    try:
        for path in paths:
            path = path.encode() #unicode 2 ascii
            path_info["path"] = path
            path_info["usage"] = get_disk_usage(path)
            path_info["is_exist"] = is_path_exist(path)
            path_info["is_writeable"] = is_path_writeable(path)
            path_info["uid"], path_info["gid"], path_info["mtime"] = get_path_stat(path)
            ret.append(path_info)
    except Exception as e:
        logger.error("get paths info failed, reason: {0}".format(str(e)))
    data = Message("reportinforeq", "path", result = ret)
    sn = data.get_sn()
    return update_data(url, data)

"""
   get specific application flow data
"""
def update_billing_info(billing_log_dir, ip_addr):
    url = "http://%s/o_galaxy_monitor_cycle" % ip_addr
    index_file = "/var/run/.billinfo"
    prev_pos_record ="/var/run/.prevbilling"
    billing_files = flow_collect.get_sorted_logs(billing_log_dir)   
    queued_data, candidates, offset = flow_collect.gen_billing_dict(billing_files, index_file, prev_pos_record)
    if queued_data is None:
        logger.error("no more flow log need to update")
        return
    elif candidates == "latest":
        cur_log = billing_files[-1]
        cur_res = queued_data
        data = Message("reportinforeq", "flow", result = cur_res)
        sn = data.get_sn()
        ret = update_data(url, data)
        if ret == -1:
            logger.error("upload billing log: %s failed" % cur_log)
            flow_collect.save_index(index_file, cur_log)
            return
        else:
            flow_collect.save_pos("/var/run/.prevbilling", cur_log, offset)
        
    else:
        if not queued_data:
            flow_collect.save_index(index_file, billing_files[-1])
            return
        for k, v in queued_data.items():
            data = Message("reportinforeq", "flow", result = v)
            sn = data.get_sn()
            ret = update_data(url, data)
            if ret != -1:
                continue
            else:
                logger.error("upload billing log: %s failed" % k)
                flow_collect.save_index(index_file, k)
                return
                #to do: exit loop, record last file fail to uploaded
        flow_collect.save_index(index_file, billing_files[-1])
      

'''
   test
'''
if __name__ == "__main__":
    print update_machineinfo()
    print get_task()
