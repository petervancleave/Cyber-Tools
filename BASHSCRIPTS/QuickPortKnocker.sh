#!/bin/bash

# Port knocking script to access a protected service
# Port knocking is a security technique where a sequence of connection attempts 
# to specific closed ports triggers the firewall to open access to a service


TARGET="ENTER TARGET IP" # Target IP to perform port knocking on
PORTS=(ENTER TARGET PORTS) # Sequence of ports to knock in order
# note: perhaps avoid common ports (1-1023) that might be actively used by common services. These could interfere with normal operation or be filtered by firewalls
# note: choose non-standard ports that aren't likely to receive random connection attempts from other services
# note: sequence matters

# Loop through each port in the sequence
for port in "${PORTS[@]}"; do
    nc -z -w1 $TARGET $port # use netcat to attempt a connection to each port
    # -z : zero-I/O mode (just scan for listening daemons)
    # -w1 sets the timeout to 1 second
done

echo "Knocking Completed"
