#!/bin/bash

# Check if Scapy is installed
if ! python3 -c "import scapy.all" &> /dev/null; then
    echo "[!] Scapy is not installed. Installing now..."
    pip install scapy
fi

# Create the Python script for packet generation
cat << 'EOF' > generate_pcap.py
from scapy.all import *
import base64

def generate_pcap(filename):
    print("[*] Generating test PCAP...")

    # Normal TCP and UDP packets
    packets = [
        IP(dst="8.8.8.8") / TCP(dport=80) / Raw(load="Normal HTTP request"),
        IP(dst="192.168.1.1") / UDP(dport=53) / Raw(load="Regular DNS Query"),
    ]

    # Anomalous Data (Base64, Hex, Unusual Protocols)
    base64_payload = base64.b64encode(b"This is a hidden message").decode()
    hex_payload = bytes.fromhex("48656c6c6f2c2053656372657420576f726c6421")  # "Hello, Secret World!"
    
    anomaly_packets = [
        IP(dst="10.0.0.1") / TCP(dport=443) / Raw(load=base64_payload),  # Base64 Anomaly
        IP(dst="10.0.0.2") / UDP(dport=53) / Raw(load=hex_payload),      # Hex Anomaly
        IP(dst="10.0.0.3") / ICMP() / Raw(load="Suspicious ICMP traffic")  # Unusual Protocol
    ]

    # Save packets to PCAP
    all_packets = packets + anomaly_packets
    wrpcap(filename, all_packets)

    print(f"[✔] PCAP file '{filename}' created with sample packets and anomalies.")

# Generate the PCAP
pcap_filename = "test_anomalies.pcap"
generate_pcap(pcap_filename)
EOF

# Run the Python script
echo "[*] Running PCAP generator..."
python3 generate_pcap.py

# Clean up the Python script (optional)
rm generate_pcap.py

echo "[✔] PCAP generation complete. Check 'test_anomalies.pcap'."

