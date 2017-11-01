#!/usr/bin/python

import urllib
import urllib2
import os
import hashlib
import logging
import logging.handlers
import commands
import sys
import time
import json

LOG_FILE='/var/log/.smbinst.log'

EN_READ_SN=1
EN_READ_VER=2
EN_DOWNLOAD_SMB=3
EN_INSTALL_SMB=4
EN_INSTALL_SUCCESS=5
EN_INSTALL_FAILED=6

def issmbstart():
    try:
        res=os.popen("cat /thunder/etc/config.json")
    except:
        return False
    config_json=res.read()
    logger.info("is smb running :[%s]" % config_json)
    try:
        flag=json.loads(config_json)["samba"]
    except:
        flag=False
    return flag


def loginit():
    global LOG_FILE
    global logger
    if os.path.exists(LOG_FILE):
        os.remove(LOG_FILE)

    handler = logging.handlers.RotatingFileHandler(LOG_FILE, maxBytes = 1024*1024, backupCount = 5)
    fmt = '%(asctime)s - %(filename)s:%(lineno)s - %(name)s - %(message)s'
    formatter = logging.Formatter(fmt)
    handler.setFormatter(formatter)
    logger = logging.getLogger('smb')
    logger.addHandler(handler)
    logger.setLevel(logging.DEBUG)

def read_SN():
    sn=None
    try:
        sn=os.popen("cat /tmp/miner_sn")
    except:
        sn=None
    if sn != None:
        sn=sn.read().strip()
        logger.info("sn [%s]" % sn)
    return sn

def read_local_smbver():
    ver=None
    if (os.path.exists("/usr/sbin/smbd") == False) or (os.path.exists("/usr/sbin/nmbd") == False):
        ver="0.0.0"
        return ver

    try:
        ver=os.popen("/usr/sbin/smbd --version")
    except:
        try:
            ver=os.popen("/usr/sbin/nmbd --version")
        except:
            ver=None
    if ver != None:
        name,ver=ver.read().split()
        logger.info("name [%s] ver [%s]" % (name,ver))
    return ver

def report_state(sn,version):
    url = "http://upgrade.peiluyou.com:5180/device/%s/sambatest/%s/install" % (sn,version)
    req = urllib2.Request(url)
    logger.info("Reguest url %s ,get req %s" % (url,req))

    res_data = urllib2.urlopen(req)
    res = res_data.read()
    logger.info("Reguest url %s ,get req %s" % (url,req))

def dl_smbipk():
    cmd='opkg update'
    ret=os.system(cmd)
    logger.info("cmd: [%s] ret:[%d]" % (cmd,ret))
    cmd='cd /tmp; opkg download samba'
    ret=os.system(cmd)
    logger.info("cmd: [%s] ret:[%d]" % (cmd,ret))
    return ret

def install_smbipk():
    cmd='opkg install /tmp/samba_4.6.7_arm.ipk'
    ret=os.system(cmd)
    logger.info("cmd: [%s] ret:[%d]" % (cmd,ret))
    return ret

def clear_ipk():
    cmd='opkg remove samba'
    ret=os.system(cmd)
    cmd='rm /tmp/samba*.ipk'
    ret=os.system(cmd)

#EN_READ_SN=1
#EN_READ_VER=2
#EN_DOWNLOAD_SMB=3
#EN_INSTALL_SMB=4
#EN_INSTALL_SUCCESS=5
#EN_INSTALL_FAILED=6


if __name__ == '__main__':
    loginit()
    STATE=EN_READ_SN
    sn=None
    ver=None
    running_flag=issmbstart()
    while True:
        if STATE == EN_READ_SN:
            sn=read_SN()
            if sn != None :
                STATE = EN_READ_VER
                logger.info("state : read sn [%s]" % sn);
                continue;
            else:
                logger.info("state : read sn sleep 5");
                time.sleep(5)
                continue;

        if STATE == EN_READ_VER:
            ver = read_local_smbver()
            if ver == "4.6.7":
                logger.info("state : read version [%s]" % ver)
                time.sleep(60*60*24)
                continue;
            else:
                STATE = EN_DOWNLOAD_SMB
                continue;

        if STATE == EN_DOWNLOAD_SMB:
            logger.info("state : download smb")
            ret = dl_smbipk()
            if ret == 0 : 
                STATE = EN_INSTALL_SMB
                continue;
            else:
                logger.info("state : download smb again")
                time.sleep(10)
                continue;

        if STATE == EN_INSTALL_SMB:
            ret = install_smbipk()
            if ret == 0:
                STATE = EN_INSTALL_SUCCESS
                if running_flag == True:
                    logger.info("state: install smb over,restart it")
                    os.system("/etc/init.d/S91smb restart");
                continue
            else:
                STATE = EN_INSTALL_FAILED
                continue

        if STATE == EN_INSTALL_SUCCESS:
            logger.info("state : install success")
            report_state(sn,"4.6.7");
            time.sleep(60*60*24)
            continue

        if STATE == EN_INSTALL_FAILED:
            logger.info("state : install smbipk failed")
            clear_ipk()
            STATE=EN_READ_SN
            continue
