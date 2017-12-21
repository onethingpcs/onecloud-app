#!/bin/sh
cache_base="/tmp/dcdn_base/.thirdapp/pluginiqiyihapp_DATA"
while true
do
    if [ -d $cache_base ]; then
        chown -R pluginiqiyihapp:pluginiqiyihapp $cache_base
    fi
    sleep 5
done
