variable "name" {
  description = "VM name"
  type        = string
}

variable "resource_pool_id" {
  description = "Resource pool ID"
  type        = string
}

variable "datastore_id" {
  description = "Datastore ID"
  type        = string
}

variable "num_cpus" {
  description = "Number of CPUs"
  type        = number
}

variable "memory" {
  description = "Memory in MB"
  type        = number
}

variable "guest_id" {
  description = "Guest OS ID"
  type        = string
}

variable "firmware" {
  description = "Firmware type"
  type        = string
  default     = "bios"
}

variable "scsi_type" {
  description = "SCSI controller type"
  type        = string
  default     = "pvscsi"
}

variable "network_interface" {
  description = "Network interface configuration"
  type = object({
    network_id   = string
    adapter_type = string
  })
}

variable "disk" {
  description = "Disk configuration"
  type = object({
    size             = number
    thin_provisioned = bool
  })
}

variable "clone" {
  description = "Clone configuration"
  type = object({
    template_uuid = string
  })
}

variable "extra_config" {
  description = "Extra configuration parameters"
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "VM tags"
  type        = map(string)
  default     = {}
}