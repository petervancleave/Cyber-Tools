#!/bin/bash

# Automatically detects and cracks various hash types

set -e # exit on error

GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m' 


# config variables
WORDLIST="/usr/share/wordlists/rockyou.txt"
OUTPUT_FILE="cracked.txt"
HASH_FILE="hash.txt"
MAX_RUNTIME=3600 # max runtime in seconds (1 hour is default)

# check if requirements are installed
check_requirements() {
    echo -e "${BLUE}[*] Checking requirements . . .${NC}"
    for tool in hashid hashcat; do
        if ! command -v $tool &> /dev/null; then
            echo -e "${RED}[!] Error: $tool is not installed${NC}"
            echo -e "${YELLOW}[*] Install it with: sudo apt install $tool${NC}"
            exit 1
        fi
    done
    
    if [ ! -f "$WORDLIST" ]; then
        echo -e "${RED}[!] Error: Wordlist not found at $WORDLIST${NC}"
        echo -e "${YELLOW}[*] Specify a valid wordlist path${NC}"
        exit 1
    fi
}

# Map hashid results to hashcat modes
get_hashcat_mode() {
    local hash_type="$1"
    
    # Common hash types mapping
    if echo "$hash_type" | grep -qi "MD5"; then
        echo "0"
    elif echo "$hash_type" | grep -qi "SHA-1"; then
        echo "100"
    elif echo "$hash_type" | grep -qi "SHA-256"; then
        echo "1400"
    elif echo "$hash_type" | grep -qi "SHA-512"; then
        echo "1700"
    elif echo "$hash_type" | grep -qi "NTLM"; then
        echo "1000"
    elif echo "$hash_type" | grep -qi "MySQL"; then
        echo "200"
    elif echo "$hash_type" | grep -qi "bcrypt"; then
        echo "3200"
    elif echo "$hash_type" | grep -qi "WPA"; then
        echo "2500"
    elif echo "$hash_type" | grep -qi "MD4"; then
        echo "900"
    elif echo "$hash_type" | grep -qi "Whirlpool"; then
        echo "6100"
    else
        # Default to MD5 if no match found
        echo "0"
    fi
}

# attempt cracking with different attack methods
crack_hash() {
    local mode="$1"
    local hash="$2"
    local success=false
    
    echo -e "${BLUE}[*] Attempting to crack hash with mode $mode${NC}"
    
    # Dictionary attack
    echo -e "${YELLOW}[*] Trying dictionary attack . . .${NC}"
    if hashcat -m "$mode" -a 0 -o "$OUTPUT_FILE" "$HASH_FILE" "$WORDLIST" --quiet --force --status --status-timer=10 --runtime="$MAX_RUNTIME"; then
        if [ -s "$OUTPUT_FILE" ]; then
            success=true
            return 0
        fi
    fi
    
    # rule based attack if dictionary attack doesn't work
    if [ "$success" = false ]; then
        echo -e "${YELLOW}[*] Trying rule-based attack...${NC}"
        if hashcat -m "$mode" -a 0 -o "$OUTPUT_FILE" "$HASH_FILE" "$WORDLIST" -r /usr/share/hashcat/rules/best64.rule --quiet --force --status --status-timer=10 --runtime="$MAX_RUNTIME"; then
            if [ -s "$OUTPUT_FILE" ]; then
                success=true
                return 0
            fi
        fi
    fi
    
    # Try brute force (if hash is simple)
    if [ "$success" = false ] && [ ${#hash} -lt 32 ]; then
        echo -e "${YELLOW}[*] Trying brute force for hash . . .${NC}"
        if hashcat -m "$mode" -a 3 -o "$OUTPUT_FILE" "$HASH_FILE" "?a?a?a?a?a?a" --increment --quiet --force --status --status-timer=10 --runtime=300; then
            if [ -s "$OUTPUT_FILE" ]; then
                success=true
                return 0
            fi
        fi
    fi
    
    return 1
}

# Main function
main() {
    clear
    echo -e "${GREEN}===========================================${NC}"
    echo -e "${GREEN}       Auto Hash Cracking Tool        ${NC}"
    echo -e "${GREEN}===========================================${NC}"
    
    # Check requirements
    check_requirements
    
    # Get hash input
    echo -e "${BLUE}[*] Enter the hash to crack:${NC}"
    read -r hash
    
    if [ -z "$hash" ]; then
        echo -e "${RED}[!] Error: No hash provided${NC}"
        exit 1
    fi
    
    # Save hash to file
    echo "$hash" > "$HASH_FILE"
    
    # Identify hash type
    echo -e "${BLUE}[*] Identifying hash type...${NC}"
    hashid_output=$(hashid "$hash")
    echo -e "${GREEN}[+] Hash identification results:${NC}"
    echo "$hashid_output"
    
    # Extract most likely hash types
    hash_types=$(echo "$hashid_output" | grep -oP '(?<=\[).*?(?=\])' | sort -u)
    
    if [ -z "$hash_types" ]; then
        echo -e "${YELLOW}[!] Warning: Could not determine hash type. Defaulting to MD5.${NC}"
        hash_types="MD5"
    fi
    
    # try each possible hash type
    echo -e "${BLUE}[*] Will try the following hash types: $hash_types${NC}"
    cracked=false
    
    for hash_type in $hash_types; do
        mode=$(get_hashcat_mode "$hash_type")
        echo -e "${YELLOW}[*] Trying hash type: $hash_type (Hashcat mode: $mode)${NC}"
        
        # try to crack with current mode
        if crack_hash "$mode" "$hash"; then
            cracked=true
            break
        fi
    done
    
    # check if cracking was successful
    if [ "$cracked" = true ] || [ -s "$OUTPUT_FILE" ]; then
        echo -e "${GREEN}[+] Hash successfully cracked!${NC}"
        echo -e "${GREEN}[+] Results:${NC}"
        cat "$OUTPUT_FILE"
    else
        echo -e "${RED}[!] Failed to crack the hash with available methods.${NC}"
        echo -e "${YELLOW}[*] Consider:${NC}"
        echo -e "${YELLOW}    - Using a larger wordlist${NC}"
        echo -e "${YELLOW}    - Trying more specific hash modes manually${NC}"
        echo -e "${YELLOW}    - Using more advanced attack methods${NC}"
    fi
    
    # Cleanup
    echo -e "${BLUE}[*] Cleaning up temporary files...${NC}"
    if [ -f "$HASH_FILE" ]; then
        rm "$HASH_FILE"
    fi
    
    echo -e "${GREEN}[+] Done!${NC}"
}

# Run main 
main
