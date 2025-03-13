#!/bin/bash

# fetch public data based on a username from common sources

echo "Enter username to search:"
read USERNAME
echo "Searching for $USERNAME..."
curl -s "https://api.github.com/users/$USERNAME" | jq .
curl -s "https://www.instagram.com/$USERNAME/?__a=1" | jq .
curl -s "https://www.reddit.com/user/$USERNAME/about.json" | jq .
echo "OSINT search complete"
