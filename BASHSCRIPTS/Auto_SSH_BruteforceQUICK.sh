#!/bin/bash

echo "Enter target IP"
read IP
hydra -L users.txt -P passwords.txt ssh://$IP -t 4
