#!/bin/bash
THRESHOLD=80  # Set CPU usage limit
while true; do
    ps -eo pid,%cpu,comm --sort=-%cpu | awk -v threshold=$THRESHOLD '$2 > threshold {print "Killing process: "$3" (PID: "$1")"; system("kill -9 "$1)}'
    sleep 5
done


# Automatically detects and kills processes consuming excessive CPU.