#!/bin/bash

# Free DDNS Installation Script
# No external dependencies or costs!

set -e

echo "🆓 Installing FREE DDNS solution..."
echo "💰 Total cost: \$0.00"

# Check if we're on macOS or Linux
OS=$(uname -s)
echo "🖥️  Detected OS: $OS"

# Get project directory
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
echo "📁 Project directory: $PROJECT_DIR"

# Check if TypeScript is compiled
if [ ! -d "$PROJECT_DIR/dist/infrastructure/ddns" ]; then
    echo "🔨 Building TypeScript..."
    cd "$PROJECT_DIR"
    if command -v pnpm &> /dev/null; then
        pnpm build
    elif command -v npm &> /dev/null; then
        npm run build
    else
        echo "❌ Neither pnpm nor npm found. Please install Node.js and pnpm/npm."
        exit 1
    fi
fi

# Create necessary directories
echo "📁 Creating directories..."
mkdir -p "$PROJECT_DIR/cache" "$PROJECT_DIR/config" "$PROJECT_DIR/logs"

# Create systemd service for Linux
if [[ "$OS" == "Linux" ]]; then
    echo "🐧 Creating systemd service..."
    sudo tee /etc/systemd/system/okd-ddns.service > /dev/null <<EOF
[Unit]
Description=OKD Free DDNS Manager
After=network.target
Wants=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=$PROJECT_DIR
ExecStart=/usr/bin/node $PROJECT_DIR/dist/infrastructure/ddns/index.js
Restart=always
RestartSec=30
StandardOutput=append:$PROJECT_DIR/logs/ddns.log
StandardError=append:$PROJECT_DIR/logs/ddns-error.log

[Install]
WantedBy=multi-user.target
EOF

    echo "🔄 Enabling systemd service..."
    sudo systemctl daemon-reload
    sudo systemctl enable okd-ddns
    
    echo "✅ Service installed! Control with:"
    echo "   sudo systemctl start okd-ddns    # Start service"
    echo "   sudo systemctl stop okd-ddns     # Stop service"
    echo "   sudo systemctl status okd-ddns   # Check status"
    echo "   tail -f $PROJECT_DIR/logs/ddns.log  # View logs"

# Create launchd service for macOS  
elif [[ "$OS" == "Darwin" ]]; then
    echo "🍎 Creating launchd service..."
    
    # Find node path
    NODE_PATH=$(which node)
    if [ -z "$NODE_PATH" ]; then
        NODE_PATH="/usr/local/bin/node"
    fi
    
    tee ~/Library/LaunchAgents/com.okd.ddns.plist > /dev/null <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.okd.ddns</string>
    <key>ProgramArguments</key>
    <array>
        <string>$NODE_PATH</string>
        <string>$PROJECT_DIR/dist/infrastructure/ddns/index.js</string>
    </array>
    <key>WorkingDirectory</key>
    <string>$PROJECT_DIR</string>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>$PROJECT_DIR/logs/ddns.log</string>
    <key>StandardErrorPath</key>
    <string>$PROJECT_DIR/logs/ddns-error.log</string>
</dict>
</plist>
EOF

    echo "🔄 Loading launchd service..."
    launchctl load ~/Library/LaunchAgents/com.okd.ddns.plist
    
    echo "✅ Service installed! Control with:"
    echo "   launchctl start com.okd.ddns     # Start service"
    echo "   launchctl stop com.okd.ddns      # Stop service"  
    echo "   launchctl list | grep okd        # Check status"
    echo "   tail -f $PROJECT_DIR/logs/ddns.log  # View logs"
fi

# Create default configuration if it doesn't exist
if [ ! -f "$PROJECT_DIR/config/ddns-config.json" ]; then
    echo "📋 Creating default configuration..."
    cat > "$PROJECT_DIR/config/ddns-config.json" <<EOF
{
  "localDomain": "home.local",
  "hubIP": "192.168.2.1",
  "externalDomain": "",
  "monitoring": {
    "scanInterval": 120,
    "logLevel": "info"
  }
}
EOF
    echo "🔧 Edit $PROJECT_DIR/config/ddns-config.json to customize settings"
fi

# Create .gitignore entries
if [ -f "$PROJECT_DIR/.gitignore" ]; then
    if ! grep -q "cache/" "$PROJECT_DIR/.gitignore"; then
        echo "" >> "$PROJECT_DIR/.gitignore"
        echo "# DDNS cache and logs" >> "$PROJECT_DIR/.gitignore"
        echo "cache/" >> "$PROJECT_DIR/.gitignore"
        echo "logs/" >> "$PROJECT_DIR/.gitignore"
    fi
fi

echo ""
echo "🎉 FREE DDNS installation complete!"
echo "📊 Monitoring will start automatically on next boot"
echo "📁 Check logs in: $PROJECT_DIR/logs/ddns.log"
echo "🔧 DNS records generated in: $PROJECT_DIR/config/okd-dns-records.txt"
echo ""
echo "💡 Next steps:"
echo "   1. Edit config/ddns-config.json with your network settings"
echo "   2. Configure DynDNS on your Bell Hub 3000 (optional for external access)"
echo "   3. Use the generated DNS records for your OKD cluster configuration"
echo "   4. Monitor logs to see discovered Mac devices"
echo ""
echo "⚡ Quick commands:"
if [[ "$OS" == "Linux" ]]; then
    echo "   sudo systemctl start okd-ddns    # Start now"
    echo "   tail -f logs/ddns.log            # Watch logs"
elif [[ "$OS" == "Darwin" ]]; then
    echo "   launchctl start com.okd.ddns     # Start now"
    echo "   tail -f logs/ddns.log            # Watch logs"
fi