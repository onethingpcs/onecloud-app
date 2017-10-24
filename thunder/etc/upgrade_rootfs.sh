#!/bin/sh
ROOTFS_MD5_FILE='/tmp/rootfs_md5'
ROOTFS_MOUNT='/tmp/rootfs'
UPGRADE_LOG='/tmp/upgrade_rootfs.log'
ROOTFS_TGZ="/tmp/minecrafter_rootfs_${1}.tar.gz"
ROOTFS_OPKG_NAME="onecloud-rootfs"

log_print ()
{
    echo $1 >> $UPGRADE_LOG
    echo $1
}

burn_rootfs ()
{
    #step0: check rootfs file
    if [ -f $ROOTFS_TGZ ];then
      log_print "find rootfs ${ROOTFS_TGZ}"
    else
      log_print "can't find rootfs ${ROOTFS_TGZ}"
      return 1
    fi
    
    #step1: check version
    ROOTFS_VERSION=`fw_printenv rootfs_version | awk -F "=" '{print $2}'`

    if [ "$ROOTFS_VERSION" = "$1" ]; then 
        log_print "the rootfs has already upgraded to version $1"
        return 1
    fi

    log_print "Read second_rootfs_load env " 

    #step2:check rootfs partition
    SECOND_LOAD_ROOTFS=`fw_printenv second_rootfs_load 2>/dev/null | grep second_rootfs_load | awk -F "=" '{print $2}'`

    if [ "$SECOND_LOAD_ROOTFS" = "off" ]; then
        log_print "rootfs loaded from 1st partition"
        ROOTFS_DEVICE_WRITE="/dev/backup"
        NEXT_FLAG="on"
    elif [ "$SECOND_LOAD_ROOTFS" = "on" ]; then
        log_print "rootfs loaded from 2nd partition"
        ROOTFS_DEVICE_WRITE="/dev/system"
        NEXT_FLAG="off"
    else
        log_print "unknown second_rootfs_load=\"$SECOND_LOAD_ROOTFS\""
        return 1
    fi

    #step3: MAKE EXT4 ROOTFS SYSTEM IN THE OTHER DEVICE PARTITION
    log_print "make ext4 filesystem on $ROOTFS_DEVICE_WRITE"
    mkfs.ext4 -F -t ext4 "$ROOTFS_DEVICE_WRITE" 2>&1 >> $UPGRADE_LOG
    
    #step4:MOUNT THE OTHER PARTITION IN EXT4 FS TYPE TO /tmp/rootfs    
    umount -f $ROOTFS_MOUNT 2>&1 >> $UPGRADE_LOG
    rm -rf $ROOTFS_MOUNT
    mkdir -p $ROOTFS_MOUNT
    
    log_print "mount $rootfs_device_write $rootfs_mount"
    mount -t ext4 $ROOTFS_DEVICE_WRITE $ROOTFS_MOUNT

    if [ "$?" = "0" ];then
        MD5SUM_VALUE=`md5sum $ROOTFS_TGZ | awk '{print $1}'`
        ROOTFS_MD5=`cat $ROOTFS_MD5_FILE`
        if [ "$MD5SUM_VALUE" == "$ROOTFS_MD5" ];then
                log_print "MD5 CHECK SUCCESS"
        else
                log_print "MD5 CHECK failed, exit upgrade script"
                log_print "$MD5SUM_VALUE  $ROOTFS_MD5"
                umount -f $ROOTFS_MOUNT
                return 1
        fi
    else
        log_print "can't mount rootfs,mkfs.ext4 $ROOTFS_DEVICE_WRITE fail"
        return 1
    fi

    log_print "tar xzf $ROOTFS_TGZ -C $ROOTFS_MOUNT"
    tar xzf $ROOTFS_TGZ -C $ROOTFS_MOUNT
    
    if [ $? -ne 0 ]; then
      log_print "decompress $ROOTFS_TGZ to $ROOTFS_MOUNT fail"
      return 1
    fi
    
    \cp -a /thunder/ $ROOTFS_MOUNT/
    cp -a /etc/passwd*  $ROOTFS_MOUNT/etc/
    cp -a /etc/group  $ROOTFS_MOUNT/etc/
    cp -a /etc/shadow* $ROOTFS_MOUNT/etc/
    cp -a /usr/lib/opkg/info/thunder-miner-app.* $ROOTFS_MOUNT/usr/lib/opkg/info/
    cp -a /usr/lib/opkg/status $ROOTFS_MOUNT/usr/lib/opkg/

    HOST_SN=`/thunder/bin/readkey sn | grep "data: "|sed 's/.*\(....\)$/\1/'`
    echo "        option hostname    Minecrafter_$HOST_SN" >> $ROOTFS_MOUNT/etc/config/network
    touch $ROOTFS_MOUNT/.ROOTFS_$1.REC
    sync
    sleep 1
    sync

    log_print "reset env into rom"
    umount $ROOTFS_MOUNT
    log_print "`fsck.ext4 -fp $ROOTFS_DEVICE_WRITE`"
    
    log_print "set env rootfs_version $1"
    fw_setenv rootfs_version $1 > /dev/null
    
    log_print "set env second_rootfs_load $NEXT_FLAG"
    fw_setenv second_rootfs_load $NEXT_FLAG > /dev/null
    
    log_print "update rootfs success"
    rm -rf ${ROOTFS_TGZ}
    echo $1 > /tmp/.HAS_UPGRADE_ROOTFS_IMG
    echo -e "\033[42;31;5m UPGRADE SUCCESS \033[0m"
    
    return 0
}

usage()
{
    echo "$1 <rootfs_version> "
}

if [ $# -lt 1 ];then
  usage $0
  exit 1
fi

#echo "dont't need update rootfs " > /tmp/upgrade_rootfs.log
#echo "start update rootfs " > /tmp/upgrade_rootfs.log

if [ -f "/tmp/.HAS_UPGRADE_ROOTFS_IMG" ];then
  log_print "rootfs has been upgraded,waiting for reboot now"
else
  log_print "====================`date`====================="
  burn_rootfs $1
  
  if [ $? -ne 0 ]; then
    log_print "upgrade rootfs fail,opkg remove $ROOTFS_OPKG_NAME"
    opkg remove $ROOTFS_OPKG_NAME
  fi
fi

exit 0
