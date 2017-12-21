#!/bin/sh
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/thunder/lib:/lib:/usr/lib
name=fdrawer
killall $name; sleep 1; killall -9 $name;
sleep 1;
/thunder/bin/$name  >/dev/null 2>&1
rm -rf /tmp/mnt*.info
/thunder/scripts/diag.sh &


