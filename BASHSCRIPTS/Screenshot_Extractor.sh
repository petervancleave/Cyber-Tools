#!/bin/bash
echo "Enter memory dump file:"
read dump
foremost -t jpg,png -i "$dump" -o extracted
echo "Images saved in 'extracted' folder."


# Extracts images from RAM dumps using foremost

