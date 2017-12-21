#!/bin/sh

update_busybox ()
{
    diff /bin/busybox_patch /thunder/bin/busybox
    if [ "$?" -eq "0" ]; then
    echo "busybox"
    else
    cp -a /thunder/bin/busybox /bin/busybox_patch
    fi
}

check_ramlist ()
{
    /bin/busybox cat /thunder/scripts/ramlist.txt | while read RAM_FILE
    do
    if [ ! -x $RAM_FILE ];then
    /bin/busybox ln -s /bin/busybox_patch $RAM_FILE
    echo "make link for $RAM_FILE"
    fi    
    done
}

check_rootfs_patch()
{
    ROOTFS_PATCH_DIR='/thunder/rootfs_patch'
    for patch_file in  $(find $ROOTFS_PATCH_DIR -type f) ;do
        rootfs_file=${patch_file#$ROOTFS_PATCH_DIR}
        diff $rootfs_file $patch_file > /dev/null
        if [ "$?" -eq "0" ];then
            echo "" > /dev/null
        else
            PATCH_DIR=${rootfs_file%/*}
            if [ ! -d $PATCH_DIR ];then
                mkdir -p $PATCH_DIR
            fi
            [ -s $patch_file ] || continue
            cp -a $patch_file $rootfs_file.tmp
            [ $? -eq 0  -a -s $rootfs_file.tmp ] || continue
            mv $rootfs_file.tmp $rootfs_file
            sync
            chmod a+x $rootfs_file
            chmod a+r $rootfs_file
        fi
    done
    for patch_file in  $(find $ROOTFS_PATCH_DIR -type l) ;do
        rootfs_file=${patch_file#$ROOTFS_PATCH_DIR}
        diff $rootfs_file $patch_file > /dev/null
        if [ "$?" -eq "0" ];then
        echo "" > /dev/null
        else
        PATCH_DIR=${rootfs_file%/*}
        if [ ! -d $PATCH_DIR ];then
        mkdir -p $PATCH_DIR
        fi
        cp -a $patch_file $rootfs_file
        fi
    done
    chmod a+r /usr/lib/*
    sync
}

init_env ()
{
    mkdir /tmp/plugin_tmp
    CHECK_DEFAULT_OPKG=`md5sum /thudner/etc/.opkg_default.conf | awk '{print $1}'`
    CHECK_OPKG=`md5sum /thunder/etc/opkg.conf | awk '{print $1}'`
    if [ "$CHECK_DEFAULT_OPKG" != "$CHECK_OPKG" ]; then
        cp /thunder/etc/.opkg_default.conf /thunder/etc/opkg.conf
    fi
    echo '/sbin/mdev' > /proc/sys/kernel/hotplug
    #/bin/busybox cp -a /thunder/etc/securetty /etc/
    SN_TAIL=`/thunder/bin/readkey sn | grep "data:" | sed 's/.*\(....\)$/\1/'`
    /thunder/bin/readkey sn | grep "data:" | awk '{print $2}' > /tmp/miner_sn
    chmod 777 /tmp/miner_sn
    HOSTNAME=OneCloud_$SN_TAIL
    echo $HOSTNAME > /etc/hostname
    hostname -F /etc/hostname
    export PATH=$PATH:/thunder/bin
    export LD_LIBRARY_PATH=/thunder/lib
    export QT_QPA_PLATFORM=linuxfb:fb=/dev/fb0
    export QT_QPA_FONTDIR=/usr/share/fonts
    export media_arm_audio_decoder='ape,flac,dts,ac3,eac3,wma,wmapro,mp3,aac,vorbis,raac,cook,amr,pcm,adpcm'
    export media_libplayer_modules='libcurl_mod.so,libdash_mod.so'
    export SN=`cat /tmp/miner_sn`
    export APPVER=`awk -F- '{ print $4 }' /thunder/etc/.img_date`
    update_busybox
    check_ramlist
    UBUSD_SERV_PID=`ps | grep ubusd | grep -v grep`
    [ -z "$UBUSD_SERV_PID" ] && ubusd -s /var/run/ubus.sock &
    sleep 1
    rm -rf /var/cache
    mkdir -p /var/cache
    uhttpd -p 127.0.0.1:80 -u /ubus -t 13 -a -h /thunder/www &
    /thunder/bin/minissdpd -i eth0 -i lo
    touch /tmp/.xunlei_msgqueue
    touch /tmp/.xunlei_module_queue
    touch /tmp/.mnt_usb_queue
    [ ! -d "/misc" ] &&  mkdir /misc
    [ ! -d "/app" ] &&  mkdir /app
    sh /etc/rc.common /etc/init.d/odhcpd stop
    sh /etc/rc.common /etc/init.d/odhcpd disable
    #    sh /etc/rc.common /etc/init.d/dnsmasq stop
    #    sh /etc/rc.common /etc/init.d/dnsmasq disable
    #iptables -t nat -A PREROUTING -i br0 -p udp --dport 53 -j DNAT --to $(nvram get lan_ipaddr)
    #iptables -t nat -A PREROUTING -i br0 -p tcp --dport 53 -j DNAT --to $(nvram get lan_ipaddr)

    mkdir -p /tmp/nginx/logs
    mkdir -p /tmp/nginx/socket
    /thunder/bin/nginx -p /tmp/nginx -c /thunder/etc/conf/nginx.conf
    
	/thunder/bin/hsd
}

run_app ()
{
    /usr/sbin/insmod /thunder/lib/sch_tbf.ko
    /usr/sbin/insmod /thunder/lib/sch_prio.ko
    /usr/sbin/insmod /thunder/lib/sch_sfq.ko
    /bin/sh /thunder/etc/start_app.sh  &
}

run_sys ()
{

    /thunder/bin/syswatch &
    /thunder/app/thunder/lib/EmbedThunderManager 0 > /dev/null &
    exit 0
}

run_plugin()
{
    for init_script in /misc/etc/rc.d/S??*;do
           sh  /misc/etc/rc.common  $init_script start &
    done
}


# if '/dev/app0' not mounted by /etc/inittab,try and set up mirror-mounting '/thunder'.
# otherwise,consider it is already workable. 
mount_thunder_dir()
{
    mount_dev="/dev/app0"
    mount_info=`mount | grep '/dev/app0'`
    if [ -z "$mount_info" ]; then
      mount $mount_dev /thunder
      if [ $? -ne 0 ]; then
        mkfs.ext4 -F $mount_dev
        mkdir -p /tmp/thunder
        mount $mount_dev /tmp/thunder
          if [ $? -eq 0 ]; then
            cp -rf /thunder/* /tmp/thunder
            umount $mount_dev
            mount $mount_dev /thunder
          fi
      fi
    fi
    
    return 0
}

SOFTMODE=`fw_printenv xl_softmode |  awk -F "=" '{print $2}'`
#if [ ! "$SOFTMODE" = "factory" ]; then
#    mount_thunder_dir
#fi
init_env

if [ "$SOFTMODE" == "factory" ]; then
	/etc/init.d/S50telnet   start
    /etc/hotplug/sd/sd_insert
    /etc/hotplug/usb/udisk_insert
    /thunder/bin/factory_app
else
    check_rootfs_patch
    # shutdown ssh & telnet server in release
	/etc/init.d/S50dropbear stop
	/etc/init.d/S50telnet   stop
	/etc/init.d/S70vsftpd   stop

    run_app
    if [ ! -f /tmp/.usb_insert ];then
        touch /tmp/.usb_insert
        mdev -s
    fi
fi

