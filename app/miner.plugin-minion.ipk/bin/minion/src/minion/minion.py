# -*- coding: utf-8 -*-
import sys
import os
import random
import ConfigParser
import threading
from os.path import dirname, abspath
base_path = dirname(dirname(abspath(__file__)))
sys.path.append(base_path)
import base
import log.setup
from log.setup import setup_logfile_logger
from daemon import Daemon
from time import sleep


logger = log.setup.logging.getLogger(__name__)    

PROC_INFO = "/var/run/.procinfo"

class TaskWorker(Daemon):
    
    def __init__(self, pidfile, master_addr, log_file, duration, billing_log_dir, datacenter):
        super(TaskWorker, self).__init__(pidfile)
        self.master_addr = master_addr
        self.log_file = log_file
        self.duration = duration
        self.datacenter = datacenter
        self.billing_log_dir = billing_log_dir
    
    def run(self):
        setup_logfile_logger(os.path.abspath(self.log_file))
        nat_thread = threading.Thread(target=base.save_proc_info_loop, args=(self.master_addr,))
        nat_thread.daemon = True
        nat_thread.start()
        while True:
            try:
                base.update_billing_info(self.billing_log_dir, self.datacenter)
            except Exception as e:
                logger.error("up date billing info failed, reason:{0}".format(str(e)))
            proc_info = base.read_proc_info()
            if proc_info:
                if proc_info["code"] == 0:
                    proc_names = proc_info["result"].get("process", "")
                    paths = proc_info["result"].get("folder", "")
                    if proc_names:
                        base.update_proc_info(self.datacenter, proc_names)
                    if paths:
                        base.update_path_info(self.datacenter, paths)
            sleep(float(self.duration))
            
def config_parse():
    ret = dict()
    config =  ConfigParser.ConfigParser()
    config.read(os.path.join(base_path, "../conf/minion.conf"))
    if not "global" in config.sections():
        raise ValueError("must specify global section in config")
    for section in config.sections():
        if section == "global":
            ret["pid_file"] = config.get("global", "pid_file")
            ret["master_addr"] = config.get("global", "master_addr")
            ret["log_file"] = config.get("global", "log_file")
            ret["duration"] = config.get("global", "duration")
            ret["billing_log_dir"] = config.get("global", "billing_log_dir")
        if section == "datacenter":
            ret["address"] = config.get("datacenter", "address")
    return ret
           
def main():
    if len(sys.argv) < 2:
        sys.stderr.write("Usage: minion.py start|stop|restart\n")
        sys.exit(1)
    action = sys.argv[1]
    try:
        config = config_parse()
    except Exception as e:
        sys.stderr.write("read config failed, reason: {0}".format(str(e)))
        sys.exit(1)
    pidfile = config.get("pid_file", "/var/run/minion.pid")
    master_addr = config.get("master_addr", "xy.matrix.p2cdn.com")
    log_file = config.get("log_file", "/var/log/minion")
    duration = config.get("duration", 60.0)
    billing_log_dir = config.get("billing_log_dir", "/var/log/netprog")
    datacenter = config.get("address", "xyajs.data.p2cdn.com")
    worker = TaskWorker(pidfile, master_addr, log_file, duration, billing_log_dir, datacenter)
    if action == "start":
        worker.start()
    elif action == "stop":
        worker.stop()
    elif action == "restart":
        worker.restart()
    else:
        sys.stderr.write("Don't support option %s\n" % action)
        sys.stderr.write("Usage: minion.py start|stop|restart\n")
        sys.exit(1)
    #worker.run()
    
if __name__ == "__main__":
    main()