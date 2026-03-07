output "irsa_rds_role_arn" {
  description = "IAM Role ARN for IRSA RDS SecretsManager access"
  value       = module.irsa_rds_access.iam_role_arn
  sensitive   = true
}

output "db_secret_arn" {
  value     = module.db.db_instance_master_user_secret_arn
  sensitive = true
}

output "db_instance_address" {
  description = "RDS instance address"
  value       = module.db.db_instance_address
  sensitive   = true
}

output "db_name" {
  description = "Database name"
  value       = var.db_name
  sensitive   = true
}

output "rds_endpoint" {
  description = "The connection endpoint for the RDS instance"
  value       = module.db.db_instance_endpoint
}
