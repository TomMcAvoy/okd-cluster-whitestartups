# Fedora CoreOS PXE Strategy for T7500 Cluster

## Hardware Overview
- **PXE Server**: T7500 with 48GB RAM (sufficient for DHCP/TFTP/HTTP services)
- **Target Nodes**: 4x T7500s including one with 293GB RAM
- **Network**: Assume 1Gbps networking between systems

## Why Fedora CoreOS vs Ubuntu Desktop

### Resource Efficiency
| Aspect | Fedora CoreOS | Ubuntu Desktop |
|--------|---------------|----------------|
| Base Memory Usage | ~300-500MB | ~1.5-2GB+ |
| Disk Footprint | ~2-3GB | ~10-15GB+ |
| Boot Time | ~30-60s | ~90-120s |
| Update Method | Atomic/Immutable | Package-based |
| Security Patching | Automatic | Manual |

### Container Runtime
```bash
# CoreOS includes optimized container stack
systemctl status crio      # Container Runtime Interface
systemctl status kubelet   # Kubernetes agent (when configured)
```

### Configuration Management
```yaml
# CoreOS uses Ignition for declarative configuration
# Example ignition config for PXE deployment:
variant: fcos
version: 1.4.0
passwd:
  users:
    - name: core
      ssh_authorized_keys:
        - ssh-rsa AAAA... # Your SSH key
systemd:
  units:
    - name: kubelet.service
      enabled: true
```

## PXE Server Architecture

### Services Required on 48GB T7500:
1. **DHCP Server** (dnsmasq or ISC DHCP)
2. **TFTP Server** (for boot files)
3. **HTTP Server** (for CoreOS images and Ignition configs)
4. **DNS Server** (optional, for cluster resolution)

### Network Boot Flow:
```
T7500 Node → PXE Boot → DHCP (IP + boot server)
         → TFTP (kernel + initrd)
         → HTTP (CoreOS image + Ignition config)
         → CoreOS Installation → OKD Node
```

### Storage Requirements:
- **CoreOS ISO**: ~1GB per architecture
- **Ignition Configs**: ~1KB per node
- **Additional Tools**: ~5GB total
- **Logs/Cache**: ~10GB recommended

## High-Memory Node Optimization (293GB System)

### Role Assignment:
```yaml
# Suggested roles for high-memory node:
- etcd: false          # etcd doesn't need massive memory
- worker: true         # Perfect for memory-intensive workloads
- infra: true          # Can handle logging/monitoring stacks
- storage: true        # Can run persistent volume provisioners
```

### Memory Allocation Strategy:
- **OS + System**: ~2GB
- **Kubernetes overhead**: ~4GB
- **Available for workloads**: ~287GB
- **Huge pages**: Consider enabling for high-performance applications

## Implementation Steps:

### Phase 1: PXE Server Setup (48GB T7500)
1. Install minimal Linux (CentOS Stream/RHEL/Fedora)
2. Configure network services (DHCP, TFTP, HTTP)
3. Download and prepare CoreOS images
4. Create Ignition configurations for each node role

### Phase 2: Node Provisioning
1. Configure BIOS for network boot on target T7500s
2. Boot nodes via PXE
3. Verify CoreOS installation and basic connectivity
4. Validate container runtime functionality

### Phase 3: OKD Cluster Bootstrap
1. Configure cluster networking
2. Deploy OKD control plane
3. Join worker nodes
4. Configure storage and networking CNI

## Advantages Summary:

### For PXE Server (48GB T7500):
- **Stability**: Immutable OS reduces configuration drift
- **Security**: Automatic updates with rollback capability
- **Maintenance**: Minimal manual intervention required

### For Cluster Nodes:
- **Consistency**: All nodes identical via Ignition configs
- **Performance**: Minimal OS overhead maximizes workload resources
- **Reliability**: Atomic updates prevent partial update failures
- **Security**: SELinux + container isolation by default

### For High-Memory Node (293GB):
- **Resource Maximization**: Minimal OS footprint leaves more RAM for workloads
- **Container Density**: Can run many more containers than Ubuntu Desktop
- **Performance**: No GUI overhead, all resources available for cluster workloads

## Next Steps:
1. Set up PXE server on 48GB T7500
2. Create Ignition configurations for different node roles
3. Test network boot process with one target T7500
4. Scale to remaining nodes once validated
5. Deploy OKD cluster components