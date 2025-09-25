# Cluster Information
output "cluster_name" {
  description = "Name of the OKD cluster"
  value       = var.cluster_name
}

output "cluster_domain" {
  description = "Base domain for the cluster"
  value       = var.cluster_domain
}

# Bootstrap Node
output "bootstrap_ip" {
  description = "Bootstrap node IP address"
  value       = module.bootstrap_node.vm_ip
}

# Master Nodes
output "master_ips" {
  description = "Master node IP addresses"
  value       = [for master in module.master_nodes : master.vm_ip]
}

output "master_names" {
  description = "Master node names"
  value       = [for master in module.master_nodes : master.vm_name]
}

# Worker Nodes
output "worker_ips" {
  description = "Worker node IP addresses"
  value       = [for worker in module.worker_nodes : worker.vm_ip]
}

output "worker_names" {
  description = "Worker node names"
  value       = [for worker in module.worker_nodes : worker.vm_name]
}

# Load Balancer
output "load_balancer_ip" {
  description = "Load balancer IP address"
  value       = module.load_balancer.vm_ip
}

# Cluster URLs (after installation)
output "api_url" {
  description = "Cluster API URL"
  value       = "https://api.${var.cluster_name}.${var.cluster_domain}:6443"
}

output "console_url" {
  description = "Web console URL"
  value       = "https://console-openshift-console.apps.${var.cluster_name}.${var.cluster_domain}"
}

output "oauth_url" {
  description = "OAuth server URL"
  value       = "https://oauth-openshift.apps.${var.cluster_name}.${var.cluster_domain}"
}