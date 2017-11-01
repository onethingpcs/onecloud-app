#!/bin/python
import os
import hashlib
import logging
import logging.handlers
import commands
import sys
LOG_FILE = '/tmp/.ubt.log'
logger=None
uboot_dev=[]


def init_device():
    global uboot_dev
    if os.path.exists('/dev/mmcblk0boot0'):
        logger.info("mmcblk0boot0 is exist")
        uboot_dev.append("/dev/mmcblk0boot0")
        uboot_dev.append("/dev/mmcblk0boot1")
    elif os.path.exists("/dev/mmcblk1boot0") :
        logger.info("mmcblk0boot1 is exist")
        uboot_dev.append("/dev/mmcblk1boot0")
        uboot_dev.append("/dev/mmcblk1boot1")
    uboot_dev.append("/dev/bootloader")
    return

def get_local_uboot():
    dir=os.path.dirname(os.path.realpath(__file__))
    uboot=dir+"/u-boot.bin"
    logger.info("uboot local path is %s" % uboot)
    return uboot

def md5sum(filename):
    fd = open(filename,"r")
    fcont = fd.read()
    fd.close()
    fmd5 = hashlib.md5(fcont).hexdigest()
    size = os.path.getsize(filename)
    return fmd5,size 

def loginit():
    global LOG_FILE
    global logger
    if os.path.exists(LOG_FILE):
        os.remove(LOG_FILE)

    handler = logging.handlers.RotatingFileHandler(LOG_FILE, maxBytes = 1024*1024, backupCount = 5)
    fmt = '%(asctime)s - %(filename)s:%(lineno)s - %(name)s - %(message)s'
    formatter = logging.Formatter(fmt)
    handler.setFormatter(formatter)
    logger = logging.getLogger('tst')
    logger.addHandler(handler)
    logger.setLevel(logging.DEBUG)

def upgrade_uboot(filename):
    global uboot_dev
    for dev_name in uboot_dev:
        logger.info("start open device %s" % dev_name)
        command="dd if="+filename+" of="+dev_name
        logger.info("command [%s]" % command)
        (status, output) = commands.getstatusoutput(command)
    return

def get_fw_uboot_md5(size):
    global uboot_dev
    md5list=[]
    md5=None
    for dev_name in uboot_dev:
        f = open(dev_name,"rb")
        data = f.read(size)
        md5=hashlib.md5(data).hexdigest()
        md5list.append(md5)
        f.close()
        logger.info("dev name %s, md5 result %s" % (dev_name,md5))

    if md5list[0] == md5list[1] :
        if md5list[1] == md5list[2]:
            md5=md5list[0]
    logger.info("get fw uboot md5 %s" % md5)
    return md5

def main():
    global uboot_dev
    loginit()
    init_device()
    local_uboot=get_local_uboot()
    local_uboot_md5,local_size = md5sum(local_uboot)
    logger.info("local uboot %s md5 is %s size is %d" % (local_uboot,local_uboot_md5,local_size))
    fw_uboot_md5=get_fw_uboot_md5(local_size)

    if local_uboot_md5 == fw_uboot_md5 :
        logger.info("Current uboot is 1130,don't need upgrade")
    else:
        logger.info("upgrade uboot start")
        upgrade_uboot(local_uboot)
        logger.info("upgrade uboot end, start check md5")
        new_md5=get_fw_uboot_md5(local_size)
        if new_md5 == local_uboot_md5 :
            logger.info("upgrade uboot success")
        else:
            logger.info("upgrade uboot failed")
#        commands.getstatusoutput("ubus call mnt blink")
        logger.info("ubus call mnt blink")

    logger.info("wait")
    return

main()
