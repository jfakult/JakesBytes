#!/bin/bash


# Print help menu if -h --help or no arguments are given
if [ "$1" == "-h" ] || [ "$1" == "--help" ] || [ -z "$1" ]; then
    echo "Usage: udp_upload.sh <file> [rate]"
    echo "Upload a file using UFTP"
    echo "  <file>  The file to upload"
    echo "  [rate]  The rate to upload at (kbps, default 11000)"
    exit 0
fi

# if $2, set rate, else set to 11000
rate=${2:-11000}

echo "---------------------------------------------------------------------"
echo
uftp -M fakult.net -p 443 -R $rate -Y none -x 2 -s 10 "$1" 2>&1 | grep -P "Transfer|Bytes|sending as|Sending section|NAKs|Total|throughput"
echo
echo "---------------------------------------------------------------------"