#!/bin/sh
if [ $# -ge 1 ]; then
	OTC_BASE_DIR=${1}
	if [ "${OTC_BASE_DIR}" = "/" ]; then
		OTC_BASE_DIR=
	fi
else
	OTC_BASE_DIR=/onecloud_base
fi

#OTC_BASE_ETC_DIR=${OTC_BASE_DIR}
OTC_BASE_ETC_DIR=

update_busybox ()
{
	if [ ! -x "${OTC_BASE_DIR}/thunder/bin/busybox" ]; then
		return 0;
	fi
	
    diff /bin/busybox_patch ${OTC_BASE_DIR}/thunder/bin/busybox
    if [ "$?" -eq "0" ]; then
    echo "busybox"
    else
    cp -a ${OTC_BASE_DIR}/thunder/bin/busybox /bin/busybox_patch
    fi
}

check_md5_and_overwrite()
{
	local file_src=${1}
	local file_dst=${2}
	
	if [ $# -lt 2 ]; then
		echo "check_md5_files args error" 
		return 1
	fi
	
	if [ ! -f "${file_src}" ]; then
		echo "check_md5_files src ${file_src} not find" 
		return 1
	fi
	
	if [ ! -f "${file_dst}" ]; then
		echo "check_md5_files src ${file_dst} not find, cp -f it" 
		cp -f ${file_src} ${file_dst}
		return 0
	fi
	
	local md5_src=`md5sum "${file_src}" | awk '{ print $1 }'`
	local md5_dst=`md5sum "${file_dst}" | awk '{ print $1 }'`
	if [ "${md5_src}" != "${md5_dst}" ]; then
		echo "file md5 not match, filename ${file_src} - ${file_dst}, src = ${md5_src}, dst ${md5_dst}, cp -f it" 
		cp -f ${file_src} ${file_dst}
		return 0
    fi

    return 0
}

update_common_thunder_bin_tools ()
{
	local src_dir=${OTC_BASE_DIR}/thunder/bin
	local dst_dir=/thunder/bin
	local add_tools_files="chkntfs"
	for onefile in ${add_tools_files}; do
		check_md5_and_overwrite ${src_dir}/${onefile} ${dst_dir}/${onefile}
	done
}

check_ramlist ()
{
    /bin/busybox cat ${OTC_BASE_DIR}/thunder/scripts/ramlist.txt | while read RAM_FILE
    do
    if [ ! -x $RAM_FILE ];then
    /bin/busybox ln -s /bin/busybox_patch $RAM_FILE
    echo "make link for $RAM_FILE"
    fi
    done
}

check_rootfs_patch()
{
    ROOTFS_PATCH_DIR="${OTC_BASE_DIR}/thunder/rootfs_patch"
    for patch_file in  $(find $ROOTFS_PATCH_DIR -type f) ;do
        rootfs_file=${patch_file#$ROOTFS_PATCH_DIR}
        if  grep -wq "$rootfs_file" ${OTC_BASE_DIR}/thunder/scripts/rpatch.list; then
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
                chmod a+x $rootfs_file
                chmod a+r $rootfs_file
             fi
        fi
    done

    for patch_file in  $(find $ROOTFS_PATCH_DIR -type l) ;do
        rootfs_file=${patch_file#$ROOTFS_PATCH_DIR}
        if  grep -wq "$rootfs_file" ${OTC_BASE_DIR}/thunder/scripts/rpatch.list; then
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
        fi
    done
    #chmod a+r /usr/lib/*
    sync
}

init_env ()
{
	#most env's init is by /etc/init.d/S86wxinit
    echo 1200 > /proc/sys/kernel/hung_task_timeout_secs ;
    mkdir -p /tmp/plugin_tmp
	mkdir -p /var/cache
	rm -rf /var/cache/opkg
	touch /tmp/.xunlei_msgqueue
    touch /tmp/.xunlei_module_queue
    touch /tmp/.mnt_usb_queue
	
    echo '/sbin/mdev' > /proc/sys/kernel/hotplug
    export PATH=$PATH:${OTC_BASE_DIR}/thunder/bin
    export LD_LIBRARY_PATH=${OTC_BASE_DIR}/thunder/lib
    export QT_QPA_PLATFORM=linuxfb:fb=/dev/fb0
    export QT_QPA_FONTDIR=/usr/share/fonts
    export media_arm_audio_decoder='ape,flac,dts,ac3,eac3,wma,wmapro,mp3,aac,vorbis,raac,cook,amr,pcm,adpcm'
    export media_libplayer_modules='libcurl_mod.so,libdash_mod.so'
    export SN=`cat /tmp/miner_sn`
	
	BASE_VER_CONF=${OTC_BASE_DIR}/thunder/.img_date
	if [ ! -f "${BASE_VER_CONF}" ]; then 
		BASE_VER_CONF=${BASE_VER_CONF}/thunder/etc/.img_date
	else
		diff ${BASE_VER_CONF} /thunder/etc/.img_date
		if [ "$?" -eq "0" ]; then
			echo "same .img_date..."
		else
			cp -af ${BASE_VER_CONF} /thunder/etc/.img_date
		fi
	fi
    export APPVER=`awk -F- '{ print $4 }' ${BASE_VER_CONF}`

    #update_busybox
    #check_ramlist
	
	ps w | grep "uhttpd" | grep -v grep || (uhttpd -p 127.0.0.1:80 -u /ubus -t 13 -a -h /onecloud_base/thunder/www &)
    #${OTC_BASE_DIR}/thunder/bin/minissdpd -i eth0 -i lo
	#${OTC_BASE_DIR}/thunder/bin/hsd
}

run_app ()
{
	OTB_BASE_START_SH=${OTC_BASE_DIR}/thunder/bin/start_otc_base.sh
	if [ -f "${OTB_BASE_START_SH}" ]; then
		echo "otc use ${OTB_BASE_START_SH} ${OTC_BASE_DIR} for base" 
		/bin/sh ${OTB_BASE_START_SH} ${OTC_BASE_DIR} &
	else
		echo "otc ${OTB_BASE_START_SH} not find, error..."
		#/bin/sh /thunder/bin/start_app.sh  &
	fi
}

SOFTMODE=`fw_printenv xl_softmode |  awk -F "=" '{print $2}'`
if [ "$SOFTMODE" == "factory" ]; then
    if [ -f "/thunder/bin/factory_app" ];then
        exit 0
    else
		if [ "$SOFTMODE" != "usermode" ]; then
			fw_setenv xl_softmode usermode
		fi
    fi
else
	rm -f /thunder/bin/factory_app
fi

init_env

update_common_thunder_bin_tools
check_rootfs_patch
# shutdown ssh & telnet server in release
/etc/init.d/S50dropbear stop
/etc/init.d/S50telnet   stop
#/etc/init.d/S70vsftpd   stop

run_app
echo run_base_over > /tmp/start_run_app.flag

if [ ! -f /tmp/.usb_insert ];then
    touch /tmp/.usb_insert
    mdev -s
fi
