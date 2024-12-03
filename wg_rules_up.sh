#!/bin/sh

if [ "$#" -ne 1 ]; then
    echo "$0 <interface name>"
    exit -1
fi

IFACE=$1
echo "Using interface: $1"

echo "Flushing iptables rules"
iptables -F
iptables -t nat -F
iptables -P INPUT ACCEPT
iptables -P OUTPUT ACCEPT
iptables -P FORWARD ACCEPT

echo "Current IP: `curl -s -4 ifconfig.co`"

# temporarily block forwarding so nothing leaks if we restart this script
sysctl -w net.ipv4.ip_forward=0

# allow ssh
echo "Allowing incoming/outgoing SSH established on all interfaces"
iptables -A INPUT -p tcp --dport 22 -j ACCEPT
iptables -A OUTPUT -p tcp --sport 22 -j ACCEPT

echo "Allowing DHCP traffic"
iptables -A INPUT -j ACCEPT -p udp --dport 67:68 --sport 67:68
iptables -A OUTPUT -j ACCEPT -p udp --dport 67:68 --sport 67:68

echo "Allowing traffic on lo"
iptables -A OUTPUT -j ACCEPT -o lo
iptables -A INPUT -j ACCEPT -i lo

echo "Allowing traffic on wg"
iptables -A OUTPUT -j ACCEPT -o wg+
iptables -A INPUT -j ACCEPT -i wg+

# allow traffic from established connections
echo "Allowing already established traffic"
iptables -A INPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT

# allow wireguard uid, we need this prior we run wireguard because wireguard drops permissions at the end
# make sure the port number below reflects the one from your wireguard server
echo "Allowing wireguard traffic"
iptables -A OUTPUT -p udp -m udp --dport 51820 -j ACCEPT

# allow dns because it's a third party system app that tries to do it (and not wireguard)
echo "Allowing DNS for resolving wireguard server"
iptables -A OUTPUT -p udp --dport 53 -j ACCEPT

# allow traffic on wg0 and lo
echo "Allowing lo and wg interfaces"
iptables -A OUTPUT -j ACCEPT -o lo
iptables -A OUTPUT -j ACCEPT -o wg+

# allow forward traffic only from wg0
iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT

# this is important we need to send all traffic that is being forwarded to wg0
iptables -A FORWARD -i $IFACE -o wg0 -j ACCEPT

# masq traffic on wg0
echo "Masquerading traffic on wg0"
iptables -t nat -A POSTROUTING -o wg0 -j MASQUERADE

echo "Waiting for VPN to initialize"
sleep 5

echo "Current IP: `curl -s -4 ifconfig.co`"

echo "Setting policy in output and input chain to drop"
iptables -P OUTPUT DROP
iptables -P INPUT DROP
iptables -P FORWARD DROP

# block dns because it's a third party system app that tries to do it (and not wireguard)
echo "Blocking DNS for resolving wireguard server"
iptables -D OUTPUT -p udp --dport 53 -j ACCEPT

echo "Turning on IP forwarding"
sysctl -w net.ipv4.ip_forward=1
