
data "aws_availability_zones" "available" {
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

data "aws_iam_role" "sso_admin" {
  name = "AWSReservedSSO_AdministratorAccess_8b8eb430a80a0d3d"
}

locals {
  cluster_name = "demo-eks-${random_string.suffix.result}"
  vpc_name     = "demo-vpc-${random_string.suffix.result}"
}

resource "random_string" "suffix" {
  length  = 8
  special = false
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.8.1"

  name = local.vpc_name

  cidr = "10.0.0.0/16"
  azs  = slice(data.aws_availability_zones.available.names, 0, 2)

  private_subnets = ["10.0.0.0/24", "10.0.1.0/24"]
  public_subnets  = ["10.0.2.0/24", "10.0.3.0/24"]

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  public_subnet_tags = {
    "kubernetes.io/role/elb"                      = 1
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb"             = 1
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
  }

}

# https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.8.5"

  cluster_name = local.cluster_name
  # Extra cost will be charged on extended support, keep an eye on the EKS Kubernetes version updates:
  # https://docs.aws.amazon.com/zh_tw/eks/latest/userguide/kubernetes-versions.html
  cluster_version = "1.35"

  # 🚨 for demo, we keep it open to avoid confusion on AWS-0040 & AWS-0041. In production, set to false and use private access only.
  cluster_endpoint_public_access           = true
  cluster_endpoint_public_access_cidrs     = ["0.0.0.0/0"]
  enable_cluster_creator_admin_permissions = true

  create_cloudwatch_log_group = false
  cluster_enabled_log_types   = []

  # Add this block to explicitly grant your SSO identity Cluster Admin access.
  access_entries = {
    my_sso_admin = {
      principal_arn = data.aws_iam_role.sso_admin.arn

      policy_associations = {
        admin = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }

  # 🚨 FYP DEMO: comment out this whole block to quickly eliminate AWS-0104.

  # 1) Disable the module's default "allow all egress" rule (addresses AWS-0104).
  node_security_group_enable_recommended_rules = false

  # 2) Re-add only least-privilege rules via additional security group rules.
  node_security_group_additional_rules = {
    # Allow outbound HTTPS only (for pulling images and calling AWS APIs).
    egress_https = {
      description = "Node egress restricted to HTTPS"
      protocol    = "tcp"
      from_port   = 443
      to_port     = 443
      type        = "egress"
      cidr_blocks = ["0.0.0.0/0"]
    }
    # Allow access only to internal VPC RDS PostgreSQL.
    egress_rds = {
      description = "Allow EKS nodes to access RDS internally"
      protocol    = "tcp"
      from_port   = 5432
      to_port     = 5432
      type        = "egress"
      cidr_blocks = ["10.0.0.0/16"] # Update this to your actual VPC CIDR.
    }

    # Note: disabling recommended rules also removes node-to-node internal communication.
    # In real production, add back the required ingress rules. For Trivy IaC scan and demo use,
    # the two egress rules above are enough to remove the critical 0.0.0.0/0 warning.
  }

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  eks_managed_node_group_defaults = {
    ami_type = "AL2023_x86_64_STANDARD"

  }

  eks_managed_node_groups = {
    one = {
      name = "node-group-1"

      instance_types = ["t3.medium", "t3a.medium"]
      capacity_type  = "SPOT"

      min_size     = 1
      max_size     = 2
      desired_size = 1

    }
  }

  tags = {
    Name        = local.cluster_name
    Terraform   = "true"
    Environment = "demo" # Environment identifier
    Owner       = "me"   # Owner responsible for cost and maintenance
  }
}
