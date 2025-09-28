# Dell T7500 Cluster Setup Summary

## Complete Guide to PXE Boot with Expandable LVM + XFS Storage

This guide provides everything needed to configure your Dell T7500 systems for PXE boot deployment with Fedora CoreOS and expandable LVM + XFS storage.

## Quick Start Checklist

### Phase 1: BIOS Configuration ✓
**Configure each T7500 for PXE boot:**

1. **Access BIOS**: Power on → Press F2 or F12
2. **Enable Network Boot**:
   - `Advanced > Integrated Devices > Network Interface Card: Enabled`
   - `Advanced > Integrated Devices > Network Card Option ROM: Enabled`
   - `Boot > Network Boot: Enabled`
   - `Boot > PXE Boot to LAN: Enabled`
3. **Set Boot Priority**: `Network/PXE` as first boot device
4. **Performance Settings**:
   - `Virtualization Technology: Enabled`
   - `Hyper-Threading: Enabled`
   - `CPU Power Management: Performance`

### Phase 2: PXE Server Setup ✓
**Set up your 48GB T7500 as PXE server:**

```bash
# Run the automated setup script
sudo ./scripts/setup-pxe-server.sh

# This configures:
# - DHCP/TFTP (dnsmasq)
# - HTTP server (Apache)
# - Downloads Fedora CoreOS
# - Creates PXE boot environment
```

### Phase 3: Generate Ignition Configs ✓
**Create node-specific configurations:**

```bash
# Edit your SSH public key in the script first
vim scripts/generate-t7500-ignition.sh

# Generate configs for all nodes
sudo ./scripts/generate-t7500-ignition.sh

# This creates configurations for:
# - t7500-01, t7500-02, t7500-03 (standard nodes)
# - t7500-04 (high-memory node with special optimizations)
```

## Hardware-Specific Configurations

### Standard T7500 Nodes (t7500-01 through t7500-03)
**Storage Layout:**
```
/dev/sda1: 512MB  [/boot/efi]     FAT32
/dev/sda2: 1GB    [/boot]         XFS
/dev/sda3: Rest   [LVM PV]        → coreos-vg
  ├── root-lv   40GB [/]          XFS
  ├── var-lv    30GB [/var]       XFS
  ├── home-lv   10GB [/home]      XFS
  └── tmp-lv    10GB [/tmp]       XFS
```

**Network Configuration:**
- Static IP addresses (192.168.2.101-103)
- Gigabit Ethernet optimizations
- Container networking ready

### High-Memory T7500 (t7500-04 - 293GB RAM)
**Enhanced Storage Layout:**
```
Primary Disk (/dev/sda): System volumes
Secondary Disk (/dev/sdb): Container workload storage
  └── storage-vg
      ├── containers-lv  200GB [/var/lib/containers]  XFS
      ├── logs-lv        50GB  [/var/log/containers]  XFS
      └── data-lv        100GB [/opt/data]            XFS
```

**Memory Optimizations:**
- Hugepages configuration (2048 pages)
- NUMA optimization for dual-CPU architecture
- Memory overcommit tuning
- Swappiness reduced to 1

## Storage Expansion Commands

### Expand Root Filesystem
```bash
# Add new disk to volume group
pvcreate /dev/sdc
vgextend coreos-vg /dev/sdc

# Extend logical volume
lvextend -L +50G /dev/mapper/coreos--vg-root--lv

# Grow filesystem online
xfs_growfs /

# Verify expansion
df -h /
```

### Add New Storage Volume
```bash
# Create new logical volume
lvcreate -L 100G -n new-volume-lv coreos-vg

# Format with XFS
mkfs.xfs /dev/mapper/coreos--vg-new--volume--lv

# Mount permanently
echo '/dev/mapper/coreos--vg-new--volume--lv /mnt/new-volume xfs defaults,noatime 0 2' >> /etc/fstab
mkdir /mnt/new-volume
mount /mnt/new-volume
```

## Network Configuration Details

### IP Address Assignments
| Node | IP Address | RAM | Role |
|------|------------|-----|------|
| t7500-01 | 192.168.2.101 | Standard | Worker |
| t7500-02 | 192.168.2.102 | Standard | Worker |
| t7500-03 | 192.168.2.103 | Standard | Worker |
| t7500-04 | 192.168.2.104 | 293GB | High-Memory Worker |
| PXE Server | 192.168.2.100 | 48GB | Infrastructure |

### MAC Address Collection
**You need to collect MAC addresses from each T7500:**
```bash
# From PXE boot screen, note the MAC address displayed
# Update these in scripts/setup-pxe-server.sh:

declare -A NODE_MACS=(
    ["t7500-01"]="XX:XX:XX:XX:XX:01"  # Replace with actual MAC
    ["t7500-02"]="XX:XX:XX:XX:XX:02"  # Replace with actual MAC
    ["t7500-03"]="XX:XX:XX:XX:XX:03"  # Replace with actual MAC
    ["t7500-04"]="XX:XX:XX:XX:XX:04"  # Replace with actual MAC
)
```

## Deployment Process

### 1. Prepare PXE Server (48GB T7500)
```bash
# Install and configure PXE services
sudo ./scripts/setup-pxe-server.sh

# Generate Ignition configurations
sudo ./scripts/generate-t7500-ignition.sh

# Start services
sudo systemctl start dnsmasq httpd
sudo systemctl enable dnsmasq httpd
```

### 2. Deploy First Node (Test)
1. Configure BIOS on one T7500 for PXE boot
2. Connect to network and power on
3. Watch for PXE boot sequence
4. Monitor CoreOS installation process
5. Verify LVM + XFS setup after reboot

### 3. Deploy Remaining Nodes
- Repeat process for remaining T7500s
- Monitor deployment logs on PXE server
- Verify cluster network connectivity

## Post-Deployment Verification

### Check LVM Status
```bash
# Physical volumes
sudo pvs

# Volume groups
sudo vgs

# Logical volumes
sudo lvs

# Filesystem status
df -h
```

### Verify Network Configuration
```bash
# Check IP assignment
ip addr show

# Test cluster connectivity
ping t7500-01.cluster.local
ping t7500-02.cluster.local
ping t7500-03.cluster.local
ping t7500-04.cluster.local
```

### Container Runtime Check
```bash
# Verify CRI-O is running
sudo systemctl status crio

# Check container storage
sudo podman system info
```

## Troubleshooting

### Common PXE Boot Issues

**"PXE-E53: No boot filename received"**
- Check DHCP server configuration
- Verify `next-server` and `filename` options

**"PXE-E51: No DHCP offers received"**
- Check network cable connections
- Verify DHCP service is running

**Network card not detected in BIOS**
- Update network card firmware
- Check PCIe slot connections

### Storage Issues

**LVM volumes not created**
- Check `/var/log/messages` for LVM errors
- Verify disk partitioning completed correctly
- Re-run setup scripts manually if needed

**XFS filesystem errors**
- Use `xfs_repair` to fix corruption
- Check disk health with SMART tools

## Performance Tuning

### High-Memory Node (293GB)
```bash
# Verify hugepages configuration
cat /proc/meminfo | grep Huge

# Check NUMA topology
numactl --hardware

# Monitor memory usage
free -h
```

### All Nodes
```bash
# Container performance
sudo podman system df

# Disk I/O performance
iostat -x 1

# Network performance
iftop -i eth0
```

## Next Steps: OKD Cluster Deployment

Once all T7500 nodes are running CoreOS with LVM + XFS:

1. **Install OKD**: Deploy cluster components
2. **Configure CNI**: Set up pod networking
3. **Storage Classes**: Configure persistent volume provisioning
4. **Monitoring**: Deploy Prometheus + Grafana
5. **Workloads**: Deploy container applications

## Key Benefits of This Setup

✅ **Expandable Storage**: LVM allows easy capacity expansion  
✅ **High Performance**: XFS optimized for container workloads  
✅ **Automated Deployment**: PXE + Ignition for consistent setup  
✅ **Memory Optimization**: Special tuning for 293GB node  
✅ **Container Ready**: Optimized for Kubernetes/OKD workloads  
✅ **Enterprise Features**: Snapshots, online resize, monitoring  

Your Dell T7500 cluster will provide a robust foundation for containerized workloads with enterprise-grade storage management and the ability to expand as your needs grow!