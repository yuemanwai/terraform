# AWS EKS Infrastructure Platform

> Infrastructure-as-Code project built with Terraform.
>
> This repository provisions the AWS infrastructure layer for a cloud-native platform hosting an AI-powered Japanese learning application. The design emphasizes automation, security, GitOps readiness, high availability, and operational best practices.

---

## Overview

This repository serves as the infrastructure foundation of the project.

Terraform is used to provision AWS networking, Kubernetes, database, identity, and supporting cloud services. Application deployment and platform services are managed separately through a dedicated ArgoCD GitOps repository.

The infrastructure was designed to resemble production environments while remaining cost-conscious enough to operate within a student budget.

---

## Architecture

![AWS Architecture Diagram](docs/images/aws-architecture.png)

### Key Components

* Amazon EKS
* Amazon RDS PostgreSQL
* AWS Secrets Manager
* Application Load Balancer
* Cloudflare DNS
* ACM Certificates
* IAM Roles for Service Accounts (IRSA)
* Terraform Cloud OIDC Federation
* Multi-AZ Networking

### Architecture Highlights

* Public and private subnet segmentation
* EKS worker nodes deployed exclusively in private subnets
* RDS deployment isolated in private database subnets
* Multi-AZ architecture across two Availability Zones
* TLS termination through AWS Application Load Balancer
* Cloudflare-managed DNS and edge protection
* NAT Gateway for controlled outbound internet access

---

## Design Goals

This project was built to explore how modern cloud platforms are provisioned and operated using Infrastructure as Code.

Key objectives included:

* Automated infrastructure provisioning
* GitOps-ready Kubernetes operations
* High availability across multiple Availability Zones
* Secure cloud authentication without long-lived credentials
* Least-privilege workload access control
* Separation of infrastructure and application delivery layers

---

## Infrastructure Components

### Networking

* VPC spanning two Availability Zones
* Public and private subnet architecture
* Route table segmentation
* Internet Gateway
* NAT Gateway

### Kubernetes Platform

* Amazon EKS Cluster
* Managed Node Groups
* OIDC Provider
* Kubernetes bootstrap resources

### Database Layer

* Amazon RDS PostgreSQL
* Private subnet deployment
* Secrets Manager integration

### Ingress & DNS

* AWS Application Load Balancer
* AWS Certificate Manager (ACM)
* Cloudflare DNS integration

---

## Security Highlights

### OIDC Federation

Terraform Cloud authenticates to AWS using OIDC federation and IAM role assumption.

This removes the need to store long-lived AWS access keys inside CI/CD systems.

### IAM Roles for Service Accounts (IRSA)

Kubernetes workloads authenticate directly to AWS services through IAM Roles for Service Accounts.

This eliminates embedded cloud credentials inside containers.

### Secrets Management

AWS Secrets Manager is used to manage database credentials.

Features include:

* Automatic credential rotation
* Dynamic secret retrieval
* Reduced credential exposure risk

### Security Validation

Security checks are integrated into development workflows:

* Trivy vulnerability scanning
* Terraform misconfiguration scanning
* Gitleaks secret detection
* Pre-commit validation

---

## GitOps Integration

This repository provisions and bootstraps the infrastructure layer.

Application delivery is handled separately through ArgoCD using a dedicated GitOps repository.

The GitOps layer manages:

* ArgoCD
* Prometheus
* Grafana
* Loki
* Kubecost
* Argo Rollouts
* Application workloads

This separation allows infrastructure provisioning and workload deployment to evolve independently.

---

## Repository Structure

```text
.
├── aws-tf/
├── azure-tf/
├── gcp-tf/
├── multicloud/
└── docs/
```

### Directory Description

| Directory | Purpose                                                |
| --------- | ------------------------------------------------------ |
| aws-tf/   | Core AWS VPC, EKS, RDS, and Kubernetes bootstrap layer |
| azure-tf/  | Azure reference implementation                         |
| gcp-tf/    | GCP reference implementation                           |
| multicloud/ | Multi-cloud learning material                          |
| docs/     | Architecture documentation                             |

---

## Related Repositories

| Repository       | Purpose                                          |
| ---------------- | ------------------------------------------------ |
| argocd-local     | GitOps delivery platform and Kubernetes services |
| japanese-academy | Flask web application                            |

---

## Technologies

Terraform • AWS • Amazon EKS • Amazon RDS • IAM • OIDC • IRSA • Secrets Manager • ACM • Cloudflare • GitHub Actions • Trivy • Gitleaks

---

## Notes

This repository focuses exclusively on infrastructure provisioning.

Application deployment, observability tooling, cost monitoring, and progressive delivery configurations are intentionally managed through a separate GitOps repository to maintain clear separation of concerns.
