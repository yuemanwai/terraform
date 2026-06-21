# Terraform Infrastructure Portfolio

This repository contains Terraform examples for cloud infrastructure and Kubernetes delivery.

The main project is [aws-tf](aws-tf), which provisions an AWS EKS environment. The other folders are kept as reference material for later review:

- [azure-tf](azure-tf)
- [gcp-tf](gcp-tf)
- [multicloud](multicloud)

## Project Highlights

- AWS EKS provisioning with Terraform
- VPC, subnet, and cluster access design
- `kubectl` access from my local notebook
- ArgoCD bootstrap for GitOps-driven application delivery
- Security and cost workflows with GitHub Actions
- Local pre-commit hooks for formatting, YAML checks, Terraform docs, and secret scanning

## Checks

- Local quality gates: `pre-commit` with `terraform_fmt`, `terraform_docs`, `gitleaks`, and basic file hygiene hooks
- CI security scan: GitHub Actions with Trivy for vuln, secret, and misconfiguration checks on `aws-tf`

## Why This Project

The AWS module shows the kind of work I want to do professionally:

- designing infrastructure that is practical to operate
- documenting tradeoffs directly in code
- balancing access, security, and developer usability
- keeping automation in place for validation and cost review

## GitOps and Observability

The AWS stack enables ArgoCD in [aws-tf/k8s/k8s.tf](aws-tf/k8s/k8s.tf) and uses it as the delivery layer for Kubernetes workloads.

Application stacks such as Kubecost and the Prometheus / Grafana / Loki monitoring setup are managed from a separate ArgoCD repository, which keeps the infrastructure layer and application layer cleanly separated.

## Repository Layout

- [aws-tf](aws-tf): primary AWS EKS module
- [azure-tf](azure-tf): Azure reference implementation
- [gcp-tf](gcp-tf): GCP reference implementation
- [multicloud](multicloud): multi-cloud Kubernetes tutorial material

## Architecture Diagram

The architecture diagram below gives a quick view of the AWS stack.

![AWS architecture diagram](docs/images/aws-architecture.png)

It highlights the main network and Kubernetes layout:

- VPC layout
- public and private subnets
- EKS control plane access
- node group placement
- supporting services such as RDS, Secrets Manager, and Certificate Manager

## Suggested Reading Order

1. [aws-tf/main.tf](aws-tf/main.tf)
2. [aws-tf/README.md](aws-tf/README.md)
3. [.github/workflows/security.yml](.github/workflows/security.yml)
4. [.github/workflows/cost-analysis.yml](.github/workflows/cost-analysis.yml)

## Archive

The original long-form README is stored in [docs/archive/README-original.md](docs/archive/README-original.md).
