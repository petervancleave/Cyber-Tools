#!/bin/bash

# Auto Hash Cracker

set -e

YELLOW='\033[0;33m'
NC='\033[0m'

DEFAULT_WORDLIST="/usr/share/wordlists/rockyou.txt"
SECLIST_PATH="/usr/share/wordlists/seclists/Passwords"
OUTPUT_FILE="cracked.txt"
HASH_FILE="hash.txt"
SORTED_HASH_FILE="sorted_hashes.txt"
CLUSTER_DIR="hash_clusters"
MAX_RUNTIME=3600
HASHCAT_PID=""

check_requirements() {
    echo -e "${YELLOW}[*] Checking requirements . . .${NC}"
    for tool in name-that-hash hashcat; do
        if ! command -v $tool &> /dev/null; then
            echo -e "${YELLOW}[!] Error: $tool is not installed${NC}"
            echo -e "${YELLOW}[*] Install it with: sudo apt install $tool${NC}"
            exit 1
        fi
    done
}

select_wordlist() {
    echo -e "${YELLOW}[*] Select wordlist option:${NC}"
    echo -e "${YELLOW}[1] Default (rockyou.txt)${NC}"
    echo -e "${YELLOW}[2] SecLists password collection${NC}"
    echo -e "${YELLOW}[3] Custom wordlist path${NC}"
    read -r wordlist_option

    case $wordlist_option in
        1)
            WORDLIST="$DEFAULT_WORDLIST"
            if [ ! -f "$WORDLIST" ]; then
                echo -e "${YELLOW}[!] Error: Default wordlist not found at $WORDLIST${NC}"
                echo -e "${YELLOW}[*] Please select another option${NC}"
                select_wordlist
            else
                echo -e "${YELLOW}[+] Using default wordlist: $WORDLIST${NC}"
            fi
            ;;
        2)
            if [ ! -d "$SECLIST_PATH" ]; then
                echo -e "${YELLOW}[!] Error: SecLists not found at $SECLIST_PATH${NC}"
                echo -e "${YELLOW}[*] Install it with: sudo apt install seclists${NC}"
                echo -e "${YELLOW}[*] Or select another option${NC}"
                select_wordlist
            else
                echo -e "${YELLOW}[*] Select SecList wordlist:${NC}"
                select_seclist_wordlist
            fi
            ;;
        3)
            echo -e "${YELLOW}[*] Enter the full path to your wordlist:${NC}"
            read -r custom_path
            if [ ! -f "$custom_path" ]; then
                echo -e "${YELLOW}[!] Error: Wordlist not found at $custom_path${NC}"
                echo -e "${YELLOW}[*] Please enter a valid path${NC}"
                select_wordlist
            else
                WORDLIST="$custom_path"
                echo -e "${YELLOW}[+] Using custom wordlist: $WORDLIST${NC}"
            fi
            ;;
        *)
            echo -e "${YELLOW}[!] Invalid option. Please select 1, 2, or 3${NC}"
            select_wordlist
            ;;
    esac
}

select_seclist_wordlist() {
    local options=()
    local i=1
    
    echo -e "${YELLOW}[*] Available SecList wordlists:${NC}"
    while IFS= read -r file; do
        options+=("$file")
        echo -e "${YELLOW}[$i] $(basename "$file")${NC}"
        ((i++))
    done < <(find "$SECLIST_PATH" -type f -name "*.txt" | sort)

    if [ ${#options[@]} -eq 0 ]; then
        echo -e "${YELLOW}[!] No wordlists found in SecLists directory${NC}"
        select_wordlist
        return
    fi

    echo -e "${YELLOW}[*] Enter wordlist number:${NC}"
    read -r selection
    
    if [[ "$selection" =~ ^[0-9]+$ ]] && [ "$selection" -ge 1 ] && [ "$selection" -le ${#options[@]} ]; then
        WORDLIST="${options[$((selection-1))]}"
        echo -e "${YELLOW}[+] Using wordlist: $WORDLIST${NC}"
    else
        echo -e "${YELLOW}[!] Invalid selection${NC}"
        select_seclist_wordlist
    fi
}

get_hashcat_mode() {
    local hash_type="$1"
    if echo "$hash_type" | grep -qi "MD5$"; then echo "0"
    elif echo "$hash_type" | grep -qi "MD4"; then echo "900"
    elif echo "$hash_type" | grep -qi "SHA-1"; then echo "100"
    elif echo "$hash_type" | grep -qi "SHA-224"; then echo "1300"
    elif echo "$hash_type" | grep -qi "SHA-256"; then echo "1400"
    elif echo "$hash_type" | grep -qi "SHA-384"; then echo "10800"
    elif echo "$hash_type" | grep -qi "SHA-512"; then echo "1700"
    elif echo "$hash_type" | grep -qi "SHA3-256"; then echo "17300"
    elif echo "$hash_type" | grep -qi "SHA3-512"; then echo "17400"
    elif echo "$hash_type" | grep -qi "Blake2b"; then echo "60000"
    elif echo "$hash_type" | grep -qi "Whirlpool"; then echo "6100"
    elif echo "$hash_type" | grep -qi "RIPEMD-160"; then echo "6000"
    elif echo "$hash_type" | grep -qi "NTLM"; then echo "1000"
    elif echo "$hash_type" | grep -qi "NetNTLMv2"; then echo "5600"
    elif echo "$hash_type" | grep -qi "NetNTLM"; then echo "5500"
    elif echo "$hash_type" | grep -qi "LM Hash"; then echo "3000"
    elif echo "$hash_type" | grep -qi "bcrypt"; then echo "3200"
    elif echo "$hash_type" | grep -qi "PBKDF2-HMAC-SHA1"; then echo "12000"
    elif echo "$hash_type" | grep -qi "MySQL\|MySQL323"; then echo "200"
    elif echo "$hash_type" | grep -qi "MySQL5"; then echo "300"
    elif echo "$hash_type" | grep -qi "WPA"; then echo "2500"
    elif echo "$hash_type" | grep -qi "OSX v10.7"; then echo "7100"
    elif echo "$hash_type" | grep -qi "OSX v10.8"; then echo "7100"
    elif echo "$hash_type" | grep -qi "SMF"; then echo "2600"
    else echo "0"
    fi
}

handle_multiple_hashes() {
    echo -e "${YELLOW}[*] Multiple hashes detected. Would you like to:${NC}"
    echo -e "${YELLOW}[1] Process all hashes together${NC}"
    echo -e "${YELLOW}[2] Cluster similar hashes for more efficient cracking${NC}"
    read -r cluster_option

    if [ "$cluster_option" = "2" ]; then
        cluster_hashes
    else
        echo -e "${YELLOW}[+] Processing all hashes together${NC}"
    fi
}

cluster_hashes() {
    echo -e "${YELLOW}[*] Clustering hashes by type and similarity...${NC}"
    
    rm -rf "$CLUSTER_DIR" 2>/dev/null || true
    mkdir -p "$CLUSTER_DIR"
    
    echo -e "${YELLOW}[*] Grouping by hash length...${NC}"
    awk '{print length($0), $0}' "$HASH_FILE" | sort -n | awk '{print $2}' > "$SORTED_HASH_FILE"
    
    current_length=0
    cluster_count=0
    
    while IFS= read -r hash; do
        hash_length=${#hash}
        
        if [ "$hash_length" != "$current_length" ]; then
            current_length="$hash_length"
            cluster_count=$((cluster_count + 1))
            echo -e "${YELLOW}[+] Creating cluster $cluster_count for hashes of length $current_length${NC}"
        fi
        
        echo "$hash" >> "$CLUSTER_DIR/cluster_$cluster_count.txt"
    done < "$SORTED_HASH_FILE"
    
    echo -e "${YELLOW}[+] Created $cluster_count hash clusters${NC}"
    echo -e "${YELLOW}[*] Would you like to see a summary of the clusters? (y/n)${NC}"
    read -r show_summary
    
    if [[ "$show_summary" =~ ^[Yy]$ ]]; then
        for i in $(seq 1 $cluster_count); do
            count=$(wc -l < "$CLUSTER_DIR/cluster_$i.txt")
            sample=$(head -n 1 "$CLUSTER_DIR/cluster_$i.txt")
            echo -e "${YELLOW}Cluster $i:${NC} $count hashes, length ${#sample}, sample: ${sample:0:40}..."
        done
    fi
    
    return "$cluster_count"
}

check_rainbow_tables() {
    echo -e "${YELLOW}[*] Would you like to check rainbow tables? (y/n)${NC}"
    read -r use_rainbow
    
    if [[ "$use_rainbow" =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}[*] Enter path to rainbow tables directory:${NC}"
        read -r rainbow_path
        
        if [ ! -d "$rainbow_path" ]; then
            echo -e "${YELLOW}[!] Directory not found: $rainbow_path${NC}"
            echo -e "${YELLOW}[*] Skipping rainbow table lookup${NC}"
            return 1
        fi
        
        echo -e "${YELLOW}[*] Looking for compatible rainbow tables...${NC}"
        
        rt_found=false
        
        if ls "$rainbow_path"/*.rt >/dev/null 2>&1; then
            rt_found=true
            echo -e "${YELLOW}[+] Found RainbowCrack tables${NC}"
            
            if command -v rcrack &> /dev/null; then
                echo -e "${YELLOW}[*] Running RainbowCrack...${NC}"
                rcrack "$rainbow_path"/*.rt -f "$HASH_FILE" -o "$OUTPUT_FILE.rainbow"
                
                if [ -s "$OUTPUT_FILE.rainbow" ]; then
                    echo -e "${YELLOW}[+] Rainbow table cracking successful!${NC}"
                    cat "$OUTPUT_FILE.rainbow" >> "$OUTPUT_FILE"
                    return 0
                else
                    echo -e "${YELLOW}[*] No hashes cracked with rainbow tables${NC}"
                fi
            else
                echo -e "${YELLOW}[!] rcrack not installed. Cannot use rainbow tables.${NC}"
                echo -e "${YELLOW}[*] Install with: sudo apt install rainbowcrack${NC}"
            fi
        fi
        
        if [ -d "$rainbow_path/tables" ]; then
            rt_found=true
            echo -e "${YELLOW}[+] Found Ophcrack tables${NC}"
            
            if command -v ophcrack &> /dev/null; then
                echo -e "${YELLOW}[*] Running Ophcrack...${NC}"
                ophcrack -d "$rainbow_path" -t tables -h "$HASH_FILE" -o "$OUTPUT_FILE.rainbow"
                
                if [ -s "$OUTPUT_FILE.rainbow" ]; then
                    echo -e "${YELLOW}[+] Rainbow table cracking successful!${NC}"
                    cat "$OUTPUT_FILE.rainbow" >> "$OUTPUT_FILE"
                    return 0
                else
                    echo -e "${YELLOW}[*] No hashes cracked with rainbow tables${NC}"
                fi
            else
                echo -e "${YELLOW}[!] ophcrack not installed. Cannot use rainbow tables.${NC}"
                echo -e "${YELLOW}[*] Install with: sudo apt install ophcrack${NC}"
            fi
        fi
        
        if [ "$rt_found" = false ]; then
            echo -e "${YELLOW}[!] No compatible rainbow tables found in $rainbow_path${NC}"
            echo -e "${YELLOW}[*] Skipping rainbow table lookup${NC}"
            return 1
        fi
    fi
    
    return 1
}

monitor_progress() {
    local hashcat_pid="$1"
    local start_time=$(date +%s)
    local status_file="hashcat.status"
    
    echo -e "${YELLOW}[*] Starting progress monitor for process $hashcat_pid${NC}"
    
    trap "exit" INT TERM
    trap "kill 0" EXIT
    
    echo -e "${YELLOW}========== PROGRESS MONITOR ==========${NC}"
    echo -e "${YELLOW}| Time | Progress | Speed | ETA |${NC}"
    echo -e "${YELLOW}====================================${NC}"
    
    while kill -0 "$hashcat_pid" 2>/dev/null; do
        current_time=$(date +%s)
        elapsed=$((current_time - start_time))
        elapsed_formatted=$(printf "%02d:%02d:%02d" $((elapsed/3600)) $((elapsed%3600/60)) $((elapsed%60)))
        
        if [ -f hashcat.log ]; then
            progress=$(grep -a "Progress" hashcat.log 2>/dev/null | tail -n 1 | awk -F': ' '{print $2}' | tr -d ' ' | cut -d'(' -f1)
            speed=$(grep -a "Speed" hashcat.log 2>/dev/null | tail -n 1 | awk -F': ' '{print $2}' | tr -d ' ' | cut -d',' -f1)
            eta=$(grep -a "Time.Estimated" hashcat.log 2>/dev/null | tail -n 1 | awk -F': ' '{print $2}' | tr -d ' ')
            
            if [ -n "$progress" ] && [ -n "$speed" ]; then
                printf "\r${YELLOW}| %s | %s | %s | %s |${NC}" "$elapsed_formatted" "$progress" "$speed" "$eta"
            else
                printf "\r${YELLOW}| %s | Running... | - | - |${NC}" "$elapsed_formatted"
            fi
        else
            printf "\r${YELLOW}| %s | Initializing... | - | - |${NC}" "$elapsed_formatted"
        fi
        
        sleep 2
    done
    
    echo -e "\n${YELLOW}====================================${NC}"
    echo -e "${YELLOW}[+] Cracking process completed${NC}"
}

crack_hash() {
    local mode="$1"
    local hash_file="$2"
    local success=false
    
    echo -e "${YELLOW}[*] Attempting to crack hash with mode $mode${NC}"
    
    echo -e "${YELLOW}[*] Trying dictionary attack...${NC}"
    hashcat -m "$mode" -a 0 -o "$OUTPUT_FILE" "$hash_file" "$WORDLIST" --quiet --force --status --status-timer=10 --runtime="$MAX_RUNTIME" --outfile-format=3 > hashcat.log 2>&1 &
    HASHCAT_PID=$!
    
    monitor_progress "$HASHCAT_PID" &
    MONITOR_PID=$!
    
    wait "$HASHCAT_PID" || true
    kill "$MONITOR_PID" 2>/dev/null || true
    
    if [ -s "$OUTPUT_FILE" ]; then
        success=true
        return 0
    fi
    
    if [ "$success" = false ]; then
        echo -e "\n${YELLOW}[*] Trying rule-based attack...${NC}"
        hashcat -m "$mode" -a 0 -o "$OUTPUT_FILE" "$hash_file" "$WORDLIST" -r /usr/share/hashcat/rules/best64.rule --quiet --force --status --status-timer=10 --runtime="$MAX_RUNTIME" --outfile-format=3 > hashcat.log 2>&1 &
        HASHCAT_PID=$!
        
        monitor_progress "$HASHCAT_PID" &
        MONITOR_PID=$!
        
        wait "$HASHCAT_PID" || true
        kill "$MONITOR_PID" 2>/dev/null || true
        
        if [ -s "$OUTPUT_FILE" ]; then
            success=true
            return 0
        fi
    fi
    
    hash_sample=$(head -n 1 "$hash_file")
    if [ "$success" = false ] && [ ${#hash_sample} -lt 32 ]; then
        echo -e "\n${YELLOW}[*] Trying brute force for short hash...${NC}"
        hashcat -m "$mode" -a 3 -o "$OUTPUT_FILE" "$hash_file" "?a?a?a?a?a?a" --increment --quiet --force --status --status-timer=10 --runtime=300 --outfile-format=3 > hashcat.log 2>&1 &
        HASHCAT_PID=$!
        
        monitor_progress "$HASHCAT_PID" &
        MONITOR_PID=$!
        
        wait "$HASHCAT_PID" || true
        kill "$MONITOR_PID" 2>/dev/null || true
        
        if [ -s "$OUTPUT_FILE" ]; then
            success=true
            return 0
        fi
    fi
    
    return 1
}

process_hash_clusters() {
    local cluster_count="$1"
    local cracked=false
    
    echo -e "${YELLOW}[*] Processing $cluster_count hash clusters${NC}"
    
    for i in $(seq 1 "$cluster_count"); do
        local cluster_file="$CLUSTER_DIR/cluster_$i.txt"
        echo -e "\n${YELLOW}========== Processing Cluster $i ==========${NC}"
        
        local sample_hash=$(head -n 1 "$cluster_file")
        echo -e "${YELLOW}[*] Sample hash: $sample_hash${NC}"
        
        echo -e "${YELLOW}[*] Identifying hash type for cluster $i...${NC}"
        local nth_output=$(name-that-hash "$sample_hash" | grep -iE '^\s*[0-9]+\)' | awk -F')' '{print $2}' | head -n 5)
        echo -e "${YELLOW}[+] Hash identification results for cluster $i:${NC}"
        echo "$nth_output"
        
        local hash_types=$(echo "$nth_output" | sort -u)
        
        if [ -z "$hash_types" ]; then
            echo -e "${YELLOW}[!] Warning: Could not determine hash type for cluster $i. Defaulting to MD5.${NC}"
            hash_types="MD5"
        fi
        
        echo -e "${YELLOW}[*] Will try the following hash types for cluster $i: $hash_types${NC}"
        local cluster_cracked=false
        
        for hash_type in $hash_types; do
            local mode=$(get_hashcat_mode "$hash_type")
            echo -e "${YELLOW}[*] Trying hash type: $hash_type (Hashcat mode: $mode)${NC}"
            
            if crack_hash "$mode" "$cluster_file"; then
                cluster_cracked=true
                cracked=true
                break
            fi
        done
        
        if [ "$cluster_cracked" = true ]; then
            echo -e "${YELLOW}[+] Successfully cracked hashes in cluster $i!${NC}"
        else
            echo -e "${YELLOW}[!] Failed to crack hashes in cluster $i${NC}"
        fi
    done
    
    return $cracked
}

main() {
    clear
    echo -e "${YELLOW}===========================================${NC}"
    echo -e "${YELLOW}       Enhanced Hash Cracking Tool        ${NC}"
    echo -e "${YELLOW}===========================================${NC}"
    
    check_requirements
    select_wordlist
    
    echo -e "${YELLOW}[*] Enter hash(es) to crack (paste multiple hashes, then press CTRL+D):${NC}"
    cat > "$HASH_FILE"
    
    if [ ! -s "$HASH_FILE" ]; then
        echo -e "${YELLOW}[!] Error: No hash provided${NC}"
        exit 1
    fi
    
    hash_count=$(wc -l < "$HASH_FILE")
    echo -e "${YELLOW}[+] Received $hash_count hash(es)${NC}"
    
    rainbow_success=false
    check_rainbow_tables
    rainbow_success=$?
    
    if [ "$rainbow_success" = 0 ] && [ -s "$OUTPUT_FILE" ]; then
        echo -e "${YELLOW}[+] Successfully cracked some or all hashes with rainbow tables!${NC}"
    else
        echo -e "${YELLOW}[*] Proceeding with traditional cracking methods${NC}"
        
        if [ "$hash_count" -gt 1 ]; then
            handle_multiple_hashes
            
            if [ -d "$CLUSTER_DIR" ]; then
                cluster_count=$(ls "$CLUSTER_DIR" | wc -l)
                if process_hash_clusters "$cluster_count"; then
                    cracked=true
                fi
            else
                echo -e "${YELLOW}[*] Identifying hash type...${NC}"
                sample_hash=$(head -n 1 "$HASH_FILE")
                nth_output=$(name-that-hash "$sample_hash" | grep -iE '^\s*[0-9]+\)' | awk -F')' '{print $2}' | head -n 5)
                echo -e "${YELLOW}[+] Hash identification results:${NC}"
                echo "$nth_output"
                
                hash_types=$(echo "$nth_output" | sort -u)
                
                if [ -z "$hash_types" ]; then
                    echo -e "${YELLOW}[!] Warning: Could not determine hash type. Defaulting to MD5.${NC}"
                    hash_types="MD5"
                fi
                
                echo -e "${YELLOW}[*] Will try the following hash types: $hash_types${NC}"
                cracked=false
                
                for hash_type in $hash_types; do
                    mode=$(get_hashcat_mode "$hash_type")
                    echo -e "${YELLOW}[*] Trying hash type: $hash_type (Hashcat mode: $mode)${NC}"
                    if crack_hash "$mode" "$HASH_FILE"; then
                        cracked=true
                        break
                    fi
                done
            fi
        else
            echo -e "${YELLOW}[*] Processing single hash${NC}"
            echo -e "${YELLOW}[*] Identifying hash type...${NC}"
            sample_hash=$(cat "$HASH_FILE")
            nth_output=$(name-that-hash "$sample_hash" | grep -iE '^\s*[0-9]+\)' | awk -F')' '{print $2}' | head -n 5)
            echo -e "${YELLOW}[+] Hash identification results:${NC}"
            echo "$nth_output"
            
            hash_types=$(echo "$nth_output" | sort -u)
            
            if [ -z "$hash_types" ]; then
                echo -e "${YELLOW}[!] Warning: Could not determine hash type. Defaulting to MD5.${NC}"
                hash_types="MD5"
            fi
            
            echo -e "${YELLOW}[*] Will try the following hash types: $hash_types${NC}"
            cracked=false
            
            for hash_type in $hash_types; do
                mode=$(get_hashcat_mode "$hash_type")
                echo -e "${YELLOW}[*] Trying hash type: $hash_type (Hashcat mode: $mode)${NC}"
                if crack_hash "$mode" "$HASH_FILE"; then
                    cracked=true
                    break
                fi
            done
        fi
    fi
    
    if [ -s "$OUTPUT_FILE" ]; then
        echo -e "${YELLOW}[+] Hash(es) successfully cracked!${NC}"
        echo -e "${YELLOW}[+] Results:${NC}"
        cat "$OUTPUT_FILE"
    else
        echo -e "${YELLOW}[!] Failed to crack the hash(es) with available methods.${NC}"
        echo -e "${YELLOW}[*] Consider:${NC}"
        echo -e "${YELLOW}    - Using a larger wordlist${NC}"
        echo -e "${YELLOW}    - Trying more specific hash modes manually${NC}"
        echo -e "${YELLOW}    - Using more advanced attack methods${NC}"
    fi
    
    echo -e "${YELLOW}[*] Cleaning up temporary files...${NC}"
    for file in "$HASH_FILE" "$SORTED_HASH_FILE" hashcat.log; do
        if [ -f "$file" ]; then
            rm "$file"
        fi
    done
    
    if [ -d "$CLUSTER_DIR" ]; then
        rm -rf "$CLUSTER_DIR"
    fi
    
    echo -e "${YELLOW}[+] Done!${NC}"
}

main
