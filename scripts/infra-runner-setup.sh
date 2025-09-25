#!/bin/bash
# Automated infrastructure & self-hosted runner setup script
# Covers all steps in infra-runner-setup-checklist.md

set -e

# 1. Host Preparation
sudo apt-get update && sudo apt-get upgrade -y
sudo apt-get install -y ufw auditd curl wget
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw enable
sudo systemctl enable auditd && sudo systemctl start auditd

# Restrict SSH to key-based auth only
sudo sed -i 's/^#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sudo systemctl restart sshd

# 2. Runner Installation
RUNNER_DIR="$HOME/actions-runner"
if [ ! -d "$RUNNER_DIR" ]; then
  mkdir -p "$RUNNER_DIR"
  cd "$RUNNER_DIR"
  curl -o actions-runner.tar.gz -L https://github.com/actions/runner/releases/latest/download/actions-runner-linux-x64-2.316.0.tar.gz
  tar xzf actions-runner.tar.gz
  ./bin/installdependencies.sh
  echo "Register your runner with your repo/org using the following command:"
  echo "  ./config.sh --url https://github.com/<owner>/<repo> --token <token>"
  echo "After registration, start the runner as a service:"
  echo "  sudo ./svc.sh install"
  echo "  sudo ./svc.sh start"
  cd -
else
  echo "Runner directory already exists."
fi

# 3. Container Runtime
if ! command -v podman &> /dev/null; then
  echo "Installing Podman..."
  . /etc/os-release
  if [[ "$ID" == "ubuntu" || "$ID" == "debian" ]]; then
    sudo apt-get install -y podman
  else
    sudo dnf install -y podman
  fi
else
  echo "Podman already installed."
fi

# Harden Podman
sudo mkdir -p /etc/containers
sudo tee /etc/containers/registries.conf > /dev/null <<EOF
[registries.search]
registries = ['docker.io', 'quay.io']
EOF

# 4. Monitoring & Logging
sudo systemctl enable auditd && sudo systemctl start auditd

# 5. Secrets & Credentials
echo "Ensure secrets are stored in GitHub Actions secrets, not on runner."
find $HOME -type f -name '*secret*' -o -name '*password*' -o -name '*PRIVATE_KEY*' | while read f; do
  echo "Potential secret file: $f"; done

# 6. Validation
echo "Running preflight checks..."
FULLY_AUTOMATED=1 bash scripts/step-by-step-implementation.sh

echo "Infrastructure and runner setup script completed. Please finish runner registration manually as instructed above."
