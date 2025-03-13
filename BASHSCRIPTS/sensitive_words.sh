#!/bin/bash

# scan for predefined sensitive keywords (password, secret, token)
# swap keywords for whatever is wanted

echo "Enter text file:"
read FILE
grep -E -i 'password|secret|token|api_key' "$FILE" | wc -l
