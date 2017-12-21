#!/bin/sh

PLUGIN_NAME="plugin-iqiyihapp"
ubus call ${PLUGIN_NAME} exit
killall -9 happ
