#!/bin/sh

PLUGIN_NAME="plugin-csbox"
ubus call ${PLUGIN_NAME} exit
killall -9 csbox
