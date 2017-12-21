import os
import re 
#Decimal

KB = 1000
MB = 1000 * KB
GB = 1000 * MB
TB = 1000 * GB
PB = 1000 * TB

#Binary

KiB = 1024
MiB = 1024 * KiB
GiB = 1024 * MiB
TiB = 1024 * GiB
PiB = 1024 * TiB
    
DECIMALMAP = {"k": KB, "m": MB, "g": GB, "t": TB, "p": PB}
BINARYMAP = {"k": KiB, "m": MiB, "g": GiB, "t": TiB, "p": PiB}
SIZEREGEX = re.compile("(\d+\.?\d*)([kKmMgGtTpP])?[bB]?$")
DECIMALABBRS = ["KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"]
BINARYABBRS = ["KiB", "MiB", "GiB", "TiB", "PiB", "EiB", "ZiB", "YiB"] 

def calc_size(size_str):
    size_str = size_str.replace(" ", "")
    for prefix in DECIMALABBRS:
        if size_str.endswith(prefix):
            return from_human_size(size_str)
    for prefix in BINARYABBRS:
        if size_str.endswith(prefix):
            size_str = size_str.replace("i", "")
            return mem_in_bytes(size_str)
    return from_human_size(size_str)

def from_human_size(size_str):
    return parse_size(size_str, DECIMALMAP)

def mem_in_bytes(size_str):
    return parse_size(size_str, BINARYMAP)

def parse_size(size_str, unit_map):
    matches = SIZEREGEX.match(size_str)
    if not matches:
        raise TypeError("non standard format")
    if len(matches.groups()) != 2:
        raise TypeError("not standard format")
    size = float(matches.group(1))
    try:
        unit_prefix = matches.group(2).lower()
    except AttributeError as e:
        return size
    mul = unit_map[unit_prefix]
    if mul:
        size *= mul
    return size
    
if __name__ == "__main__":
    print parse_size("100B", BINARYMAP)