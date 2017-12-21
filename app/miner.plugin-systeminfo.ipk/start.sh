#!/bin/sh

PLUGIN_NAME="plugin-systeminfo"

check_plugin=`ubus call  $PLUGIN_NAME get_status`
if [ -z "$check_plugin" ]; then
    echo "start plugin_proxy ${PLUGIN_NAME}"
    export LD_LIBRARY_PATH="/thunder/lib:/app/system/miner.${PLUGIN_NAME}.ipk/lib"
    /thunder/bin/plugin_proxy ${PLUGIN_NAME} &
else
    echo "plugin ${PLUGIN_NAME} already on ubus"
fi

