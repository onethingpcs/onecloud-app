#!/bin/sh

PLUGIN_NAME="plugin-etm"
ubus call ${PLUGIN_NAME} exit

killall -9 etm_monitor
killall -9 etm
killall -9 hubble 
killall -9 wxdp

