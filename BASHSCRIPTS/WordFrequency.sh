#!/bin/bash

echo "Enter text file:"
read FILE

cat "$FILE" | tr -s ' ' '\n' | sort | uniq -c | sort -nr | head -20

# Counts the most common words in a text file