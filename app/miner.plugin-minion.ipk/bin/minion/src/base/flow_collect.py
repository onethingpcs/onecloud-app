import os
import glob
import re
import collections
import logging

logger = logging.getLogger(__name__)

INFPATTERN = re.compile("eth0:(.*)$", re.MULTILINE)
MACFLOW = "/proc/net/dev"
PREVFLOW = "/var/run/.flowdiff"

def gen_billing_dict(billing_files, index_file, prev_pos_record):
    res = collections.OrderedDict()
    offset = 0 
    if not billing_files:
        return None, None, 0
    upload_candidates = get_candidate_billing_files(billing_files, index_file)
    if upload_candidates == "nofile":
        return None, upload_candidates, offset
    if upload_candidates == "latest":
        prev_bill_log, offset = read_prev_pos(prev_pos_record)
        if prev_bill_log == billing_files[-1]:
            #already in progress
            res, offset = parser_latest_billing_log(billing_files[-1], offset)
        else:
            #first time read the file
            res, offset = parser_latest_billing_log(billing_files[-1], 0)
        return res, upload_candidates, offset
    #a, lot of file did not upload
    #b, a new log generated
    for bill_log in upload_candidates:  
        prev_bill_log, offset = read_prev_pos(prev_pos_record)
        #new file generated, old file not end
        if bill_log == prev_bill_log:  
            inter_res, offset = parser_latest_billing_log(billing_files[-1], offset)
        else:
            inter_res = parser_old_billing_log(bill_log)
        if inter_res:
            res[bill_log] = inter_res
    return res, upload_candidates, 0

def save_index(index_file, file_name):
    with open(index_file, "w+") as info:
        info.write(file_name)
        info.truncate()
        
def get_index(index_file):
    file_name = None
    if not os.path.exists(index_file):
        return file_name
    with open(index_file) as info:
        file_name = info.readline().strip()
    return file_name

def read_prev_pos(prev_pos_record):
    file_name, offset = None, 0
    if not os.path.exists(prev_pos_record):
        return file_name, offset
    with open(prev_pos_record) as fd:
        content = fd.readline().strip()
        if content:
            file_name, offset = content.split()
    return file_name, int(offset)

def save_pos(prev_pos_record, file_name, offset):
    with open(prev_pos_record, "w") as fd:
        fd.write("%s %s" % (file_name, str(offset)))
        fd.truncate()

#return billing log list sorted by modify time
def get_sorted_logs(billing_log_dir):
    billing_files = []
    if not os.path.isdir(billing_log_dir):
        return billing_files
    billing_files = filter(os.path.isfile, glob.glob(os.path.join(billing_log_dir, "*.log")))
    billing_files = [os.path.join(billing_log_dir, f) for f in billing_files]
    billing_files.sort(key=lambda x: os.path.getmtime(x))
    return billing_files


#billing_files = get_sorted_logs(billing_log_dir)
def get_candidate_billing_files(billing_files, index_file):
    upload_candidates = []
    prev_billing_file = get_index(index_file)
    length = len(billing_files)
    if length == 1:
        return "latest"
    if prev_billing_file:
        for index, billing_file in enumerate(billing_files):
            if billing_file == prev_billing_file:
                #if there is not new file do nothing, index begin with 0
                if index == length - 1:
                    #uploading latest billing log
                    return "latest"
                    #to do
                else:
                    upload_candidates = billing_files[index:-1]
                    return upload_candidates
                                    
    else:
        if billing_files:
            return billing_files[0:-1]
        else:
            #no log to upload
            return "nofile"

def parser_old_billing_log(bill_log):
    return parser_billing_log(bill_log)

def parser_latest_billing_log(bill_log, offset):
    return parser_billing_log(bill_log, offset)

def parser_billing_log(bill_log, offset=0):
    inter_res = []
    _res = []
    agg_res = {}
    offset = offset
    with open(bill_log) as log:
        if offset:
            log.seek(offset)
        for line in log:
            line = line.strip()
            #billing log must contain 6 fields
            if line and len(line.split()) == 6:
                process, tx, rx, pid, date, dtime = line.split()
                item = {"proc_name": process, "tx": int(tx), "rx": int(rx),
                        "pid": int(pid), "btime": "%s %s" % (date, dtime)}
                _res.append(item)
        offset = log.tell()
        if _res:
            for elt in _res:
                key = elt["proc_name"] + elt["btime"]
                if key in agg_res:
                    agg_res[key]["rx"] += elt["rx"]
                    agg_res[key]["tx"] += elt["tx"]
                else:
                    agg_res[key] = elt
        inter_res = [v for k, v in agg_res.items()]
    return inter_res, offset
  
                
      

        
