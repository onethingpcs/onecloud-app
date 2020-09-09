#!/bin/sh


# Generate coredump.

# Set stack size(KB).
ulimit -s 1024
APP_MODULES="xyipk"
export PATH=$PATH:/thunder/bin
export PATH=$PATH:/app/miner.xyipkmng.ipk/bin
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/thunder/lib

run_module ()
{
    $1 > /dev/null  &
    echo -e "`date '+%Y-%m-%d %T'` <INFO>\t$1 running\t-- start_app.sh" >>/var/log/ubus_app.log
    sleep 5
}

monitor_modules ()
{
    ubus call $name get_status -t 60 >/dev/null 2>&1
    if [[ $? -eq 7 || $? -eq 4 ]]; then          #Request timed out(7) OR Object not found(4)
        if [[ $? -eq 7 ]]; then          #Request timed out(7)
            echo -e "`date '+%Y-%m-%d %T'` <INFO>\t$1 ubus request timed out, restart it\t-- start_app.sh" >>/var/log/ubus_app.log
        fi
        echo "killall -6 $name; sleep 2; killall -9 $name " >> /var/log/xyipk_debug.log
        (killall -6 $name; sleep 2; killall -9 $name) >/dev/null 2>&1
        run_module $name
    fi
}

[ ! -d "/tmp/xyipk_tmp" ] && mkdir /tmp/xyipk_tmp

for name in $APP_MODULES
do
	run_module $name
done

while :
do
    monitor_modules
    sleep 10
done
