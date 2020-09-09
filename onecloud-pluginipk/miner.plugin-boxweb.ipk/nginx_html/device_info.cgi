#!/bin/sh

printf "Content-Type: text/plain; charset=utf-8\r\n"
printf "\r\n"
#printf "device_info.cgi!\n"
python /onecloud-pluginipk/miner.plugin-boxweb.ipk/python_scripts/device_info.py
