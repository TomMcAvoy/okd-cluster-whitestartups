import { exec } from 'child_process';
import { promisify } from 'util';
import { readFileSync, writeFileSync, existsSync } from 'fs';
import { createHash } from 'crypto';

const execAsync = promisify(exec);

interface FreeConfig {
  localDomain: string;
  hubIP: string;
  externalDomain?: string; // Only if you already have free DynDNS setup on Hub 3000
  debug?: boolean; // Show all devices, not just Apple ones
  aggressiveScan?: boolean; // Use more comprehensive scanning methods
}

interface MacDevice {
  hostname: string;
  mac: string;
  ip?: string;
  lastSeen?: Date;
}

/**
 * Completely free DDNS solution using:
 * - Local DNS resolution via /etc/hosts
 * - ARP table scanning (no external tools needed)
 * - Bell Hub 3000's existing DynDNS (if configured)
 * - Zero external services or costs
 */
export class FreeDDNSManager {
  private config: FreeConfig;
  private devices: Map<string, MacDevice> = new Map();
  private hostsBackupPath = '/tmp/hosts.backup';

  constructor(config: FreeConfig) {
    this.config = config;
    this.loadDeviceCache();
  }

  private loadDeviceCache(): void {
    const cachePath = 'cache/known-devices.json';
    if (existsSync(cachePath)) {
      try {
        const cache = JSON.parse(readFileSync(cachePath, 'utf8'));
        cache.forEach((device: MacDevice) => {
          this.devices.set(device.mac, device);
        });
        console.log(`📱 Loaded ${this.devices.size} cached devices`);
      } catch (error) {
        console.warn('⚠️  Could not load device cache:', error);
      }
    }
  }

  private saveDeviceCache(): void {
    try {
      if (!existsSync('cache')) {
        require('fs').mkdirSync('cache', { recursive: true });
      }
      
      const devices = Array.from(this.devices.values());
      writeFileSync('cache/known-devices.json', JSON.stringify(devices, null, 2));
    } catch (error) {
      console.warn('⚠️  Could not save device cache:', error);
    }
  }

  /**
   * Scan network using multiple comprehensive methods
   */
  async scanLocalNetwork(): Promise<MacDevice[]> {
    try {
      const networkBase = await this.getNetworkBase();
      console.log(`🔍 Scanning network ${networkBase}.0/24 for Mac devices...`);
      
      // Method 1: Clear ARP cache and do aggressive ping sweep
      if (this.config.aggressiveScan) {
        console.log('🚀 Using aggressive scan mode...');
        try {
          await execAsync('sudo arp -d -a 2>/dev/null || true');
        } catch {}
      }
      
      // Method 2: Comprehensive ping sweep with different techniques
      console.log('� Performing network ping sweep...');
      const pingPromises = [];
      for (let i = 1; i <= 254; i++) {
        const ip = `${networkBase}.${i}`;
        // Use multiple ping methods for better discovery
        if (this.config.aggressiveScan) {
          pingPromises.push(
            execAsync(`ping -c 2 -W 2000 ${ip} 2>/dev/null || true`).catch(() => {})
          );
        } else {
          pingPromises.push(
            execAsync(`ping -c 1 -W 1000 ${ip} 2>/dev/null || true`).catch(() => {})
          );
        }
      }
      
      // Wait for pings to complete
      await Promise.allSettled(pingPromises);
      
      // Method 3: Also try to discover via Bonjour/mDNS
      if (this.config.aggressiveScan) {
        try {
          console.log('🔍 Attempting Bonjour/mDNS discovery...');
          await execAsync('dns-sd -B _device-info._tcp local. &');
          await new Promise(resolve => setTimeout(resolve, 3000)); // Wait 3 seconds
          await execAsync('pkill -f dns-sd 2>/dev/null || true');
        } catch {}
      }
      
      // Method 4: Read ARP table with enhanced parsing
      const arpCommands = [
        'arp -a',
        'cat /proc/net/arp 2>/dev/null || true',
        'ip neighbor show 2>/dev/null || true'
      ];
      
      let allArpOutput = '';
      for (const cmd of arpCommands) {
        try {
          const { stdout } = await execAsync(cmd);
          if (stdout.trim()) {
            allArpOutput += stdout + '\n';
          }
        } catch {}
      }
      
      const currentDevices: MacDevice[] = [];
      const lines = allArpOutput.split('\n');
      let totalDevicesFound = 0;
      
      for (const line of lines) {
        if (!line.trim()) continue;
        
        // Parse different ARP formats more comprehensively
        let match = line.match(/([^\s\(]+)\s*\((\d+\.\d+\.\d+\.\d+)\)\s+at\s+([a-fA-F0-9:]{17})/);
        if (!match) {
          // Linux format 1
          match = line.match(/(\d+\.\d+\.\d+\.\d+)\s+\w+\s+\w+\s+([a-fA-F0-9:]{17})/);
          if (match) {
            match = [match[0], '', match[1], match[2]];
          }
        }
        if (!match) {
          // Linux format 2 (ip neighbor)
          match = line.match(/(\d+\.\d+\.\d+\.\d+)\s+dev\s+\w+\s+lladdr\s+([a-fA-F0-9:]{17})/);
          if (match) {
            match = [match[0], '', match[1], match[2]];
          }
        }
        
        if (match) {
          const [, hostname, ip, mac] = match;
          const normalizedMac = mac.toLowerCase();
          totalDevicesFound++;
          
          // Debug mode: show all devices
          if (this.config.debug) {
            const isApple = this.isAppleDevice(normalizedMac);
            const isLikelyApple = this.isLikelyAppleDevice(hostname || '', normalizedMac);
            console.log(`🔍 Found device: ${hostname || 'unknown'} (${ip}) MAC: ${normalizedMac} ${isApple ? '🍎 APPLE' : ''} ${isLikelyApple ? '🍎 LIKELY-APPLE' : ''}`);
          }
          
          if (this.isLikelyAppleDevice(hostname || '', normalizedMac)) {
            let device = this.devices.get(normalizedMac);
            if (!device) {
              device = {
                hostname: await this.generateHostname(hostname || '', normalizedMac),
                mac: normalizedMac,
                ip,
                lastSeen: new Date()
              };
              this.devices.set(normalizedMac, device);
              console.log(`✨ New Mac discovered: ${device.hostname} (${ip}) MAC: ${normalizedMac}`);
            } else {
              device.ip = ip;
              device.lastSeen = new Date();
            }
            currentDevices.push(device);
          }
        }
      }
      
      console.log(`📊 Scan results: ${totalDevicesFound} total devices, ${currentDevices.length} Apple devices`);
      
      this.saveDeviceCache();
      return currentDevices;
      
    } catch (error) {
      console.error('❌ Network scan failed:', error);
      return [];
    }
  }

  private async getNetworkBase(): Promise<string> {
    try {
      // Get default gateway
      const { stdout } = await execAsync(`
        route get default 2>/dev/null | grep gateway | awk '{print $2}' ||
        ip route | grep default | awk '{print $3}' 2>/dev/null ||
        echo "192.168.1.1"
      `);
      const gateway = stdout.trim();
      return gateway.substring(0, gateway.lastIndexOf('.'));
    } catch {
      return '192.168.1'; // Common default
    }
  }

  private isAppleDevice(mac: string): boolean {
    // Apple MAC OUI prefixes (first 3 octets) - Updated comprehensive list
    const appleOUIs = [
      '00:1b:63', '00:1f:f3', '00:23:df', '00:25:00', '00:26:08',
      '04:0c:ce', '04:15:52', '04:69:f2', '0c:74:c2', '10:9a:dd',
      '14:10:9f', '18:af:61', '1c:ab:a7', '20:ab:37', '24:a0:74',
      '28:37:37', '2c:b4:3a', '30:90:ab', '34:15:9e', '38:ca:da',
      '3c:15:c2', '40:b3:95', '44:d8:84', '48:74:6e', '4c:32:75',
      '50:ea:d6', '54:26:96', '58:55:ca', '5c:95:ae', '60:f4:45',
      '64:b9:e8', '68:96:7b', '6c:70:9f', '70:11:24', '74:e2:f5',
      '78:31:c1', '7c:c3:a1', '80:92:9f', '84:78:ac', '88:1d:fc',
      '8c:58:77', '90:27:e4', '94:f6:d6', '98:f0:ab', '9c:04:eb',
      'a0:99:9b', 'a4:83:e7', 'a8:86:dd', 'ac:87:a3', 'b0:9f:ba',
      'b4:f0:ab', 'b8:8d:12', 'bc:92:6b', 'c0:84:7a', 'c4:b3:01',
      'c8:2a:14', 'cc:08:8d', 'd0:23:db', 'd4:9a:20', 'd8:30:62',
      'dc:2b:2a', 'e0:ac:cb', 'e4:b2:fb', 'e8:80:2e', 'ec:35:86',
      'f0:18:98', 'f4:1b:a1', 'f8:1e:df', 'fc:25:3f',
      // Additional Apple OUIs
      '7c:57:58', '58:d5:6e', 'ac:de:48', '46:26:cf', '5a:13:72', '7e:f3:4c'
    ];
    
    const devicePrefix = mac.substring(0, 8);
    return appleOUIs.includes(devicePrefix);
  }

  private isLikelyAppleDevice(hostname: string, mac: string): boolean {
    // Check hostname patterns that indicate Apple devices
    const appleHostnamePatterns = [
      /macbook/i,
      /imac/i,
      /mac-?mini/i,
      /mac-?pro/i,
      /mac-?studio/i,
      /iphone/i,
      /ipad/i,
      /apple-?tv/i,
      /.*\.local$/i
    ];
    
    // Check for Apple-like hostname patterns
    const hasAppleHostname = appleHostnamePatterns.some(pattern => pattern.test(hostname));
    
    // Check for randomized MAC (common on modern Apple devices)
    // Randomized MACs often have locally administered bit set (2nd bit of first octet)
    const firstOctet = parseInt(mac.substring(0, 2), 16);
    const isRandomized = (firstOctet & 0x02) !== 0;
    
    return this.isAppleDevice(mac) || (hasAppleHostname && isRandomized);
  }

  private async generateHostname(discoveredName: string, mac: string): Promise<string> {
    let hostname = discoveredName.toLowerCase().replace(/\.local$/, '');
    
    if (!hostname || hostname.match(/^\d+\.\d+\.\d+\.\d+$/) || hostname === '?') {
      const macHash = createHash('md5').update(mac).digest('hex').substring(0, 6);
      hostname = `mac-${macHash}`;
    }
    
    return hostname.replace(/[^a-z0-9-]/g, '-').replace(/-+/g, '-');
  }

  /**
   * Update local DNS using /etc/hosts (completely free)
   */
  async updateLocalDNS(devices: MacDevice[]): Promise<void> {
    try {
      // Backup current hosts file
      await execAsync(`cp /etc/hosts ${this.hostsBackupPath}`);
      
      // Read current hosts file
      let hostsContent = readFileSync('/etc/hosts', 'utf8');
      
      // Remove old OKD managed entries
      const lines = hostsContent.split('\n');
      const filteredLines = lines.filter(line => 
        !line.includes('# OKD-DDNS-MANAGED') && 
        !line.includes('.home.local')
      );
      
      // Add new entries
      const newEntries = [
        '',
        '# OKD-DDNS-MANAGED - Auto-generated entries',
        `# Generated: ${new Date().toISOString()}`,
      ];
      
      for (const device of devices) {
        if (device.ip) {
          newEntries.push(`${device.ip} ${device.hostname}.${this.config.localDomain} ${device.hostname} # OKD-DDNS-MANAGED`);
        }
      }
      
      // Write updated hosts file
      const updatedHosts = filteredLines.join('\n') + '\n' + newEntries.join('\n') + '\n';
      writeFileSync('/tmp/hosts.new', updatedHosts);
      
      // Atomic update
      await execAsync('sudo cp /tmp/hosts.new /etc/hosts');
      await execAsync('rm /tmp/hosts.new');
      
      console.log(`✅ Updated /etc/hosts with ${devices.length} Mac devices`);
      
      // Flush DNS cache
      await execAsync(`
        sudo dscacheutil -flushcache 2>/dev/null ||
        sudo systemctl restart systemd-resolved 2>/dev/null ||
        sudo service networking restart 2>/dev/null ||
        true
      `);
      
    } catch (error) {
      console.error('❌ Failed to update local DNS:', error);
      // Restore backup if something went wrong
      try {
        await execAsync(`sudo cp ${this.hostsBackupPath} /etc/hosts`);
      } catch {}
    }
  }

  /**
   * Generate cluster-ready DNS records for OKD
   */
  generateOKDDNSRecords(devices: MacDevice[]): string {
    const records = [
      '# OKD Cluster DNS Records',
      '# Use these in your cluster configuration',
      '',
      '# Mac devices in cluster:'
    ];
    
    devices.forEach((device, index) => {
      if (device.ip) {
        records.push(`# Node ${index + 1}: ${device.hostname}.${this.config.localDomain} -> ${device.ip}`);
        records.push(`${device.hostname}.${this.config.localDomain}. 300 IN A ${device.ip}`);
        
        // Add OKD service records
        records.push(`api.${device.hostname}.${this.config.localDomain}. 300 IN A ${device.ip}`);
        records.push(`*.apps.${device.hostname}.${this.config.localDomain}. 300 IN A ${device.ip}`);
      }
    });
    
    return records.join('\n');
  }

  /**
   * Start the free monitoring service
   */
  async startFreeMonitoring(): Promise<void> {
    console.log('🚀 Starting FREE DDNS monitoring...');
    console.log('💰 Cost: $0.00 - Using only local resources!');
    console.log(`🏠 Local domain: ${this.config.localDomain}`);
    
    const monitoringLoop = async () => {
      try {
        console.log('🔄 Scanning for Mac devices...');
        const devices = await this.scanLocalNetwork();
        
        if (devices.length > 0) {
          console.log(`📱 Found ${devices.length} Mac devices:`,
            devices.map(d => `${d.hostname}(${d.ip})`).join(', ')
          );
          
          await this.updateLocalDNS(devices);
          
          // Generate OKD DNS records
          const okdRecords = this.generateOKDDNSRecords(devices);
          if (!existsSync('config')) {
            require('fs').mkdirSync('config', { recursive: true });
          }
          writeFileSync('config/okd-dns-records.txt', okdRecords);
          
          console.log('📝 Generated OKD DNS records in config/okd-dns-records.txt');
        } else {
          console.log('😴 No Mac devices found');
        }
        
      } catch (error) {
        console.error('❌ Monitoring cycle error:', error);
      }
    };
    
    // Initial scan
    await monitoringLoop();
    
    // Monitor every 2 minutes
    setInterval(monitoringLoop, 2 * 60 * 1000);
    
    console.log('✅ Free DDNS monitoring started');
    console.log('💡 Tip: Configure your Bell Hub 3000 DynDNS for external access');
  }
}