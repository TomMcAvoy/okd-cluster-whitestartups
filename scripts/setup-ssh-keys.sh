#!/bin/bash

# OKD Cluster Development - SSH Key Setup Script
# This script generates SSH keys for OKD cluster automation

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SSH_DIR="$HOME/.ssh"
KEY_NAME="id_ed25519_okd"
KEY_TYPE="ed25519"
KEY_COMMENT="${USER}@$(hostname)-okd-cluster"

# Functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_requirements() {
    log_info "Checking requirements..."
    
    if ! command -v ssh-keygen &> /dev/null; then
        log_error "ssh-keygen is not installed. Please install OpenSSH client."
        exit 1
    fi
    
    if ! command -v ssh-agent &> /dev/null; then
        log_error "ssh-agent is not installed. Please install OpenSSH client."
        exit 1
    fi
    
    log_success "All requirements met"
}

setup_ssh_directory() {
    log_info "Setting up SSH directory..."
    
    if [[ ! -d "$SSH_DIR" ]]; then
        mkdir -p "$SSH_DIR"
        log_info "Created SSH directory: $SSH_DIR"
    fi
    
    chmod 700 "$SSH_DIR"
    log_success "SSH directory configured with correct permissions"
}

generate_ssh_key() {
    local private_key="$SSH_DIR/$KEY_NAME"
    local public_key="$SSH_DIR/$KEY_NAME.pub"
    
    if [[ -f "$private_key" ]]; then
        log_warning "SSH key already exists: $private_key"
        read -p "Do you want to overwrite it? [y/N]: " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Keeping existing key"
            return 0
        fi
    fi
    
    log_info "Generating SSH key pair..."
    log_info "Key type: $KEY_TYPE"
    log_info "Key location: $private_key"
    log_info "Key comment: $KEY_COMMENT"
    
    echo -e "\n${YELLOW}You will be prompted for a passphrase. Using a passphrase is recommended for security.${NC}"
    echo -e "${YELLOW}You can press Enter to skip the passphrase, but this is less secure.${NC}\n"
    
    ssh-keygen -t "$KEY_TYPE" -C "$KEY_COMMENT" -f "$private_key"
    
    if [[ $? -eq 0 ]]; then
        log_success "SSH key pair generated successfully"
    else
        log_error "Failed to generate SSH key pair"
        exit 1
    fi
    
    # Set correct permissions
    chmod 600 "$private_key"
    chmod 644 "$public_key"
    
    log_success "Key permissions set correctly"
}

setup_ssh_agent() {
    log_info "Setting up SSH agent..."
    
    local private_key="$SSH_DIR/$KEY_NAME"
    
    # Start ssh-agent if not running
    if [[ -z "${SSH_AUTH_SOCK:-}" ]]; then
        log_info "Starting SSH agent..."
        eval "$(ssh-agent -s)"
    else
        log_info "SSH agent already running"
    fi
    
    # Add key to agent
    log_info "Adding key to SSH agent..."
    ssh-add "$private_key"
    
    if [[ $? -eq 0 ]]; then
        log_success "Key added to SSH agent"
    else
        log_warning "Failed to add key to SSH agent (this might be due to passphrase prompt)"
    fi
}

create_ssh_config() {
    local ssh_config="$SSH_DIR/config"
    local config_entry="
# OKD Cluster Development
Host github.com-okd
    HostName github.com
    User git
    IdentityFile ~/.ssh/$KEY_NAME
    IdentitiesOnly yes

# Default GitHub configuration for OKD project
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/$KEY_NAME
    IdentitiesOnly yes

# OKD Cluster Nodes (template - adjust as needed)
Host okd-master-*
    User core
    IdentityFile ~/.ssh/$KEY_NAME
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
    Port 22

Host okd-worker-*
    User core
    IdentityFile ~/.ssh/$KEY_NAME
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
    Port 22
"
    
    if [[ -f "$ssh_config" ]]; then
        log_warning "SSH config file already exists"
        read -p "Do you want to append OKD configuration? [y/N]: " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo "$config_entry" >> "$ssh_config"
            log_success "OKD SSH configuration appended to existing config"
        fi
    else
        echo "$config_entry" > "$ssh_config"
        chmod 600 "$ssh_config"
        log_success "SSH config file created with OKD configuration"
    fi
}

display_public_key() {
    local public_key="$SSH_DIR/$KEY_NAME.pub"
    
    echo -e "\n${GREEN}=== YOUR PUBLIC KEY ===${NC}"
    cat "$public_key"
    echo -e "\n${BLUE}=== COPY THE ABOVE KEY TO ADD TO GITHUB ===${NC}"
    
    echo -e "\n${YELLOW}Next steps:${NC}"
    echo "1. Copy the public key above"
    echo "2. Go to GitHub Settings → SSH and GPG keys"
    echo "3. Click 'New SSH key'"
    echo "4. Paste the public key"
    echo "5. Give it a title like 'OKD Cluster Development'"
    echo "6. Click 'Add SSH key'"
    
    echo -e "\n${YELLOW}Test the connection:${NC}"
    echo "ssh -T git@github.com"
}

test_github_connection() {
    log_info "Testing GitHub SSH connection..."
    
    echo -e "\n${YELLOW}Testing SSH connection to GitHub...${NC}"
    if ssh -T -o ConnectTimeout=10 git@github.com 2>&1 | grep -q "successfully authenticated"; then
        log_success "GitHub SSH connection successful!"
    else
        log_warning "GitHub SSH connection test failed or key not yet added to GitHub"
        echo "Make sure you've added the public key to your GitHub account"
    fi
}

main() {
    echo -e "${BLUE}"
    echo "================================================================"
    echo "       OKD Cluster Development - SSH Key Setup"
    echo "================================================================"
    echo -e "${NC}"
    
    check_requirements
    setup_ssh_directory
    generate_ssh_key
    setup_ssh_agent
    create_ssh_config
    display_public_key
    
    echo -e "\n${YELLOW}Would you like to test the GitHub connection now?${NC}"
    read -p "[y/N]: " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        test_github_connection
    fi
    
    echo -e "\n${GREEN}SSH key setup completed!${NC}"
    echo -e "Key files created:"
    echo -e "  Private key: $SSH_DIR/$KEY_NAME"
    echo -e "  Public key:  $SSH_DIR/$KEY_NAME.pub"
    echo -e "\nFor more information, see: docs/ssh-key-setup.md"
}

# Run main function
main "$@"