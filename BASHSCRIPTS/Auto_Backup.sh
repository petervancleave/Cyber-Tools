#!/bin/bash

# Back up specific directories to an external drive or remote server daily

SRC="/home/user/Documents"
DEST="/mnt/backup"
DATE=$(date +%Y-%m-%d)
tar -czf "$DEST/backup-$DATE.tar.gz" "$SRC"
echo "Backup completed: $DEST/backup-$DATE.tar.gz"
