# LVM + XFS Expandable Root Filesystem for CoreOS

## Overview
This guide configures Fedora CoreOS with LVM (Logical Volume Management) and XFS filesystem for expandable root storage on Dell T7500 systems.

## Why LVM + XFS for Container Hosts?

### LVM Advantages:
- **Dynamic Resizing**: Expand root filesystem without downtime
- **Snapshot Support**: Create backups before system updates
- **Multiple Disk Support**: Combine multiple drives into single logical volume
- **Thin Provisioning**: Allocate space as needed

### XFS Advantages:
- **Container Optimized**: Better performance for many small files
- **Online Resize**: Expand filesystem while mounted (grow only)
- **Large File Support**: Handles container images and logs efficiently
- **B+ Tree Structure**: Excellent for directory-heavy workloads

## Disk Layout Strategy for T7500

### Recommended Partition Scheme
```
/dev/sda (Primary Boot Disk - SSD recommended)
├── /dev/sda1    512MB   [/boot/efi]     FAT32    (UEFI boot)
├── /dev/sda2    1GB     [/boot]         XFS      (Boot partition)  
└── /dev/sda3    Rest    [LVM PV]        LVM      (Physical Volume)

Volume Group: coreos-vg
├── root-lv      30GB    [/]             XFS      (Root filesystem)
├── var-lv       20GB    [/var]          XFS      (Container storage)
├── home-lv      10GB    [/home]         XFS      (User data)
└── tmp-lv       5GB     [/tmp]          XFS      (Temporary files)
                 Free    Available for expansion
```

### For High-Capacity T7500 (with additional drives)
```
/dev/sda: System disk (as above)
/dev/sdb: Additional storage disk
/dev/sdc: Additional storage disk (if available)

Extended Volume Group: storage-vg
├── container-lv  100GB   [/var/lib/containers]  XFS
├── logs-lv       50GB    [/var/log]            XFS  
├── data-lv       Rest    [/opt/data]           XFS
```

## Ignition Configuration for LVM + XFS

### Base LVM Configuration
```yaml
# coreos-lvm-base.yml - Base configuration with LVM
variant: fcos
version: 1.4.0

storage:
  disks:
    - device: /dev/sda
      wipe_table: true
      partitions:
        - label: efi
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
    - device: /dev/sda1
      format: fat32
      label: EFI-SYSTEM
      path: /boot/efi
    - device: /dev/sda2
      format: xfs
      label: boot
      path: /boot

  # LVM Configuration
  lvm:
    volume_groups:
      - name: coreos-vg
        physical_volumes:
          - /dev/sda3
        logical_volumes:
          - name: root-lv
            size_mib: 30720  # 30GB
          - name: var-lv
            size_mib: 20480  # 20GB
          - name: home-lv
            size_mib: 10240  # 10GB
          - name: tmp-lv
            size_mib: 5120   # 5GB

  filesystems:
    - device: /dev/mapper/coreos--vg-root--lv
      format: xfs
      label: root
      path: /
      mount_options:
        - defaults
        - noatime
    - device: /dev/mapper/coreos--vg-var--lv
      format: xfs
      label: var
      path: /var
      mount_options:
        - defaults
        - noatime
    - device: /dev/mapper/coreos--vg-home--lv
      format: xfs
      label: home
      path: /home
      mount_options:
        - defaults
        - noatime
    - device: /dev/mapper/coreos--vg-tmp--lv
      format: xfs
      label: tmp
      path: /tmp
      mount_options:
        - defaults
        - noatime
        - noexec
        - nosuid
        - nodev

systemd:
  units:
    - name: var-lib-containers.mount
      enabled: true
      contents: |
        [Unit]
        Description=Container Storage Mount
        Before=multi-user.target
        
        [Mount]
        What=/dev/mapper/coreos--vg-var--lv
        Where=/var/lib/containers
        Type=xfs
        Options=defaults,noatime,prjquota
        
        [Install]
        WantedBy=multi-user.target

passwd:
  users:
    - name: core
      ssh_authorized_keys:
        - ssh-rsa AAAAB3NzaC1yc... # Your SSH public key
      groups:
        - sudo
        - wheel
```

### High-Memory T7500 Configuration (293GB system)
```yaml
# t7500-high-memory.yml - Configuration for 293GB T7500
variant: fcos
version: 1.4.0

storage:
  disks:
    - device: /dev/sda
      wipe_table: true
      partitions:
        - label: efi
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
    # Additional storage disk for container workloads
    - device: /dev/sdb
      wipe_table: true
      partitions:
        - label: storage
          number: 1
          type_guid: E6D6D379-F507-44C2-A23C-238F2A3DF928

  lvm:
    volume_groups:
      - name: coreos-vg
        physical_volumes:
          - /dev/sda3
        logical_volumes:
          - name: root-lv
            size_mib: 40960  # 40GB (larger for high-memory node)
          - name: var-lv
            size_mib: 30720  # 30GB
          - name: home-lv
            size_mib: 10240  # 10GB
          - name: tmp-lv
            size_mib: 10240  # 10GB (larger for memory dumps)
      
      - name: storage-vg
        physical_volumes:
          - /dev/sdb1
        logical_volumes:
          - name: containers-lv
            size_mib: 204800  # 200GB for container storage
          - name: logs-lv
            size_mib: 51200   # 50GB for logs
          - name: data-lv
            size_mib: 102400  # 100GB for application data

  files:
    # Hugepages configuration for high-memory workloads
    - path: /etc/sysctl.d/99-hugepages.conf
      mode: 0644
      contents:
        inline: |
          # Configure hugepages for high-performance applications
          vm.nr_hugepages = 2048
          vm.hugetlb_shm_group = 0
          kernel.shmmax = 68719476736
          kernel.shmall = 4294967296
    
    # Container runtime configuration
    - path: /etc/crio/crio.conf.d/99-storage.conf
      mode: 0644
      contents:
        inline: |
          [crio.runtime]
          default_runtime = "runc"
          
          [crio.image]
          default_transport = "docker://"
          
          [crio.storage]
          storage_driver = "overlay"
          storage_option = ["overlay.mount_program=/usr/bin/fuse-overlayfs"]

systemd:
  units:
    # Mount points for storage volumes
    - name: var-lib-containers.mount
      enabled: true
      contents: |
        [Unit]
        Description=Container Storage
        Before=crio.service
        
        [Mount]
        What=/dev/mapper/storage--vg-containers--lv
        Where=/var/lib/containers
        Type=xfs
        Options=defaults,noatime,prjquota
        
        [Install]
        WantedBy=multi-user.target
    
    - name: opt-data.mount
      enabled: true
      contents: |
        [Unit]
        Description=Application Data Storage
        
        [Mount]
        What=/dev/mapper/storage--vg-data--lv
        Where=/opt/data
        Type=xfs
        Options=defaults,noatime
        
        [Install]
        WantedBy=multi-user.target
    
    # Optimize for high-memory workloads
    - name: memory-optimization.service
      enabled: true
      contents: |
        [Unit]
        Description=Memory Optimization for High-Memory Node
        After=multi-user.target
        
        [Service]
        Type=oneshot
        RemainAfterExit=yes
        ExecStart=/bin/bash -c 'echo madvise > /sys/kernel/mm/transparent_hugepage/enabled'
        ExecStart=/bin/bash -c 'echo 10 > /proc/sys/vm/swappiness'
        
        [Install]
        WantedBy=multi-user.target
```

## Filesystem Expansion Commands

### Expanding Root Filesystem
```bash
# Add new physical disk to existing volume group
pvcreate /dev/sdc
vgextend coreos-vg /dev/sdc

# Extend logical volume (add 50GB)
lvextend -L +50G /dev/mapper/coreos--vg-root--lv

# Grow XFS filesystem online
xfs_growfs /

# Check new size
df -h /
```

### Expanding Container Storage
```bash
# Extend container storage volume
lvextend -L +100G /dev/mapper/storage--vg-containers--lv

# Grow XFS filesystem
xfs_growfs /var/lib/containers

# Verify expansion
df -h /var/lib/containers
```

### Adding New Storage Volumes
```bash
# Create new logical volume
lvcreate -L 200G -n backup-lv storage-vg

# Create XFS filesystem
mkfs.xfs /dev/mapper/storage--vg-backup--lv

# Create mount point
mkdir /opt/backup

# Add to fstab
echo '/dev/mapper/storage--vg-backup--lv /opt/backup xfs defaults,noatime 0 2' >> /etc/fstab

# Mount
mount /opt/backup
```

## Monitoring and Maintenance

### LVM Status Commands
```bash
# Physical Volume status
pvs
pvdisplay

# Volume Group status  
vgs
vgdisplay

# Logical Volume status
lvs
lvdisplay

# Filesystem usage
df -h
```

### XFS Maintenance Commands
```bash
# Check filesystem health
xfs_info /
xfs_db -r -c "check" /dev/mapper/coreos--vg-root--lv

# Defragment filesystem (if needed)
xfs_fsr /

# Repair filesystem (unmounted)
xfs_repair /dev/mapper/coreos--vg-root--lv
```

### Performance Monitoring
```bash
# I/O statistics
iostat -x 1

# Disk usage by directory
du -sh /var/lib/containers/*

# Container storage usage
podman system df
```

## Best Practices for T7500 Cluster

### 1. Storage Allocation Strategy
- **Boot Disk**: Fast SSD for OS and container images
- **Data Disks**: Larger SATA drives for persistent volumes
- **Leave 20% free space**: For LVM snapshots and expansion

### 2. XFS Optimization
```bash
# Mount options for container workloads
defaults,noatime,largeio,inode64,prjquota
```

### 3. LVM Snapshots for Updates
```bash
# Before major updates, create snapshot
lvcreate -L 5G -s -n root-backup /dev/mapper/coreos--vg-root--lv

# After successful update, remove snapshot
lvremove /dev/mapper/coreos--vg-root--backup
```

### 4. Container Storage Isolation
- Separate `/var/lib/containers` on dedicated LV
- Use project quotas to limit container storage
- Monitor container storage growth

This LVM + XFS setup provides maximum flexibility for your T7500 cluster, allowing you to expand storage as your container workloads grow while maintaining optimal performance.