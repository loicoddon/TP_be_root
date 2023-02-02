#!/bin/bash
# Disable IPv6

echo "Disabling IPv6..."
echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6
echo "Disabling IPv6 on boot..."
cat >> /etc/sysctl.conf << EOF
#disable ipv6 on boot
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1
EOF