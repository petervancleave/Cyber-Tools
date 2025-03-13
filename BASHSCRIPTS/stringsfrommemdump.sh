#!/bin/bash

# Finds readable strings inside a memory dump

echo "Enter memory dump file:"
read DUMP

strings "$DUMP" | less
