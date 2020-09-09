import os
import json
import re
import sys

def ip_into_int(ip):
    return reduce(lambda x,y:(x<<8)+y,map(int,ip.split('.')))

def is_internal_ip(ip):
    ip = ip_into_int(ip)
    net_a = ip_into_int('10.255.255.255') >> 24
    net_b = ip_into_int('172.31.255.255') >> 20
    net_c = ip_into_int('192.168.255.255') >> 16
    return ip >> 24 == net_a or ip >>20 == net_b or ip >> 16 == net_c

json_str = os.popen("ubus call netcfg get_network_all 2>/dev/null").read()

if json_str == "":
    json_str = os.popen("ubus call netcfg get_ipv6_network 2>/dev/null").read()

if json_str == "":
    json_str = os.popen("ubus call netcfg get_network 2>/dev/null").read()

if json_str == "":
    print '{"error_code":1}'
else:
    ip = os.environ['REMOTE_ADDR']
    retstr = is_internal_ip(ip) 
    if not(retstr):
        print '{"error_code":3}'
        sys.exit()

    dict = json.loads(json_str)
    if ("pppoe" in json_str):
        sub_json_str = json.dumps(dict ["pppoe"])
        sub_dict = json.loads(sub_json_str)
        sub_dict["error_code"] = 0
        if sub_dict["on"] == 1:
            print json.dumps(sub_dict)
            sys.exit()
    
    if ("ipv4" in json_str):
        sub_json_str = json.dumps(dict ["ipv4"])
        sub_dict = json.loads(sub_json_str)
        sub_dict["error_code"] = 0
        print json.dumps(sub_dict)
    else: 
        dict["error_code"] = 0
        json_str_ret = json.dumps(dict)
        print json_str_ret
    
