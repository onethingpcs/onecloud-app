#!/bin/sh

PLUGIN_NAME="plugin-vodclient"
ubus call ${PLUGIN_NAME} exit
killall -9 vod
