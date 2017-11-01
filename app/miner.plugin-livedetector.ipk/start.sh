#!/bin/sh

PLUGIN_NAME="plugin-livedetector"

check_plugin=`ubus list | grep $PLUGIN_NAME`
if [ -z "$check_plugin" ]; then
    echo "start plugin_proxy ${PLUGIN_NAME}"
    export LD_LIBRARY_PATH="/thunder/lib:/app/system/miner.${PLUGIN_NAME}.ipk/lib"
    /thunder/bin/plugin_proxy ${PLUGIN_NAME} &
else
    echo "plugin ${PLUGIN_NAME} already on ubus"
fi

