# outputs.tf

output "kubeconfig" {
  description = "Kubernetes config for the EKS cluster."
  value       = module.eks.kubeconfig
  sensitive   = true
}

output "eks_cluster_name" {
  description = "Name of the EKS cluster."
  value       = module.eks.cluster_name
}

output "vpc_id" {
  description = "ID of the VPC created."
  value       = module.vpc.vpc_id
}

output "private_subnets" {
  description = "List of private subnets."
  value       = module.vpc.private_subnets
}

output "public_subnets" {
  description = "List of public subnets."
  value       = module.vpc.public_subnets
}

output "eks_cluster_security_group_id" {
  description = "Security Group ID of the EKS cluster."
  value       = module.eks.cluster_security_group_id
}

output "eks_node_group_security_group_id" {
  description = "Security Group ID of the EKS node group."
  value       = module.eks.node_security_group_id
}

output "rds_endpoint" {
  description = "The connection endpoint for the RDS instance."
  value       = module.db_postgresql.db_instance_address
}

output "rds_port" {
  description = "The port for the RDS instance."
  value       = module.db_postgresql.db_instance_port
}

output "rds_username" {
  description = "The master username for the RDS instance."
  value       = module.db_postgresql.db_instance_username
}

output "rds_password" {
  description = "The master password for the RDS instance."
  value       = random_string.db_password.result
  sensitive   = true
}

output "my_webapp_alb_dns_name" {
  description = "DNS name of the ALB created for my-webapp-new."
  value       = try(kubernetes_ingress_v1.my_webapp_ingress[0].status.0.load_balancer.0.ingress.0.hostname, "")
}