#!/bin/bash
# Script to update /etc/hosts with cluster node IPs and hostnames
# Usage: sudo bash update-etc-hosts.sh

set -e

# Define your cluster nodes here
NODES=(
  "192.168.2.38 macbook-pro1"
  "192.168.2.171 macbook-pro2"
  "192.168.2.173 macbook-pro3"
  # Add more nodes as needed
)

for entry in "${NODES[@]}"; do
  IP=$(echo "$entry" | awk '{print $1}')
  HOSTNAME=$(echo "$entry" | awk '{print $2}')
  if grep -q "$IP" /etc/hosts; then
    echo "$IP already exists in /etc/hosts. Skipping."
  else
    echo "Adding $IP $HOSTNAME to /etc/hosts."
    echo "$IP $HOSTNAME" | sudo tee -a /etc/hosts > /dev/null
  fi
  if grep -q "$HOSTNAME" /etc/hosts; then
    echo "$HOSTNAME already exists in /etc/hosts. Skipping."
  else
    echo "Adding $HOSTNAME to /etc/hosts."
    echo "$IP $HOSTNAME" | sudo tee -a /etc/hosts > /dev/null
  fi
  echo
done

echo "/etc/hosts update complete."
