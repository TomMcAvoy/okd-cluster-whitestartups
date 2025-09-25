# Development Deployment Script
#!/bin/bash

set -euo pipefail

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING:${NC} $1"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR:${NC} $1"
    exit 1
}

# Configuration
ENVIRONMENT="${1:-dev}"
TERRAFORM_DIR="terraform"
ANSIBLE_DIR="ansible"
DOCKER_DIR="docker"

main() {
    log "Starting OKD cluster deployment for environment: $ENVIRONMENT"
    
    # Check prerequisites
    check_prerequisites
    
    # Start supporting services
    start_services
    
    # Deploy infrastructure
    deploy_infrastructure
    
    # Configure cluster
    configure_cluster
    
    # Verify deployment
    verify_deployment
    
    log "✅ OKD cluster deployment completed successfully!"
}

check_prerequisites() {
    log "Checking prerequisites..."
    
    command -v terraform >/dev/null 2>&1 || error "Terraform is required"
    command -v ansible >/dev/null 2>&1 || error "Ansible is required"
    command -v docker >/dev/null 2>&1 || error "Docker is required"
    command -v docker-compose >/dev/null 2>&1 || error "Docker Compose is required"
    
    if [[ ! -f "$TERRAFORM_DIR/environments/$ENVIRONMENT.tfvars" ]]; then
        error "Terraform variables file not found: $TERRAFORM_DIR/environments/$ENVIRONMENT.tfvars"
    fi
    
    log "All prerequisites met"
}

start_services() {
    log "Starting supporting services..."
    
    cd "$DOCKER_DIR"
    docker-compose -f compose/hashicorp-services.yml up -d
    docker-compose -f compose/security-monitoring.yml up -d
    
    # Wait for services to be ready
    sleep 30
    
    log "Services started successfully"
    cd ..
}

deploy_infrastructure() {
    log "Deploying infrastructure with Terraform..."
    
    cd "$TERRAFORM_DIR"
    
    # Initialize if not already done
    if [[ ! -d ".terraform" ]]; then
        terraform init
    fi
    
    # Plan
    terraform plan -var-file="environments/$ENVIRONMENT.tfvars" -out=tfplan
    
    # Apply with approval
    read -p "Apply Terraform plan? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        terraform apply tfplan
        log "Infrastructure deployed successfully"
    else
        warn "Infrastructure deployment skipped"
    fi
    
    cd ..
}

configure_cluster() {
    log "Configuring OKD cluster with Ansible..."
    
    cd "$ANSIBLE_DIR"
    
    # Run the main playbook
    ansible-playbook -i "inventory/$ENVIRONMENT" playbooks/site.yml
    
    log "Cluster configuration completed"
    cd ..
}

verify_deployment() {
    log "Verifying deployment..."
    
    # Check if kubectl/oc is available and configured
    if command -v oc >/dev/null 2>&1; then
        oc get nodes
        oc get co
    else
        warn "oc command not found, skipping cluster verification"
    fi
    
    # Check supporting services
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    
    log "Deployment verification completed"
}

cleanup() {
    log "Cleaning up..."
    # Add cleanup tasks if needed
}

# Trap for cleanup on exit
trap cleanup EXIT

# Run main function
main "$@"