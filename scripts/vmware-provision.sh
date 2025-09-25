#!/bin/bash
# VMware VM provisioning automation script for OKD cluster nodes
# Requires: VMware Fusion/Workstation CLI tools (vmrun), Fedora CoreOS image

set -e

# Configurable parameters
VM_COUNT=3
VM_NAME_PREFIX="okd-node"
VM_RAM_MB=4096
VM_CPUS=2
VM_DISK_GB=40
FCOS_IMAGE="/path/to/fedora-coreos.vmdk"
VMWARE_DIR="$HOME/vmware/okd-nodes"

mkdir -p "$VMWARE_DIR"

for i in $(seq 1 $VM_COUNT); do
  VM_NAME="$VM_NAME_PREFIX-$i"
  VM_PATH="$VMWARE_DIR/$VM_NAME/$VM_NAME.vmx"
  mkdir -p "$VMWARE_DIR/$VM_NAME"
  # Copy base VMDK image
  cp "$FCOS_IMAGE" "$VMWARE_DIR/$VM_NAME/${VM_NAME}.vmdk"
  # Create VMX config
  cat > "$VM_PATH" <<EOF
.encoding = "UTF-8"
config.version = "8"
virtualHW.version = "16"
guestOS = "otherlinux-64"
memsize = "$VM_RAM_MB"
numvcpus = "$VM_CPUS"
disks = "$VM_DISK_GB"
sata0:0.fileName = "${VM_NAME}.vmdk"
ethernet0.present = "TRUE"
ethernet0.connectionType = "nat"
EOF
  # Register and start VM
  vmrun -T fusion register "$VM_PATH"
  vmrun -T fusion start "$VM_PATH" nogui
  echo "Provisioned and started $VM_NAME at $VM_PATH"
done

echo "All VMware OKD nodes provisioned. Customize VMX/network as needed."
