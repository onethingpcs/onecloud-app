import sys
import json
import os

def ip_into_int(ip):
    return reduce(lambda x,y:(x<<8)+y,map(int,ip.split('.')))

def is_internal_ip(ip):
    ip = ip_into_int(ip)
    net_a = ip_into_int('10.255.255.255') >> 24
    net_b = ip_into_int('172.31.255.255') >> 20
    net_c = ip_into_int('192.168.255.255') >> 16
    return ip >> 24 == net_a or ip >>20 == net_b or ip >> 16 == net_c

def reboot():
    ip = os.environ['REMOTE_ADDR']                                                                                  
    retstr = is_internal_ip(ip) 
    if not(retstr):
        return '{"error_code":2}'
    
    os.popen("ubus call mnt reboot")
        

ret_str = reboot()
#print ret_str
