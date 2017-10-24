#!/bin/sh

export LD_LIBRARY_PATH=/thunder/lib
export PATH=$PATH:/thunder/bin
echo "kill start_app.sh"
ps | grep  start_app.sh| grep -v 'grep'|grep -v 'restart_app.sh' | awk -F ' ' '{print $1}' | xargs kill -9
killall mnt

echo "stop dcdn"
ubus call dcdn_client_0 uninit
sleep 3
echo "kill the other module"

ps | grep thunder
PIDS=`ps | grep thunder |grep -v 'grep'| grep -v 'restart_app.sh'| grep -v 'opkg-cl' | grep -v 'preinst' | awk -F ' ' '{print $1}' `
for pid in $PIDS
do
    echo $pid
    kill -9 $pid
    echo $?
done

/thunder/bin/run.sh > /dev/null 2>&1
