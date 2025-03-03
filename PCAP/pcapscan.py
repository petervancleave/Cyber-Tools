import pyshark
from scapy.all import rdpcap, Raw
import base64
import binascii
import re
import sys
import os

"""
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

Script to analyze a pcap file for hidden data, searches for:
-Embedded files by extracting payloads
-Steganography in TCP/UDP streams
-Base64 encoded data
-Hex/ASCII anomalies
-Unusual protocols

++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

Extracts raw payloads from packets
Detects base64 encoded hidden data
Detects hex encoded ASCII data
Identifies unusual protocols

++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

Usage:
python pcapscan.py example.pcap

++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
"""

# File signatures for carving
FILE_SIGNATURES = {
    b"\x89PNG": "png",
    b"\xFF\xD8\xFF": "jpg",
    b"PK\x03\x04": "zip",
    b"%PDF": "pdf",
    b"GIF87a": "gif",
    b"GIF89a": "gif",
    b"\x42\x4D": "bmp",
    b"\x7F\x45\x4C\x46": "elf",
    b"MZ": "exe"
}



def extract_payloads(pcap_file):
    # Extract raw payload data from all packets
    packets = rdpcap(pcap_file)
    payloads = []
    for pkt in packets:
        if pkt.haslayer(Raw):
            data = pkt[Raw].load
            payloads.append(data)
    return payloads

def detect_base64(payloads):
    # Detect base64 encoded hidden data
    base64_pattern = re.compile(rb'([A-Za-z0-9+/]{20,}={0,2})')  # Look for long base64 strings
    for i, payload in enumerate(payloads):
        matches = base64_pattern.findall(payload)
        for match in matches:
            try:
                decoded = base64.b64decode(match).decode(errors='ignore')
                print(f"[!] Possible base64-encoded data in packet {i}: {decoded[:100]}...")
            except binascii.Error:
                pass

def detect_hex_ascii(payloads):
    # Detect sequences of hex-encoded ASCII data
    hex_pattern = re.compile(rb'([0-9A-Fa-f]{20,})')  # Look for long hex strings
    for i, payload in enumerate(payloads):
        matches = hex_pattern.findall(payload)
        for match in matches:
            try:
                decoded = bytes.fromhex(match.decode()).decode(errors='ignore')
                print(f"[!] Possible hex-encoded ASCII data in packet {i}: {decoded[:100]}...")
            except ValueError:
                pass

def detect_unusual_protocols(pcap_file):
    # Check for unusual protocols
    cap = pyshark.FileCapture(pcap_file)
    unusual_protocols = set()
    for pkt in cap:
        if hasattr(pkt, 'highest_layer'):
            layer = pkt.highest_layer
            if layer not in {"TCP", "UDP", "HTTP", "DNS", "ICMP", "TLS", "ARP"}:
                unusual_protocols.add(layer)
    cap.close()
    if unusual_protocols:
        print(f"[!] Unusual protocols detected: {', '.join(unusual_protocols)}")



def extract_embedded_files(payloads):
    # Extract and save embedded files based on file signatures
    output_dir = "extracted_files"
    os.makedirs(output_dir, exist_ok=True)

    for i, payload in enumerate(payloads):
        for magic, ext in FILE_SIGNATURES.items():
            if magic in payload:
                filename = f"{output_dir}/extracted_{i}.{ext}"
                with open(filename, "wb") as f:
                    f.write(payload)
                print(f"[+] Extracted possible {ext} file: {filename}")

def detect_steganography(payloads):
    # Detect potential steganographic data in TCP/UDP streams
    for i, payload in enumerate(payloads):
        entropy = len(set(payload)) / len(payload) if len(payload) > 0 else 0  # Measure randomness
        if entropy > 0.9:  # High entropy suggests encrypted or hidden data
            print(f"[!] High entropy (possible steganography) in packet {i}.")

        if b"\x00" * 10 in payload:  # Look for large zero-padding 
            print(f"[!] Large zero-padding detected in packet {i} (possible hidden data).")



def analyze_pcap(pcap_file):
    print(f"[*] Analyzing {pcap_file} for hidden data...\n")
    payloads = extract_payloads(pcap_file)

    detect_base64(payloads)
    detect_hex_ascii(payloads)
    detect_unusual_protocols(pcap_file)
    extract_embedded_files(payloads)
    detect_steganography(payloads)

    print("\n[+] Analysis complete")

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print(f"Usage: {sys.argv[0]} <pcap_file>")
        sys.exit(1)

    pcap_file = sys.argv[1]
    analyze_pcap(pcap_file)
