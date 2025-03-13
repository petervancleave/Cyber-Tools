#!/bin/bash
echo "Enter target IP:"
read IP
mkdir recon
nmap -sC -sV -oN recon/nmap.txt $IP
gobuster dir -u http://$IP -w /usr/share/wordlists/dirb/common.txt -o recon/gobuster.txt
nikto -h http://$IP > recon/nikto.txt
echo "Recon completed!"


# Automates nmap, gobuster, and nikto scanning.