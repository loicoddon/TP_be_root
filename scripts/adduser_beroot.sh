#!/bin/bash
#Add default user
sudo useradd -s /bin/bash adminberoot
sudo echo "adminberoot:123" | sudo chpasswd
sudo usermod -aG sudo adminberoot