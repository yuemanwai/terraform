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



# output "db_url" { 
#   value = "postgresql://${var.db_username}:${var.db_password}@${module.db.db_instance_endpoint}/${module.db.db_instance_name}" 
#   sensitive = true
# }