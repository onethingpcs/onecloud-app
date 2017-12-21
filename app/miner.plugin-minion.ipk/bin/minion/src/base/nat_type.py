import os
import sys
import subprocess
import logging
import re
import time
from time import sleep
import signal

logger = logging.getLogger(__name__)
BASEDIR = os.path.dirname(os.path.abspath(__file__))
UPNPPATTERN = re.compile("upnp:\ (.*),(\d+.\d+.\d+.\d+:\d+),(\d+.\d+.\d+.\d+:\d+)$", re.MULTILINE)
NATPATTERN = re.compile("(nat\ type:).*(\d+)$", re.MULTILINE)
NATUPNPINFO = "/var/run/.upnpnat"

def clean_worker(worker, wait_for_kill=10):
    '''
    Generic method for cleaning up multiproessing workers
    
    From: https://github.com/saltstack/salt/blob/v2014.1.13/salt/master.py#L74
    Orig func clean_proc clean mutilprocessing, make little change for subprocess
    '''
    # NoneType and other fun stuff need not apply
    if not worker:
        return
    try:
        waited = 0
        while worker.poll() == None:
            worker.terminate()
            waited += 1
            time.sleep(0.1)
            if worker.poll() == None and (waited >= wait_for_kill):
                logging.error(
                    'process did not die with terminate(): {0}'.format(
                        worker.pid
                    )
                )
                os.kill(signal.SIGKILL, worker.pid)
    except (AssertionError, AttributeError):
        # Catch AssertionError when the worker is evaluated inside the child
        # Catch AttributeError when the pro ess dies between worker.is_alive()
        # and worker.terminate() and turns into a NoneType
        pass

def gen_nat_upnp_info():
    is_upnp, in_ip, ex_ip = None, None, None
    nat_type = None
    res = read_upnp_nat()
    try:
        if res:
            is_upnp, in_ip, ex_ip, nat_type = res.split()
    except Exception as e:
        logger.error("gen nat upnp info failed, reason: {0}".format(str(e)))
    if is_upnp:
        is_upnp = int(is_upnp)
    if nat_type:
        nat_type = int(nat_type)
    return (is_upnp, in_ip, ex_ip, nat_type)

def save_upnp_nat_loop():
    while True:
        info = invoke_natdetect()
        res = parser_upnp_nat_type(info)
        save_upnp_nat(res)
        sleep(60*10.0)

def is_natdetect_running():
    ret = None
    comm = "ps -ef | grep net_detect | grep -v grep |awk '{print $1}'"
    try:
        ret = subprocess.check_output(comm, shell=True)
    except Exception as e:
        logger.error("check net_detect failed, reason: {0}".format(str(e)))
    return ret
    
def invoke_natdetect():
    bin = os.path.join(BASEDIR, "../../package/net_detect")
    ret = None
    is_running = is_natdetect_running()
    if is_running:
        logger.error("last net detec is runing, pid: %s" % str(is_running))
        os.kill(signal.SIGKILL, is_running)
    try:
        ret = subprocess.check_output(bin, shell=True)
    except Exception as e:
        logger.error("exec process failed, reason: {0}".format(str(e)))
    return ret

def parser_upnp_nat_type(data):
    m_upnp = UPNPPATTERN.search(data)
    m_nat = NATPATTERN.search(data)
    is_upnp, in_ip, ex_ip = None, None, None
    nat_type = None
    if m_upnp and len(m_upnp.groups()) == 3:
        is_upnp = m_upnp.group(1)
        in_ip = m_upnp.group(2).split(":")[0]
        ex_ip = m_upnp.group(3).split(":")[0]
    if m_nat and len(m_nat.groups()) == 2:
        nat_type = m_nat.group(2)
    return (is_upnp, in_ip, ex_ip, nat_type)
 
def save_upnp_nat(info):
    with open(NATUPNPINFO, "w") as fd:
        fd.write(" ".join(info))
         
def read_upnp_nat():
    res = None
    if not os.path.exists(NATUPNPINFO):
        return res
    with open(NATUPNPINFO) as fd:
        content = fd.readline()
        res = content.strip()
    return res

#test       
if __name__ == "__main__":
    data = invoke_natdetect()
    res = parser_upnp_nat_type(data)
    save_upnp_nat(res)
    