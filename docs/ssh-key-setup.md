# SSH Key Generation Guide

This guide explains how to generate SSH keys for secure authentication with the OKD cluster automation project.

## Why You Need SSH Keys

SSH keys provide:
- Secure, password-less authentication
- Better security than password-based authentication
- Required for Git operations over SSH
- Essential for server and cluster access
- Needed for OKD/OpenShift cluster management

## SSH Key Types

### Ed25519 (Recommended)
- Most secure and modern
- Smaller key size, faster performance
- Supported by GitHub and most modern systems

### RSA
- Widely supported legacy option
- Use 4096-bit keys for security
- Larger key size than Ed25519

## Generating SSH Keys

### Method 1: Ed25519 Keys (Recommended)

```bash
# Generate Ed25519 key
ssh-keygen -t ed25519 -C "your_email@example.com" -f ~/.ssh/id_ed25519_okd

# When prompted:
# - Enter a secure passphrase (recommended)
# - Confirm the passphrase
```

### Method 2: RSA Keys (Legacy Support)

```bash
# Generate 4096-bit RSA key
ssh-keygen -t rsa -b 4096 -C "your_email@example.com" -f ~/.ssh/id_rsa_okd

# When prompted:
# - Enter a secure passphrase (recommended)
# - Confirm the passphrase
```

### Key Generation Parameters

- `-t`: Key type (ed25519, rsa, ecdsa, dsa)
- `-b`: Key bits (4096 for RSA)
- `-C`: Comment (usually your email)
- `-f`: Output filename

## SSH Key Management

### File Locations
After generation, you'll have:
- **Private key**: `~/.ssh/id_ed25519_okd` (keep secret!)
- **Public key**: `~/.ssh/id_ed25519_okd.pub` (safe to share)

### Setting Correct Permissions
```bash
# Set private key permissions (read-only for owner)
chmod 600 ~/.ssh/id_ed25519_okd

# Set public key permissions
chmod 644 ~/.ssh/id_ed25519_okd.pub

# Set .ssh directory permissions
chmod 700 ~/.ssh
```

## Adding Keys to GitHub

### Step 1: Copy Public Key
```bash
# Copy public key to clipboard (Linux)
cat ~/.ssh/id_ed25519_okd.pub | xclip -selection clipboard

# Copy public key to clipboard (macOS)
cat ~/.ssh/id_ed25519_okd.pub | pbcopy

# Display key for manual copy
cat ~/.ssh/id_ed25519_okd.pub
```

### Step 2: Add to GitHub
1. Go to GitHub Settings → SSH and GPG keys
2. Click "New SSH key"
3. Give it a title: "OKD Cluster Development"
4. Select key type: "Authentication Key"
5. Paste the public key content
6. Click "Add SSH key"

## SSH Agent Configuration

### Start SSH Agent
```bash
# Start ssh-agent
eval "$(ssh-agent -s)"

# Add your key to the agent
ssh-add ~/.ssh/id_ed25519_okd
```

### Persistent SSH Agent (Optional)
Add to `~/.bashrc` or `~/.zshrc`:
```bash
# SSH Agent auto-start
if [ -z "$SSH_AUTH_SOCK" ]; then
  eval "$(ssh-agent -s)"
  ssh-add ~/.ssh/id_ed25519_okd 2>/dev/null
fi
```

## SSH Config Setup

### Create SSH Config
Create/edit `~/.ssh/config`:
```
# OKD Cluster Development
Host github.com-okd
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519_okd
    IdentitiesOnly yes

# Default GitHub (if you have other keys)
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519_okd
    IdentitiesOnly yes

# OKD Cluster Nodes (example)
Host okd-master-*
    User core
    IdentityFile ~/.ssh/id_ed25519_okd
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null

Host okd-worker-*
    User core
    IdentityFile ~/.ssh/id_ed25519_okd
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
```

## Testing SSH Keys

### Test GitHub Connection
```bash
# Test SSH connection to GitHub
ssh -T git@github.com

# Expected output:
# Hi username! You've successfully authenticated, but GitHub does not provide shell access.
```

### Test Specific Key
```bash
# Test with specific key file
ssh -T -i ~/.ssh/id_ed25519_okd git@github.com

# Verbose output for troubleshooting
ssh -T -v git@github.com
```

## Using SSH Keys with Git

### Clone Repository
```bash
# Clone using SSH
git clone git@github.com:TomMcAvoy/okd-cluster-whitestartups.git

# Clone using specific SSH config host
git clone git@github.com-okd:TomMcAvoy/okd-cluster-whitestartups.git
```

### Change Existing Repository
```bash
# Change from HTTPS to SSH
git remote set-url origin git@github.com:TomMcAvoy/okd-cluster-whitestartups.git
```

## OKD/OpenShift Specific Usage

### Cluster Installation
SSH keys are needed for:
- Accessing cluster nodes
- Debugging cluster issues
- Performing maintenance tasks

### Key Distribution
```bash
# Copy public key to clipboard for cluster installation
cat ~/.ssh/id_ed25519_okd.pub

# Add this key to your install-config.yaml:
# sshKey: 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5...'
```

## Security Best Practices

### Key Security
1. **Use strong passphrases** for private keys
2. **Never share private keys**
3. **Regularly rotate keys** (every 6-12 months)
4. **Use different keys** for different purposes
5. **Store keys securely** (encrypted storage)

### Access Control
1. **Remove unused keys** from GitHub/servers
2. **Monitor key usage** in GitHub settings
3. **Use key-specific SSH configs**
4. **Implement key rotation policies**

### Backup Strategy
1. **Backup private keys** securely
2. **Document key locations** and purposes
3. **Test key restoration** procedures
4. **Store recovery information** safely

## Troubleshooting

### Common Issues

#### Permission Denied
```bash
# Check key permissions
ls -la ~/.ssh/

# Fix permissions if needed
chmod 600 ~/.ssh/id_ed25519_okd
chmod 644 ~/.ssh/id_ed25519_okd.pub
chmod 700 ~/.ssh
```

#### SSH Agent Issues
```bash
# Kill existing agent
pkill ssh-agent

# Start fresh agent
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519_okd
```

#### Wrong Key Being Used
```bash
# List loaded keys
ssh-add -l

# Remove all keys
ssh-add -D

# Add specific key
ssh-add ~/.ssh/id_ed25519_okd
```

### Debugging Commands
```bash
# Verbose SSH connection
ssh -vvv git@github.com

# Test specific key
ssh -i ~/.ssh/id_ed25519_okd -T git@github.com

# Check SSH agent
echo $SSH_AUTH_SOCK
ssh-add -l
```

## Key Rotation Process

### When to Rotate
- Every 6-12 months
- After security incidents
- When team members leave
- If keys are compromised

### Rotation Steps
1. Generate new key pair
2. Add new public key to all services
3. Test new key functionality
4. Update SSH configs and scripts
5. Remove old public key from services
6. Securely delete old private key

## Advanced Configuration

### Multiple Keys for Different Services
```bash
# Generate service-specific keys
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_github -C "github-access"
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_okd -C "okd-cluster-access"
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_servers -C "server-access"
```

### SSH Certificate Authority (Advanced)
For large deployments, consider SSH Certificate Authorities for centralized key management.