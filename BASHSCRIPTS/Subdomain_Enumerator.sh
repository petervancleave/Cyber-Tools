#!/bin/bash

# Usage:
# make the script executable (chmod +x)
# run script (./)
# Enter the target domain when prompted
# Choose port scanning


# perform Amass enumeration
amass_enum() {
  local domain="$1"
  echo "Performing Amass enumeration for $domain..."
  amass enum -d "$domain" -o "$domain"_amass.txt 2>/dev/null  # Redirect stderr to /dev/null to suppress errors
  echo "Amass enumeration completed. Results saved to $domain_amass.txt"
}

# query crt.sh
crtsh_query() {
  local domain="$1"
  echo "Querying crt.sh for $domain..."
  curl -s "https://crt.sh/?q=%.${domain}&output=json" | jq -r '.[].name_value' | sort -u > "$domain"_crtsh.txt
  echo "crt.sh query completed. Results saved to $domain_crtsh.txt"
}

# Combine and deduplicate results
combine_results() {
  local domain="$1"
  echo "Combining and deduplicating results..."
  cat "$domain"_amass.txt "$domain"_crtsh.txt | sort -u > "$domain"_combined.txt
  echo "Combined results saved to $domain_combined.txt"
}

# filter wildcard subdomains
filter_wildcards() {
    local domain="$1"
    local combined_file="$domain"_combined.txt
    local filtered_file="$domain"_filtered.txt

    echo "Filtering wildcard subdomains..."

    while IFS= read -r line; do
        if [[ "$line" == *"$domain" ]]; then
            echo "$line" >> "$filtered_file"
        fi
    done < "$combined_file"

    sort -u "$filtered_file" -o "$filtered_file"

    echo "Filtered results saved to $filtered_file"
}

# resolve subdomains to IP addresses
resolve_subdomains() {
  local domain="$1"
  local filtered_file="$domain"_filtered.txt
  local resolved_file="$domain"_resolved.txt

  echo "Resolving subdomains to IP addresses..."

  while IFS= read -r subdomain; do
    if host "$subdomain" &>/dev/null; then # check if host command succeeds
        host "$subdomain" | awk '/has address/ {print $4}' | sort -u | while read -r ip; do
            echo "$subdomain,$ip" >> "$resolved_file"
        done
    else
        echo "$subdomain,NO_IP" >> "$resolved_file"
    fi
  done < "$filtered_file"

  echo "Resolved subdomains saved to $resolved_file"
}

# perform optional port scanning (using nmap)
port_scan() {
  local domain="$1"
  local resolved_file="$domain"_resolved.txt
  local nmap_results_file="$domain"_nmap_results.txt
  local ip

  echo "Performing port scanning (nmap) on resolved IPs..."

  while IFS=',' read -r subdomain ip; do
    if [[ "$ip" != "NO_IP" ]]; then
      echo "Scanning $subdomain ($ip)..."
      nmap -sV -sC -oN "$nmap_results_file" "$ip" 2>/dev/null #basic nmap scan. redirect stderr
    else
      echo "Skipping $subdomain (no IP resolved)."
    fi
  done < "$resolved_file"

  echo "Nmap results saved to $nmap_results_file"
}

# Main script
echo "Enter domain:"
read domain

amass_enum "$domain"
crtsh_query "$domain"
combine_results "$domain"
filter_wildcards "$domain"
resolve_subdomains "$domain"

read -p "Perform port scanning (nmap)? (y/n): " do_nmap

if [[ "$do_nmap" == "y" ]]; then
  port_scan "$domain"
fi

echo "Subdomain enumeration completed."