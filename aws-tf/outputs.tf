# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.eks.cluster_endpoint
}

output "cluster_security_group_id" {
  description = "Security group ids attached to the cluster control plane"
  value       = module.eks.cluster_security_group_id
}

output "region" {
  description = "AWS region"
  value       = var.region
}

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "cluster_name" {
  description = "Kubernetes Cluster Name"
  value       = module.eks.cluster_name
}

output "oidc_provider" {
  description = "OIDC provider URL for the EKS cluster"
  value       = module.eks.oidc_provider
}

output "node_security_group_id" {
  value       = module.eks.node_security_group_id
  description = "Security group ids attached to the worker nodes"
}

output "private_subnet_ids" {
  description = "Private subnet ids"
  value       = module.vpc.private_subnets

}


output "cert_arn" {
  value = aws_acm_certificate.web_cert.arn
}

output "domain_validation_options" {
  value = aws_acm_certificate.web_cert.domain_validation_options
}

output "module_path" {
  value = path.module
}
