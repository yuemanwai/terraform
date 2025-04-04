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

output "cluster_name" {
  description = "Kubernetes Cluster Name"
  value       = module.eks.cluster_name
}

# output "kubeconfig" {
# value = join("\n", [
#   "apiVersion: v1",
#   "clusters:",
#   "- cluster:",
#   "    server: ${module.eks.cluster_endpoint}",
#   "    certificate-authority-data: ${base64encode(module.eks.cluster_certificate_authority_data)}",
#   "  name: ${module.eks.cluster_name}",
#   "contexts:",
#   "- context:",
#   "    cluster: ${module.eks.cluster_name}",
#   "    user: ${module.eks.cluster_name}",
#   "  name: ${module.eks.cluster_name}",
#   "current-context: ${module.eks.cluster_name}",
#   "kind: Config",
#   "preferences: {}",
#   "users:",
#   "- name: ${module.eks.cluster_name}",
#   "  user:",
#   "    exec:",
#   "      apiVersion: client.authentication.k8s.io/v1",
#   "      command: aws",
#   "      args:",
#   "        - eks",
#   "        - get-token",
#   "        - --cluster-name",
#   "        - ${module.eks.cluster_name}",
#   "        - --interactive-mode",
#   "        - auto",    
# ])
# }
