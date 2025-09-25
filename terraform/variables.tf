# VMware vSphere Configuration Variables

variable "vsphere_server" {
  description = "vSphere server hostname or IP"
  type        = string
}

variable "vsphere_user" {
  description = "vSphere username"
  type        = string
}

variable "vsphere_password" {
  description = "vSphere password"
  type        = string
  sensitive   = true
}

variable "allow_unverified_ssl" {
  description = "Allow unverified SSL certificates"
  type        = bool
  default     = false
}

# Infrastructure Variables
variable "datacenter" {
  description = "vSphere datacenter name"
  type        = string
}

variable "cluster" {
  description = "vSphere cluster name"
  type        = string
}

variable "datastore" {
  description = "vSphere datastore name"
  type        = string
}

variable "network_name" {
  description = "vSphere network name"
  type        = string
}

variable "fcos_template_name" {
  description = "Fedora CoreOS template name"
  type        = string
  default     = "fedora-coreos-template"
}

# Cluster Configuration
variable "cluster_name" {
  description = "OKD cluster name"
  type        = string
  default     = "okd-cluster"
}

variable "cluster_domain" {
  description = "Base domain for the cluster"
  type        = string
  default     = "cluster.local"
}

# Node Configuration
variable "master_count" {
  description = "Number of master nodes"
  type        = number
  default     = 3
}

variable "worker_count" {
  description = "Number of worker nodes"
  type        = number
  default     = 3
}

# Bootstrap Node Configuration
variable "bootstrap_cpu" {
  description = "Bootstrap node CPU count"
  type        = number
  default     = 4
}

variable "bootstrap_memory" {
  description = "Bootstrap node memory in MB"
  type        = number
  default     = 8192
}

variable "bootstrap_disk_size" {
  description = "Bootstrap node disk size in GB"
  type        = number
  default     = 80
}

# Master Node Configuration
variable "master_cpu" {
  description = "Master node CPU count"
  type        = number
  default     = 4
}

variable "master_memory" {
  description = "Master node memory in MB"
  type        = number
  default     = 16384
}

variable "master_disk_size" {
  description = "Master node disk size in GB"
  type        = number
  default     = 120
}

# Worker Node Configuration
variable "worker_cpu" {
  description = "Worker node CPU count"
  type        = number
  default     = 8
}

variable "worker_memory" {
  description = "Worker node memory in MB"
  type        = number
  default     = 32768
}

variable "worker_disk_size" {
  description = "Worker node disk size in GB"
  type        = number
  default     = 200
}

# Network Configuration
variable "cluster_network_cidr" {
  description = "CIDR for cluster network"
  type        = string
  default     = "10.128.0.0/14"
}

variable "service_network_cidr" {
  description = "CIDR for service network"
  type        = string
  default     = "172.30.0.0/16"
}

variable "host_prefix" {
  description = "Host prefix for cluster network"
  type        = number
  default     = 23
}

# Security Configuration
variable "ssh_public_key" {
  description = "SSH public key for cluster access"
  type        = string
}

variable "pull_secret" {
  description = "Red Hat pull secret"
  type        = string
  sensitive   = true
}

# Common Tags
variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default = {
    Environment = "dev"
    Project     = "okd-cluster"
    ManagedBy   = "terraform"
  }
}