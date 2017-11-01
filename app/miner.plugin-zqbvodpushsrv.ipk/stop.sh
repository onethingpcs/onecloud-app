#!/bin/sh

PLUGIN_NAME="plugin-zqbvodpushsrv"
ubus call ${PLUGIN_NAME} exit
killall -9 myp2prun
