#!/bin/bash
apt update && apt upgrade -y
if [ $? -eq 0 ]; then
    echo "Update successful. Rebooting..."
    shutdown -r +5
else
    echo "Update failed. Check manually."
fi

# Keeps the system updated and schedules a reboot if necessary