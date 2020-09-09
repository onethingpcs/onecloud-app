#!/bin/sh

rm -rf /tmp/diag_log
mkdir -p /tmp/diag_log

DIAG_LOG_SYS="/tmp/diag_log/system_info"
DIAG_LOG_PROC="/tmp/diag_log/process_info"
DIAG_LOG_NET="/tmp/diag_log/network_info"
DIAG_LOG_DISK="/tmp/diag_log/disk_info"


diag_system()
{
	echo "=========== date ===========" >> ${DIAG_LOG_SYS}
	date >> ${DIAG_LOG_SYS} 2>&1

	echo "=========== uptime ===========" >> ${DIAG_LOG_SYS}
	uptime >> ${DIAG_LOG_SYS} 2>&1

	echo "=========== uname -a ===========" >> ${DIAG_LOG_SYS}
	uname -a >> ${DIAG_LOG_SYS} 2>&1

	echo "=========== ubus call upgrade get_status ===========" >> ${DIAG_LOG_SYS}
	ubus call upgrade get_status >> ${DIAG_LOG_SYS}

	echo "=========== cat /proc/meminfo ===========" >> ${DIAG_LOG_SYS}                                                                      
	cat /proc/meminfo  >> ${DIAG_LOG_SYS} 2>&1
}

diag_process()
{
	echo "=========== ps |wc -l ===========" >> ${DIAG_LOG_PROC}
	ps |wc -l >> ${DIAG_LOG_PROC}

	echo "=========== ps -o user,group,pid,ppid,pgid,etime,nice,time,stat,rss,vsz,comm,args ===========" >> ${DIAG_LOG_PROC}
	ps -o user,group,pid,ppid,pgid,etime,nice,time,stat,rss,vsz,comm,args >> ${DIAG_LOG_PROC} 2>&1

	echo "=========== top -b -n 1 ===========" >> ${DIAG_LOG_PROC}
	top -b -n 1 >> ${DIAG_LOG_PROC} 2>&1
	
}


diag_network()
{
	echo "=========== ifconfig -a ===========" >> ${DIAG_LOG_NET}
	ifconfig -a >> ${DIAG_LOG_NET} 2>&1

	echo "================== cat /etc/hosts ==================" >> ${DIAG_LOG_NET}                                                                       
	cat /etc/hosts   >> ${DIAG_LOG_NET} 2>&1

	echo "================== cat /etc/resolv.conf ==================" >> ${DIAG_LOG_NET}                                                                          
	cat /etc/resolv.conf   >> ${DIAG_LOG_NET} 2>&1

	echo "=========== route -n ===========" >> ${DIAG_LOG_NET}
	route -n >> ${DIAG_LOG_NET} 2>&1

	echo "=========== netstat -anp ===========" >> ${DIAG_LOG_NET}
	netstat -anp >> ${DIAG_LOG_NET} 2>&1

	echo "========== fping www.baidu.com  114.114.114.114  portal.remotedl.onethingpcs.com \
		  session.remotedl.onethingpcs.com  control.remotedl.onethingpcs.com license.remotedl.onethingpcs.com \
		  portal.onethingpcs.com  conn.onethingpcs.com  control.onethingpcs.com \
		  kjapi.peiluyou.com  upgrade.peiluyou.com  util.peiluyou.com update.peiluyou.com \
		  ntp.cc.sandai.net ntp.ubuntu.com \
		  -t 1000 -c2 -a -A ==========" >> ${DIAG_LOG_NET}
	fping www.baidu.com  114.114.114.114  portal.remotedl.onethingpcs.com \
		  session.remotedl.onethingpcs.com  control.remotedl.onethingpcs.com license.remotedl.onethingpcs.com \
		  portal.onethingpcs.com  conn.onethingpcs.com  control.onethingpcs.com \
		  kjapi.peiluyou.com  upgrade.peiluyou.com  util.peiluyou.com update.peiluyou.com \
		  ntp.cc.sandai.net ntp.ubuntu.com \
		  -t 1000 -c2 -a -A >> ${DIAG_LOG_NET} 2>&1
}

diag_disk()
{
	echo "================== df -h =================" >> ${DIAG_LOG_DISK}
	df -h >> ${DIAG_LOG_DISK}

	echo "================== mount =================" >> ${DIAG_LOG_DISK}	
	mount >> ${DIAG_LOG_DISK} 2>&1

	echo "=========== ubus call mnt get_disk_detail ============" >> ${DIAG_LOG_DISK}
	ubus call mnt get_disk_detail >> ${DIAG_LOG_DISK}

	echo "================== dumpe2fs -h /dev/system  =================" >> ${DIAG_LOG_DISK}	
	dumpe2fs -h /dev/system  >> ${DIAG_LOG_DISK} 2>&1

	echo "================== fdisk -l =================" >> ${DIAG_LOG_DISK}	
	fdisk -l  >> ${DIAG_LOG_DISK} 2>&1

	echo "================== ls -l /dev/sd* =================" >> ${DIAG_LOG_DISK}
	ls -l /dev/sd* 2>/dev/null |awk '{print $10}' |while read line
	do
		echo "blkid ${line}" >> ${DIAG_LOG_DISK}  2>&1
		blkid ${line} >> ${DIAG_LOG_DISK} 2>&1
	done

}

cp_important_log(){
	cp /tmp/upgrade.log /tmp/diag_log
	cp /tmp/ubus_app.log /tmp/diag_log
	cp /tmp/tunnel-agent.log* /tmp/diag_log
	cp /tmp/xyagentlog* /tmp/diag_log
	cp /tmp/remote.log  /tmp/diag_log
	cp /tmp/upgrade_shb.log /tmp/diag_log

	dmesg > /tmp/diag_log/dmesg
}

diag_system
diag_process
diag_network
diag_disk
cp_important_log


tar -zcvf /tmp/diag_log.tar.gz -C /tmp/ diag_log  > /dev/null 2>&1

openssl enc -e -aes-128-cbc -k onething0_CLOUD -p -nosalt  -in /tmp/diag_log.tar.gz  -out /tmp/diag_log.enc > /dev/null 2>&1

rm -rf /tmp/diag_log.tar.gz 


