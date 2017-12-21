#!/bin/sh

PLUGIN_NAME="plugin-relay"
ubus call ${PLUGIN_NAME} exit
killall -9 relay
