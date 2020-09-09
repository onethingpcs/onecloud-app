#!/bin/sh

PLUGIN_NAME="plugin-boxweb"
PLUGIN_DIR="/onecloud-pluginipk/miner.${PLUGIN_NAME}.ipk"
PROCESS_NAME="fcgiwrap -f -s unix:/run/fcgiwrap.socket"

ubus call ${PLUGIN_NAME} exit
killall -9 boxweb_monitor
killall -9 boxweb

proc_id=`ps | grep -w "$PROCESS_NAME" | grep -v grep | awk '{print $1}'`
if [ -n "$proc_id" ]; then
    kill -9 $proc_id
fi

${PLUGIN_DIR}/etc/init.d/S91nginx stop



