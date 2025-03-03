from scapy.all import rdpcap, wrpcap
import sys

"""
Convert PCAPNG file to PCAP file
--------------------------------

Usage: python pcapng2pcap.py input.pcapng output.pcap

"""


def convert_pcapng_to_pcap(input_file, output_file):
    try:
        packets = rdpcap(input_file)  
        wrpcap(output_file, packets)  
        print(f"Conversion successful: {input_file} -> {output_file}")
    except Exception as e:
        print(f"Error converting file: {e}")

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python convert_pcapng_to_pcap.py <input.pcapng> <output.pcap>")
    else:
        convert_pcapng_to_pcap(sys.argv[1], sys.argv[2])
