#!/bin/sh

PLUGIN_NAME="plugin-platinum"
ubus call ${PLUGIN_NAME} exit
killall -9 platinumd
