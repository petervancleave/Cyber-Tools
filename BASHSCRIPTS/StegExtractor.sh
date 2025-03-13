#!/bin/bash

# extract hidden messages from images using steghide and binwalk
# ensure requirements are installed

echo "Enter Image File"
# enter the name of the image file 

read img

# attempt to extract hidden data with steghide
steghide extract -sf "$img"
# note: this will prompt for a password if the file is password protected

# use binwalk to identify and extract embedded files and data
binwalk -e "$img"

