# VM Module for creating VMs on vSphere

resource "vsphere_virtual_machine" "vm" {
  name             = var.name
  resource_pool_id = var.resource_pool_id
  datastore_id     = var.datastore_id

  num_cpus         = var.num_cpus
  memory           = var.memory
  guest_id         = var.guest_id
  firmware         = var.firmware
  scsi_type        = var.scsi_type

  network_interface {
    network_id   = var.network_interface.network_id
    adapter_type = var.network_interface.adapter_type
  }

  disk {
    label            = "${var.name}_disk"
    size             = var.disk.size
    thin_provisioned = var.disk.thin_provisioned
  }

  clone {
    template_uuid = var.clone.template_uuid
  }

  extra_config = var.extra_config

  wait_for_guest_net_timeout = 0
  wait_for_guest_ip_timeout  = 0

  tags = var.tags
}