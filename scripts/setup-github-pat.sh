#!/bin/bash

# OKD Cluster Development - GitHub PAT Setup Helper
# This script helps configure GitHub Personal Access Tokens

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
ENV_FILE=".env"
SAMPLE_ENV_FILE=".env.example"

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

show_pat_instructions() {
    echo -e "${BLUE}"
    echo "================================================================"
    echo "    GitHub Personal Access Token (PAT) Generation Guide"
    echo "================================================================"
    echo -e "${NC}"
    
    echo -e "${YELLOW}Step-by-step instructions:${NC}"
    echo
    echo "1. Open your web browser and go to:"
    echo "   https://github.com/settings/personal-access-tokens/tokens"
    echo
    echo "2. Click 'Generate new token' → 'Generate new token (classic)'"
    echo
    echo "3. Fill in the token details:"
    echo "   - Note: 'OKD Cluster Automation'"
    echo "   - Expiration: 90 days (recommended)"
    echo
    echo "4. Select the following scopes:"
    echo "   ✓ repo (Full control of private repositories)"
    echo "   ✓ workflow (Update GitHub Action workflows)"
    echo "   ✓ read:packages (Download packages)"
    echo "   ✓ write:packages (Upload packages - if needed)"
    echo "   ✓ read:user (Read user profile data)"
    echo "   ✓ user:email (Access user email addresses)"
    echo
    echo "5. Click 'Generate token'"
    echo
    echo "6. IMPORTANT: Copy the token immediately!"
    echo "   (You won't be able to see it again)"
    echo
    echo -e "${RED}SECURITY WARNING:${NC}"
    echo "• Never commit the token to your repository"
    echo "• Store it securely in environment variables"
    echo "• Don't share it with others"
    echo
}

prompt_for_token() {
    echo -e "${YELLOW}Have you generated your GitHub PAT token?${NC}"
    read -p "Enter 'yes' when ready to configure it: " -r
    
    if [[ ! $REPLY =~ ^[Yy]es$ ]]; then
        log_info "Please generate your PAT token first, then run this script again"
        exit 0
    fi
}

get_github_username() {
    local username=""
    
    echo -e "\n${YELLOW}Enter your GitHub username:${NC}"
    read -p "Username: " username
    
    if [[ -z "$username" ]]; then
        log_error "GitHub username is required"
        exit 1
    fi
    
    echo "$username"
}

get_pat_token() {
    local token=""
    
    echo -e "\n${YELLOW}Enter your GitHub PAT token:${NC}"
    echo -e "${BLUE}(Input will be hidden for security)${NC}"
    read -s -p "Token: " token
    echo
    
    if [[ -z "$token" ]]; then
        log_error "GitHub PAT token is required"
        exit 1
    fi
    
    # Basic validation - GitHub tokens start with 'ghp_' for classic tokens
    if [[ ! $token =~ ^ghp_[A-Za-z0-9_]{36}$ ]]; then
        log_warning "Token format doesn't match expected classic PAT format (ghp_...)"
        echo -e "${YELLOW}Are you sure this is a classic GitHub PAT token?${NC}"
        read -p "Continue anyway? [y/N]: " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Please verify your token and try again"
            exit 1
        fi
    fi
    
    echo "$token"
}

create_env_file() {
    local username="$1"
    local token="$2"
    
    log_info "Creating environment configuration..."
    
    if [[ -f "$ENV_FILE" ]]; then
        log_warning ".env file already exists"
        read -p "Do you want to overwrite it? [y/N]: " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Keeping existing .env file"
            return 0
        fi
    fi
    
    cat > "$ENV_FILE" << EOF
# GitHub Configuration for OKD Cluster Automation
# Generated on $(date)

# GitHub Personal Access Token (Classic)
# This token provides access to GitHub repositories and APIs
GITHUB_TOKEN=$token

# GitHub Username
GITHUB_USERNAME=$username

# GitHub Repository URL (SSH)
GITHUB_REPO_SSH=git@github.com:TomMcAvoy/okd-cluster-whitestartups.git

# GitHub Repository URL (HTTPS with token)
GITHUB_REPO_HTTPS=https://$username:$token@github.com/TomMcAvoy/okd-cluster-whitestartups.git

# OKD Cluster Configuration (customize as needed)
OKD_CLUSTER_NAME=okd-cluster-dev
OKD_BASE_DOMAIN=example.com

# Optional: GitHub API Base URL (for enterprise GitHub)
# GITHUB_API_URL=https://api.github.com

# Optional: GitHub Enterprise settings
# GITHUB_ENTERPRISE=false
EOF

    chmod 600 "$ENV_FILE"
    log_success "Environment file created: $ENV_FILE"
}

create_sample_env() {
    log_info "Creating sample environment file..."
    
    cat > "$SAMPLE_ENV_FILE" << 'EOF'
# GitHub Configuration for OKD Cluster Automation
# Copy this file to .env and fill in your actual values

# GitHub Personal Access Token (Classic)
# Generate at: https://github.com/settings/personal-access-tokens/tokens
GITHUB_TOKEN=your_github_pat_token_here

# Your GitHub Username
GITHUB_USERNAME=your_github_username

# GitHub Repository URLs
GITHUB_REPO_SSH=git@github.com:TomMcAvoy/okd-cluster-whitestartups.git
GITHUB_REPO_HTTPS=https://your_username:your_token@github.com/TomMcAvoy/okd-cluster-whitestartups.git

# OKD Cluster Configuration
OKD_CLUSTER_NAME=okd-cluster-dev
OKD_BASE_DOMAIN=example.com

# Optional: GitHub API Base URL (for enterprise GitHub)
# GITHUB_API_URL=https://api.github.com

# Optional: GitHub Enterprise settings
# GITHUB_ENTERPRISE=false
EOF

    log_success "Sample environment file created: $SAMPLE_ENV_FILE"
}

setup_git_credentials() {
    local username="$1"
    local token="$2"
    
    echo -e "\n${YELLOW}Would you like to configure Git to use your PAT token?${NC}"
    read -p "[y/N]: " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log_info "Configuring Git credentials..."
        
        # Set up credential helper
        git config --global credential.helper store
        
        # Create credentials file
        echo "https://$username:$token@github.com" > ~/.git-credentials
        chmod 600 ~/.git-credentials
        
        log_success "Git credentials configured"
    fi
}

test_pat_token() {
    local token="$1"
    
    echo -e "\n${YELLOW}Would you like to test your PAT token?${NC}"
    read -p "[y/N]: " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log_info "Testing PAT token..."
        
        local response
        response=$(curl -s -H "Authorization: token $token" https://api.github.com/user)
        
        if echo "$response" | grep -q '"login"'; then
            local github_user
            github_user=$(echo "$response" | grep '"login"' | cut -d'"' -f4)
            log_success "PAT token is valid! Authenticated as: $github_user"
        else
            log_error "PAT token test failed"
            echo "Response: $response"
        fi
    fi
}

show_usage_examples() {
    echo -e "\n${BLUE}=== Usage Examples ===${NC}"
    echo
    echo -e "${YELLOW}1. Load environment variables in your shell:${NC}"
    echo "   source .env"
    echo "   # or"
    echo "   export \$(cat .env | xargs)"
    echo
    echo -e "${YELLOW}2. Use in scripts:${NC}"
    echo "   curl -H \"Authorization: token \$GITHUB_TOKEN\" https://api.github.com/user"
    echo
    echo -e "${YELLOW}3. Clone repository with token:${NC}"
    echo "   git clone \$GITHUB_REPO_HTTPS"
    echo
    echo -e "${YELLOW}4. Use with GitHub CLI:${NC}"
    echo "   echo \$GITHUB_TOKEN | gh auth login --with-token"
    echo
    echo -e "${YELLOW}5. Docker/Containerfile:${NC}"
    echo "   ENV GITHUB_TOKEN=\${GITHUB_TOKEN}"
    echo
}

show_security_reminders() {
    echo -e "\n${RED}=== SECURITY REMINDERS ===${NC}"
    echo
    echo "• The .env file contains sensitive information"
    echo "• It's already added to .gitignore to prevent accidental commits"
    echo "• Never share your PAT token with others"
    echo "• Regularly rotate your tokens (every 90 days recommended)"
    echo "• Monitor token usage in GitHub settings"
    echo "• Revoke tokens that are no longer needed"
    echo
    echo -e "${YELLOW}Token management URL:${NC}"
    echo "https://github.com/settings/personal-access-tokens/tokens"
}

main() {
    echo -e "${BLUE}"
    echo "================================================================"
    echo "       GitHub PAT Token Configuration Helper"
    echo "================================================================"
    echo -e "${NC}"
    
    show_pat_instructions
    prompt_for_token
    
    local username
    local token
    
    username=$(get_github_username)
    token=$(get_pat_token)
    
    create_env_file "$username" "$token"
    create_sample_env
    setup_git_credentials "$username" "$token"
    test_pat_token "$token"
    show_usage_examples
    show_security_reminders
    
    echo -e "\n${GREEN}PAT token configuration completed!${NC}"
    echo -e "Configuration file: $ENV_FILE"
    echo -e "Sample file: $SAMPLE_ENV_FILE"
    echo -e "\nFor more information, see: docs/github-pat-setup.md"
}

# Check if running in interactive mode
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi