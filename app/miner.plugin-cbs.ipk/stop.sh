#!/bin/sh

PLUGIN_NAME="plugin-cbs"
ubus call ${PLUGIN_NAME} exit

killall -9 cbs_client

