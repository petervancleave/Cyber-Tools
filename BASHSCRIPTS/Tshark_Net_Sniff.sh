#!/bin/bash

# Monitor a network for potentially insecure transmission of passwords over HTTP (no HTTPS) 
# Tshark = command line version of wireshark
# useful for pcap challenges (modify for static pcap file analysis), check for flags hidden in network traffic, find passwords or tokens being transmitted in HTTP traffic


echo "starting packet capture on eth0"

tshark -i eth0 -Y "http contains password" -T fields -e ip.src -e http.request.full_uri -e http.authorization
# runs Tshark with parameters
# -i eth0 : specifies to capture packets on the eth0 network interface
# -Y "http contains password" : applies a display filter to showo nly HTTP packets that contain the word password
# -T fields : sets output format to display specific fields only
# -e ip.src : shows the souce IP address
# -e http.request.full_uri : shows the full URI of HTTP requests
#  -e http.authorization : shows any HTTP authorization headers


