# OKD Cluster Infrastructure
# This Terraform configuration creates the infrastructure for OKD cluster on VMware

terraform {
  required_version = ">= 1.0"
  required_providers {
    vsphere = {
      source  = "hashicorp/vsphere"
      version = "~> 2.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
  
  # Backend configuration for state management
  backend "consul" {
    address = "vault.local:8500"
    scheme  = "http"
    path    = "terraform/okd-cluster"
  }
}

# Configure the vSphere Provider
provider "vsphere" {
  user                 = var.vsphere_user
  password             = var.vsphere_password
  vsphere_server       = var.vsphere_server
  allow_unverified_ssl = var.allow_unverified_ssl
}

# Data sources for vSphere resources
data "vsphere_datacenter" "dc" {
  name = var.datacenter
}

data "vsphere_datastore" "datastore" {
  name          = var.datastore
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_compute_cluster" "cluster" {
  name          = var.cluster
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_network" "network" {
  name          = var.network_name
  datacenter_id = data.vsphere_datacenter.dc.id
}

# Fedora CoreOS template
data "vsphere_virtual_machine" "fcos_template" {
  name          = var.fcos_template_name
  datacenter_id = data.vsphere_datacenter.dc.id
}

# Create bootstrap node
module "bootstrap_node" {
  source = "./modules/vm"
  
  name             = "${var.cluster_name}-bootstrap"
  resource_pool_id = data.vsphere_compute_cluster.cluster.resource_pool_id
  datastore_id     = data.vsphere_datastore.datastore.id
  
  num_cpus       = var.bootstrap_cpu
  memory         = var.bootstrap_memory
  guest_id       = data.vsphere_virtual_machine.fcos_template.guest_id
  scsi_type      = data.vsphere_virtual_machine.fcos_template.scsi_type
  firmware       = data.vsphere_virtual_machine.fcos_template.firmware
  
  network_interface = {
    network_id   = data.vsphere_network.network.id
    adapter_type = data.vsphere_virtual_machine.fcos_template.network_interface_types[0]
  }
  
  disk = {
    size             = var.bootstrap_disk_size
    thin_provisioned = true
  }
  
  clone = {
    template_uuid = data.vsphere_virtual_machine.fcos_template.id
  }
  
  extra_config = {
    "guestinfo.ignition.config.data"          = base64encode(data.ignition_config.bootstrap.rendered)
    "guestinfo.ignition.config.data.encoding" = "base64"
  }
  
  tags = var.common_tags
}

# Create master nodes
module "master_nodes" {
  source = "./modules/vm"
  count  = var.master_count
  
  name             = "${var.cluster_name}-master-${count.index}"
  resource_pool_id = data.vsphere_compute_cluster.cluster.resource_pool_id
  datastore_id     = data.vsphere_datastore.datastore.id
  
  num_cpus       = var.master_cpu
  memory         = var.master_memory
  guest_id       = data.vsphere_virtual_machine.fcos_template.guest_id
  scsi_type      = data.vsphere_virtual_machine.fcos_template.scsi_type
  firmware       = data.vsphere_virtual_machine.fcos_template.firmware
  
  network_interface = {
    network_id   = data.vsphere_network.network.id
    adapter_type = data.vsphere_virtual_machine.fcos_template.network_interface_types[0]
  }
  
  disk = {
    size             = var.master_disk_size
    thin_provisioned = true
  }
  
  clone = {
    template_uuid = data.vsphere_virtual_machine.fcos_template.id
  }
  
  extra_config = {
    "guestinfo.ignition.config.data"          = base64encode(data.ignition_config.master[count.index].rendered)
    "guestinfo.ignition.config.data.encoding" = "base64"
  }
  
  tags = var.common_tags
}

# Create worker nodes
module "worker_nodes" {
  source = "./modules/vm"
  count  = var.worker_count
  
  name             = "${var.cluster_name}-worker-${count.index}"
  resource_pool_id = data.vsphere_compute_cluster.cluster.resource_pool_id
  datastore_id     = data.vsphere_datastore.datastore.id
  
  num_cpus       = var.worker_cpu
  memory         = var.worker_memory
  guest_id       = data.vsphere_virtual_machine.fcos_template.guest_id
  scsi_type      = data.vsphere_virtual_machine.fcos_template.scsi_type
  firmware       = data.vsphere_virtual_machine.fcos_template.firmware
  
  network_interface = {
    network_id   = data.vsphere_network.network.id
    adapter_type = data.vsphere_virtual_machine.fcos_template.network_interface_types[0]
  }
  
  disk = {
    size             = var.worker_disk_size
    thin_provisioned = true
  }
  
  clone = {
    template_uuid = data.vsphere_virtual_machine.fcos_template.id
  }
  
  extra_config = {
    "guestinfo.ignition.config.data"          = base64encode(data.ignition_config.worker[count.index].rendered)
    "guestinfo.ignition.config.data.encoding" = "base64"
  }
  
  tags = var.common_tags
}

# Load balancer for API and apps
module "load_balancer" {
  source = "./modules/vm"
  
  name             = "${var.cluster_name}-lb"
  resource_pool_id = data.vsphere_compute_cluster.cluster.resource_pool_id
  datastore_id     = data.vsphere_datastore.datastore.id
  
  num_cpus       = 2
  memory         = 4096
  guest_id       = "fedora64Guest"
  
  network_interface = {
    network_id   = data.vsphere_network.network.id
    adapter_type = "vmxnet3"
  }
  
  disk = {
    size             = 40
    thin_provisioned = true
  }
  
  tags = var.common_tags
}