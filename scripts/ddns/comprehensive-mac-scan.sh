#!/bin/bash

echo "🔍 Comprehensive Mac Detection Test"
echo "====================================="

# Get network info
GATEWAY=$(route get default 2>/dev/null | grep gateway | awk '{print $2}' || echo "192.168.2.1")
NETWORK_BASE=$(echo $GATEWAY | cut -d. -f1-3)

echo "🌐 Network Info:"
echo "   Gateway: $GATEWAY"
echo "   Network: $NETWORK_BASE.0/24"
echo ""

# Method 1: ARP table scan
echo "📡 Method 1: ARP Table Scan"
echo "=============================="
arp -a | head -20
echo ""

# Method 2: Ping sweep + ARP
echo "📡 Method 2: Ping Sweep + ARP"
echo "=============================="
echo "Pinging network range..."
for i in {1..254}; do
    ping -c 1 -W 1000 "$NETWORK_BASE.$i" &>/dev/null &
done
wait

echo "Updated ARP table:"
arp -a | grep -E "([0-9]{1,3}\.){3}[0-9]{1,3}" | head -20
echo ""

# Method 3: Bonjour/mDNS scan
echo "📡 Method 3: Bonjour/mDNS Discovery"
echo "==================================="
if command -v dns-sd &> /dev/null; then
    timeout 5s dns-sd -B _device-info._tcp local || echo "No mDNS responses"
elif command -v avahi-browse &> /dev/null; then
    timeout 5s avahi-browse -t _device-info._tcp || echo "No Avahi responses"
else
    echo "No mDNS tools available"
fi
echo ""

# Method 4: Check for Apple devices by MAC OUI
echo "📡 Method 4: Apple MAC Address Detection"
echo "======================================="
echo "Scanning for Apple MAC OUIs..."

# Create temporary file with Apple OUIs
cat > /tmp/apple_ouis.txt << 'EOF'
00:1b:63
00:1f:f3
00:23:df
00:25:00
00:26:08
04:0c:ce
04:15:52
04:69:f2
0c:74:c2
10:9a:dd
14:10:9f
18:af:61
1c:ab:a7
20:ab:37
24:a0:74
28:37:37
2c:b4:3a
30:90:ab
34:15:9e
38:ca:da
3c:15:c2
40:b3:95
44:d8:84
48:74:6e
4c:32:75
50:ea:d6
54:26:96
58:55:ca
5c:95:ae
60:f4:45
64:b9:e8
68:96:7b
6c:70:9f
70:11:24
74:e2:f5
78:31:c1
7c:c3:a1
80:92:9f
84:78:ac
88:1d:fc
8c:58:77
90:27:e4
94:f6:d6
98:f0:ab
9c:04:eb
a0:99:9b
a4:83:e7
a8:86:dd
ac:87:a3
b0:9f:ba
b4:f0:ab
b8:8d:12
bc:92:6b
c0:84:7a
c4:b3:01
c8:2a:14
cc:08:8d
d0:23:db
d4:9a:20
d8:30:62
dc:2b:2a
e0:ac:cb
e4:b2:fb
e8:80:2e
ec:35:86
f0:18:98
f4:1b:a1
f8:1e:df
fc:25:3f
EOF

# Check ARP table against Apple OUIs
APPLE_COUNT=0
arp -a | while read line; do
    if echo "$line" | grep -E "([a-fA-F0-9]{2}:){5}[a-fA-F0-9]{2}" > /dev/null; then
        MAC=$(echo "$line" | grep -oE "([a-fA-F0-9]{2}:){5}[a-fA-F0-9]{2}")
        OUI=$(echo "$MAC" | cut -d: -f1-3 | tr 'A-F' 'a-f')
        
        if grep -q "^$OUI$" /tmp/apple_ouis.txt; then
            IP=$(echo "$line" | grep -oE "([0-9]{1,3}\.){3}[0-9]{1,3}")
            HOSTNAME=$(echo "$line" | awk '{print $1}' | sed 's/^(//' | sed 's/)$//')
            echo "🍎 FOUND APPLE DEVICE: $HOSTNAME ($IP) MAC: $MAC"
            APPLE_COUNT=$((APPLE_COUNT + 1))
        fi
    fi
done

# Clean up
rm -f /tmp/apple_ouis.txt

echo ""
echo "📊 Summary"
echo "==========="
echo "Expected Macs: 4"
echo "Found Apple devices: Check output above"
echo ""

# Method 5: Check current machine's network interfaces
echo "📡 Method 5: Local Network Interfaces"
echo "====================================="
echo "This machine's network interfaces:"
ifconfig | grep -E "(en[0-9]|wl[0-9])" -A 5 | grep -E "inet |ether " || \
ip addr show | grep -E "inet |link/ether " | head -10

echo ""
echo "🔍 If no Apple devices were found:"
echo "   1. Ensure all 4 Macs are powered on"
echo "   2. Ensure they're connected to the same network"  
echo "   3. Try: sudo arp -d -a && ping broadcast"
echo "   4. Check if they're on different VLANs or subnets"