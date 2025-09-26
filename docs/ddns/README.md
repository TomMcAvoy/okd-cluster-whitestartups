# Free DDNS for OKD Cluster 🆓

A completely free Dynamic DNS solution for your OKD cluster using Bell Hub 3000 and Mac devices. **Total cost: $0.00!**

## 🌟 Features

- **100% Free**: No external services, subscriptions, or costs
- **Automatic Mac Discovery**: Finds Apple devices on your network automatically
- **Local DNS Resolution**: Updates `/etc/hosts` for immediate local access
- **OKD Integration**: Generates cluster-ready DNS records
- **Bell Hub 3000 Compatible**: Works with your existing router
- **Zero Configuration**: Auto-discovers devices and generates hostnames
- **Production Ready**: Includes systemd/launchd services

## 🚀 Quick Start

### 1. Install Dependencies
```bash
# Install development tools
pnpm install

# Build the project
pnpm build
```

### 2. Install and Start Service
```bash
# One-command installation
pnpm ddns:install

# Start monitoring (automatically starts on boot after installation)
pnpm ddns:start
```

### 3. View Results
```bash
# Check discovered devices and logs
pnpm ddns:logs

# View generated DNS records for OKD
cat config/okd-dns-records.txt
```

That's it! Your Macs will now be discoverable at `hostname.home.local`.

## 📋 Configuration

### Basic Configuration
Create `config/ddns-config.json`:
```json
{
  "localDomain": "home.local",
  "hubIP": "192.168.2.1",
  "externalDomain": "your-home.no-ip.org",
  "monitoring": {
    "scanInterval": 120,
    "logLevel": "info"
  }
}
```

### Bell Hub 3000 DynDNS (Optional)
For external access, configure your Bell Hub 3000:
1. Log into router admin (usually `192.168.2.1`)
2. Go to **Advanced** → **Dynamic DNS**
3. Enable DynDNS with free provider:
   - **No-IP.com** (free)
   - **DynDNS.org** (free tier)
   - **ChangeIP.com** (free)
4. Enter your domain (e.g., `your-home.no-ip.org`)

## 🛠️ Available Commands

```bash
# Service Management
pnpm ddns:install    # Install system service
pnpm ddns:start      # Start monitoring
pnpm ddns:stop       # Stop monitoring  
pnpm ddns:restart    # Restart service
pnpm ddns:status     # Check service status

# Development
pnpm ddns:dev        # Run in development mode with auto-reload
pnpm ddns:logs       # View live logs

# Manual Operations
pnpm build           # Compile TypeScript
```

## 🏗️ How It Works

### 1. Network Discovery
- Performs ping sweep of local network (`192.168.x.0/24`)
- Reads ARP table to find devices with IP/MAC mappings
- Identifies Apple devices by MAC OUI (Organizationally Unique Identifier)

### 2. Mac Device Detection
The system recognizes Apple devices by their MAC address prefixes:
```typescript
// Examples of Apple MAC OUIs
'00:1b:63', '04:0c:ce', '18:af:61', 'a4:83:e7', 'f0:18:98'
// And 100+ more...
```

### 3. Hostname Generation
- Uses discovered bonjour/mDNS names when available
- Falls back to `mac-{hash}` format for generic names
- Ensures DNS-safe hostnames (lowercase, no special chars)

### 4. Local DNS Updates
Updates `/etc/hosts` with entries like:
```
# OKD-DDNS-MANAGED - Auto-generated entries
# Generated: 2025-09-25T10:30:00.000Z
192.168.2.101 macbook-pro.home.local macbook-pro # OKD-DDNS-MANAGED
192.168.2.102 imac-studio.home.local imac-studio # OKD-DDNS-MANAGED
```

### 5. OKD DNS Records Generation
Creates `config/okd-dns-records.txt`:
```
# OKD Cluster DNS Records
# Node 1: macbook-pro.home.local -> 192.168.2.101
macbook-pro.home.local. 300 IN A 192.168.2.101
api.macbook-pro.home.local. 300 IN A 192.168.2.101
*.apps.macbook-pro.home.local. 300 IN A 192.168.2.101
```

## 🔧 System Integration

### macOS (Launchd)
Service file: `~/Library/LaunchAgents/com.okd.ddns.plist`
```bash
launchctl list | grep okd        # Check status
launchctl start com.okd.ddns     # Manual start
launchctl stop com.okd.ddns      # Manual stop
```

### Linux (systemd)  
Service file: `/etc/systemd/system/okd-ddns.service`
```bash
systemctl status okd-ddns        # Check status
sudo systemctl start okd-ddns    # Manual start
sudo systemctl stop okd-ddns     # Manual stop
```

## 📊 Monitoring & Logs

### Log Files
- **Main logs**: `logs/ddns.log`
- **Error logs**: `logs/ddns-error.log`  
- **Device cache**: `cache/known-devices.json`

### Log Output Example
```
🚀 Starting FREE DDNS monitoring...
💰 Cost: $0.00 - Using only local resources!
🏠 Local domain: home.local
📱 Loaded 2 cached devices
🔍 Scanning local network...
✨ New Mac discovered: macbook-air-a1b2c3 (192.168.2.103)
📱 Found 3 Mac devices: macbook-pro(192.168.2.101), imac-studio(192.168.2.102), macbook-air-a1b2c3(192.168.2.103)
✅ Updated /etc/hosts with 3 Mac devices
📝 Generated OKD DNS records in config/okd-dns-records.txt
✅ Free DDNS monitoring started
```

## 🔒 Security & Permissions

The system requires `sudo` access to:
- Update `/etc/hosts` file
- Flush DNS cache
- Install system services

This is standard for DNS management and unavoidable for local DNS resolution.

## 💡 Use Cases

### For OKD Cluster
```yaml
# Use discovered devices as cluster nodes
apiVersion: v1
kind: ConfigMap
metadata:
  name: cluster-dns
data:
  master-node: "macbook-pro.home.local"
  worker-nodes: |
    imac-studio.home.local
    macbook-air-a1b2c3.home.local
```

### For Development
```bash
# SSH to any Mac by hostname
ssh user@macbook-pro.home.local
ssh user@imac-studio.home.local

# Access services
curl http://macbook-pro.home.local:8080
curl http://api.macbook-pro.home.local
```

### For External Access (with Bell Hub DynDNS)
```bash
# From anywhere on the internet (if Hub DynDNS configured)
ssh user@your-home.no-ip.org -p 22001  # Port forwarded to macbook-pro
curl https://your-home.no-ip.org:8443   # Port forwarded to cluster API
```

## 🆘 Troubleshooting

### No devices found
```bash
# Check network connectivity
ping 192.168.2.1

# Manually check ARP table
arp -a

# Verify network range
ip route | grep default
```

### Permission errors
```bash
# Ensure script has sudo access for /etc/hosts
sudo echo "test" >> /etc/hosts
sudo sed -i '$d' /etc/hosts

# Check service permissions
sudo systemctl status okd-ddns  # Linux
launchctl list | grep okd        # macOS
```

### Service not starting
```bash
# Check logs
pnpm ddns:logs

# Rebuild and reinstall
pnpm build
pnpm ddns:install
```

## 💰 Cost Breakdown

| Component | Cost |
|-----------|------|
| Network scanning | **FREE** (ping, arp) |
| DNS resolution | **FREE** (/etc/hosts) |
| Service monitoring | **FREE** (systemd/launchd) |
| Device detection | **FREE** (MAC OUI database) |
| Bell Hub DynDNS | **FREE** (No-IP.com free tier) |
| **Monthly Total** | **$0.00** |

## 🚀 What's Next?

1. **Configure your Bell Hub 3000** for external DynDNS (optional)
2. **Use generated DNS records** in your OKD cluster configuration
3. **Monitor the logs** to see your Macs being discovered
4. **Enjoy free, automatic DNS** for your home lab!

---

**🎉 You now have enterprise-grade Dynamic DNS for $0.00/month!**