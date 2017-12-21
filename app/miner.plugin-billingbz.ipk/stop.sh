#!/bin/sh

PLUGIN_NAME="plugin-billingbz"
ubus call ${PLUGIN_NAME} exit
killall -9 billingbz
