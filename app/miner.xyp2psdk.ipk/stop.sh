#!/bin/sh

PLUGIN_NAME="xyp2psdk"
ubus call ${PLUGIN_NAME} exit
killall -9 xy_p2p_sdk
