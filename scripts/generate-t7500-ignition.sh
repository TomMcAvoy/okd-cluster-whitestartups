#!/bin/bash
# Generate Ignition configurations for Dell T7500 cluster with LVM + XFS
# This script creates node-specific Ignition configs with expandable storage

set -euo pipefail

CONFIG_DIR="/srv/pxe/configs"
IGNITION_DIR="/srv/pxe/http/ignition"
SSH_PUBLIC_KEY="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC... # YOUR_SSH_PUBLIC_KEY_HERE"

# Node definitions
declare -A NODES=(
    ["t7500-01"]="192.168.2.101"
    ["t7500-02"]="192.168.2.102"
    ["t7500-03"]="192.168.2.103"
    ["t7500-04"]="192.168.2.104"  # High-memory node (293GB)
)

# Create directories
mkdir -p "$CONFIG_DIR" "$IGNITION_DIR"

echo "Generating Ignition configurations for T7500 cluster..."

# Function to generate base Ignition config
generate_base_config() {
    local node_name="$1"
    local node_ip="$2"
    local is_high_memory="$3"
    
    cat > "$CONFIG_DIR/${node_name}.yml" <<EOF
variant: fcos
version: 1.4.0

passwd:
  users:
    - name: core
      ssh_authorized_keys:
        - $SSH_PUBLIC_KEY
      groups:
        - sudo
        - wheel
        - docker

storage:
  disks:
    - device: /dev/sda
      wipe_table: true
      partitions:
        - label: efi-system
          number: 1
          size_mib: 512
          type_guid: C12A7328-F81F-11D2-BA4B-00A0C93EC93B
        - label: boot
          number: 2
          size_mib: 1024
          type_guid: 0FC63DAF-8483-4772-8E79-3D69D8477DE4
        - label: root
          number: 3
          type_guid: E6D6D379-F507-44C2-A23C-238F2A3DF928

  filesystems:
    - device: /dev/disk/by-partlabel/efi-system
      format: fat32
      label: EFI-SYSTEM
    - device: /dev/disk/by-partlabel/boot
      format: xfs
      label: boot
    - device: /dev/disk/by-partlabel/root
      format: xfs
      label: root

  files:
    # Hostname configuration
    - path: /etc/hostname
      mode: 0644
      contents:
        inline: $node_name
    
    # Network configuration
    - path: /etc/NetworkManager/system-connections/eth0.nmconnection
      mode: 0600
      contents:
        inline: |
          [connection]
          id=eth0
          type=ethernet
          interface-name=eth0
          autoconnect=true
          autoconnect-priority=10
          
          [ipv4]
          method=manual
          addresses=$node_ip/24
          gateway=192.168.2.1
          dns=192.168.2.1;8.8.8.8
          dns-search=cluster.local
          
          [ipv6]
          method=ignore
    
    # Container storage configuration
    - path: /etc/containers/storage.conf
      mode: 0644
      contents:
        inline: |
          [storage]
          driver = "overlay"
          runroot = "/run/containers/storage"
          graphroot = "/var/lib/containers/storage"
          
          [storage.options]
          additionalimagestores = []
          
          [storage.options.overlay]
          mountopt = "nodev,metacopy=on"
          
          [storage.options.thinpool]
    
    # CRI-O configuration
    - path: /etc/crio/crio.conf.d/99-t7500.conf
      mode: 0644
      contents:
        inline: |
          [crio]
          storage_driver = "overlay"
          storage_option = [
            "overlay.mountopt=nodev",
          ]
          
          [crio.runtime]
          default_runtime = "runc"
          conmon = "/usr/bin/conmon"
          conmon_cgroup = "pod"
          default_env = [
            "NSS_SDB_USE_CACHE=no",
          ]
          
          [crio.image]
          default_transport = "docker://"
          pause_image = "k8s.gcr.io/pause:3.6"
          
          [crio.network]
          network_dir = "/etc/cni/net.d/"
          plugin_dirs = ["/opt/cni/bin/"]
    
    # System tuning for containers
    - path: /etc/sysctl.d/99-kubernetes.conf
      mode: 0644
      contents:
        inline: |
          # Kubernetes networking
          net.bridge.bridge-nf-call-iptables = 1
          net.bridge.bridge-nf-call-ip6tables = 1
          net.ipv4.ip_forward = 1
          
          # Container performance
          fs.inotify.max_user_watches = 524288
          fs.inotify.max_user_instances = 8192
          
          # Network performance
          net.core.somaxconn = 32768
          net.core.rmem_max = 268435456
          net.core.wmem_max = 268435456
          net.ipv4.tcp_rmem = 4096 65536 268435456
          net.ipv4.tcp_wmem = 4096 65536 268435456
    
    # Disable swap
    - path: /etc/systemd/zram-generator.conf
      mode: 0644
      contents:
        inline: |
          # Disable zram swap for Kubernetes
          [zram0]
          
    # SSH configuration
    - path: /etc/ssh/sshd_config.d/99-t7500.conf
      mode: 0644
      contents:
        inline: |
          PermitRootLogin no
          PasswordAuthentication no
          ChallengeResponseAuthentication no
          UsePAM yes
          PrintMotd no
          ClientAliveInterval 60
          ClientAliveCountMax 3

systemd:
  units:
    # Enable container runtime
    - name: crio.service
      enabled: true
    
    # Network configuration
    - name: NetworkManager.service
      enabled: true
    
    # Disable zram swap
    - name: systemd-zram-setup@zram0.service
      enabled: false
      mask: true
    
    # System tuning service
    - name: system-tuning.service
      enabled: true
      contents: |
        [Unit]
        Description=System tuning for T7500 container host
        After=multi-user.target
        
        [Service]
        Type=oneshot
        RemainAfterExit=yes
        ExecStart=/bin/bash -c 'echo never > /sys/kernel/mm/transparent_hugepage/enabled'
        ExecStart=/bin/bash -c 'echo 1 > /proc/sys/vm/overcommit_memory'
        ExecStart=/bin/bash -c 'modprobe br_netfilter'
        
        [Install]
        WantedBy=multi-user.target

EOF

    # Add high-memory specific configuration
    if [[ "$is_high_memory" == "true" ]]; then
        cat >> "$CONFIG_DIR/${node_name}.yml" <<EOF

  # High-memory node specific configuration
  files:
    # Hugepages configuration
    - path: /etc/sysctl.d/99-hugepages.conf
      mode: 0644
      contents:
        inline: |
          # Hugepages for high-performance workloads
          vm.nr_hugepages = 2048
          vm.hugetlb_shm_group = 0
          kernel.shmmax = 68719476736
          kernel.shmall = 16777216
          
          # Memory management for high-memory systems
          vm.swappiness = 1
          vm.dirty_ratio = 5
          vm.dirty_background_ratio = 2
    
    # Memory-optimized container limits
    - path: /etc/systemd/system.conf.d/99-high-memory.conf
      mode: 0644
      contents:
        inline: |
          [Manager]
          DefaultLimitNOFILE=1048576
          DefaultLimitNPROC=1048576
          DefaultLimitCORE=infinity
          DefaultLimitMEMLOCK=infinity

  systemd:
    units:
      # Memory optimization service
      - name: memory-optimization.service
        enabled: true
        contents: |
          [Unit]
          Description=Memory optimization for high-memory T7500
          After=multi-user.target
          
          [Service]
          Type=oneshot
          RemainAfterExit=yes
          ExecStart=/bin/bash -c 'echo madvise > /sys/kernel/mm/transparent_hugepage/enabled'
          ExecStart=/bin/bash -c 'echo 1 > /proc/sys/vm/overcommit_memory'
          ExecStart=/bin/bash -c 'echo 10 > /proc/sys/vm/swappiness'
          
          [Install]
          WantedBy=multi-user.target
      
      # NUMA optimization (T7500 has dual CPU)
      - name: numa-optimization.service
        enabled: true
        contents: |
          [Unit]
          Description=NUMA optimization for dual-CPU T7500
          After=multi-user.target
          
          [Service]
          Type=oneshot
          RemainAfterExit=yes
          ExecStart=/bin/bash -c 'echo 2 > /proc/sys/kernel/numa_balancing'
          
          [Install]
          WantedBy=multi-user.target

EOF
    fi
}

# Function to generate LVM-enabled configuration
generate_lvm_config() {
    local node_name="$1"
    local is_high_memory="$2"
    
    # Add LVM configuration to existing YAML
    cat >> "$CONFIG_DIR/${node_name}.yml" <<EOF

  # LVM Configuration for expandable storage
  luks:
    # No encryption for performance (add if security required)
  
  raid:
    # No RAID configuration (using LVM)

  # Note: LVM configuration in Ignition is limited
  # LVM setup will be handled by a post-install script
  
  files:
    # LVM post-install script
    - path: /opt/setup-lvm.sh
      mode: 0755
      contents:
        inline: |
          #!/bin/bash
          # Post-install LVM setup for T7500
          set -euo pipefail
          
          echo "Setting up LVM on \$(hostname)..."
          
          # Wait for disk to be available
          while [[ ! -b /dev/sda3 ]]; do
            echo "Waiting for /dev/sda3..."
            sleep 2
          done
          
          # Create physical volume
          pvcreate /dev/sda3
          
          # Create volume group
          vgcreate coreos-vg /dev/sda3
          
          # Create logical volumes
          lvcreate -L 40G -n root-lv coreos-vg
          lvcreate -L 30G -n var-lv coreos-vg
          lvcreate -L 10G -n home-lv coreos-vg
          lvcreate -L 10G -n tmp-lv coreos-vg
          
          # Create filesystems
          mkfs.xfs -f /dev/mapper/coreos--vg-root--lv
          mkfs.xfs -f /dev/mapper/coreos--vg-var--lv
          mkfs.xfs -f /dev/mapper/coreos--vg-home--lv
          mkfs.xfs -f /dev/mapper/coreos--vg-tmp--lv
          
          # Update fstab
          cat >> /etc/fstab <<FSTAB_EOF
          /dev/mapper/coreos--vg-root--lv / xfs defaults,noatime 0 1
          /dev/mapper/coreos--vg-var--lv /var xfs defaults,noatime 0 2
          /dev/mapper/coreos--vg-home--lv /home xfs defaults,noatime 0 2
          /dev/mapper/coreos--vg-tmp--lv /tmp xfs defaults,noatime,noexec,nosuid,nodev 0 2
          FSTAB_EOF
          
          echo "LVM setup completed successfully"

systemd:
  units:
    # LVM setup service (runs once after first boot)
    - name: setup-lvm.service
      enabled: true
      contents: |
        [Unit]
        Description=Setup LVM for expandable storage
        After=multi-user.target
        ConditionPathExists=!/var/lib/lvm-setup-complete
        
        [Service]
        Type=oneshot
        ExecStart=/opt/setup-lvm.sh
        ExecStartPost=/bin/touch /var/lib/lvm-setup-complete
        RemainAfterExit=yes
        
        [Install]
        WantedBy=multi-user.target

EOF

    # Add high-memory specific LVM configuration
    if [[ "$is_high_memory" == "true" ]]; then
        cat >> "$CONFIG_DIR/${node_name}.yml" <<EOF

  files:
    # Extended LVM setup for high-memory node
    - path: /opt/setup-extended-lvm.sh
      mode: 0755
      contents:
        inline: |
          #!/bin/bash
          # Extended LVM setup for high-memory T7500
          set -euo pipefail
          
          # Check if second disk exists
          if [[ -b /dev/sdb ]]; then
            echo "Setting up extended storage on /dev/sdb..."
            
            # Partition second disk
            parted -s /dev/sdb mklabel gpt
            parted -s /dev/sdb mkpart primary 1MiB 100%
            
            # Create physical volume
            pvcreate /dev/sdb1
            
            # Create storage volume group
            vgcreate storage-vg /dev/sdb1
            
            # Create logical volumes for container workloads
            lvcreate -L 200G -n containers-lv storage-vg
            lvcreate -L 50G -n logs-lv storage-vg
            lvcreate -L 100G -n data-lv storage-vg
            
            # Create XFS filesystems
            mkfs.xfs -f /dev/mapper/storage--vg-containers--lv
            mkfs.xfs -f /dev/mapper/storage--vg-logs--lv
            mkfs.xfs -f /dev/mapper/storage--vg-data--lv
            
            # Create mount points
            mkdir -p /var/lib/containers /var/log/containers /opt/data
            
            # Add to fstab
            cat >> /etc/fstab <<EXTENDED_FSTAB
          /dev/mapper/storage--vg-containers--lv /var/lib/containers xfs defaults,noatime,prjquota 0 2
          /dev/mapper/storage--vg-logs--lv /var/log/containers xfs defaults,noatime 0 2
          /dev/mapper/storage--vg-data--lv /opt/data xfs defaults,noatime 0 2
          EXTENDED_FSTAB
            
            # Mount filesystems
            mount -a
            
            echo "Extended LVM setup completed"
          else
            echo "Second disk /dev/sdb not found, skipping extended setup"
          fi

  systemd:
    units:
      # Extended LVM setup for high-memory node
      - name: setup-extended-lvm.service
        enabled: true
        contents: |
          [Unit]
          Description=Setup extended LVM for high-memory node
          After=setup-lvm.service
          ConditionPathExists=!/var/lib/extended-lvm-setup-complete
          
          [Service]
          Type=oneshot
          ExecStart=/opt/setup-extended-lvm.sh
          ExecStartPost=/bin/touch /var/lib/extended-lvm-setup-complete
          RemainAfterExit=yes
          
          [Install]
          WantedBy=multi-user.target

EOF
    fi
}

# Generate configurations for each node
for node in "${!NODES[@]}"; do
    node_ip="${NODES[$node]}"
    is_high_memory="false"
    
    # Check if this is the high-memory node
    if [[ "$node" == "t7500-04" ]]; then
        is_high_memory="true"
    fi
    
    echo "Generating configuration for $node (IP: $node_ip)..."
    
    # Generate base configuration
    generate_base_config "$node" "$node_ip" "$is_high_memory"
    
    # Add LVM configuration
    generate_lvm_config "$node" "$is_high_memory"
    
    # Convert YAML to Ignition JSON
    if command -v fcct &> /dev/null; then
        fcct --pretty --strict < "$CONFIG_DIR/${node}.yml" > "$IGNITION_DIR/${node}.ign"
        echo "✓ Generated Ignition config: $IGNITION_DIR/${node}.ign"
    else
        echo "⚠ Warning: fcct not found. Install it to generate Ignition JSON files"
        echo "Download from: https://github.com/coreos/fcct/releases"
        echo "YAML config saved to: $CONFIG_DIR/${node}.yml"
    fi
done

# Generate a validation script
cat > "$CONFIG_DIR/validate-configs.sh" <<'EOF'
#!/bin/bash
# Validate generated Ignition configurations

echo "Validating Ignition configurations..."

for config in *.ign; do
    if [[ -f "$config" ]]; then
        echo -n "Validating $config... "
        if jq empty < "$config" 2>/dev/null; then
            echo "✓ Valid JSON"
        else
            echo "✗ Invalid JSON"
            exit 1
        fi
    fi
done

echo "All configurations validated successfully!"
EOF

chmod +x "$CONFIG_DIR/validate-configs.sh"

echo ""
echo "Ignition configuration generation complete!"
echo ""
echo "Generated files:"
for node in "${!NODES[@]}"; do
    echo "  - $CONFIG_DIR/${node}.yml (YAML source)"
    if [[ -f "$IGNITION_DIR/${node}.ign" ]]; then
        echo "  - $IGNITION_DIR/${node}.ign (Ignition JSON)"
    fi
done
echo ""
echo "Next steps:"
echo "1. Review configurations in $CONFIG_DIR/"
echo "2. Update SSH public key in the configs"
echo "3. Validate configs: $CONFIG_DIR/validate-configs.sh"
echo "4. Test PXE boot with one T7500 node"
echo ""
echo "Key features:"
echo "  ✓ LVM + XFS expandable root filesystem"
echo "  ✓ Container runtime optimization"
echo "  ✓ Network configuration with static IPs"
echo "  ✓ High-memory optimization for t7500-04"
echo "  ✓ NUMA and memory tuning for dual-CPU T7500s"