#!/bin/bash


# Lists all functions in an ELF binary
# useful for analyzing targets in binary exploitation


echo "Enter binary file:"
read FILE

objdump -t "$FILE" | grep " .text" | awk '{print $NF}'
