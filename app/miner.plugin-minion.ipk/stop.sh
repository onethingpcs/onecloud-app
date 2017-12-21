#!/bin/sh

PLUGIN_NAME="plugin-minion"
ubus call ${PLUGIN_NAME} exit
pid=`ps -ef | grep minion | grep python | grep -v grep`
kill $pid

