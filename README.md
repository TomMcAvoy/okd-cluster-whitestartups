# OKD Cluster White Startups - DevSecOps Automation

A comprehensive OKD (OpenShift) cluster automation solution built with DevSecOps best practices, featuring VMware Fusion/vSphere automation, Fedora CoreOS, HashiCorp tooling, and Ansible configuration management.

## 🏗️ Architecture Overview

This project provides infrastructure-as-code and configuration management for deploying and managing OKD clusters using:

- **VMware Fusion/vSphere** for virtualization infrastructure
- **Fedora CoreOS** as the container-optimized OS
- **HashiCorp Terraform** for infrastructure provisioning  
- **HashiCorp Vault** for secrets management
- **Ansible** for configuration management and deployment
- **Docker containers** for supporting services
- **Security scanning** and compliance automation
- **CI/CD pipelines** with integrated security checks

## 📁 Project Structure

```
├── terraform/          # Infrastructure as Code
│   ├── modules/        # Reusable Terraform modules
│   ├── environments/   # Environment-specific configs
│   └── providers/      # Provider configurations
├── ansible/            # Configuration Management
│   ├── playbooks/      # Ansible playbooks
│   ├── roles/          # Custom roles
│   └── inventory/      # Environment inventories
├── vmware/             # VMware automation scripts
│   ├── templates/      # VM templates and configs
│   └── scripts/        # PowerCLI and shell scripts
├── docker/             # Container services
│   ├── services/       # Supporting service containers
│   └── compose/        # Docker Compose configurations
├── security/           # Security and compliance
│   ├── policies/       # Security policies as code
│   └── scanners/       # Security scanning configs
├── ci-cd/              # CI/CD pipeline definitions
│   ├── github/         # GitHub Actions workflows
│   └── jenkins/        # Jenkins pipeline scripts
├── monitoring/         # Monitoring and observability
│   ├── prometheus/     # Prometheus configurations
│   └── grafana/        # Grafana dashboards
└── docs/               # Documentation
    ├── architecture/   # Architecture documentation
    ├── operations/     # Operational runbooks
    └── security/       # Security guidelines
```

## 🚀 Quick Start

### Prerequisites

- VMware Fusion (for local development) or vSphere access
- HashiCorp Terraform >= 1.0
- Ansible >= 2.9
- Docker and Docker Compose
- Git

### Installation

1. Clone the repository:
```bash
git clone https://github.com/TomMcAvoy/okd-cluster-whitestartups.git
cd okd-cluster-whitestartups
```

2. Copy and customize configuration:
```bash
cp terraform/environments/example.tfvars terraform/environments/dev.tfvars
# Edit dev.tfvars with your environment settings
```

3. Initialize infrastructure:
```bash
cd terraform
terraform init
terraform plan -var-file=environments/dev.tfvars
terraform apply -var-file=environments/dev.tfvars
```

4. Configure cluster with Ansible:
```bash
cd ../ansible
ansible-playbook -i inventory/dev playbooks/site.yml
```

## 🔐 Security Features

- **Secrets Management**: HashiCorp Vault integration
- **Policy as Code**: OPA/Gatekeeper policies
- **Vulnerability Scanning**: Trivy, Clair integration
- **Compliance Checking**: CIS benchmarks automation
- **Network Security**: Calico network policies
- **RBAC**: Fine-grained access controls

## 🔧 DevSecOps Pipeline

The project includes automated CI/CD pipelines that:

- ✅ Lint and validate infrastructure code
- ✅ Run security scans on containers and code
- ✅ Test infrastructure deployments
- ✅ Apply configuration changes safely
- ✅ Monitor deployment health
- ✅ Generate compliance reports

## 📊 Monitoring & Observability

- **Metrics**: Prometheus + Grafana
- **Logging**: ELK/EFK stack
- **Tracing**: Jaeger
- **Alerting**: AlertManager integration
- **Health Checks**: Automated monitoring

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes following DevSecOps practices
4. Run security and quality checks
5. Submit a pull request

## 📚 Documentation

- [Architecture Overview](docs/architecture/README.md)
- [Installation Guide](docs/operations/installation.md)
- [Security Guidelines](docs/security/README.md)
- [Troubleshooting](docs/operations/troubleshooting.md)

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
