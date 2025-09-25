# Terraform template for OKD node VMs in VMware Fusion
provider "vsphere" {
  user           = var.vsphere_user
  password       = var.vsphere_password
  vsphere_server = var.vsphere_server
  allow_unverified_ssl = true
}

resource "vsphere_virtual_machine" "okd_node" {
  count            = var.okd_node_count
  name             = "okd-node-${count.index + 1}"
  resource_pool_id = var.resource_pool_id
  datastore_id     = var.datastore_id

  num_cpus = 2
  memory   = 4096
  guest_id = "other3xLinux64Guest"

  network_interface {
    network_id   = var.network_id
    adapter_type = "vmxnet3"
  }

  disk {
    label            = "disk0"
    size             = 40
    eagerly_scrub    = false
    thin_provisioned = true
  }

  clone {
    template_uuid = var.template_uuid
  }
}
