# OKD Cluster WhiteStartups

OpenShift Origin (OKD) cluster automation for WhiteStartups development and production environments.

## Quick Start

### Prerequisites

Before you can develop with this project, you need to set up:
- **SSH keys** for secure authentication
- **GitHub Personal Access Token (PAT)** for API access

### 🚀 Automated Setup

Run the setup script to configure both SSH keys and GitHub PAT:

```bash
# Clone the repository first (using HTTPS initially)
git clone https://github.com/TomMcAvoy/okd-cluster-whitestartups.git
cd okd-cluster-whitestartups

# Run the interactive setup
./scripts/setup-development.sh

# Or run specific setups:
./scripts/setup-development.sh --ssh    # SSH keys only
./scripts/setup-development.sh --pat    # GitHub PAT only  
./scripts/setup-development.sh --all    # Both (non-interactive)
```

### 📖 Manual Setup

If you prefer manual setup, follow these guides:

1. **SSH Keys**: [docs/ssh-key-setup.md](docs/ssh-key-setup.md)
2. **GitHub PAT**: [docs/github-pat-setup.md](docs/github-pat-setup.md)

## Project Structure

```
okd-cluster-whitestartups/
├── docs/                          # Documentation
│   ├── ssh-key-setup.md          # SSH key generation guide
│   └── github-pat-setup.md       # GitHub PAT setup guide
├── scripts/                       # Automation scripts
│   ├── setup-development.sh      # Main setup script
│   ├── setup-ssh-keys.sh        # SSH key setup
│   └── setup-github-pat.sh      # GitHub PAT setup
├── templates/                     # Configuration templates
│   ├── .env.template            # Environment variables template
│   └── ssh-config.template      # SSH configuration template
└── README.md                     # This file
```

## Development Workflow

### 1. Initial Setup

```bash
# After running setup scripts, clone with SSH
git clone git@github.com:TomMcAvoy/okd-cluster-whitestartups.git
cd okd-cluster-whitestartups

# Load environment variables
source .env
```

### 2. Verify Setup

```bash
# Test SSH connection
ssh -T git@github.com

# Test GitHub API access
curl -H "Authorization: token $GITHUB_TOKEN" https://api.github.com/user
```

### 3. Development

- Create feature branches for new work
- Use the configured SSH keys for Git operations  
- Use the PAT token for GitHub API interactions
- Follow standard Git workflow practices

## Security Features

### 🔐 Secure by Default

- **SSH keys** use Ed25519 encryption (most secure)
- **Environment variables** stored in `.env` (not committed)
- **Sensitive files** automatically excluded via `.gitignore`
- **Minimal token scopes** for GitHub PAT
- **Proper file permissions** set automatically

### 🛡️ Best Practices Enforced

- Passphrase-protected SSH keys (recommended)
- Token expiration policies
- Regular key rotation reminders
- Secure credential storage
- No hardcoded secrets in code

## OKD Cluster Features

This project provides automation for:

- **Cluster Installation** - Automated OKD cluster deployment
- **Configuration Management** - Infrastructure as Code
- **Monitoring & Logging** - Observability stack setup  
- **Security Policies** - Security baselines and compliance
- **Backup & Recovery** - Data protection strategies
- **CI/CD Integration** - DevOps pipeline automation

## Environment Configuration

The project supports multiple environments:

- **Development** - Local development and testing
- **Staging** - Pre-production validation
- **Production** - Live workload clusters

Environment-specific configurations are managed through:
- Environment variables (`.env` files)
- SSH configurations (`~/.ssh/config`)
- OKD install configs
- Infrastructure templates

## Contributing

1. **Set up your development environment** using the setup scripts
2. **Create a feature branch**: `git checkout -b feature/your-feature`
3. **Make your changes** and test thoroughly
4. **Commit your changes**: `git commit -am 'Add some feature'`
5. **Push to the branch**: `git push origin feature/your-feature`
6. **Create a Pull Request**

## Support

- **Documentation**: Check the `docs/` directory
- **Issues**: Open GitHub issues for bugs or feature requests
- **Security**: Report security issues privately via GitHub Security tab

## License

This project is licensed under the MIT License - see the LICENSE file for details.

---

**Note**: This project requires both SSH keys and GitHub PAT tokens for full functionality. Make sure to complete the setup process before contributing.
