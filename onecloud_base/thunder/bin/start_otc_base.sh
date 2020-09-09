#!/bin/sh
if [ $# -ge 1 ]; then
	OTC_BASE_DIR=${1}
else
	echo "wx warning no args for OTC_APP_DIR......"
	OTC_BASE_DIR=/onecloud_base
fi

# export the sn and appver to workaround 211 factory version bug
export SN=`cat /tmp/miner_sn`

if [ -z "${APPVER}" ]; then
	export APPVER=`awk -F- '{ print $4 }' ${OTC_BASE_DIR}/thunder/.img_date`
fi

# Generate coredump.
ulimit -c unlimited
echo "/tmp/dcdn_base/debug/core-%e-%p-%t" > /proc/sys/kernel/core_pattern

# Set stack size(KB).
ulimit -s 1024

#APP_MODULES="stat netcfg mnt upgrade dcdn remote devicemgr quota iopsmgr hsd"
APP_MODULES="stat netcfg mnt upgrade dcdn quota iopsmgr config_watcher activate_auth remote"

modules_name="$APP_MODULES"

mem_total=`head -n 1 /proc/meminfo | awk '{ print $2 }'`

SYSVER=
if [ -f /.sys_ver ]; then
    SYSVER=`cat /.sys_ver`
fi

stat_module()
{
    #$1 == module_name
    local name=$1

    local st=0

    eval st=\$st_$name
	
    if [ -z "$st" ]; then
        st=0
    fi

    local pid="`pidof $name | awk '{ print $1 }'`"
    if [ -z "$pid" -a $st -eq 0 ]; then
        return 1
    fi
    
    local topline=
    local cpu=
    local mem=
    local fds=

    if [ -n "$pid" ]; then
        fds="`ls /proc/$pid/fd | wc -l`"
        topline="`top -n 1 -b | grep -v grep | grep "^\ *$pid\ \+"`"
        if [ -n "$topline" ]; then          
            cpu="`echo $topline | awk '{ print $7 }' | awk -F% '{ print $1 }'`"
            mem="`echo $topline | awk '{ print $6 }' | awk -F% '{ print $1 }'`"
        fi
    fi

    local et="`date +%s`"
    
    if [ -z "$cpu" ]; then
        cpu=0
    fi

    if [ -z "$mem" ]; then
        mem=0
    fi

    if [ -z "$fds" ]; then
        fds=0
    fi

    #echo "name $1, pid $pid, cpu $cpu, mem $mem, fds $fds, et $et"

    ubus send stat.normal '{"act":"process","et":"'$et'","v":"'$APPVER'","sn":"'$SN'","pn":"'$name'","cu":"'$cpu'","mu":"'$mem'","st":"'$st'","fn":"'$fds'"}'

    eval st_$name=0

    return 0
}



stat_modules()
{
	# stat system: cpu memory
    local topline=
    local mem_used=0
    local mem_used_percent=0
    local mem_free_percent=0
    local cpu_free_percent=0
    local cpu_used_percent=0
    local io_percent=0

    topline=`top -n 1 -b | head -n 2`
    if [ -n "$topline" ]; then
        mem_used=`echo $topline | head -n 1 | awk '{ print $4 }' | awk -FK '{ print $1 }'`
        if [ -n "$mem_used" ]; then
            mem_used_percent=$(($mem_used * 100 / $mem_total))
            mem_free_percent=$((100 - $mem_used_percent))
        fi
        
		local cpuline=`top -n 1 -b | grep "^CPU:"`
		if [ -n "$cpuline" ]; then
            io_percent=`echo $cpuline | awk '{ print $10 }' | awk -F% '{ print $1 }'`
            cpu_free_percent=`echo $cpuline | awk '{ print $8 }' | awk -F% '{ print $1 }'`
            if [ -n "$cpu_free_percent" ]; then
                cpu_used_percent=$((100 - $cpu_free_percent))
            fi
        fi
    fi	

	local uptime=`awk -F. '{ print $1 }' /proc/uptime`
    if [ -z "$uptime" ]; then
         uptime=0
    fi

    local et="`date +%s`"

    ubus send stat.normal '{"act":"system","et":"'$et'","sv":"'$SYSVER'","v":"'$APPVER'","sn":"'$SN'","mu":"'$mem_used_percent'","mf":"'$mem_free_percent'","io":"'$io_percent'","cu":"'$cpu_used_percent'","cf":"'$cpu_free_percent'","ut":"'$uptime'"}'

    for name in $modules_name
    do
        stat_module $name
    done
}

run_module ()
{
    if [ "$1" = "upgrade" -a -x /usr/sbin/upgrade ]; then
      return
    fi

	if [ "$1" == "remote" ]; then
		(nice -n -10 ${OTC_BASE_DIR}/thunder/bin/$1 > /dev/null 2>&1) &
	else
		${OTC_BASE_DIR}/thunder/bin/$1 > /dev/null 2>&1 &
	fi
	
	if [ "$1" == "netcfg" ]; then
		echo "wait for netcfg"
		ubus wait_for $1 -t 10
	else
		ubus wait_for $1 -t 3
	fi
    echo -e "`date '+%Y-%m-%d %T'` <INFO>\t$1 running\t-- start_app.sh" >>/var/log/ubus_app.log
}

monitor_modules ()
{
    for name in $APP_MODULES
    do
        if [ "$name" = "upgrade" -a -x /usr/sbin/upgrade ]; then
	    UPG_PROC=`ps | grep onecloud_upgrade_run.sh | grep -v grep`
            if [ -z "$UPG_PROC" ]; then
            	sh /usr/sbin/onecloud_upgrade_run.sh &
            fi
            continue
        fi

        ubus call $name get_status -t 30 >/dev/null 2>&1
        if [[ $? -eq 7 || $? -eq 4 ]]; then          #Request timed out(7) OR Object not found(4)
            (killall $name; sleep 2; killall -9 $name) >/dev/null 2>&1
            run_module $name
			eval st_${name}="\$((\$st_${name} + 1))"
        fi
    done
}

monitor_file_over_size()
{
    # file list for monitoring size
    file_list="/tmp/usb_repair.log /tmp/mdev.log"
    max_size=1024000

    for file in $file_list
    do
        if [ ! -e $file ]; then
            continue
        fi

        file_size=$(wc -c <"$file")
        if [ $file_size -gt $max_size ]; then
            echo -e "file $file size is over $max_size bytes, now truncate it" >>/var/log/ubus_app.log
            truncate -c -s $max_size $file
            cp $file $file.0
            truncate -c -s 0 $file
        fi
    done
    
}

for name in $APP_MODULES
do
	run_module $name
done

# report bootup event to server
ubus send stat.push '{"act":"bootup","sv":"'$SYSVER'","v":"'$APPVER'","sn":"'$SN'"}'

stat_module_timer=0

while :
do
    monitor_modules
    monitor_file_over_size
    if [ $stat_module_timer -ge 360 ]; then
        stat_module_timer=0
        stat_modules
    else
        stat_module_timer=$(($stat_module_timer + 1))
    fi
    sleep 10
	
done

