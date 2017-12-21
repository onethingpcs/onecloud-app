#!/bin/sh

PLUGIN_NAME="plugin-natdetect"
ubus call ${PLUGIN_NAME} exit
killall -9 natdetect
