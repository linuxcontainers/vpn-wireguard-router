#!/bin/sh

echo "Flushing iptables rules"
iptables -F
iptables -t nat -F
iptables -P INPUT ACCEPT
iptables -P OUTPUT ACCEPT
iptables -P FORWARD ACCEPT

echo "Current IP: `curl -s -4 ifconfig.co`"

# temporarily block forwarding so nothing leaks if we restart this script
sysctl -w net.ipv4.ip_forward=0
