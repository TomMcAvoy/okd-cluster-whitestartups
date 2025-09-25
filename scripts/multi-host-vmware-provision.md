# Multi-Host VMware VM Provisioning & OKD Cluster Setup Guide

## 1. Plan Node Allocation
| Host         | RAM (GB) | VMs to Provision         | Suggested Roles         |
|--------------|----------|-------------------------|------------------------|
| MacBook Pro1 | 24       | 1x Control (12GB), 1x Worker (8GB) | Control, Worker       |
| MacBook Pro2 | 32       | 1x Control (12GB), 2x Worker (8GB) | Control, Workers      |
| MacBook Pro3 | 16       | 1x Worker (8GB)         | Worker                 |

## 2. Prepare Each Host
- Install VMware Fusion/Workstation
- Download Fedora CoreOS/OKD node image (VMDK)
- Clone this repo and copy `scripts/vmware-provision.sh` to each host
- Edit `VM_COUNT`, `VM_RAM_MB`, `VM_CPUS`, `FCOS_IMAGE`, and `VM_NAME_PREFIX` in the script for each host's allocation

## 3. Provision VMs
- Run `vmware-provision.sh` on each host to create and start VMs
- Assign static IPs or configure DHCP reservations for each VM
- Ensure all VMs are on the same network/subnet and can reach each other

## 4. Network Configuration
- Open required ports (API, etcd, SSH, mTLS, etc.) on host firewalls
- Test VM-to-VM connectivity (ping, SSH)

## 5. OKD Cluster Bootstrap
- On one host, run OKD installer and specify all VM IPs/hostnames in the install config
- Use `openshift-install` or OKD equivalent
- Distribute ignition files to each VM
- Start cluster bootstrap and monitor logs

## 6. Post-Install
- Validate all nodes join the cluster
- Configure mTLS, monitoring, and remediation as per automation scripts
- Run conformance and security tests

---

> For automation, you can extend `vmware-provision.sh` to accept remote host/SSH parameters and trigger provisioning on each MacBook. For advanced orchestration, consider Ansible or Terraform with remote execution.
