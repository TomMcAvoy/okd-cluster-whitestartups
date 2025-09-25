#!/bin/bash
# Remote VMware VM provisioning script for multi-host OKD cluster
# Usage: ./remote-vmware-provision.sh <host> <user> <path-to-vmware-provision.sh> <fcos-image> <vm-count> <vm-ram> <vm-cpus> <vm-disk> <vm-name-prefix>

set -e

HOST="$1"
USER="$2"
PROVISION_SCRIPT="$3"
FCOS_IMAGE="$4"
VM_COUNT="$5"
VM_RAM_MB="$6"
VM_CPUS="$7"
VM_DISK_GB="$8"
VM_NAME_PREFIX="$9"

# Copy script and image to remote host
scp "$PROVISION_SCRIPT" "$USER@$HOST:~/vmware-provision.sh"
scp "$FCOS_IMAGE" "$USER@$HOST:~/fedora-coreos.vmdk"

# Run provisioning script remotely with parameters
ssh "$USER@$HOST" bash ~/vmware-provision.sh \
  "$VM_COUNT" "$VM_RAM_MB" "$VM_CPUS" "$VM_DISK_GB" "~/fedora-coreos.vmdk" "$VM_NAME_PREFIX"

echo "Provisioning triggered on $HOST for $VM_COUNT VMs."
