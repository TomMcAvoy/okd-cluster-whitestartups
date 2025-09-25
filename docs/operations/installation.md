# OKD Cluster Installation Guide

This guide walks you through the complete installation and configuration of an OKD cluster using DevSecOps best practices.

## Prerequisites

### Hardware Requirements
- **VMware vSphere/Fusion Environment**
- **Minimum Resources:**
  - Bootstrap node: 4 vCPUs, 8GB RAM, 80GB disk
  - Master nodes (3): 4 vCPUs, 16GB RAM, 120GB disk each
  - Worker nodes (2+): 4 vCPUs, 16GB RAM, 200GB disk each
  - Load balancer: 2 vCPUs, 4GB RAM, 40GB disk

### Software Requirements
- VMware vSphere 7.0+ or VMware Fusion Pro 13+
- Terraform 1.6+
- Ansible 7.0+
- HashiCorp Vault
- Docker and Docker Compose
- PowerShell Core (for PowerCLI)
- Git

## Installation Steps

### Step 1: Environment Setup

1. **Clone the Repository**
   ```bash
   git clone https://github.com/TomMcAvoy/okd-cluster-whitestartups.git
   cd okd-cluster-whitestartups
   ```

2. **Configure Environment Variables**
   ```bash
   cp terraform/environments/example.tfvars terraform/environments/dev.tfvars
   # Edit dev.tfvars with your specific configuration
   ```

3. **Generate SSH Keys**
   ```bash
   ssh-keygen -t rsa -b 4096 -C "okd-cluster" -f ~/.ssh/okd-cluster-key
   # Add public key to dev.tfvars
   ```

### Step 2: HashiCorp Services Setup

1. **Start Supporting Services**
   ```bash
   cd docker
   docker-compose -f compose/hashicorp-services.yml up -d
   ```

2. **Configure Vault**
   ```bash
   export VAULT_ADDR="http://localhost:8200"
   export VAULT_TOKEN="okd-dev-root-token"
   
   # Create secrets
   vault kv put secret/okd/vsphere \
     server="vcenter.example.com" \
     username="administrator@vsphere.local" \
     password="your-password"
   ```

### Step 3: Fedora CoreOS Template Creation

1. **Download and Create Template**
   ```bash
   cd vmware/scripts
   export VCENTER_SERVER="vcenter.example.com"
   export VCENTER_USER="administrator@vsphere.local"
   export VCENTER_PASSWORD="your-password"
   
   ./create-fcos-template.sh
   ```

### Step 4: Infrastructure Provisioning

1. **Initialize Terraform**
   ```bash
   cd terraform
   terraform init
   ```

2. **Plan Infrastructure**
   ```bash
   terraform plan -var-file=environments/dev.tfvars
   ```

3. **Apply Infrastructure**
   ```bash
   terraform apply -var-file=environments/dev.tfvars
   ```

### Step 5: OKD Installation

1. **Generate Ignition Configs**
   ```bash
   cd ansible
   ansible-playbook -i inventory/dev playbooks/generate-ignition.yml
   ```

2. **Install OKD Cluster**
   ```bash
   ansible-playbook -i inventory/dev playbooks/site.yml
   ```

3. **Wait for Installation**
   ```bash
   # Monitor bootstrap process
   openshift-install wait-for bootstrap-complete --dir=./okd-config
   
   # Monitor cluster installation
   openshift-install wait-for install-complete --dir=./okd-config
   ```

### Step 6: Post-Installation Configuration

1. **Configure Authentication**
   ```bash
   ansible-playbook -i inventory/dev playbooks/post-install.yml --tags auth
   ```

2. **Install Security Policies**
   ```bash
   oc apply -f security/policies/
   ```

3. **Setup Monitoring**
   ```bash
   ansible-playbook -i inventory/dev playbooks/monitoring.yml
   ```

## Verification

1. **Check Cluster Status**
   ```bash
   oc get nodes
   oc get co  # cluster operators
   oc get pods --all-namespaces
   ```

2. **Access Web Console**
   - URL: https://console-openshift-console.apps.okd-dev.dev.whitestartups.local
   - Use kubeadmin credentials from install output

3. **Verify Security Policies**
   ```bash
   oc get constrainttemplates
   oc get k8srequiredsecuritycontext
   ```

## Troubleshooting

### Common Issues

1. **Bootstrap Timeout**
   - Check network connectivity
   - Verify DNS resolution
   - Review bootstrap logs: `ssh core@bootstrap-ip journalctl -f`

2. **Certificate Errors**
   - Verify NTP synchronization
   - Check certificate validity dates
   - Regenerate certificates if needed

3. **Network Issues**
   - Verify DHCP/static IP configuration
   - Check firewall rules
   - Validate load balancer configuration

### Log Locations

- **Bootstrap logs**: `/var/log/bootstrap.log`
- **Master logs**: `journalctl -u kubelet`
- **Installation logs**: `~/.openshift_install.log`

## Security Hardening

1. **Enable Pod Security Standards**
   ```bash
   oc label namespace default pod-security.kubernetes.io/enforce=restricted
   ```

2. **Configure Network Policies**
   ```bash
   oc apply -f security/network-policies/
   ```

3. **Setup RBAC**
   ```bash
   ansible-playbook -i inventory/dev playbooks/rbac-config.yml
   ```

## Backup and Recovery

1. **Cluster Backup**
   ```bash
   ansible-playbook -i inventory/dev playbooks/backup.yml
   ```

2. **Disaster Recovery**
   - Follow the disaster recovery procedures in `/docs/operations/disaster-recovery.md`

## Monitoring and Alerting

- **Prometheus**: http://localhost:9090
- **Grafana**: http://localhost:3000 (admin/admin123)
- **OKD Console**: Check cluster monitoring tab

For detailed troubleshooting, see [Troubleshooting Guide](troubleshooting.md).