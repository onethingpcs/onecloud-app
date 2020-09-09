#!/bin/sh

PLUGIN_NAME="plugin-boxweb"
MAIN_EXE_NAME="boxweb"
PLUGIN_MONITOR=${MAIN_EXE_NAME}_monitor

PLUGIN_DIR="/onecloud-pluginipk/miner.${PLUGIN_NAME}.ipk"
PLUGIN_BIN_DIR="${PLUGIN_DIR}/bin"
PLUGIN_CONF_DIR="${PLUGIN_DIR}/conf"
PLUGIN_LIB_DIR="${PLUGIN_DIR}/lib"

# Note: Do not add & to make it run background.
cd ${PLUGIN_BIN_DIR} && ./${PLUGIN_MONITOR}

