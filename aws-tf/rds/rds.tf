
data "aws_vpc" "vpc" {
  id = data.terraform_remote_state.vpc_eks.outputs.vpc_id
}

resource "aws_security_group" "rds_sg" {
  name        = "rds-sg"
  description = "Allow inbound PostgreSQL"
  vpc_id      = data.aws_vpc.vpc.id

  ingress {
    description     = "Allow EKS nodes to access RDS"
    from_port       = var.db_port
    to_port         = var.db_port
    protocol        = "tcp"
    security_groups = [data.terraform_remote_state.vpc_eks.outputs.node_security_group_id]
  }

  # egress {
  #   from_port   = 0
  #   to_port     = 0
  #   protocol    = "-1"
  #   cidr_blocks = ["0.0.0.0/0"]
  # }

  tags = {
    Name = "rds-sg"
  }
}

# https://registry.terraform.io/modules/terraform-aws-modules/rds/aws/latest
module "db" {
  source = "terraform-aws-modules/rds/aws"

  identifier = var.db_name

  engine            = "postgres"
  engine_version    = "16.6"
  instance_class    = "db.t3.micro"
  allocated_storage = 5

  db_name  = var.db_name
  username = var.db_username
  port     = var.db_port

  major_engine_version = "16"
  family               = "postgres16"


  # DB subnet group
  vpc_security_group_ids = [
    aws_security_group.rds_sg.id,
  ]
  create_db_subnet_group = true
  subnet_ids             = data.terraform_remote_state.vpc_eks.outputs.private_subnet_ids

  # Database Deletion Protection
  deletion_protection = false
  skip_final_snapshot = true

  tags = {
    Environment = "demo"
    Terraform   = "true"
    Owner       = "me"
  }
}

# ================================================================================================================== #

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/secretsmanager_secret_version
data "aws_secretsmanager_secret_version" "db-secret" {
  secret_id = module.db.db_instance_master_user_secret_arn
}


# ================================================================================================================== #

# 以下是 IRSA 的配置，允许 EKS Pod 访问 RDS Secrets Manager

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "rds_secrets_policy" {
  statement {
    actions   = ["secretsmanager:GetSecretValue"]
    resources = [module.db.db_instance_master_user_secret_arn]
  }
}

resource "aws_iam_policy" "rds_secrets" {
  name        = "allow-read-db-secret"
  description = "Allow reading DB secret from Secrets Manager"
  policy      = data.aws_iam_policy_document.rds_secrets_policy.json
}

module "irsa_rds_access" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version = "5.39.0"

  create_role                   = true
  role_name                     = "irsa-rds-access-${data.terraform_remote_state.vpc_eks.outputs.cluster_name}"
  provider_url                  = data.terraform_remote_state.vpc_eks.outputs.oidc_provider
  role_policy_arns              = [aws_iam_policy.rds_secrets.arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:default:webapp-sa"]
}
