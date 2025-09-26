# Quick Deploy Guide for Other Macs 🚀

Follow these steps to deploy the Free DDNS solution on your other Mac devices.

## 🔄 On Each Additional Mac:

### 1. Clone the Repository
```bash
git clone https://github.com/TomMcAvoy/okd-cluster-whitestartups.git
cd okd-cluster-whitestartups
```

### 2. Install Dependencies
```bash
# Install pnpm if not already installed
curl -fsSL https://get.pnpm.io/install.sh | sh

# Install project dependencies
pnpm install

# Build the project
pnpm build
```

### 3. Quick Test (Optional)
```bash
# Test network detection
pnpm ddns:scan

# Test the system in debug mode (Ctrl+C to stop)
DEBUG=true pnpm tsx src/infrastructure/ddns/index.ts
```

### 4. Install as System Service
```bash
# One-command installation
pnpm ddns:install

# This will:
# - Create launchd service on macOS (or systemd on Linux)
# - Start monitoring automatically on boot
# - Create logs in logs/ddns.log
```

### 5. Verify Installation
```bash
# Check if service is running
pnpm ddns:status

# View live logs
pnpm ddns:logs

# Check discovered devices
cat cache/known-devices.json

# Check generated DNS records
cat config/okd-dns-records.txt
```

## 🔧 Configuration (Optional)

Create `config/ddns-config.json` to customize:
```json
{
  "localDomain": "home.local",
  "hubIP": "192.168.2.1",
  "debug": false,
  "aggressiveScan": false,
  "monitoring": {
    "scanInterval": 120
  }
}
```

## 🎯 Expected Results

After installation on each Mac, you should see:

1. **Device Discovery**: Each Mac will discover other Macs on the network
2. **Local DNS**: All Macs accessible via `.home.local` domains
3. **Automatic Updates**: IP changes detected and updated every 2 minutes
4. **OKD Ready**: DNS records generated for cluster configuration

## 📊 Monitoring Commands

```bash
# Service management
pnpm ddns:start      # Start monitoring
pnpm ddns:stop       # Stop monitoring
pnpm ddns:restart    # Restart service
pnpm ddns:status     # Check status

# Debugging
pnpm ddns:debug      # Run in debug mode
pnpm ddns:scan       # Manual network scan
pnpm ddns:logs       # View logs

# Testing
ping macbook-pro2.home.local
ssh user@macbook-pro3.home.local
```

## 🔍 Troubleshooting

### If no devices are found:
1. Ensure all Macs are on the same network (192.168.2.x)
2. Check that devices aren't using VPN or different subnets
3. Run with debug mode: `DEBUG=true pnpm ddns:start`

### Permission issues:
```bash
# Ensure proper permissions for /etc/hosts
sudo chmod 644 /etc/hosts

# Check service permissions
sudo systemctl status okd-ddns  # Linux
launchctl list | grep okd        # macOS
```

### Network issues:
```bash
# Clear ARP cache and rescan
sudo arp -d -a
pnpm ddns:scan
```

## ✅ Success Indicators

You'll know it's working when:
- ✅ Service shows as "running" in status
- ✅ Multiple Mac devices appear in logs
- ✅ `ping macbook-proX.home.local` works
- ✅ DNS records generated in `config/okd-dns-records.txt`
- ✅ Devices show in `/etc/hosts` with `# OKD-DDNS-MANAGED` tags

## 🎉 Next Steps

Once deployed on all Macs:
1. Use generated DNS records for OKD cluster configuration
2. Configure Bell Hub 3000 DynDNS for external access (optional)
3. Monitor logs to ensure all devices stay discovered
4. Enjoy your $0.00/month enterprise DDNS solution! 🎯