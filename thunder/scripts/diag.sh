#!/bin/sh

####################################################################################################
# The script to diagnostic the system and the result is writed to sdcard or harddisk, the log file
# name is onecloud-diag.txt
#
# Author : Xiong Dibin, xiongdibin@xunlei.com
# Zhu Shiwei, zhushiwei@xunlei.com
#
# the items to diag :
# .) software status
#    firmware version
#    application status (fdrawer, fmgr, sysmgr, tfmgr, turnclient)
# .) disk infomation : 
#    volume info, partition, mount point, mount options, fs type, capacity, and free space
# .) network status
#    link status, up or down, link speed
#    IP address, netmask, gateway, DNS
#    connect to internet status
# .) system status
#    dmesg, syslog, ifconfig, etc
#
####################################################################################################

# Usage
# diag.sh [-c]
# -c   check it now

VOL=
DIAG_LOG=/tmp/onecloud-diag.txt
DIAG_LOG2=""
diag_ok=0
needdiag=0
CHECK_NOW=0
NEED_DIAG=0

mkdir -p /tmp

if [ $# -gt 0 ]; then
	if [ $1 == "-c" -a $# -eq 2 ]; then
		echo "Check it now, result to /tmp/$2 !"
		CHECK_NOW=1
		DIAG_LOG=/tmp/$2
	else
		echo "Usage: $0 [-c output]"
		echo "-c output  check it now, and write the result to output"
		exit 1
	fi
else
	if [ -e /tmp/mnt.info -o -e /tmp/mnt2.info ]; then
		# the diag had already runned
		echo "the diag had already runned"
		exit 0
	fi
	# wait the application to start
	echo "wait the application to start"
	#sleep 30
	sleep 1
fi

echo "Diagnostic Start ......"

volume_get()
{
	# arg1 the storage file
	#echo "args cnt $#"
	#echo "0 $0, 1 $1, 2 $2"
	
	while read line 
	do
		#echo "check line ${line}"
		VOL=`echo ${line} | awk -F'[ ]' '{ print $2 }'`
		#echo "VOL = ${VOL}"
		# check if writeable ?
		local opt_rw=`echo "${line}" | grep rw`
		if [ "${opt_rw}" == "" ]; then
			echo "not writeable, ${line}"
			continue
		fi
		# check really write ?
		#echo "test write ${VOL}"
		DIAG_LOG2=${VOL}/onecloud-diag.txt
		echo "diag dir : ${NEED_DIAG}"
		# test for write 1MB
		# test for write 1MB
		dd if=/dev/zero of=${DIAG_LOG2} bs=1024 count=1024 > /dev/null 2>&1
		if [ -f ${DIAG_LOG2} ]; then
			diag_ok=1
			#echo "diag_ok = ${diag_ok}"
			return
		fi

	done < $1
}

diag_inc_find()
{
	# arg1 the storage file
	#echo "args cnt $#"
	#echo "0 $0, 1 $1, 2 $2"
	
	while read line 
	do
		echo "check line ${line}"
		VOL=`echo ${line} | awk -F'[ ]' '{ print $2 }'`
		NEED_DIAG=${VOL}/ocneeddiag
		echo "find weather need to $VOL"
		if [ -f ${NEED_DIAG} ]; then
			needdiag=1
			echo "need diag  = ${needdiag}"
			return 
		fi
	done < $1
}

needdiag_storage_get()
{
	local MNT_INFO="`grep sd /proc/mounts`"
	if [ "${MNT_INFO}" != "" ]; then
		# hdd found
		echo "${MNT_INFO}" > /tmp/mnt.info
		diag_inc_find /tmp/mnt.info
		if [ ${needdiag} -eq 1 ]; then
			return
		fi
	fi
	
}


external_storage_get()
{
	local MNT_INFO="`grep sd /proc/mounts`"
	if [ "${MNT_INFO}" != "" ]; then
		# hdd found
		echo "${MNT_INFO}" > /tmp/mnt.info
		volume_get /tmp/mnt.info
		if [ ${diag_ok} -eq 1 ]; then
			return
		fi
	fi
	
	# check if any sdcard plugged
	local MNT_INFO2="`grep mmcblk /proc/mounts`"
	if [ "${MNT_INFO2}" != "" ]; then
		# sd card found
		echo "${MNT_INFO2}" > /tmp/mnt2.info
		volume_get /tmp/mnt2.info
		if [ ${diag_ok} -eq 1 ]; then
			return
		fi
	fi	
}


#echo "diag_ok = ${diag_ok}"
#echo "DIAG_LOG2 = ${DIAG_LOG2}"

#echo "Write log to ${DIAG_LOG}"
echo "Diagnostic information for onecloud" > ${DIAG_LOG} 2>&1
echo "Date : `date`" >> ${DIAG_LOG} 2>&1


diag_software()
{
	
	echo "================== System vesion ==========================" >> ${DIAG_LOG}
	ubus call upgrade get_status >> ${DIAG_LOG}
	uptime >> ${DIAG_LOG} 2>&1	
	uname -a >> ${DIAG_LOG} 2>&1
	echo "================== Application Status ==================" >> ${DIAG_LOG}
	# check fdrawer
	echo "Application Name : fdrawer" >> ${DIAG_LOG}
	if [ "`ps | grep fdrawer | grep -v grep`" == "" ]; then
		echo "    running      : NO" >> ${DIAG_LOG}
	else
		echo "    running      : YES" >> ${DIAG_LOG}
		# check status, binding port
		echo "fdrawer:getfdrawerstatus" >> ${DIAG_LOG}
		curl "http://127.0.0.1:8800/fdrawer?opt=getfdrawerstatus"  2>&1 >> ${DIAG_LOG}
	fi
	
	echo "ps |grep thunder |wc -l" >> ${DIAG_LOG}
	ps |grep thunder |wc -l >> ${DIAG_LOG}
	
	echo "ps |grep thunder" >> ${DIAG_LOG}
	ps |grep thunder >> ${DIAG_LOG}
	
	echo "Application Name : fmgr" >> ${DIAG_LOG}
	if [ "`ps | grep fmgr | grep -v grep`" == "" ]; then
		echo "    running      : NO" >> ${DIAG_LOG}
	else
		echo "    running      : YES" >> ${DIAG_LOG}
		# check status, binding port
		echo "fmgr:querydir" >> ${DIAG_LOG}
		curl "http://127.0.0.1:8800/fmgr?opt=querydir&path="  2>&1 >> ${DIAG_LOG}
	fi
	
	echo "Application Name : sysmgr" >> ${DIAG_LOG}
	if [ "`ps | grep sysmgr | grep -v grep`" == "" ]; then
		echo "    running      : NO" >> ${DIAG_LOG}
	else
		echo "    running      : YES" >> ${DIAG_LOG}
		# check status, binding port
		echo "sysmgr:opt=listpeer"  >> ${DIAG_LOG}
		curl "http://127.0.0.1:8800/sysmgr?opt=listpeer" 2>&1 >> ${DIAG_LOG}
	fi
	
	# check etm
	echo "Application Name : ETM" >> ${DIAG_LOG}
	if [ "`ps | grep etm | grep -v grep`" == "" ]; then
		echo "    running      : NO" >> ${DIAG_LOG}
	else
		echo "    running      : YES" >> ${DIAG_LOG}
		# check status, binding port

		if [ "`netstat -anu | grep 9000`" != "" ]; then
			echo "    bind 9000    : YES" >> ${DIAG_LOG}
		else
			echo "    bind 9000    : NO" >> ${DIAG_LOG}
		fi
	fi

	
	#check nginx
	echo "Application Name : nginx" >> ${DIAG_LOG}
	if [ "`ps | grep nginx | grep -v grep`" == "" ]; then
		echo "    running      : NO" >> ${DIAG_LOG}
	else
		echo "    running      : YES" >> ${DIAG_LOG}
		# check status, binding port
		if [ "`netstat -ant | grep 8800`" != "" ]; then
			echo "    bind 8800      : YES" >> ${DIAG_LOG}
		else
			echo "    bind 8800      : NO" >> ${DIAG_LOG}
		fi
		if [ "`netstat -ant | grep 443`" != "" ]; then
			echo "    bind 443      : YES" >> ${DIAG_LOG}
		else
			echo "    bind 443      : NO" >> ${DIAG_LOG}
		fi
	fi
	
	echo "Application Name : SAMBA" >> ${DIAG_LOG}
	if [ "`ps | grep smbd | grep -v grep`" == "" ]; then
		echo "    running(smbd): NO" >> ${DIAG_LOG}
	else
		echo "    running(smbd): YES" >> ${DIAG_LOG}
	fi
	if [ "`ps | grep nmbd | grep -v grep`" == "" ]; then
		echo "    running(nmbd): NO" >> ${DIAG_LOG}
	else
		echo "    running(nmbd): YES" >> ${DIAG_LOG}
	fi

	echo "Application Name : DLNA" >> ${DIAG_LOG}
	if [ "`ps | grep dlna | grep -v grep`" == "" ]; then
		echo "    running      : NO" >> ${DIAG_LOG}
	else
		echo "    running      : YES" >> ${DIAG_LOG}	
		# check status, binding port

		if [ "`netstat -ant | grep 8202`" != "" ]; then
			echo "    bind 8202    : YES" >> ${DIAG_LOG}
		else
			echo "    bind 8202    : NO" >> ${DIAG_LOG}
		fi
	fi

}


diag_disk()
{
	echo "================== Disk Status ==================" >> ${DIAG_LOG}
	
	if [ ! -e /sys/bus/usb/devices/2-1 ]; then
		echo "USB cable not plugged" >> ${DIAG_LOG}
	else
		echo "HDD enclosure information :" >> ${DIAG_LOG}
		USB_MANU="`cat /sys/bus/usb/devices/2-1/manufacturer`"
		USB_PRD="`cat /sys/bus/usb/devices/2-1/product`"
		USB_VID="`cat /sys/bus/usb/devices/2-1/idVendor`"
		USB_PID="`cat /sys/bus/usb/devices/2-1/idProduct`"
		echo "    Manufacturer          : ${USB_MANU}" >> ${DIAG_LOG}
		echo "    Product               : ${USB_PRD}" >> ${DIAG_LOG}
		echo "    VID PID               : ${USB_VID} ${USB_PID}" >> ${DIAG_LOG}

		echo "Disk mounting information :" >> ${DIAG_LOG}
		cat /tmp/mnt.info >> ${DIAG_LOG} 2>&1
		echo "Disk capacity and free space :" >> ${DIAG_LOG}
		FREE_SPACE=`df -h | grep "sd"`
		echo "${FREE_SPACE}" >> ${DIAG_LOG} 2>&1
		
		echo "---------------------------------------->" >> ${DIAG_LOG}
		echo "Volume and Label(UTF-8 encode) information :" >> ${DIAG_LOG}
		volume_info >>  ${DIAG_LOG} 2>&1
		echo "(type: 1 ntfs, 2 fat, 3 fat32, 4 exfat, 5 hfs, 6 hfs+, 7 ext, 8 ext2, 9 ext3, 10 ext4, 11 xfs)" >> ${DIAG_LOG}
		
		echo "---------------------------------------->" >> ${DIAG_LOG}
		if [ -e /dev/sda ]; then
			echo "HardDisk partition infomation :" >> ${DIAG_LOG}
			fdisk -l /dev/sda >> ${DIAG_LOG} 2>&1
		fi
	fi

	if [ -e /dev/mmcblk* ]; then
		echo "---------------------------------------->" >> ${DIAG_LOG}
		echo "SDCard partition infomation :" >> ${DIAG_LOG}
		fdisk -l /dev/mmcblk0p1 >> ${DIAG_LOG} 2>&1
	fi
}

IP_ADDR=""
NETMASK_ADDR=""
GATEWAY=""
DNS=""

diag_network()
{
	echo "================== Network Status ==================" >> ${DIAG_LOG}
	PHY_STAT_INFO="`ethtool eth0`"
	if [ "`echo ${PHY_STAT_INFO} | grep "Link detected: yes"`" != "" ]; then
		"`ethtool eth0`" >> ${DIAG_LOG} 

		IFCONFIG_INFO=`ifconfig eth0`
		if [ "`echo ${IFCONFIG_INFO} | grep RUNNING`" == "" ]; then
			echo "    Logic link   : DOWN" >> ${DIAG_LOG}
		else
			echo "    Logic link   : UP" >> ${DIAG_LOG}
			IP_ADDR="`ifconfig eth0 | grep 'inet' | awk -F":" '{ print $2 }' | awk '{ print $1}'`"
			NETMASK_ADDR="`ifconfig eth0 | grep 'inet' | awk -F":" '{ print $4 }'`"
			GATEWAY="`route -n |  grep UG | awk '{ print $2 }'`"
			DNS="`grep nameserver /etc/resolv.conf  | awk '{ print $2 }'`"
			echo "    IP address   : ${IP_ADDR}" >> ${DIAG_LOG} 2>&1
			echo "    Netmask      : ${NETMASK_ADDR}" >> ${DIAG_LOG} 2>&1
			echo "    Gateway      : ${GATEWAY}" >> ${DIAG_LOG} 2>&1
			for d in ${DNS}
			do
				echo "    DNS          : ${d}" >> ${DIAG_LOG} 2>&1
			done
		fi
	else
		echo "    PHY link     : DOWN (check the cable)" >> ${DIAG_LOG}
	fi
	
	PYH_MAC="`ifconfig eth0 | grep HWaddr | awk '{ print $5 }'`"
	#LOGIC_MAC="`ifconfig br-lan | grep HWaddr | awk '{ print $5 }'`"
	echo "    PHY MAC      : ${PYH_MAC}" >> ${DIAG_LOG}
	#echo "    Logic MAC    : ${LOGIC_MAC}" >> ${DIAG_LOG}

	# check internet
	
	echo "check internet :" >> ${DIAG_LOG}
	
	if [ "${IP_ADDR}" != "" -a "${GATEWAY}" != "" ]; then
		echo "---------------------------------------->" >> ${DIAG_LOG}
		echo "Ping gateway ${GATEWAY}" >> ${DIAG_LOG}
		ping ${GATEWAY} -c 4 -W 1 -w 2 >> ${DIAG_LOG} 
		
		echo "---------------------------------------->" >> ${DIAG_LOG}
		ping baidu.com -c 4 -W 1 -w 2 >> ${DIAG_LOG} 
		
		echo "---------------------------------------->" >> ${DIAG_LOG}
		echo "Ping portal.remotedl.onethingpcs.com:80" >> ${DIAG_LOG}
		ping portal.remotedl.onethingpcs.com  -c 4 -W 1 -w 2 >> ${DIAG_LOG} 
		
		echo "---------------------------------------->" >> ${DIAG_LOG}
		ping portal.remotedl.onethingpcs.com -c 4 -W 1 -w 2 >> ${DIAG_LOG} 
		
		echo "---------------------------------------->" >> ${DIAG_LOG}
		ping 114.114.114.114 -c 4 -W 1 -w 2 >> ${DIAG_LOG}
		echo "---------------------------------------->" >> ${DIAG_LOG}
		ping portal.remotedl.onethingpcs.com  -c 4 -W 1 -w 2 >> ${DIAG_LOG}
		echo "---------------------------------------->" >> ${DIAG_LOG}
		echo "ping session.remotedl.onethingpcs.com:8000 "
		ping session.remotedl.onethingpcs.com  -c 4 -W 1 -w 2 >> ${DIAG_LOG}
		echo "---------------------------------------->" >> ${DIAG_LOG}
		ping control.remotedl.onethingpcs.com  -c 4 -W 1 -w 2 >> ${DIAG_LOG}
		echo "---------------------------------------->" >> ${DIAG_LOG}
		ping license.remotedl.onethingpcs.com  -c 4 -W 1 -w 2 >> ${DIAG_LOG}
		echo "---------------------------------------->" >> ${DIAG_LOG}
		ping portal.onethingpcs.com  -c 4 -W 1 -w 2 >> ${DIAG_LOG}
		echo "---------------------------------------->" >> ${DIAG_LOG}
		ping conn.onethingpcs.com  -c 4 -W 1 -w 2 >> ${DIAG_LOG}
		echo "---------------------------------------->" >> ${DIAG_LOG}
		ping control.onethingpcs.com  -c 4 -W 1 -w 2 >> ${DIAG_LOG}
		echo "---------------------------------------->" >> ${DIAG_LOG}
		ping kjapi.peiluyou.com  -c 4 -W 1 -w 2 >> ${DIAG_LOG}
		echo "---------------------------------------->" >> ${DIAG_LOG}
		ping upgrade.peiluyou.com  -c 4 -W 1 -w 2 >> ${DIAG_LOG}
		echo "---------------------------------------->" >> ${DIAG_LOG}
		ping util.peiluyou.com  -c 4 -W 1 -w 2 >> ${DIAG_LOG}
		ping update.peiluyou.com -c 4 -W 1 -w 2 >> ${DIAG_LOG}


	fi
	
	if [ -f "/thunder/bin/netcat" ]; then
		echo "---------------------------------------->" >> ${DIAG_LOG}
		echo "/thunder/bin/netcat -zv portal.remotedl.onethingpcs.com 80" >>  ${DIAG_LOG}
		/thunder/bin/netcat -zv portal.remotedl.onethingpcs.com 80 >>  ${DIAG_LOG} 2>&1
		echo "---------------------------------------->" >> ${DIAG_LOG}
		echo "/thunder/bin/netcat -zv portal.remotedl.onethingpcs.com 80" >>  ${DIAG_LOG}
		/thunder/bin/netcat -zv session.remotedl.onethingpcs.com 8000 >>  ${DIAG_LOG} 2>&1
		echo "---------------------------------------->" >> ${DIAG_LOG}
		echo "/thunder/bin/netcat -zv portal.remotedl.onethingpcs.com 80" >>  ${DIAG_LOG}
		/thunder/bin/netcat -zv control.remotedl.onethingpcs.com 80 >>  ${DIAG_LOG} 2>&1
		echo "---------------------------------------->" >> ${DIAG_LOG}
		echo "/thunder/bin/netcat -zv portal.remotedl.onethingpcs.com 80" >>  ${DIAG_LOG}
		/thunder/bin/netcat -zv license.remotedl.onethingpcs.com 80 >>  ${DIAG_LOG} 2>&1
		echo "---------------------------------------->" >> ${DIAG_LOG}
		echo "/thunder/bin/netcat -zv portal.remotedl.onethingpcs.com 80" >>  ${DIAG_LOG}
		/thunder/bin/netcat -zv portal.onethingpcs.com 80 >>  ${DIAG_LOG} 2>&1
		echo "---------------------------------------->" >> ${DIAG_LOG}
		echo "/thunder/bin/netcat -zv conn.onethingpcs.com 7000" >>  ${DIAG_LOG}
		/thunder/bin/netcat -zv conn.onethingpcs.com 7000 >>  ${DIAG_LOG} 2>&1
		echo "---------------------------------------->" >> ${DIAG_LOG}
		echo "/thunder/bin/netcat -zv control.onethingpcs.com 80" >>  ${DIAG_LOG}
		/thunder/bin/netcat -zv control.onethingpcs.com 80 >>  ${DIAG_LOG} 2>&1
		
		echo "---------------------------------------->" >> ${DIAG_LOG}
		echo "/thunder/bin/netcat -zv kjapi.peiluyou.com 5171 5172 443 5170" >>  ${DIAG_LOG}
		/thunder/bin/netcat -zv kjapi.peiluyou.com 5171 5172 443 5170 >>  ${DIAG_LOG} 2>&1
		echo "/thunder/bin/netcat -zv kjapi0.peiluyou.com 5171 5172 443 5170" >>  ${DIAG_LOG}
		/thunder/bin/netcat -zv kjapi0.peiluyou.com 5171 5172 443 5170 >>  ${DIAG_LOG} 2>&1
		echo "/thunder/bin/netcat -zv kjapi1.peiluyou.com 5171 5172 443 5170" >>  ${DIAG_LOG}
		/thunder/bin/netcat -zv kjapi1.peiluyou.com 5171 5172 443 5170 >>  ${DIAG_LOG} 2>&1
		
		echo "---------------------------------------->" >> ${DIAG_LOG}
		echo "/thunder/bin/netcat -zv upgrade.peiluyou.com 5180" >>  ${DIAG_LOG}
		/thunder/bin/netcat -zv upgrade.peiluyou.com 5180 >>  ${DIAG_LOG} 2>&1
		echo "---------------------------------------->" >> ${DIAG_LOG}
		echo "/thunder/bin/netcat -zv util.peiluyou.com 5181 5281" >>  ${DIAG_LOG}
		/thunder/bin/netcat -zv util.peiluyou.com 5181 5281 >>  ${DIAG_LOG} 2>&1
		echo "---------------------------------------->" >> ${DIAG_LOG}
		echo "/thunder/bin/netcat -zv update.peiluyou.com 443" >>  ${DIAG_LOG}
		/thunder/bin/netcat -zv update.peiluyou.com 443 >>  ${DIAG_LOG} 2>&1
	
	fi
	
}

diag_system()
{
	echo "================== System Status ==================" >> ${DIAG_LOG}
	echo "All interface status :" >> ${DIAG_LOG}
	ifconfig -a >> ${DIAG_LOG} 2>&1
	
	echo "All socket status :" >> ${DIAG_LOG}
	netstat -an >> ${DIAG_LOG} 2>&1

	echo "All route table :" >> ${DIAG_LOG}
	route -n >> ${DIAG_LOG} 2>&1
	
	echo "process info :" >> ${DIAG_LOG}
	ps >> ${DIAG_LOG} 2>&1
	top -b -n 1 >> ${DIAG_LOG} 2>&1
	echo "================== meminfo Status ==================" >> ${DIAG_LOG}
	echo "ALL /proc/meminfo  info  :" >> ${DIAG_LOG}                                                                           
	cat /proc/meminfo  >> ${DIAG_LOG} 2>&1
	echo "================== resolv.conf==================" >> ${DIAG_LOG}
	echo "cat /etc/resolv.conf :" >> ${DIAG_LOG}                                                                           
	cat /etc/resolv.conf   >> ${DIAG_LOG} 2>&1
	echo "==================hosts==================" >> ${DIAG_LOG}
	echo "cat /etc/hosts :" >> ${DIAG_LOG}                                                                           
	cat /etc/hosts   >> ${DIAG_LOG} 2>&1

	echo "================== mount =================" >> ${DIAG_LOG}	
	echo "mount :" >> ${DIAG_LOG}
	mount >> ${DIAG_LOG} 2>&1
	echo "================== system inode  =================" >> ${DIAG_LOG}	
	echo "	dumpe2fs -h /dev/system  :" >> ${DIAG_LOG}
	dumpe2fs -h /dev/system  >> ${DIAG_LOG} 2>&1
	echo "================== system inode  =================" >> ${DIAG_LOG}	
	echo "	dumpe2fs -h /dev/system  :" >> ${DIAG_LOG}
	dumpe2fs -h /dev/system  >> ${DIAG_LOG} 2>&1
	
	echo "================== disk =================" >> ${DIAG_LOG}	
	echo "fdisk -l :-------------------------------------->" >> ${DIAG_LOG}
	fdisk -l  >> ${DIAG_LOG} 2>&1
	echo "df :-------------------------------------->" >> ${DIAG_LOG}
	df  >> ${DIAG_LOG} 2>&1
	echo "blkid :-------------------------------------->" >> ${DIAG_LOG}
	ls -l /dev/sd* |awk '{print $10}' |while read line
	do
		echo "blkid ${line}" >> ${DIAG_LOG}  2>&1
		blkid ${line} >> ${DIAG_LOG} 2>&1
	done
	
	echo "================== /thunder/etc/config.json==================" >> ${DIAG_LOG}
	echo "cat /thunder/etc/config.json  :" >> ${DIAG_LOG}  
	cat /thunder/etc/config.json   >> ${DIAG_LOG} 
	echo "================== cat /tmp/smb.conf ==================" >> ${DIAG_LOG}
	echo "cat /tmp/smb.conf   :" >> ${DIAG_LOG}  
	cat /tmp/smb.conf  >> ${DIAG_LOG} 
	
	echo "cat /thunder/etc/samba.json    :" >> ${DIAG_LOG}  
	cat /thunder/etc/samba.json   >> ${DIAG_LOG} 		
	
	echo "================== fdrawer.log==================" >> ${DIAG_LOG}
	echo "cat /tmp/fdrawer.log  :" >> ${DIAG_LOG}                                                                           
	cat /tmp/fdrawer.log   >> ${DIAG_LOG} 2>&1
	echo "================== ubus_app.log=================" >> ${DIAG_LOG}
	echo "All ubus log  message :" >> ${DIAG_LOG}
	cat /tmp/ubus_app.log  >> ${DIAG_LOG} 2>&1
	echo "================== All ubus log  message=================" >> ${DIAG_LOG}	
	echo "All kernel message :" >> ${DIAG_LOG}
	dmesg >> ${DIAG_LOG} 2>&1
	
}

needdiag_storage_get

if [ ${needdiag} -ne 1 ]; then
	echo "The system does not need to be diagnosed "
	rm -rf /tmp/mnt*.info
	exit 0
fi
if [ ${CHECK_NOW} -ne 1 ]; then
	external_storage_get
fi

diag_software
diag_network
diag_system
diag_disk

echo "Diagnostic over ......"

if [ ${CHECK_NOW} -eq 1 ]; then
	# return now
	exit 0
fi

if [ ${diag_ok} -eq 1 ]; then
	openssl enc -e -aes-128-cbc -k onething0_CLOUD -p -nosalt  -in ${DIAG_LOG}  -out ${DIAG_LOG}_enc
	# copy a log to external hdd or sd
	echo "Copy log to ${DIAG_LOG2}"
	cp -f ${DIAG_LOG}_enc ${DIAG_LOG2}
	rm -f ${DIAG_LOG}
	rm -rf  ${DIAG_LOG}_enc 
else
	echo "Not found any external storage"
fi

