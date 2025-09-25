# OKD Cluster Automation Project

This project is designed to automate the provisioning and management of an OKD cluster using TypeScript and pnpm, following DevSecOps best practices. It includes configuration for free CI/CD tools suitable for OKD (GitHub Actions, Tekton, Argo CD).

## Features
- TypeScript-based automation scripts
- pnpm for package management
- DevSecOps workflow templates
- CI/CD integration examples

## Getting Started
1. Install [pnpm](https://pnpm.io/installation) and [Node.js](https://nodejs.org/)
2. Run `pnpm install` to set up dependencies
3. Review CI/CD templates in `.github/workflows/`, `tekton/`, and `argocd/` folders

## Folder Structure
- `src/` - TypeScript automation scripts
- `.github/workflows/` - GitHub Actions workflows
- `tekton/` - Tekton pipeline definitions
- `argocd/` - Argo CD manifests

## Security
- Follows DevSecOps best practices for cluster automation
- Example security scanning and policy enforcement included

## License
This project uses only free and open-source tools.
