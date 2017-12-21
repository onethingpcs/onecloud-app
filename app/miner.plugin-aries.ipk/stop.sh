#!/bin/sh

PLUGIN_NAME="plugin-aries"
ubus call ${PLUGIN_NAME} exit

/usr/bin/python /app/system/miner.${PLUGIN_NAME}.ipk/bin/aries.py stop

