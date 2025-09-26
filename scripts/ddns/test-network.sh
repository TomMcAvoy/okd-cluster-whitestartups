#!/bin/bash

echo "🧪 Testing Free DDNS Network Detection"
echo "======================================"

echo ""
echo "🔍 1. Testing network connectivity..."
ping -c 1 8.8.8.8 > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "✅ Internet connectivity: OK"
else
    echo "❌ Internet connectivity: FAILED"
fi

echo ""
echo "🏠 2. Detecting local network configuration..."
if command -v route > /dev/null 2>&1; then
    GATEWAY=$(route get default 2>/dev/null | grep gateway | awk '{print $2}' | head -1)
else
    GATEWAY=$(ip route | grep default | awk '{print $3}' 2>/dev/null | head -1)
fi

if [ -n "$GATEWAY" ]; then
    echo "✅ Default gateway: $GATEWAY"
    NETWORK_BASE=${GATEWAY%.*}
    echo "✅ Network base: $NETWORK_BASE.x"
else
    echo "❌ Could not detect default gateway"
    exit 1
fi

echo ""
echo "🔗 3. Testing gateway connectivity..."
ping -c 1 $GATEWAY > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "✅ Gateway reachable: $GATEWAY"
else
    echo "❌ Gateway not reachable: $GATEWAY"
fi

echo ""
echo "📡 4. Checking ARP table for devices..."
ARP_COUNT=$(arp -a 2>/dev/null | wc -l | tr -d ' ')
echo "✅ ARP table entries: $ARP_COUNT devices"

if [ "$ARP_COUNT" -gt 0 ]; then
    echo ""
    echo "📱 Devices in ARP table:"
    arp -a 2>/dev/null | head -5
    if [ "$ARP_COUNT" -gt 5 ]; then
        echo "   ... and $((ARP_COUNT - 5)) more devices"
    fi
fi

echo ""
echo "🍎 5. Checking for Apple device MAC prefixes..."
APPLE_DEVICES=$(arp -a 2>/dev/null | grep -i -E "(00:1b:63|04:0c:ce|18:af:61|a4:83:e7|f0:18:98)" | wc -l | tr -d ' ')
echo "✅ Potential Apple devices found: $APPLE_DEVICES"

if [ "$APPLE_DEVICES" -gt 0 ]; then
    echo ""
    echo "📱 Apple devices detected:"
    arp -a 2>/dev/null | grep -i -E "(00:1b:63|04:0c:ce|18:af:61|a4:83:e7|f0:18:98)"
fi

echo ""
echo "🔧 6. System requirements check..."
if command -v node > /dev/null 2>&1; then
    NODE_VERSION=$(node --version)
    echo "✅ Node.js: $NODE_VERSION"
else
    echo "❌ Node.js: Not found"
fi

if command -v pnpm > /dev/null 2>&1; then
    PNPM_VERSION=$(pnpm --version)
    echo "✅ pnpm: $PNPM_VERSION"
else
    echo "❌ pnpm: Not found"
fi

if [ -f "dist/infrastructure/ddns/index.js" ]; then
    echo "✅ DDNS compiled: Ready"
else
    echo "⚠️  DDNS compiled: Run 'pnpm build' first"
fi

echo ""
echo "📝 7. Configuration check..."
if [ -f "config/ddns-config.json" ]; then
    echo "✅ Custom config: Found"
    cat config/ddns-config.json
else
    echo "⚠️  Custom config: Using defaults"
    echo "   Copy config/ddns-config.example.json to config/ddns-config.json to customize"
fi

echo ""
echo "🎯 Summary:"
echo "--------"
if [ "$ARP_COUNT" -gt 0 ]; then
    echo "✅ Network scanning should work - $ARP_COUNT devices visible"
else
    echo "⚠️  Limited network visibility - may need to wait for devices to communicate"
fi

if [ "$APPLE_DEVICES" -gt 0 ]; then
    echo "✅ Apple device detection should work - $APPLE_DEVICES devices found"
else
    echo "ℹ️  No Apple devices currently visible (this Mac may not show in its own ARP table)"
fi

echo ""
echo "🚀 Ready to run: pnpm ddns:start"
echo "📊 Monitor with: pnpm ddns:logs"