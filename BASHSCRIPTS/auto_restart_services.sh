#!/bin/bash
SERVICE="apache2"
if ! systemctl is-active --quiet $SERVICE; then
    echo "$SERVICE is down. Restarting..."
    systemctl restart $SERVICE
fi

# Monitors and restarts a service if it crashes