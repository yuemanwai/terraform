
data "aws_vpc" "vpc" {
  id = data.terraform_remote_state.vpc.outputs.vpc_id
}

resource "aws_security_group" "rds_sg" {
  name        = "rds-sg"
  description = "Allow inbound PostgreSQL"
  vpc_id      = data.aws_vpc.vpc.id

  ingress {
    description     = "Allow EKS nodes to access RDS"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    security_groups = [data.terraform_remote_state.vpc.outputs.node_security_group_id]
  }
  
  ingress {
      from_port         = 5432
      to_port           = 5432
      protocol          = "tcp"
      cidr_blocks       = ["112.120.137.102/32"]  # 👈 我的 IP
      description       = "Allow my IP to access RDS PostgreSQL"
      }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "rds-sg"
  }
}


module "db" {
  source = "terraform-aws-modules/rds/aws"

  identifier = "demodb"

  engine            = "postgres"
  engine_version    = "16.6"
  instance_class    = "db.t3.micro"
  allocated_storage = 5

  db_name  = "demodb"
  username = var.db_username
  port     = "5432"

  major_engine_version = "16"
  family = "postgres16"


  # DB subnet group
  vpc_security_group_ids = [
    aws_security_group.rds_sg.id,
  ]
  create_db_subnet_group = true
  subnet_ids             =  data.terraform_remote_state.vpc.outputs.private_subnet_ids

  # Database Deletion Protection
  deletion_protection = false
  skip_final_snapshot = true

  tags = {
    Environment = "demo"
  }
}

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "rds_secrets_policy" {
  statement {
    actions   = ["secretsmanager:GetSecretValue"]
    resources = ["arn:aws:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:rds-db-credentials*"]

  }
}

resource "aws_iam_policy" "rds_secrets" {
  name   = "eks-rds-secrets-access"
  policy = data.aws_iam_policy_document.rds_secrets_policy.json
}

module "irsa_rds_access" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version = "5.39.0"

  create_role                   = true
  role_name                     = "irsa-rds-access-${data.terraform_remote_state.vpc.outputs.cluster_name}"
  provider_url                  = data.terraform_remote_state.vpc.outputs.oidc_provider
  role_policy_arns              = [aws_iam_policy.rds_secrets.arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:default:webapp-sa"]
}

