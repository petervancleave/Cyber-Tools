#!/bin/bash
LOGS=("/var/log/syslog" "/var/log/auth.log")
echo "Cleaning logs..."
for log in "${LOGS[@]}"; do
    > "$log"
done
rm -rf /tmp/*
echo "Logs and temp files cleared."


# clear log files and /tmp folder periodically. Free up disk space