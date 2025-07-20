output "rds_endpoint" {
  value = module.db.db_instance_address
}

output "rds_port" {
  value = module.db.db_instance_port
}

output "db_name" {
  value = module.db.db_instance_name
}

output "db_username" {
  value = module.db.db_instance_username
}

output "db_password_arn" {
  value = module.db.db_instance_master_user_secret_arn
  sensitive = true
}

output "irsa_rds_role_arn" {
  description = "IAM Role ARN for IRSA RDS SecretsManager access"
  value       = module.irsa_rds_access.iam_role_arn
}

# 不支持直接輸出db password
# output "db_url" { 
#   value = "postgresql://${var.db_username}:${var.db_password}@${module.db.db_instance_endpoint}/${module.db.db_instance_name}" 
#   sensitive = true
# }

