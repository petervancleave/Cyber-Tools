#!/bin/bash

# System Integrity Monitor quick check
# monitor critical files for unauthorized modifications

while true; do
    sha256sum /etc/passwd /etc/shadow > current.txt
    sleep 10
    sha256sum -c current.txt || echo "Warning! files modified"
done
