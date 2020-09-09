#!/bin/sh

printf "Content-Type: text/plain; charset=utf-8\r\n"
printf "\r\n"
#printf "set_network.cgi!\n"
python /onecloud-pluginipk/miner.plugin-boxweb.ipk/python_scripts/set_network.py
