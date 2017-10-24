#!/bin/sh
cp -a /thunder/etc/netcfg.config /etc/config/network
HOST_SN=`/thunder/bin/readkey sn | grep "data: "|sed 's/.*\(....\)$/\1/'`
echo "        option hostname    Minecrafter_$HOST_SN" >> /etc/config/network
sync
