#!/bin/sh

PLUGIN_NAME="plugin-netprog"
ubus call ${PLUGIN_NAME} exit
killall -9 netprog
