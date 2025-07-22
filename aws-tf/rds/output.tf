output "db_password_arn" {
  value = module.db.db_instance_master_user_secret_arn
  sensitive = true
}

output "db_password" {
  value = jsondecode(data.aws_secretsmanager_secret_version.db-secret.secret_string)["password"]
  sensitive = true
}

output "db_url" { 
  description = "The full database connection URL."
  value = format("postgresql://%s:%s@%s:%s/%s",
    var.db_username,
    jsondecode(data.aws_secretsmanager_secret_version.db-secret.secret_string)["password"],
    module.db.db_instance_address,
    var.db_port,
    var.db_name
    )
  sensitive = true
}