# Terraform configuration for OKD cluster infrastructure

terraform {
  required_version = ">= 1.5.0"
}

provider "kubernetes" {
  # Configure with your cluster details
}

# Add resources for OKD cluster provisioning here
