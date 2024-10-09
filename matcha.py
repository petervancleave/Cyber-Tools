import subprocess
import re

def get_nearby_networks():
    # Scan for nearby WiFi networks using the "netsh" command on Windows
    output = subprocess.run(["netsh", "wlan", "show", "networks", "mode=bssid"], capture_output=True).stdout.decode()

    # Pattern to extract SSID and its encryption/authentication type
    network_pattern = r"SSID \d+ : (.*)\r\n.*?Authentication\s*:\s*(.*)\r\n.*?Encryption\s*:\s*(.*)\r\n"
    networks = re.findall(network_pattern, output, re.DOTALL)

    network_info = []
    for ssid, auth, enc in networks:
        network_info.append({
            "SSID": ssid.strip(),
            "Authentication": auth.strip(),
            "Encryption": enc.strip()
        })
    
    return network_info

def check_for_vulnerabilities(network):
    # Check for common vulnerabilities in the given network
    vulnerabilities = []
    auth = network['Authentication']
    enc = network['Encryption']
    
    # Vulnerability checks:
    if "WEP" in enc:
        vulnerabilities.append("WEP encryption is used, which is easily crackable")
    
    if "WPA" in auth and "WPA2" not in auth:
        vulnerabilities.append("WPA encryption is used without WPA2, which is less secure")
    
    if "Open" in auth:
        vulnerabilities.append("No encryption is used, network is open and insecure")

    return vulnerabilities

def main():
    # Get the list of nearby WiFi networks
    networks = get_nearby_networks()
    
    # Iterate over each network and check for vulnerabilities
    for network in networks:
        print(f"Checking network: {network['SSID']}")
        vulnerabilities = check_for_vulnerabilities(network)
        
        if vulnerabilities:
            print("  Vulnerabilities found:")
            for vulnerability in vulnerabilities:
                print(f"  - {vulnerability}")
        else:
            print("  No vulnerabilities found.")
        
        print()

if __name__ == "__main__":
    main()
