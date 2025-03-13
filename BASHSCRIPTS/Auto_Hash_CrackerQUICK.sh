#!/bin/bash

# ID and crack password hashes using hashid and hashcat.
# Ask the user to input a hash
# Use hashid to identify what type of hash it is
# Show the potential hash types to the user
# Save the hash to a file
# Attempt to crack the hash with hashcat and rockyou wordlist
# Using MD5 (mode 0) as the default hash type
# Save any successfully cracked passwords to cracked.txt

# Note: it only tries to crack the hash as MD5 (-m 0) regardless of what hashid is identified. 
# modify script to use correct hash mode based on hashid results. (See AUTOHASHCRACKULT.sh)

# prompt user to input a hash value
echo "Enter Hash:"

# read the hash value input by the user and store it in the variable called hash
read hash

# pipe the hash to the hashid tool to id possible hash types
# store the output in the variable hashid_output
hasdhid_output=$(echo "$hash" | hashid)

echo "The Hash Type is:"

# display the hash type id result from hashid
echo "$hashid_output"

echo "Cracking Hash . . . "

# write the hash to a text file named hash.txt for hashcat to use
echo "$hash" > hash.txt

hashcat -m 0 -a 0 -o cracked.txt hash.txt /usr/share/wordlists/rockyou.txt --force

# runs hashcat with the following parameters:
# -m 0 -> specifies the hash mode 0 (MD5)
# -a 0 -> specifies attack mode 0 (dictionary attack)
# -0 cracked.txt -> outputs the cracked password to cracked.txt
# hash.txt -> the input file w/ the hash to be cracked 
# /usr/share/wordlists/rockyou.txt -> the wordlist for the dictionary attack
# --force -> forces hashcat to run