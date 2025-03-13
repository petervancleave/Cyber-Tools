#!/bin/bash

#===============================================================
# CTF Recon Automation Script
# A comprehensive reconnaissance tool for CTF challenges
# Features:
# - Customizable scan profiles (quick, normal, full)
# - Multi-threaded scanning
# - Service fingerprinting and discovery
# - Web enumeration and vulnerability scanning
# - Multiple output formats
# - Progress tracking and reporting
#===============================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m' 

# defaults
TARGET=""
OUTPUT_DIR="ctf_recon_$(date +%Y%m%d_%H%M%S)"
SCAN_TYPE="normal"
WEB_SCAN=true
CHECK_DEPS=true
THREADS=10
TIMEOUT=300
PORTS="1-65535"
WEB_WORDLIST="/usr/share/wordlists/dirb/common.txt"
SKIP_QUESTIONS=false
USE_RANDOM_AGENT=true
SCREENSHOT=false
VULN_SCAN=true
DNS_DISCOVERY=true
OS_DETECTION=true
START_TIME=$(date +%s)

# Banner 
show_banner() {
    clear
    cat << "EOF"
 ██████╗████████╗███████╗    ██████╗ ███████╗ ██████╗ ██████╗ ███╗   ██╗
██╔════╝╚══██╔══╝██╔════╝    ██╔══██╗██╔════╝██╔════╝██╔═══██╗████╗  ██║
██║        ██║   █████╗      ██████╔╝█████╗  ██║     ██║   ██║██╔██╗ ██║
██║        ██║   ██╔══╝      ██╔══██╗██╔══╝  ██║     ██║   ██║██║╚██╗██║
╚██████╗   ██║   ██║         ██║  ██║███████╗╚██████╗╚██████╔╝██║ ╚████║
 ╚═════╝   ╚═╝   ╚═╝         ╚═╝  ╚═╝╚══════╝ ╚═════╝ ╚═════╝ ╚═╝  ╚═══╝
EOF
    echo -e "${GREEN}=======================================================${NC}"
    echo -e "${YELLOW}         -------- CTF Reconnaissance Toolkit          ${NC}"
    echo -e "${GREEN}=======================================================${NC}"
    echo
}

# Help 
show_help() {
    echo -e "${GREEN}Usage:${NC}"
    echo -e "  ./$(basename "$0") [options]"
    echo
    echo -e "${GREEN}Options:${NC}"
    echo -e "  -h, --help               Show this help message"
    echo -e "  -t, --target IP/HOSTNAME Target IP address or hostname"
    echo -e "  -o, --output DIR         Output directory (default: auto-generated)"
    echo -e "  -s, --scan-type TYPE     Scan type: quick, normal, full (default: normal)"
    echo -e "  -p, --ports RANGE        Port range to scan (default: 1-65535)"
    echo -e "  -w, --web-wordlist FILE  Wordlist for web discovery (default: dirb/common.txt)"
    echo -e "  -T, --threads NUM        Number of threads (default: 10)"
    echo -e "  --no-web                 Skip web scanning"
    echo -e "  --no-dns                 Skip DNS enumeration"
    echo -e "  --no-vuln                Skip vulnerability scanning"
    echo -e "  --no-os                  Skip OS detection"
    echo -e "  --screenshot             Take screenshots of web services"
    echo -e "  --skip-deps              Skip dependency checking"
    echo -e "  --yes                    Answer yes to all questions (non-interactive mode)"
    echo
    echo -e "${GREEN}Examples:${NC}"
    echo -e "  ./$(basename "$0") -t 10.10.10.10"
    echo -e "  ./$(basename "$0") -t target.ctf.com -s quick -o target_recon"
    echo -e "  ./$(basename "$0") -t 10.10.10.10 -s full -p 1-10000 --screenshot"
}

# Check if dependencies are installed
check_dependencies() {
    if [ "$CHECK_DEPS" = false ]; then
        return 0
    fi

    local missing_tools=0
    local required_tools=("nmap" "gobuster" "nikto" "searchsploit" "ffuf" "curl" "whatweb" "dig" "whois" "smbclient" "enum4linux" "wpscan")
    
    echo -e "${BLUE}[*] Checking required tools...${NC}"
    
    for tool in "${required_tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            echo -e "${YELLOW}[!] $tool is not installed${NC}"
            missing_tools=$((missing_tools+1))
        fi
    done
    
    # Optional tools
    for tool in "wafw00f" "nuclei" "eyewitness"; do
        if ! command -v "$tool" &> /dev/null; then
            echo -e "${YELLOW}[!] Optional tool $tool is not installed${NC}"
        fi
    done
    
    if [ $missing_tools -gt 0 ]; then
        echo -e "${RED}[!] $missing_tools required tools are missing. Install them with:${NC}"
        echo -e "${YELLOW}    sudo apt update && sudo apt install -y nmap gobuster nikto curl whatweb dnsutils whois smbclient enum4linux${NC}"
        
        if [ "$SKIP_QUESTIONS" = false ]; then
            echo -e "${BLUE}[?] Continue anyway? (y/n)${NC}"
            read -r choice
            if [[ ! "$choice" =~ ^[Yy]$ ]]; then
                exit 1
            fi
        fi
    else
        echo -e "${GREEN}[+] All required tools are installed!${NC}"
    fi
}

# Create output directory structure
create_dir_structure() {
    local dirs=("$OUTPUT_DIR" "$OUTPUT_DIR/nmap" "$OUTPUT_DIR/web" "$OUTPUT_DIR/web/screenshots" "$OUTPUT_DIR/exploits" "$OUTPUT_DIR/services" "$OUTPUT_DIR/enum" "$OUTPUT_DIR/vulnerabilities")
    
    echo -e "${BLUE}[*] Creating directory structure...${NC}"
    for dir in "${dirs[@]}"; do
        mkdir -p "$dir"
    done
    echo -e "${GREEN}[+] Created output directory structure${NC}"
}

# Function to save scan info and metadata
save_scan_info() {
    {
        echo "# Recon Scan Info"
        echo "Target: $TARGET"
        echo "Scan Type: $SCAN_TYPE"
        echo "Start Time: $(date -d @$START_TIME)"
        echo "End Time: $(date)"
        echo "Duration: $(($(date +%s) - START_TIME)) seconds"
        echo
        echo "## Scan Options"
        echo "Web Scan: $WEB_SCAN"
        echo "Vulnerability Scan: $VULN_SCAN"
        echo "DNS Discovery: $DNS_DISCOVERY"
        echo "Port Range: $PORTS"
        echo "Threads: $THREADS"
        echo
        echo "## System Info"
        echo "Scanner: $(hostname)"
        echo "OS: $(uname -a)"
    } > "$OUTPUT_DIR/scan_info.md"
    echo -e "${GREEN}[+] Saved scan information${NC}"
}

# Network scanning with nmap
run_nmap_scan() {
    echo -e "${BLUE}[*] Starting network reconnaissance with nmap...${NC}"
    
    # Initial ping scan
    echo -e "${YELLOW}[*] Running ping scan...${NC}"
    nmap -sn -T4 "$TARGET" -oN "$OUTPUT_DIR/nmap/ping_scan.txt"
    
    # Different scan types based on scan profile
    case "$SCAN_TYPE" in
        quick)
            echo -e "${YELLOW}[*] Running quick port scan (top 1000 ports)...${NC}"
            nmap -sV -sC --min-rate=1000 -T4 -oA "$OUTPUT_DIR/nmap/quick_scan" "$TARGET"
            ;;
            
        normal)
            echo -e "${YELLOW}[*] Running standard port scan...${NC}"
            nmap -sV -sC -p- --min-rate=1000 -T4 -oA "$OUTPUT_DIR/nmap/standard_scan" "$TARGET"
            
            if [ "$OS_DETECTION" = true ]; then
                echo -e "${YELLOW}[*] Running OS detection scan...${NC}"
                nmap -O --osscan-guess -T4 -oA "$OUTPUT_DIR/nmap/os_detection" "$TARGET"
            fi
            ;;
            
        full)
            echo -e "${YELLOW}[*] Running comprehensive port scan...${NC}"
            nmap -sV -sC -p- -A --min-rate=1000 -T4 -oA "$OUTPUT_DIR/nmap/full_scan" "$TARGET"
            
            echo -e "${YELLOW}[*] Running UDP scan on common ports...${NC}"
            nmap -sU -sV --version-intensity 0 -F -T4 -oA "$OUTPUT_DIR/nmap/udp_scan" "$TARGET"
            
            echo -e "${YELLOW}[*] Running vulnerability scan...${NC}"
            nmap --script "vuln and safe" -p- -T4 -oA "$OUTPUT_DIR/nmap/vuln_scan" "$TARGET"
            ;;
    esac
    
    # Extract open ports for further analysis
    grep "open" "$OUTPUT_DIR/nmap/standard_scan.nmap" 2>/dev/null || grep "open" "$OUTPUT_DIR/nmap/quick_scan.nmap" 2>/dev/null || grep "open" "$OUTPUT_DIR/nmap/full_scan.nmap" 2>/dev/null > "$OUTPUT_DIR/open_ports.txt"
    
    echo -e "${GREEN}[+] Nmap scans completed${NC}"
}

# Extract and analyze discovered services
analyze_services() {
    echo -e "${BLUE}[*] Analyzing discovered services...${NC}"
    
    # Check for web services
    if grep -q "80/tcp\|443/tcp\|8080/tcp\|8000/tcp\|8443/tcp" "$OUTPUT_DIR/open_ports.txt" 2>/dev/null; then
        echo -e "${GREEN}[+] Web services detected!${NC}"
        echo "web" >> "$OUTPUT_DIR/services/detected_services.txt"
    fi
    
    # Check for SSH
    if grep -q "22/tcp" "$OUTPUT_DIR/open_ports.txt" 2>/dev/null; then
        echo -e "${GREEN}[+] SSH service detected!${NC}"
        echo "ssh" >> "$OUTPUT_DIR/services/detected_services.txt"
        # Banner grabbing for SSH
        nc -w 3 "$TARGET" 22 2>&1 | tee "$OUTPUT_DIR/services/ssh_banner.txt"
    fi
    
    # Check for FTP
    if grep -q "21/tcp" "$OUTPUT_DIR/open_ports.txt" 2>/dev/null; then
        echo -e "${GREEN}[+] FTP service detected!${NC}"
        echo "ftp" >> "$OUTPUT_DIR/services/detected_services.txt"
        # Try anonymous login
        echo -e "${YELLOW}[*] Trying anonymous FTP login...${NC}"
        timeout 10 ftp -n "$TARGET" <<EOF 2>&1 | tee "$OUTPUT_DIR/services/ftp_anon.txt"
user anonymous anonymous
pwd
ls -la
quit
EOF
    fi
    
    # Check for SMB
    if grep -q "139/tcp\|445/tcp" "$OUTPUT_DIR/open_ports.txt" 2>/dev/null; then
        echo -e "${GREEN}[+] SMB service detected!${NC}"
        echo "smb" >> "$OUTPUT_DIR/services/detected_services.txt"
        # Run enum4linux
        echo -e "${YELLOW}[*] Running enum4linux...${NC}"
        enum4linux -a "$TARGET" | tee "$OUTPUT_DIR/services/enum4linux.txt"
        # List shares
        echo -e "${YELLOW}[*] Listing SMB shares...${NC}"
        smbclient -L "//$TARGET/" -N | tee "$OUTPUT_DIR/services/smb_shares.txt"
    fi
    
    # Check for SNMP
    if grep -q "161/udp" "$OUTPUT_DIR/open_ports.txt" 2>/dev/null; then
        echo -e "${GREEN}[+] SNMP service detected!${NC}"
        echo "snmp" >> "$OUTPUT_DIR/services/detected_services.txt"
        # Try common community strings
        echo -e "${YELLOW}[*] Trying common SNMP community strings...${NC}"
        onesixtyone -c /usr/share/doc/onesixtyone/dict.txt "$TARGET" | tee "$OUTPUT_DIR/services/snmp_strings.txt"
    fi
    
    # Check for databases
    if grep -q "3306/tcp" "$OUTPUT_DIR/open_ports.txt" 2>/dev/null; then
        echo -e "${GREEN}[+] MySQL service detected!${NC}"
        echo "mysql" >> "$OUTPUT_DIR/services/detected_services.txt"
    fi
    
    if grep -q "5432/tcp" "$OUTPUT_DIR/open_ports.txt" 2>/dev/null; then
        echo -e "${GREEN}[+] PostgreSQL service detected!${NC}"
        echo "postgresql" >> "$OUTPUT_DIR/services/detected_services.txt"
    fi
    
    if grep -q "1521/tcp" "$OUTPUT_DIR/open_ports.txt" 2>/dev/null; then
        echo -e "${GREEN}[+] Oracle service detected!${NC}"
        echo "oracle" >> "$OUTPUT_DIR/services/detected_services.txt"
    fi
    
    if grep -q "1433/tcp" "$OUTPUT_DIR/open_ports.txt" 2>/dev/null; then
        echo -e "${GREEN}[+] MSSQL service detected!${NC}"
        echo "mssql" >> "$OUTPUT_DIR/services/detected_services.txt"
    fi
    
    if grep -q "6379/tcp" "$OUTPUT_DIR/open_ports.txt" 2>/dev/null; then
        echo -e "${GREEN}[+] Redis service detected!${NC}"
        echo "redis" >> "$OUTPUT_DIR/services/detected_services.txt"
    fi
    
    if grep -q "27017/tcp\|27018/tcp" "$OUTPUT_DIR/open_ports.txt" 2>/dev/null; then
        echo -e "${GREEN}[+] MongoDB service detected!${NC}"
        echo "mongodb" >> "$OUTPUT_DIR/services/detected_services.txt"
    fi
    
    echo -e "${GREEN}[+] Service analysis completed${NC}"
}

# DNS enumeration and domain information
run_dns_enum() {
    if [ "$DNS_DISCOVERY" = false ]; then
        return 0
    fi
    
    echo -e "${BLUE}[*] Starting DNS enumeration...${NC}"
    
    # Try to determine if target is an IP or hostname
    if [[ "$TARGET" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        # It's an IP, try to get PTR record
        dig -x "$TARGET" +short | tee "$OUTPUT_DIR/enum/dns_ptr.txt"
    else
        # It's a hostname, do full DNS enumeration
        echo -e "${YELLOW}[*] Running DNS lookup on $TARGET...${NC}"
        dig "$TARGET" ANY +short | tee "$OUTPUT_DIR/enum/dns_records.txt"
        
        # Try zone transfer
        echo -e "${YELLOW}[*] Attempting zone transfer...${NC}"
        dig "$TARGET" AXFR | tee "$OUTPUT_DIR/enum/dns_zonetransfer.txt"
        
        # Get WHOIS information
        echo -e "${YELLOW}[*] Getting WHOIS information...${NC}"
        whois "$TARGET" | tee "$OUTPUT_DIR/enum/whois.txt"
        
        # Try subdomain enumeration with common subdomains
        echo -e "${YELLOW}[*] Attempting subdomain discovery...${NC}"
        for sub in www dev admin mail ftp test stage api app portal vpn remote ssh webmail; do
            host "$sub.$TARGET" | grep -v "not found" >> "$OUTPUT_DIR/enum/subdomains.txt"
        done
    fi
    
    echo -e "${GREEN}[+] DNS enumeration completed${NC}"
}

# Web service scanning and enumeration
run_web_scanning() {
    if [ "$WEB_SCAN" = false ]; then
        return 0
    fi
    
    echo -e "${BLUE}[*] Starting web service reconnaissance...${NC}"
    
    # Discover web servers on various ports
    local web_ports=(80 443 8000 8080 8443 8888)
    local discovered_webs=()
    
    for port in "${web_ports[@]}"; do
        if nc -z -w 2 "$TARGET" "$port" 2>/dev/null; then
            if [ "$port" -eq 443 ] || [ "$port" -eq 8443 ]; then
                discovered_webs+=("https://$TARGET:$port")
            else
                discovered_webs+=("http://$TARGET:$port")
            fi
        fi
    done
    
    # If no web servers found in common ports, skip web scanning
    if [ ${#discovered_webs[@]} -eq 0 ]; then
        echo -e "${YELLOW}[!] No web servers discovered on common ports${NC}"
        return 0
    fi
    
    echo -e "${GREEN}[+] Discovered ${#discovered_webs[@]} web services${NC}"
    
    # Process each discovered web service
    for web_url in "${discovered_webs[@]}"; do
        echo -e "${YELLOW}[*] Processing $web_url...${NC}"
        
        # Get server information
        echo -e "${YELLOW}[*] Getting server information...${NC}"
        curl -s -I "$web_url" | tee "$OUTPUT_DIR/web/$(echo "$web_url" | sed 's/[:/]/_/g')_headers.txt"
        
        # Run whatweb for technology detection
        echo -e "${YELLOW}[*] Detecting web technologies...${NC}"
        whatweb -a 3 "$web_url" | tee "$OUTPUT_DIR/web/$(echo "$web_url" | sed 's/[:/]/_/g')_whatweb.txt"
        
        # Run WAF detection
        if command -v wafw00f &> /dev/null; then
            echo -e "${YELLOW}[*] Detecting WAF...${NC}"
            wafw00f "$web_url" | tee "$OUTPUT_DIR/web/$(echo "$web_url" | sed 's/[:/]/_/g')_waf.txt"
        fi
        
        # Directory discovery with gobuster
        echo -e "${YELLOW}[*] Running directory enumeration...${NC}"
        gobuster dir -u "$web_url" -w "$WEB_WORDLIST" -t "$THREADS" -o "$OUTPUT_DIR/web/$(echo "$web_url" | sed 's/[:/]/_/g')_gobuster.txt" 2>/dev/null
        
        # Nikto scan
        echo -e "${YELLOW}[*] Running Nikto scan...${NC}"
        nikto -h "$web_url" -output "$OUTPUT_DIR/web/$(echo "$web_url" | sed 's/[:/]/_/g')_nikto.txt"
        
        # Check for WordPress
        if curl -s "$web_url" | grep -qi "wordpress"; then
            echo -e "${GREEN}[+] WordPress detected!${NC}"
            
            # Run WPScan if available
            if command -v wpscan &> /dev/null; then
                echo -e "${YELLOW}[*] Running WordPress scan...${NC}"
                wpscan --url "$web_url" --no-banner --random-agent | tee "$OUTPUT_DIR/web/$(echo "$web_url" | sed 's/[:/]/_/g')_wpscan.txt"
            fi
        fi
        
        # Check for robots.txt
        echo -e "${YELLOW}[*] Checking robots.txt...${NC}"
        curl -s "$web_url/robots.txt" | tee "$OUTPUT_DIR/web/$(echo "$web_url" | sed 's/[:/]/_/g')_robots.txt"
        
        # Check for sitemap.xml
        echo -e "${YELLOW}[*] Checking sitemap.xml...${NC}"
        curl -s "$web_url/sitemap.xml" | tee "$OUTPUT_DIR/web/$(echo "$web_url" | sed 's/[:/]/_/g')_sitemap.txt"
        
        # FFUF for virtual host discovery (for full scan type)
        if [ "$SCAN_TYPE" = "full" ]; then
            echo -e "${YELLOW}[*] Running virtual host discovery...${NC}"
            ffuf -u "$web_url" -H "Host: FUZZ.$TARGET" -w /usr/share/wordlists/dirb/common.txt -o "$OUTPUT_DIR/web/$(echo "$web_url" | sed 's/[:/]/_/g')_vhost.json" -of json 2>/dev/null
        fi
        
        # Take screenshots if enabled
        if [ "$SCREENSHOT" = true ] && command -v eyewitness &> /dev/null; then
            echo -e "${YELLOW}[*] Taking screenshots...${NC}"
            eyewitness --web --single "$web_url" -d "$OUTPUT_DIR/web/screenshots"
        fi
    done
    
    echo -e "${GREEN}[+] Web scanning completed${NC}"
}

# Vulnerability scanning
run_vuln_scanning() {
    if [ "$VULN_SCAN" = false ]; then
        return 0
    fi
    
    echo -e "${BLUE}[*] Starting vulnerability scanning...${NC}"
    
    # Searchsploit for potential exploits based on services
    if command -v searchsploit &> /dev/null; then
        echo -e "${YELLOW}[*] Searching for potential exploits...${NC}"
        # Extract service versions from nmap scan
        grep -E "Service Info:|Product:|Version:" "$OUTPUT_DIR/nmap/"*".nmap" 2>/dev/null | sed 's/|//' | sort -u > "$OUTPUT_DIR/service_versions.txt"
        
        # Run searchsploit on each service version
        while IFS= read -r service; do
            # Extract the service name and version
            service_cleaned=$(echo "$service" | sed -e 's/Service Info: //g' -e 's/Product: //g' -e 's/Version: //g' | tr -d '\r')
            echo -e "${YELLOW}[*] Searching exploits for: $service_cleaned${NC}"
            searchsploit "$service_cleaned" | tee -a "$OUTPUT_DIR/exploits/searchsploit_results.txt"
        done < "$OUTPUT_DIR/service_versions.txt"
    fi
    
    # Nuclei scanning for web vulnerabilities
    if command -v nuclei &> /dev/null && [ "$WEB_SCAN" = true ]; then
        echo -e "${YELLOW}[*] Running Nuclei vulnerability scanner...${NC}"
        for web_url in $(find "$OUTPUT_DIR/web" -name "*_headers.txt" | sed 's/_headers.txt$//' | sed 's/.*\///'); do
            actual_url=$(echo "$web_url" | sed 's/_/:/1' | sed 's/_/\//g')
            echo -e "${YELLOW}[*] Scanning $actual_url with Nuclei...${NC}"
            nuclei -u "$actual_url" -t cves/ -o "$OUTPUT_DIR/vulnerabilities/nuclei_$web_url.txt"
        done
    fi
    
    echo -e "${GREEN}[+] Vulnerability scanning completed${NC}"
}

# Generate summary report
generate_report() {
    echo -e "${BLUE}[*] Generating summary report...${NC}"
    
    {
        echo "# CTF Recon Summary Report"
        echo
        echo "## Target Information"
        echo "* Target: $TARGET"
        echo "* Scan Type: $SCAN_TYPE"
        echo "* Scan Date: $(date)"
        echo "* Scan Duration: $(($(date +%s) - START_TIME)) seconds"
        echo
        
        echo "## Open Ports and Services"
        if [ -f "$OUTPUT_DIR/open_ports.txt" ]; then
            echo '```'
            cat "$OUTPUT_DIR/open_ports.txt"
            echo '```'
        else
            echo "No open ports found."
        fi
        echo
        
        echo "## Detected Services"
        if [ -f "$OUTPUT_DIR/services/detected_services.txt" ]; then
            while IFS= read -r service; do
                echo "* $service"
            done < "$OUTPUT_DIR/services/detected_services.txt"
        else
            echo "No specific services detected."
        fi
        echo
        
        echo "## Web Findings"
        if [ "$WEB_SCAN" = true ] && [ "$(find "$OUTPUT_DIR/web" -type f | wc -l)" -gt 0 ]; then
            echo "### Web Technologies"
            grep -h "Summary" "$OUTPUT_DIR/web/"*"_whatweb.txt" 2>/dev/null
            
            echo "### Interesting Directories"
            if find "$OUTPUT_DIR/web/" -name "*_gobuster.txt" | grep -q .; then
                for gobuster_file in "$OUTPUT_DIR/web/"*"_gobuster.txt"; do
                    echo "#### $(basename "$gobuster_file" | sed 's/_gobuster.txt//')"
                    echo '```'
                    head -n 20 "$gobuster_file" 2>/dev/null
                    echo '```'
                done
            else
                echo "No directories discovered."
            fi
            
            echo "### Potential Vulnerabilities"
            if [ -f "$OUTPUT_DIR/web/"*"_nikto.txt" ]; then
                grep -h "OSVDB-" "$OUTPUT_DIR/web/"*"_nikto.txt" 2>/dev/null | head -n 15
            else
                echo "No vulnerabilities reported by Nikto."
            fi
        else
            echo "Web scanning was not performed or no web services were detected."
        fi
        echo
        
        echo "## Potential Exploits"
        if [ -f "$OUTPUT_DIR/exploits/searchsploit_results.txt" ]