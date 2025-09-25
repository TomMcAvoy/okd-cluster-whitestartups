#!/bin/bash
# Step-by-step implementation script for OKD cluster monitoring, remediation, and security hardening
# Confirms each step before proceeding

set -e

confirm() {
  if [ "$FULLY_AUTOMATED" = "1" ] || [ "$1" = "--auto" ]; then
    echo "[AUTO] Proceeding with step: $1"
    return
  fi
  read -p "Proceed with step: $1? (y/n) " yn
  case $yn in
    [Yy]*) ;;
    *) echo "Aborted at step: $1"; exit 1;;
  esac
}

# 1. Preflight checks
confirm "Preflight checks (OS, resources, container runtime, KUBECONFIG, network)"
echo "Checking runner OS and resources..."
echo "Runner OS: $(uname -a)"
echo "CPU cores: $(nproc || sysctl -n hw.ncpu)"
echo "Memory: $(free -h || vm_stat)"
echo "Disk: $(df -h .)"
echo "Checking Docker/Podman availability..."
(docker --version || podman --version) && echo "Container runtime available" || (echo "No container runtime found" && exit 1)
echo "Checking KUBECONFIG..."
if [ -f "$KUBECONFIG" ]; then echo "KUBECONFIG found: $KUBECONFIG"; else echo "KUBECONFIG not found"; exit 1; fi
echo "Checking network connectivity..."
ping -c 2 github.com
ping -c 2 registry-1.docker.io
ping -c 2 quay.io

# 2. Install Trivy for image scanning
confirm "Install Trivy for image vulnerability scanning"
curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin

# 3. Build remediation handler image
confirm "Build remediation handler Docker image"
cd monitoring/remediation
(docker build -t okd-remediation-handler:latest . || podman build -t okd-remediation-handler:latest .)
cd -

# 4. Scan image for vulnerabilities
confirm "Scan remediation handler image for vulnerabilities"
trivy image --severity HIGH,CRITICAL okd-remediation-handler:latest

# 5. Check for secrets in repo
confirm "Check for secrets in repository"
if grep -r --exclude-dir='.git' --exclude='*.md' --exclude='*.yml' --exclude='*.yaml' 'password\|secret\|PRIVATE_KEY' .; then echo "Potential secrets found!"; exit 1; else echo "No secrets detected."; fi

# 6. Enable audit logging
confirm "Enable audit logging for workflow run"
mkdir -p /var/log/ghaudit
logfile="/var/log/ghaudit/workflow-$(date +%Y%m%d-%H%M%S).log"
echo "Audit log for workflow run $(date)" >> "$logfile"
echo "Runner: $(uname -a)" >> "$logfile"
echo "User: $(whoami)" >> "$logfile"

# 7. Test remediation handler script
confirm "Test remediation handler script"
cd monitoring/remediation
bash remediation-handler.sh <<< '{"alerts":[{"labels":{"alertname":"PodCrashLooping","namespace":"default","pod":"test-pod"}}]}'
cd -

# 8. Upload Prometheus alert rules and Alertmanager config (manual step)
confirm "Upload Prometheus alert rules and Alertmanager config (manual step)"
echo "Upload monitoring/prometheus/alert-rules.yaml and monitoring/alertmanager/alertmanager-config.yaml to your monitoring stack."

# 9. Complete
echo "All steps completed successfully."
echo "To run fully automated, set FULLY_AUTOMATED=1 in your environment or run:"
echo "  FULLY_AUTOMATED=1 bash scripts/step-by-step-implementation.sh"
