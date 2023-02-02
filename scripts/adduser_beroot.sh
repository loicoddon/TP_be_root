#!/bin/bash
#Add default user
sudo useradd -s /bin/bash beroot
sudo echo "beroot:password" | sudo chpasswd