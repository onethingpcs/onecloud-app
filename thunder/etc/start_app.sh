#!/bin/sh


# Generate coredump.
ulimit -c unlimited
echo "/tmp/dcdn_base/debug/core-%e-%p-%t" > /proc/sys/kernel/core_pattern

# Set stack size(KB).
ulimit -s 1024

APP_MODULES="netcfg mnt upgrade xqos dcdn remote fmgr fdrawer xldp turnclient sysmgr tfmgr xlplayer gui"

run_module ()
{
    if [ "$1" = "upgrade" -a -x /usr/sbin/upgrade ]; then
      return
    fi
    
    /thunder/bin/$1 > /dev/null 2>&1 &
    ubus wait_for $1 -t 3
    echo -e "`date '+%Y-%m-%d %T'` <INFO>\t$1 running\t-- start_app.sh" >>/var/log/ubus_app.log
}

monitor_modules ()
{
    for name in $APP_MODULES
    do
        if [ "$name" = "upgrade" -a -x /usr/sbin/upgrade ]; then
          continue
        fi
        
        ubus call $name get_status -t 30 >/dev/null 2>&1
        if [[ $? -eq 7 || $? -eq 4 ]]; then          #Request timed out(7) OR Object not found(4)
            (killall $name; sleep 2; killall -9 $name) >/dev/null 2>&1
            run_module $name
        fi
    done
}

for name in $APP_MODULES
do
	run_module $name
done

while :
do
    monitor_modules
    cpu_governor=`cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor`
    if [ "$cpu_governor" != "performance" ]; then
        echo "performance" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
    fi
    sleep 10
done

