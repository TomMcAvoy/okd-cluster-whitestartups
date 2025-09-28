#!/bin/bash
# PXE Server Setup Script for T7500 Cluster
# Configures DHCP, TFTP, and HTTP services for Fedora CoreOS deployment

set -euo pipefail

# Configuration
PXE_SERVER_IP="192.168.2.100"  # Adjust to your network
NETWORK_RANGE="192.168.2.0"
NETMASK="255.255.255.0"
GATEWAY="192.168.2.1"
DNS_SERVER="192.168.2.1"

# T7500 Node Configuration
declare -A NODES=(
    ["t7500-01"]="192.168.2.101"
    ["t7500-02"]="192.168.2.102"
    ["t7500-03"]="192.168.2.103"
    ["t7500-04"]="192.168.2.104"  # The 293GB memory node
)

# MAC addresses - you'll need to collect these from each T7500
declare -A NODE_MACS=(
    ["t7500-01"]="00:11:22:33:44:01"
    ["t7500-02"]="00:11:22:33:44:02"
    ["t7500-03"]="00:11:22:33:44:03"
    ["t7500-04"]="00:11:22:33:44:04"
)

# Directories
PXE_ROOT="/srv/pxe"
TFTP_ROOT="$PXE_ROOT/tftp"
HTTP_ROOT="$PXE_ROOT/http"
CONFIG_ROOT="$PXE_ROOT/configs"

echo "Setting up PXE server for Fedora CoreOS deployment..."

# Install required packages
install_packages() {
    echo "Installing PXE server packages..."
    if command -v dnf &> /dev/null; then
        sudo dnf install -y dnsmasq httpd wget curl
    elif command -v yum &> /dev/null; then
        sudo yum install -y dnsmasq httpd wget curl
    else
        echo "Package manager not supported"
        exit 1
    fi
}

# Create directory structure
setup_directories() {
    echo "Creating PXE directory structure..."
    sudo mkdir -p "$TFTP_ROOT"/{pxelinux.cfg,images/coreos}
    sudo mkdir -p "$HTTP_ROOT"/{coreos,ignition}
    sudo mkdir -p "$CONFIG_ROOT"
    sudo chown -R apache:apache "$HTTP_ROOT"
}

# Download Fedora CoreOS
download_coreos() {
    echo "Downloading Fedora CoreOS..."
    
    # Get latest stable release
    COREOS_STREAM="stable"
    COREOS_URL="https://builds.coreos.fedoraproject.org/streams/${COREOS_STREAM}.json"
    
    # Download release metadata
    curl -s "$COREOS_URL" > /tmp/coreos-release.json
    
    # Extract URLs for PXE files
    KERNEL_URL=$(jq -r '.architectures.x86_64.artifacts.metal.formats.pxe.kernel.location' /tmp/coreos-release.json)
    INITRD_URL=$(jq -r '.architectures.x86_64.artifacts.metal.formats.pxe.initramfs.location' /tmp/coreos-release.json)
    ROOTFS_URL=$(jq -r '.architectures.x86_64.artifacts.metal.formats.pxe.rootfs.location' /tmp/coreos-release.json)
    
    # Download CoreOS PXE files
    sudo wget -O "$TFTP_ROOT/images/coreos/vmlinuz" "$KERNEL_URL"
    sudo wget -O "$TFTP_ROOT/images/coreos/initrd.img" "$INITRD_URL"
    sudo wget -O "$HTTP_ROOT/coreos/coreos.cpio.xz" "$ROOTFS_URL"
    
    echo "CoreOS files downloaded successfully"
}

# Configure DHCP/TFTP with dnsmasq
setup_dnsmasq() {
    echo "Configuring dnsmasq for DHCP/TFTP..."
    
    sudo tee /etc/dnsmasq.conf > /dev/null <<EOF
# Interface configuration
interface=eth0
bind-interfaces

# DHCP configuration
dhcp-range=$NETWORK_RANGE,static,infinite
dhcp-option=option:router,$GATEWAY
dhcp-option=option:dns-server,$DNS_SERVER

# PXE/TFTP configuration
enable-tftp
tftp-root=$TFTP_ROOT
dhcp-boot=pxelinux.0

# Static IP assignments for T7500 nodes
EOF

    # Add static DHCP reservations for each node
    for node in "${!NODES[@]}"; do
        echo "dhcp-host=${NODE_MACS[$node]},${NODES[$node]},$node,infinite" | sudo tee -a /etc/dnsmasq.conf
    done
}

# Setup PXE boot menu
setup_pxe_menu() {
    echo "Setting up PXE boot menu..."
    
    # Copy syslinux files (assuming syslinux is installed)
    sudo cp /usr/share/syslinux/{pxelinux.0,menu.c32,ldlinux.c32} "$TFTP_ROOT/"
    
    # Create default PXE menu
    sudo tee "$TFTP_ROOT/pxelinux.cfg/default" > /dev/null <<EOF
DEFAULT menu.c32
PROMPT 0
TIMEOUT 300

MENU TITLE T7500 Cluster PXE Boot Menu

LABEL coreos-install
    MENU LABEL Install Fedora CoreOS
    KERNEL images/coreos/vmlinuz
    APPEND initrd=images/coreos/initrd.img coreos.inst.install_dev=/dev/sda coreos.inst.image_url=http://$PXE_SERVER_IP/coreos/coreos.cpio.xz coreos.inst.ignition_url=http://$PXE_SERVER_IP/ignition/CONFIG_FILE.ign

LABEL local
    MENU LABEL Boot from local disk
    LOCALBOOT 0
EOF
}

# Generate Ignition configurations
generate_ignition_configs() {
    echo "Generating Ignition configurations..."
    
    # Base configuration for all nodes
    cat > "$CONFIG_ROOT/base-config.yml" <<EOF
variant: fcos
version: 1.4.0
passwd:
  users:
    - name: core
      ssh_authorized_keys:
        - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC... # Add your SSH public key here
      groups:
        - sudo
        - docker
storage:
  files:
    - path: /etc/hostname
      mode: 0644
      contents:
        inline: NODE_NAME
    - path: /etc/systemd/resolved.conf
      mode: 0644
      contents:
        inline: |
          [Resolve]
          DNS=$DNS_SERVER
          Domains=cluster.local
systemd:
  units:
    - name: docker.service
      enabled: true
    - name: kubelet.service
      enabled: false  # Will be enabled during OKD setup
EOF

    # Generate node-specific configs
    for node in "${!NODES[@]}"; do
        # Create node-specific configuration
        sed "s/NODE_NAME/$node/g" "$CONFIG_ROOT/base-config.yml" > "$CONFIG_ROOT/$node.yml"
        
        # Special configuration for high-memory node (t7500-04)
        if [ "$node" == "t7500-04" ]; then
            cat >> "$CONFIG_ROOT/$node.yml" <<EOF
            
# High-memory node specific configuration
storage:
  files:
    - path: /etc/sysctl.d/99-hugepages.conf
      mode: 0644
      contents:
        inline: |
          # Enable huge pages for high-performance workloads
          vm.nr_hugepages=1024
          vm.hugetlb_shm_group=0
EOF
        fi
        
        # Convert YAML to Ignition JSON using fcct (if available)
        if command -v fcct &> /dev/null; then
            fcct --pretty --strict < "$CONFIG_ROOT/$node.yml" > "$HTTP_ROOT/ignition/$node.ign"
            echo "Generated Ignition config for $node"
        else
            echo "Warning: fcct not found. You'll need to convert YAML to Ignition format manually"
            echo "Install fcct: https://github.com/coreos/fcct/releases"
        fi
    done
}

# Configure HTTP server
setup_http_server() {
    echo "Configuring HTTP server..."
    
    # Apache configuration for PXE files
    sudo tee /etc/httpd/conf.d/pxe.conf > /dev/null <<EOF
<Directory "$HTTP_ROOT">
    Options Indexes FollowSymLinks
    AllowOverride None
    Require all granted
</Directory>

Alias /coreos "$HTTP_ROOT/coreos"
Alias /ignition "$HTTP_ROOT/ignition"
EOF

    # Enable and start Apache
    sudo systemctl enable httpd
    sudo systemctl start httpd
    
    # Open firewall ports
    if command -v firewall-cmd &> /dev/null; then
        sudo firewall-cmd --permanent --add-service=http
        sudo firewall-cmd --permanent --add-service=dhcp
        sudo firewall-cmd --permanent --add-service=tftp
        sudo firewall-cmd --reload
    fi
}

# Node-specific PXE configs
create_node_pxe_configs() {
    echo "Creating node-specific PXE configurations..."
    
    for node in "${!NODES[@]}"; do
        # Convert MAC address to PXE filename format
        pxe_mac=$(echo "${NODE_MACS[$node]}" | tr ':' '-' | tr '[:upper:]' '[:lower:]')
        pxe_file="01-$pxe_mac"
        
        # Create node-specific PXE config
        sudo tee "$TFTP_ROOT/pxelinux.cfg/$pxe_file" > /dev/null <<EOF
DEFAULT coreos-install

LABEL coreos-install
    KERNEL images/coreos/vmlinuz
    APPEND initrd=images/coreos/initrd.img coreos.inst.install_dev=/dev/sda coreos.inst.image_url=http://$PXE_SERVER_IP/coreos/coreos.cpio.xz coreos.inst.ignition_url=http://$PXE_SERVER_IP/ignition/$node.ign console=tty0 console=ttyS0,115200n8
EOF
        
        echo "Created PXE config for $node (MAC: ${NODE_MACS[$node]})"
    done
}

# Main setup function
main() {
    echo "Starting PXE server setup for T7500 cluster..."
    
    install_packages
    setup_directories
    download_coreos
    setup_dnsmasq
    setup_pxe_menu
    generate_ignition_configs
    setup_http_server
    create_node_pxe_configs
    
    # Start services
    sudo systemctl enable dnsmasq
    sudo systemctl start dnsmasq
    
    echo "PXE server setup complete!"
    echo ""
    echo "Next steps:"
    echo "1. Update MAC addresses in the script for your actual T7500 hardware"
    echo "2. Add your SSH public key to the Ignition configurations"
    echo "3. Configure T7500 BIOS for network boot"
    echo "4. Test PXE boot with one node first"
    echo ""
    echo "Server endpoints:"
    echo "  TFTP: $PXE_SERVER_IP:69"
    echo "  HTTP: http://$PXE_SERVER_IP/coreos/ (CoreOS images)"
    echo "  HTTP: http://$PXE_SERVER_IP/ignition/ (Ignition configs)"
    echo ""
    echo "Monitor logs:"
    echo "  sudo journalctl -u dnsmasq -f"
    echo "  sudo journalctl -u httpd -f"
}

# Run main function
main "$@"