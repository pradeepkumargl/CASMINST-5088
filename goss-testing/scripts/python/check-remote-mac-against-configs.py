#! /usr/bin/env python3

# Script to check MAC address of remote NCNs against data.json and statics.conf
# Invocation: check-remote-mac-against-configs.py /path/to/data.json /path/to/statics.conf
# Check the count of passed tests against the number of NCNs in data.conf - and send either PASS or FAIL

import subprocess, sys, logging
import lib.data_json_parser as djp

getMACcommand = "ip addr show dev bond0 | grep 'link/ether' | tr -s ' ' | cut -d ' ' -f 3"
passed = 0
failed = 0

# setup logging
logging.basicConfig(filename='/tmp/' + sys.argv[0].split('/')[-1] + '.log',  level=logging.DEBUG)
logging.info("Starting up")

def remoteCmd(host, command):
    cmd = subprocess.Popen(['ssh', '-o StrictHostKeyChecking=no', host , command], stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    stdout,stderr = cmd.communicate()
    return stdout

def get_arg_no_brackets(arg):
    return arg.strip('[').strip(']')

# quick check to ensure we received the locations of data.json and statics.conf
if len(sys.argv) != 3:
    print("Wrong number of arguments provided")
    sys.exit()
    
# This version of goss sends [.Arg.*] as string with [
# Apparently fixed in 0.3.14 
data = djp.dataJson(get_arg_no_brackets(sys.argv[1]))
staticsFile = open(get_arg_no_brackets(sys.argv[2]),'r')
statics = staticsFile.read()


# ensure remote MAC matches data.json (casminst-384) and statics.conf (casminst-380)
for server in data.ncnList:
    # get the MAC from the NCN
    mac = remoteCmd(server, getMACcommand).decode().strip()
    
    # ensure that the MAC address is somehere in data.json
    if mac in data.ncnKeys:
        # ensure that the hostname's MAC in data.json matches reality
        if data.ncnList[server] == mac:
            passed += 1
    else:
        failed += 1
        
    # ensure that the mac exists in statics.conf
    if mac in statics:
        # check statics.conf
        # should find something like: dhcp-host=b8:59:9f:2b:2e:d2,10.252.0.7,ncn-s001,infinite
        # the ip is between the first commas
        try:
            search = statics[statics.find('dhcp-host=' + data.ncnList[server]):statics.find('\n',statics.find('dhcp-host=' + data.ncnList[server]))]    
            ip, hname = search[search.find(','):search.rfind(',')].split(',')[-2:]
            if mac == data.ncnList[hname]: 
                passed += 1
        except:
            print("Error in statics.conf")

    else:
        failed += 1
# There are two tests per ncn, so the number of tests passed should == number of keys * 2
if passed == len(data.ncnKeys) * 2:
    print("PASS")
else:
    print("FAIL")

