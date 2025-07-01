
data "aws_vpc" "vpc" {
  id = data.terraform_remote_state.vpc.outputs.vpc_id
}

resource "aws_security_group" "rds_sg" {
  name        = "rds-sg"
  description = "Allow inbound PostgreSQL"
  vpc_id      = data.aws_vpc.vpc.id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = data.terraform_remote_state.vpc.outputs.vpc_cidr_block
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

  engine            = "mysql"
  engine_version    = "5.7"
  instance_class    = "db.t3.micro"
  allocated_storage = 5

  db_name  = "demodb"
  username = var.db_username
  password = var.db_password
  port     = "5432"

  # iam_database_authentication_enabled = true

  vpc_security_group_ids = [
    aws_security_group.rds_sg.id,
  ]

  # maintenance_window = "Mon:00:00-Mon:03:00"
  # backup_window      = "03:00-06:00"

  # Enhanced Monitoring - see example for details on how to create the role
  # by yourself, in case you don't want to create it automatically
  monitoring_interval    = 0
  # monitoring_role_name   = "MyRDSMonitoringRole"
  # create_monitoring_role = true

  tags = {
    Owner       = "admin"
    Environment = "demo"
  }

  # DB subnet group
  create_db_subnet_group = true
  subnet_ids             = data.aws_vpc.vpc.subnet_ids.private.ids

  # DB parameter group
  family = "mysql5.7"

  # DB option group
  major_engine_version = "5.7"

  # Database Deletion Protection
  deletion_protection = false

  skip_final_snapshot = true

  # parameters = [
  #   {
  #     name  = "character_set_client"
  #     value = "utf8mb4"
  #   },
  #   {
  #     name  = "character_set_server"
  #     value = "utf8mb4"
  #   }
  # ]

  # options = [
  #   {
  #     option_name = "MARIADB_AUDIT_PLUGIN"

  #     option_settings = [
  #       {
  #         name  = "SERVER_AUDIT_EVENTS"
  #         value = "CONNECT"
  #       },
  #       {
  #         name  = "SERVER_AUDIT_FILE_ROTATIONS"
  #         value = "37"
  #       },
  #     ]
  #   },
  # ]
}
