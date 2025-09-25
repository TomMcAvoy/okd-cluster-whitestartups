# Infrastructure & Self-Hosted Runner Setup Checklist

## 1. Host Preparation
- [ ] Provision dedicated VM or bare-metal host for runner
- [ ] Apply latest OS patches and security updates
- [ ] Set up firewall: allow only required ports (SSH, runner, monitoring)
- [ ] Restrict SSH access (key-based, limited users)
- [ ] Configure network segmentation (VLANs, subnets)

## 2. Runner Installation
- [ ] Install GitHub Actions self-hosted runner
- [ ] Register runner to your repository/org
- [ ] Run runner as non-root user
- [ ] Set up runner service for auto-restart
- [ ] Limit runner permissions (no sudo, minimal access)

## 3. Container Runtime
- [ ] Install Podman (preferred) or Docker (rootless if possible)
- [ ] Validate runtime installation (`podman --version` or `docker --version`)
- [ ] Harden container runtime (disable remote API, restrict images)

## 4. Monitoring & Logging
- [ ] Enable OS audit logging (auditd, journald)
- [ ] Set up runner logs (GitHub Actions, custom audit)
- [ ] Monitor for suspicious activity (Falco, OSSEC)

## 5. Secrets & Credentials
- [ ] Store secrets in GitHub Actions secrets (never on runner)
- [ ] Rotate credentials regularly
- [ ] Validate no secrets in runner environment or files

## 6. Validation
- [ ] Run preflight script (`step-by-step-implementation.sh` preflight section)
- [ ] Confirm network connectivity to GitHub, registries, cluster nodes
- [ ] Document runner host details and security controls

---

> Use this checklist before bootstrapping your OKD cluster. For automation, see `scripts/step-by-step-implementation.sh`.
