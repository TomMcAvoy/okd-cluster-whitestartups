#!/bin/bash
#
# Fedora CoreOS Template Creation Script for VMware vSphere
# This script downloads and creates a Fedora CoreOS template for OKD installation
#

set -euo pipefail

# Configuration
FCOS_VERSION="${FCOS_VERSION:-38.20231002.3.0}"
FCOS_STREAM="${FCOS_STREAM:-stable}"
TEMPLATE_NAME="${TEMPLATE_NAME:-fedora-coreos-${FCOS_VERSION}}"
DATASTORE="${DATASTORE:-datastore1}"
DATACENTER="${DATACENTER:-Datacenter}"
CLUSTER="${CLUSTER:-Cluster}"
NETWORK="${NETWORK:-VM Network}"
TEMP_DIR="/tmp/fcos-template"

# vSphere Configuration
VCENTER_SERVER="${VCENTER_SERVER:-vcenter.example.com}"
VCENTER_USER="${VCENTER_USER:-administrator@vsphere.local}"
VCENTER_PASSWORD="${VCENTER_PASSWORD}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

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

check_dependencies() {
    log "Checking dependencies..."
    
    command -v curl >/dev/null 2>&1 || error "curl is required but not installed"
    command -v gunzip >/dev/null 2>&1 || error "gunzip is required but not installed"
    command -v ovftool >/dev/null 2>&1 || error "ovftool is required but not installed"
    
    if [[ -z "${VCENTER_PASSWORD:-}" ]]; then
        error "VCENTER_PASSWORD environment variable is required"
    fi
    
    log "All dependencies found"
}

download_fcos() {
    log "Downloading Fedora CoreOS ${FCOS_VERSION}..."
    
    mkdir -p "${TEMP_DIR}"
    cd "${TEMP_DIR}"
    
    # Download OVA file
    FCOS_URL="https://builds.coreos.fedoraproject.org/prod/streams/${FCOS_STREAM}/builds/${FCOS_VERSION}/x86_64/fedora-coreos-${FCOS_VERSION}-vmware.x86_64.ova"
    
    if [[ ! -f "fedora-coreos-${FCOS_VERSION}-vmware.x86_64.ova" ]]; then
        log "Downloading from ${FCOS_URL}"
        curl -L -o "fedora-coreos-${FCOS_VERSION}-vmware.x86_64.ova" "${FCOS_URL}"
    else
        log "FCOS OVA already exists, skipping download"
    fi
}

deploy_template() {
    log "Deploying Fedora CoreOS template to vSphere..."
    
    cd "${TEMP_DIR}"
    
    # Deploy OVA as template using ovftool
    ovftool \
        --acceptAllEulas \
        --noSSLVerify \
        --diskMode=thin \
        --powerOffTarget \
        --name="${TEMPLATE_NAME}" \
        --datastore="${DATASTORE}" \
        --network="${NETWORK}" \
        "fedora-coreos-${FCOS_VERSION}-vmware.x86_64.ova" \
        "vi://${VCENTER_USER}:${VCENTER_PASSWORD}@${VCENTER_SERVER}/${DATACENTER}/host/${CLUSTER}"
    
    log "Template ${TEMPLATE_NAME} deployed successfully"
}

configure_template() {
    log "Configuring template settings..."
    
    # Use PowerCLI to convert VM to template and configure settings
    pwsh -File "$(dirname "$0")/../powercli/configure-template.ps1" \
        -VCenterServer "${VCENTER_SERVER}" \
        -VCenterUser "${VCENTER_USER}" \
        -VCenterPassword "${VCENTER_PASSWORD}" \
        -TemplateName "${TEMPLATE_NAME}" \
        -Datacenter "${DATACENTER}"
}

cleanup() {
    log "Cleaning up temporary files..."
    rm -rf "${TEMP_DIR}"
}

main() {
    log "Starting Fedora CoreOS template creation for OKD"
    
    check_dependencies
    download_fcos
    deploy_template
    configure_template
    cleanup
    
    log "Fedora CoreOS template creation completed successfully!"
    log "Template name: ${TEMPLATE_NAME}"
}

# Trap for cleanup on script exit
trap cleanup EXIT

# Run main function
main "$@"