# AWS EKS Infrastructure Stack

This directory contains the AWS foundation layer for the project.

For the top-level project overview, see [../README.md](../README.md).

Terraform here provisions the AWS networking, EKS cluster, RDS database layer, and Kubernetes bootstrap resources used by the platform. The application repo and GitOps manifests live separately.

## What This Stack Provisions

- A VPC with public and private subnets across two Availability Zones
- An Amazon EKS cluster with a managed node group on SPOT capacity
- A public EKS endpoint so `kubectl` can be used from a local workstation
- Terraform Cloud remote state and OIDC-based AWS access
- An explicit administrator role for the SSO identity used in this project
- A PostgreSQL RDS instance in private subnets
- AWS Secrets Manager integration for the database master secret
- IRSA-based access for the web app service account to read the DB secret
- Cloudflare DNS, ACM certificates, and ALB ingress integration
- ArgoCD bootstrap and core Kubernetes add-ons in [`k8s/`](k8s)

## Architecture Snapshot

![AWS architecture diagram](../docs/images/aws-architecture.png)

The diagram reflects the main building blocks in this stack:

- VPC networking
- public and private subnet placement
- EKS control plane and worker node placement
- RDS, Secrets Manager, ACM, and DNS integration

## Directory Layout

- [`main.tf`](main.tf): core VPC and EKS foundation
- [`provider.tf`](provider.tf): Terraform Cloud backend and providers
- [`variables.tf`](variables.tf): inputs for AWS, Cloudflare, and ArgoCD bootstrap
- [`outputs.tf`](outputs.tf): values exposed after apply
- [`rds/`](rds): PostgreSQL workspace built on the base cluster and VPC
- [`k8s/`](k8s): cluster add-ons, ExternalDNS, and ArgoCD bootstrap

## Prerequisites

- AWS access with permission to create VPC, EKS, IAM, and related resources
- Terraform Cloud access for the base workspace used by this stack
- A Cloudflare account, zone ID, and API token
- A GitHub personal access token if the ArgoCD repo is private
- A local workstation for `kubectl` access after the cluster is created

## Required Inputs

Set these variables before applying the base stack:

- `region`
- `cloudflare_api_token`
- `domain_name`
- `cloudflare_zone_id`

For the RDS workspace, also provide:

- `db_username`
- `db_name`
- `db_port`

For ArgoCD bootstrap, also provide:

- `repoURL`
- `github_username`
- `github_token`

## Suggested Deployment Order

1. Apply the base workspace in this directory.
2. Apply [`rds/`](rds) if you want the database layer.
3. Apply [`k8s/`](k8s) to bootstrap ArgoCD and the cluster add-ons.

## Accessing the Cluster

After the base workspace is applied, update your kubeconfig from your local workstation:

```bash
aws eks --region $(terraform output -raw region) update-kubeconfig \
  --name $(terraform output -raw cluster_name)
```

Then verify access:

```bash
kubectl config get-contexts
kubectl get nodes
```

## Useful Outputs

- `region`
- `vpc_id`
- `private_subnet_ids`
- `cluster_name`
- `cluster_endpoint`
- `cluster_version`
- `oidc_provider`
- `oidc_provider_arn`
- `cluster_security_group_id`
- `node_security_group_id`

## Notes

- The cluster endpoint is intentionally public so local `kubectl` access stays simple.
- The cluster uses managed node groups with SPOT capacity for cost control.
- Application deployment, observability tooling, cost monitoring, and progressive delivery are managed in the separate GitOps repository.
