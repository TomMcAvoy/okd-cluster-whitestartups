# GitHub Personal Access Token (PAT) Generation Guide

This guide explains how to generate classic Personal Access Tokens (PAT) for the OKD cluster automation project.

## Why You Need a PAT

Personal Access Tokens are required for:
- Accessing GitHub repositories programmatically
- Authenticating with GitHub APIs
- Cloning private repositories in automation scripts
- Performing Git operations in CI/CD pipelines

## Generating a Classic PAT

### Step 1: Access GitHub Settings
1. Log in to your GitHub account
2. Click on your profile picture (top right corner)
3. Select "Settings" from the dropdown menu
4. In the left sidebar, click "Developer settings"
5. Click "Personal access tokens" → "Tokens (classic)"

### Step 2: Create New Token
1. Click "Generate new token" → "Generate new token (classic)"
2. Give your token a descriptive name like "OKD Cluster Automation"
3. Set expiration (recommended: 90 days for security)

### Step 3: Select Required Scopes
For OKD cluster automation, select these scopes:

**Repository Access:**
- `repo` - Full control of private repositories
  - `repo:status` - Access commit status
  - `repo_deployment` - Access deployment status
  - `public_repo` - Access public repositories

**Workflow Access:**
- `workflow` - Update GitHub Action workflows

**Package Access (if using GitHub Packages):**
- `read:packages` - Download packages from GitHub Package Registry
- `write:packages` - Upload packages to GitHub Package Registry

**User Information:**
- `read:user` - Read user profile data
- `user:email` - Access user email addresses

### Step 4: Generate and Save Token
1. Click "Generate token"
2. **IMPORTANT**: Copy the token immediately - you won't be able to see it again
3. Store it securely (see storage section below)

## Secure Token Storage

### Environment Variables (Recommended)
Create a `.env` file in your project root:
```bash
# GitHub Configuration
GITHUB_TOKEN=your_pat_token_here
GITHUB_USERNAME=your_github_username
```

### For Shell Sessions
Add to your `~/.bashrc` or `~/.zshrc`:
```bash
export GITHUB_TOKEN="your_pat_token_here"
```

### For GitHub Actions
Add as a repository secret:
1. Go to your repository Settings
2. Click "Secrets and variables" → "Actions"
3. Click "New repository secret"
4. Name: `GITHUB_TOKEN`
5. Value: Your PAT token

## Using the PAT

### Git Operations
```bash
# Clone using PAT
git clone https://your_username:your_pat_token@github.com/TomMcAvoy/okd-cluster-whitestartups.git

# Or set up credential helper
git config --global credential.helper store
echo "https://your_username:your_pat_token@github.com" > ~/.git-credentials
```

### API Calls
```bash
# Using curl
curl -H "Authorization: token your_pat_token" https://api.github.com/user

# Using GitHub CLI
gh auth login --with-token < your_token_file
```

## Security Best Practices

1. **Never commit tokens to repositories**
2. **Use environment variables or secure credential stores**
3. **Set appropriate token expiration dates**
4. **Regularly rotate tokens**
5. **Use minimal required scopes**
6. **Monitor token usage in GitHub settings**
7. **Revoke unused or compromised tokens immediately**

## Token Management

### Viewing Active Tokens
- Go to GitHub Settings → Developer settings → Personal access tokens
- Review active tokens and their last used dates

### Revoking Tokens
1. Find the token in your PAT list
2. Click "Delete" next to the token
3. Confirm the deletion

### Token Renewal
1. Before expiration, generate a new token
2. Update all systems using the old token
3. Revoke the old token

## Troubleshooting

### Common Issues
- **403 Forbidden**: Check token scopes and expiration
- **401 Unauthorized**: Verify token format and validity
- **Token not working**: Ensure proper URL encoding for special characters

### Testing Your Token
```bash
# Test token validity
curl -H "Authorization: token your_pat_token" https://api.github.com/user
```

Expected response should include your user information.