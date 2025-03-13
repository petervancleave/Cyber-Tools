#!/bin/bash

# Finds and extracts email addresses from a file

echo "Enter text file:"
read FILE

grep -oE '[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}' "$FILE" | sort -u > emails.txt
echo "Extracted emails saved in emails.txt."
