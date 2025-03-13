#!/bin/bash
while true; do
    import -window root screenshot_$(date +%s).png
    sleep 10
done

# Takes a screenshot every 10 seconds

