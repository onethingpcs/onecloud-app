import sys
import json
import os
import re

def ip_into_int(ip):
    return reduce(lambda x,y:(x<<8)+y,map(int,ip.split('.')))

def is_internal_ip(ip):
    ip = ip_into_int(ip)
    net_a = ip_into_int('10.255.255.255') >> 24
    net_b = ip_into_int('172.31.255.255') >> 20
    net_c = ip_into_int('192.168.255.255') >> 16
    return ip >> 24 == net_a or ip >>20 == net_b or ip >> 16 == net_c

def check_is_pppoe_type(check_json_str):
    check_json_dict = json.loads(check_json_str)
    if check_json_dict["type"] == "pppoe":
        return 1
    else:
        return 0

def set_pppoe_network(pppoe_json_str):
    pppoe_dict = json.loads(pppoe_json_str)
    if pppoe_dict["type"] == "pppoe":
        # Check the number of parameters
        dict_len = len(pppoe_dict)
        #print ("pppoe dict len = %d" %dict_len)
        if dict_len != 3:
            #print "Error: pppoe type, args > 3"
            return 1
        # check the length of json str
        str_len = len(pppoe_json_str)
        if str_len > 256:
            # print ('the length of pppoe_json_str is too long : %d' %str_len)
            return 1

        pppoe_dict["on"] = 1
        #print json.dumps(pppoe_dict)
        set_params = json.dumps(pppoe_dict)
        pppoe_data = "ubus call netcfg set_pppoe '%s'" % (set_params)
        #print "pppoe_data is", pppoe_data
        os.popen(pppoe_data)
        allinfo_str = os.popen("ubus call netcfg get_network_all").read()
        if allinfo_str != "":
            allinfo_str = json.loads(allinfo_str)
            sub_json_str = json.dumps(allinfo_str["pppoe"])
            if sub_json_str != "":
                sub_dict = json.loads(sub_json_str)
                if sub_dict["on"] == 1:
                    return 0 
    return 1

def set_network():
    #json_str = "{\"type\": \"pppoe\", \"username\": \"hello\", \"password\": \"helloworld\"}"
    json_str = sys.stdin.readline()
    
    if json_str == "":
        return '{"error_code":1}'
    else:
        # avoid illegal command
        chars = set(';&|')
        if any((c in chars) for c in json_str):
            return '{"error_code":2}'
        # if not(re.match("[A-Za-z0-9\"\-_@{}:,. ]*$", json_str)):
        #    return '{"error_code":2}'
           
        ip = os.environ['REMOTE_ADDR']
        retstr = is_internal_ip(ip) 
        if not(retstr):
            return '{"error_code":3}'
           
        is_pppoe_type = check_is_pppoe_type(json_str)
        if is_pppoe_type == 1:
            pppoe_set_result = set_pppoe_network(json_str)
            if pppoe_set_result == 0:
                return '{"error_code":0}'
            else:
                return '{"error_code":1}'
        
        # Check the number of parameters
        para_dict = json.loads(json_str)
        dict_len = len(para_dict)
        #print ("dict len = %d" %dict_len)
        if dict_len > 7:
            #print "Error: args > 7"
            return '{"error_code":4}'
        # check the length of json str
        str_len = len(json_str)
        if str_len > 256:
            # print ('the length of json_str is too long : %d' %str_len)
            return '{"error_code":4}'

        data = "ubus call netcfg set_network '%s'" % (json_str)
        os.popen(data) # fine, nothing return... 
    
        new_json_str = os.popen("ubus call netcfg get_network").read()

        if new_json_str == "":
            return '{"error_code":1}'
        else:
            new_dict = json.loads(new_json_str)
            old_dict = json.loads(json_str)

            if new_dict["type"] != old_dict["type"]:
                return '{"error_code":1}'

            # dhcp mode
            if new_dict["type"] == "dhcp":
                return '{"error_code":0}'
            
            # static mode
            if new_dict["type"] != "static":
                return '{"error_code":1}'
            if new_dict["ip"] != old_dict["ip"]:
                return '{"error_code":1}'
            if new_dict["netmask"] != old_dict["netmask"]:
                return '{"error_code":1}'
            if new_dict["gateway"] != old_dict["gateway"]:
                return '{"error_code":1}'

    return '{"error_code":0}'

ret = set_network()
print ret
