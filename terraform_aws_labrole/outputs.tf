#
# Outputs
#

# locals {
#   config_map_aws_auth = <<CONFIGMAPAWSAUTH
# apiVersion: v1
# kind: ConfigMap
# metadata:
#   name: aws-auth
#   namespace: kube-system
# data:
#   mapRoles: |
#     - rolearn: ${data.aws_iam_role.lab_role.arn}
#       username: system:node:{{EC2PrivateDNSName}}
#       groups:
#         - system:bootstrappers
#         - system:nodes
# CONFIGMAPAWSAUTH

#   kubeconfig = <<KUBECONFIG
# apiVersion: v1
# clusters:
# - cluster:
#     server: ${aws_eks_cluster.eks_cluster.endpoint}
#     certificate-authority-data: ${aws_eks_cluster.eks_cluster.certificate_authority[0].data}
#   name: kubernetes
# contexts:
# - context:
#     cluster: kubernetes
#     user: aws
#   name: aws
# current-context: aws
# kind: Config
# preferences: {}
# users:
# - name: aws
#   user:
#     exec:
#       apiVersion: client.authentication.k8s.io/v1beta1
#       command: aws-iam-authenticator
#       args:
#         - "token"
#         - "-i"
#         - "${var.cluster_name}"
# KUBECONFIG
# }

# output "config_map_aws_auth" {
#   value = local.config_map_aws_auth
# }

# output "kubeconfig" {
#   value = local.kubeconfig
# }

# output "aws_profile" {
#   value = var.aws_profile
# }

output "lb_ip" {
  value = kubernetes_service.nginx.status.0.load_balancer.0.ingress.0.hostname
}

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = aws_eks_cluster.eks_cluster.endpoint
}

output "cluster_name" {
  description = "Kubernetes Cluster Name"
  value       = aws_eks_cluster.eks_cluster.name
}