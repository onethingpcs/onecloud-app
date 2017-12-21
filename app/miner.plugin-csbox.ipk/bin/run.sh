#!/bin/sh

PLUGIN_NAME="plugin-csbox"
MAIN_EXE_NAME="csbox"
PLUGIN_MONITOR=${MAIN_EXE_NAME}_monitor

PLUGIN_DIR="/app/system/miner.${PLUGIN_NAME}.ipk"
PLUGIN_BIN_DIR="${PLUGIN_DIR}/bin"
PLUGIN_CONF_DIR="${PLUGIN_DIR}/conf"
PLUGIN_LIB_DIR="${PLUGIN_DIR}/lib"

# Note: Do not add & to make it run background.
cd ${PLUGIN_BIN_DIR} && ./${PLUGIN_MONITOR}
#ulimit -v unlimited
#cd ${PLUGIN_BIN_DIR} && python ./run.py

