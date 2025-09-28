# Dell T7500 PXE Boot Configuration Guide

## BIOS/UEFI Configuration for PXE Boot

### Step 1: Access BIOS Setup
1. Power on the T7500
2. Press **F12** during startup for Boot Menu, or **F2** for BIOS Setup
3. Navigate to **System Setup** if using F12, then **BIOS Setup**

### Step 2: Enable Network Boot
```
BIOS Navigation:
├── Advanced
│   ├── Integrated Devices
│   │   ├── Network Interface Card: [Enabled]
│   │   ├── Network Interface Card Boot: [Enabled]
│   │   └── Wake on LAN: [Enabled] (optional)
│   └── USB Configuration
│       └── Legacy USB Support: [Enabled]
├── Boot
│   ├── Boot Device Priority
│   │   ├── 1st Boot Device: [Network/PXE]
│   │   ├── 2nd Boot Device: [Hard Drive]
│   │   └── 3rd Boot Device: [CD/DVD]
│   ├── Hard Disk Drives
│   │   └── 1st Drive: [Your primary disk]
│   └── Network Boot
│       ├── Network Boot: [Enabled]
│       ├── Boot to Network: [Enabled]
│       └── PXE Boot to LAN: [Enabled]
```

### Step 3: Configure Network Adapter
```
Advanced > Integrated Devices:
├── Integrated Network Card: [Enabled]
├── Network Card Option ROM: [Enabled]  # Critical for PXE
├── Network Boot Protocol: [PXE]
└── Network Boot Retry Count: [3]
```

### Step 4: Save and Exit
- Press **F10** to save changes and exit
- System will reboot and attempt PXE boot

## T7500 Network Interface Details

### Built-in Network Adapters
- **Primary NIC**: Broadcom NetXtreme BCM5761 Gigabit Ethernet
- **Secondary NIC**: Broadcom NetXtreme BCM5761 Gigabit Ethernet (if dual-port)

### PXE Boot Sequence
1. **POST** → **Network ROM Loading** → **DHCP Discovery**
2. **TFTP Boot File Download** → **Kernel Loading** → **CoreOS Installation**

### Common T7500 PXE Issues & Solutions

#### Issue: "PXE-E53: No boot filename received"
**Solution:**
- Check DHCP server configuration
- Ensure `next-server` and `filename` options are set
- Verify network cable connection

#### Issue: "PXE-E51: No DHCP or proxy DHCP offers were received"
**Solution:**
- Check network connectivity
- Verify DHCP server is running on correct VLAN
- Check switch configuration for PXE VLAN

#### Issue: Network card not detected
**Solution:**
- Update network card firmware
- Check PCIe slot connection (if using add-in card)
- Enable legacy boot support in BIOS

## Hardware-Specific Considerations

### Memory Configuration (for 293GB T7500)
```bash
# T7500 Memory Slots (18 DIMM slots total)
CPU0: 9 DIMM slots (channels A, B, C - 3 slots each)
CPU1: 9 DIMM slots (channels A, B, C - 3 slots each)

# For 293GB configuration (likely using 16GB + 32GB DIMMs)
# Example: 9x32GB + 9x32GB = 288GB (close to 293GB reported)
```

### Storage Controller Support
- **PERC H200**: Supports AHCI/IT mode (recommended for Linux)
- **PERC H700**: Hardware RAID (can be used but not recommended for container storage)
- **Onboard SATA**: 6x SATA ports available

### Network Performance
- **Gigabit Ethernet**: Sufficient for PXE boot and cluster traffic
- **Consider**: Adding 10GbE card for high-bandwidth workloads

## BIOS Settings Summary for PXE Boot

### Critical Settings Checklist
```
☐ Network Interface Card: Enabled
☐ Network Interface Card Boot: Enabled  
☐ Network Card Option ROM: Enabled
☐ Boot Device Priority: Network/PXE first
☐ Network Boot: Enabled
☐ PXE Boot to LAN: Enabled
☐ Legacy USB Support: Enabled (for fallback)
☐ UEFI Boot: Disabled (use Legacy for CoreOS compatibility)
```

### Advanced Performance Settings
```
☐ Virtualization Technology: Enabled (for containers)
☐ VT-d (Intel): Enabled (for device passthrough)
☐ Hyper-Threading: Enabled (for better container density)
☐ CPU Power Management: Performance (for consistent performance)
☐ Memory Operating Mode: Optimizer Mode
```

## Network Boot Troubleshooting

### Verify Network Interface MAC Address
```bash
# During PXE boot, note the MAC address displayed
# Example: "Intel Boot Agent Version X.X.XX"
# MAC: 00:11:22:33:44:55

# Add this MAC to your PXE server DHCP configuration
```

### Test Network Connectivity
```bash
# From PXE server, test connectivity to T7500
ping 192.168.2.101  # T7500 IP after DHCP assignment

# Check DHCP lease assignment
sudo dhcp-lease-list
# or
sudo tail -f /var/log/syslog | grep dhcp
```

### Monitor PXE Boot Process
```bash
# On PXE server, monitor services
sudo journalctl -u dnsmasq -f    # DHCP/TFTP logs
sudo tail -f /var/log/httpd/access_log  # HTTP requests

# Look for:
# 1. DHCP DISCOVER/OFFER/REQUEST/ACK sequence
# 2. TFTP requests for pxelinux.0, kernel, initrd
# 3. HTTP requests for CoreOS image and Ignition config
```

## Next Steps After PXE Configuration

1. **Test PXE Boot**: Boot one T7500 to verify PXE chain works
2. **Configure Storage**: Set up LVM/XFS as described in storage guide
3. **Deploy CoreOS**: Use Ignition configs for automated installation
4. **Join Cluster**: Configure as OKD worker nodes

## T7500-Specific Performance Tuning

### BIOS Performance Settings
```
Performance Options:
├── CPU Performance: Maximum Performance
├── Memory Speed: Maximum Supported
├── Power Management: Performance
└── Thermal Management: Performance
```

### Network Performance
```bash
# After CoreOS installation, tune network performance
echo 'net.core.rmem_max = 268435456' >> /etc/sysctl.conf
echo 'net.core.wmem_max = 268435456' >> /etc/sysctl.conf
echo 'net.ipv4.tcp_rmem = 4096 65536 268435456' >> /etc/sysctl.conf
```

This configuration ensures your Dell T7500 systems can reliably PXE boot and are optimized for container workloads in your OKD cluster.