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

class SysInfo(Daemon):
    
    def __init__(self, pidfile, master_addr, log_file, duration, datacenter):
        super(SysInfo, self).__init__(pidfile)
        self.master_addr = master_addr
        self.log_file = log_file
        self.duration = duration
        self.datacenter = datacenter

    
    def run(self):
        setup_logfile_logger(os.path.abspath(self.log_file))
        nat_thread = threading.Thread(target=base.nat_type.save_upnp_nat_loop, args=())
        nat_thread.daemon = True
        nat_thread.start()
        while True:
            base.update_machineinfo(self.datacenter)
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
        if section == "datacenter":
            ret["address"] = config.get("datacenter", "address")
    return ret
           
def main():
    if len(sys.argv) < 2:
        sys.stderr.write("Usage: docker-minion.py start|stop|restart\n")
        sys.exit(1)
    action = sys.argv[1]
    try:
        config = config_parse()
    except Exception as e:
        sys.stderr.write("read config failed, reason: {0}".format(str(e)))
        sys.exit(1)
    pid_file = config.get("pid_file", "/var/run/sysinfo.pid")
    master_addr = config.get("master_addr", "xy.matrix.p2cdn.com")
    log_file = config.get("log_file", "/var/log/sysinfo")
    duration = config.get("duration", 60.0)
    datacenter = config.get("address", "xyajs.data.p2cdn.com")
    worker = SysInfo(pid_file, master_addr, log_file, duration, datacenter)
    if action == "start":
        worker.start()
    elif action == "stop":
        worker.stop()
    elif action == "restart":
        worker.restart()
    else:
        sys.stderr.write("Don't support option %s\n" % action)
        sys.stderr.write("Usage: docker-minion.py start|stop|restart\n")
        sys.exit(1)
    #worker.run()
    
if __name__ == "__main__":
    main()