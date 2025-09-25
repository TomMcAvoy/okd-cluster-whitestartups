#!/bin/bash

# OKD Cluster Development - Complete Setup Script
# This script sets up both SSH keys and GitHub PAT tokens

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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

show_welcome() {
    echo -e "${BLUE}"
    echo "================================================================"
    echo "           OKD Cluster Development Setup"
    echo "================================================================"
    echo -e "${NC}"
    echo
    echo "This script will help you set up:"
    echo "• SSH keys for secure authentication"
    echo "• GitHub Personal Access Token (PAT) for API access"
    echo
    echo "Both are required for OKD cluster automation development."
    echo
}

check_requirements() {
    log_info "Checking system requirements..."
    
    local missing_tools=()
    
    # Check for required tools
    command -v ssh-keygen >/dev/null 2>&1 || missing_tools+=("ssh-keygen")
    command -v ssh-agent >/dev/null 2>&1 || missing_tools+=("ssh-agent")
    command -v git >/dev/null 2>&1 || missing_tools+=("git")
    command -v curl >/dev/null 2>&1 || missing_tools+=("curl")
    
    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        log_error "Missing required tools: ${missing_tools[*]}"
        echo
        echo "Please install the missing tools and run this script again."
        echo
        echo "On Ubuntu/Debian:"
        echo "  sudo apt update && sudo apt install -y openssh-client git curl"
        echo
        echo "On CentOS/RHEL/Fedora:"
        echo "  sudo dnf install -y openssh-clients git curl"
        echo
        echo "On macOS:"
        echo "  # Tools should be pre-installed, or install via Homebrew"
        echo "  brew install git curl"
        exit 1
    fi
    
    log_success "All required tools are available"
}

show_setup_options() {
    echo -e "\n${YELLOW}What would you like to set up?${NC}"
    echo
    echo "1) SSH keys only"
    echo "2) GitHub PAT token only" 
    echo "3) Both SSH keys and PAT token (recommended)"
    echo "4) Show documentation links"
    echo "5) Exit"
    echo
}

run_ssh_setup() {
    log_info "Starting SSH key setup..."
    echo
    
    if [[ -x "$SCRIPT_DIR/setup-ssh-keys.sh" ]]; then
        "$SCRIPT_DIR/setup-ssh-keys.sh"
    else
        log_error "SSH setup script not found or not executable: $SCRIPT_DIR/setup-ssh-keys.sh"
        return 1
    fi
}

run_pat_setup() {
    log_info "Starting GitHub PAT setup..."
    echo
    
    if [[ -x "$SCRIPT_DIR/setup-github-pat.sh" ]]; then
        "$SCRIPT_DIR/setup-github-pat.sh"
    else
        log_error "PAT setup script not found or not executable: $SCRIPT_DIR/setup-github-pat.sh"
        return 1
    fi
}

show_documentation() {
    echo -e "\n${BLUE}=== Documentation ===${NC}"
    echo
    echo "Detailed guides are available in the docs/ directory:"
    echo
    echo "• docs/ssh-key-setup.md - Complete SSH key guide"
    echo "• docs/github-pat-setup.md - Complete GitHub PAT guide"
    echo
    echo "You can also view them online:"
    echo "• https://github.com/TomMcAvoy/okd-cluster-whitestartups/blob/main/docs/ssh-key-setup.md"
    echo "• https://github.com/TomMcAvoy/okd-cluster-whitestartups/blob/main/docs/github-pat-setup.md"
    echo
}

show_next_steps() {
    echo -e "\n${GREEN}=== Next Steps ===${NC}"
    echo
    echo "After completing the setup, you can:"
    echo
    echo "1. Clone the repository using SSH:"
    echo "   git clone git@github.com:TomMcAvoy/okd-cluster-whitestartups.git"
    echo
    echo "2. Load environment variables:"
    echo "   source .env"
    echo
    echo "3. Test your GitHub connection:"
    echo "   ssh -T git@github.com"
    echo "   curl -H \"Authorization: token \$GITHUB_TOKEN\" https://api.github.com/user"
    echo
    echo "4. Start developing OKD cluster automation!"
    echo
}

verify_setup() {
    echo -e "\n${YELLOW}Would you like to verify your setup?${NC}"
    read -p "[y/N]: " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        return 0
    fi
    
    log_info "Verifying setup..."
    echo
    
    # Check SSH key
    if [[ -f ~/.ssh/id_ed25519_okd ]]; then
        log_success "SSH private key found: ~/.ssh/id_ed25519_okd"
    else
        log_warning "SSH private key not found: ~/.ssh/id_ed25519_okd"
    fi
    
    if [[ -f ~/.ssh/id_ed25519_okd.pub ]]; then
        log_success "SSH public key found: ~/.ssh/id_ed25519_okd.pub"
    else
        log_warning "SSH public key not found: ~/.ssh/id_ed25519_okd.pub"
    fi
    
    # Check environment file
    if [[ -f .env ]]; then
        log_success "Environment file found: .env"
        
        if grep -q "GITHUB_TOKEN=" .env && grep -q "GITHUB_USERNAME=" .env; then
            log_success "Environment file contains required variables"
        else
            log_warning "Environment file missing required variables"
        fi
    else
        log_warning "Environment file not found: .env"
    fi
    
    # Test GitHub SSH connection
    echo -e "\n${YELLOW}Testing GitHub SSH connection...${NC}"
    if timeout 10 ssh -T -o ConnectTimeout=5 git@github.com 2>&1 | grep -q "successfully authenticated"; then
        log_success "GitHub SSH connection successful"
    else
        log_warning "GitHub SSH connection failed (key might not be added to GitHub yet)"
    fi
    
    # Test GitHub PAT
    if [[ -f .env ]]; then
        echo -e "\n${YELLOW}Testing GitHub PAT token...${NC}"
        source .env 2>/dev/null || true
        
        if [[ -n "${GITHUB_TOKEN:-}" ]]; then
            local response
            response=$(curl -s -w "%{http_code}" -H "Authorization: token $GITHUB_TOKEN" https://api.github.com/user)
            local http_code="${response: -3}"
            
            if [[ "$http_code" == "200" ]]; then
                log_success "GitHub PAT token is valid"
            else
                log_warning "GitHub PAT token test failed (HTTP $http_code)"
            fi
        else
            log_warning "GITHUB_TOKEN not found in environment"
        fi
    fi
}

interactive_menu() {
    while true; do
        show_setup_options
        read -p "Select an option [1-5]: " choice
        
        case $choice in
            1)
                run_ssh_setup
                ;;
            2)
                run_pat_setup
                ;;
            3)
                run_ssh_setup
                echo -e "\n${BLUE}================================================================${NC}"
                run_pat_setup
                ;;
            4)
                show_documentation
                ;;
            5)
                log_info "Exiting..."
                exit 0
                ;;
            *)
                log_warning "Invalid option. Please select 1-5."
                ;;
        esac
        
        echo -e "\n${YELLOW}Setup completed for selected option.${NC}"
        echo -e "${YELLOW}Would you like to do something else?${NC}"
        read -p "[y/N]: " -n 1 -r
        echo
        
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            break
        fi
    done
}

main() {
    show_welcome
    check_requirements
    interactive_menu
    verify_setup
    show_next_steps
    
    echo -e "\n${GREEN}Setup process completed!${NC}"
    echo -e "Thank you for setting up OKD cluster development environment."
}

# Handle command line arguments
case "${1:-interactive}" in
    --ssh)
        show_welcome
        check_requirements
        run_ssh_setup
        ;;
    --pat)
        show_welcome
        check_requirements
        run_pat_setup
        ;;
    --all)
        show_welcome
        check_requirements
        run_ssh_setup
        echo -e "\n${BLUE}================================================================${NC}"
        run_pat_setup
        verify_setup
        show_next_steps
        ;;
    --help|-h)
        echo "OKD Cluster Development Setup"
        echo
        echo "Usage: $0 [option]"
        echo
        echo "Options:"
        echo "  (none)    Interactive menu"
        echo "  --ssh     Setup SSH keys only"
        echo "  --pat     Setup GitHub PAT only"
        echo "  --all     Setup both SSH keys and PAT"
        echo "  --help    Show this help message"
        exit 0
        ;;
    interactive|*)
        main
        ;;
esac