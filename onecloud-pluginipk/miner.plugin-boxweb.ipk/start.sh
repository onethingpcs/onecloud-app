#!/bin/sh

PLUGIN_NAME="plugin-boxweb"

CHECK_FILE="/onecloud-pluginipk/miner.plugin-boxweb.ipk/stop.sh"
if [ -f  ${CHECK_FILE} ]; then
    /bin/sh ${CHECK_FILE}
fi
sleep 2

idx=0
while [ $idx -lt 30 ]
do
check_plugin=`ubus call  $PLUGIN_NAME get_status`
if [ -z "$check_plugin" ]; then
    echo "start plugin_proxy ${PLUGIN_NAME}"
    export LD_LIBRARY_PATH="/thunder/lib:/onecloud-pluginipk/miner.${PLUGIN_NAME}.ipk/lib"
    /thunder/bin/plugin_proxy ${PLUGIN_NAME} &
    ubus wait_for ${PLUGIN_NAME} -t 3
    idx=`expr $idx + 1`
    continue
else
    echo "plugin ${PLUGIN_NAME} already on ubus"
    break
fi
done

