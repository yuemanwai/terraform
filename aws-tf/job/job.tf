
data "aws_eks_cluster" "cluster" {
  name = data.terraform_remote_state.vpc.outputs.cluster_name
}

data "aws_eks_cluster_auth" "eks" {
  name = data.aws_eks_cluster.cluster.name
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.eks.token
}

# ================================================================================================================== #

# resource "kubernetes_job_v1" "rds_test" {
#   metadata {
#     name      = "rds-connection-test"
#     namespace = "default"
#   }

#   spec {
#     template {
#       metadata {
#         labels = {
#           app = "rds-test"
#         }
#       }

#       spec {
#         restart_policy = "Never"

#         container {
#           name  = "psql-client"
#           image = "bitnami/postgresql:16"  # 對應你 RDS 版本

#           command = [
#             "sh", "-c",
#             "psql \"$$DB_URL?sslmode=require\" -c 'SELECT version();'"
#           ]



#           env {
#             name  = "DB_HOST"
#             value = data.terraform_remote_state.rds.outputs.rds_endpoint
#           }
#           env {
#             name  = "DB_USER"
#             value = data.terraform_remote_state.rds.outputs.db_username
#           }
#           env {
#             name  = "DB_PASSWORD"
#             value = data.terraform_remote_state.rds.outputs.db_password
#           }
#           env {
#             name  = "DB_NAME"
#             value = data.terraform_remote_state.rds.outputs.db_name
#           }
#           env {
#             name  = "DB_URL"
#             value = data.terraform_remote_state.rds.outputs.db_url
#           }
#         }
#       }
#     }

#     backoff_limit = 0
#   }
# }

# ================================================================================================================== #

data "aws_secretsmanager_secret_version" "db_secret" {
  secret_id = data.terraform_remote_state.rds.outputs.db_password_arn
}

resource "kubernetes_pod" "psql_debug" {
  metadata {
    name      = "psql-debug"
    namespace = "default"
  }

  spec {
    restart_policy = "Never"

    container {
      name  = "psql-client"
      image = "bitnami/postgresql:16"  # 或你用開個版本

      # command = [
      #   "sh", "-c",
      #   "PGPASSWORD=$$DB_PASSWORD psql -h $$DB_HOST -U $$DB_USER -d $$DB_NAME 'sslmode=require' -c 'SELECT version();'"
      # ]
      
      command = ["sh", "-c", "sleep 3600"]

      env {
        name  = "DB_HOST"
        value = data.terraform_remote_state.rds.outputs.rds_endpoint
      }
      env {
        name  = "DB_USER"
        value = data.terraform_remote_state.rds.outputs.db_username
      }
      env {
        name  = "DB_PASSWORD"
        value = jsondecode(data.aws_secretsmanager_secret_version.db_secret.secret_string)["password"]
      }
      env {
        name  = "DB_NAME"
        value = data.terraform_remote_state.rds.outputs.db_name
      }
      # env {
      #   name  = "DB_URL"
      #   value = data.terraform_remote_state.rds.outputs.db_url
      # }
    }
  }
}

# ================================================================================================================== #

# output "db_secret" {
#   value = jsondecode(data.aws_secretsmanager_secret_version.db_secret.secret_string)["password"]
#   sensitive = true
# }