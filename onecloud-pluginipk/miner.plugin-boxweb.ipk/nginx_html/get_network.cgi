#!/bin/sh

printf "Content-Type: text/plain; charset=utf-8\r\n"
printf "\r\n"
#printf "get_network.cgi!\n"
python /onecloud-pluginipk/miner.plugin-boxweb.ipk/python_scripts/get_network.py
