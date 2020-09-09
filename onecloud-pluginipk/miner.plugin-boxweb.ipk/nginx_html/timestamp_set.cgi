#!/bin/sh

printf "Content-Type: text/plain; charset=utf-8\r\n"
printf "\r\n"
#printf "timestamp_set.cgi!\n"
python /onecloud-pluginipk/miner.plugin-boxweb.ipk/python_scripts/timestamp_set.py
