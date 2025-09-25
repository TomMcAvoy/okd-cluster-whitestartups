# Variables for VMware Fusion Terraform provisioning
variable "vsphere_user" {}
variable "vsphere_password" {}
variable "vsphere_server" {}
variable "resource_pool_id" {}
variable "datastore_id" {}
variable "network_id" {}
variable "template_uuid" {}
variable "okd_node_count" { default = 3 }
