#!/bin/sh
touch "/tmp/kplayertest"
while :
do
    if [ -f '/tmp/kplayertest' ];then
        (sleep 47; killall kplayer)| kplayer /root/test.avi > /dev/null
    else
        break
    fi
done
