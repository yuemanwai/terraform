
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

  # this is for local using cmd to run kubectl, restrict access to only my IP
  cluster_endpoint_public_access           = true
  cluster_endpoint_public_access_cidrs     = ["0.0.0.0/0"]
  enable_cluster_creator_admin_permissions = true

  create_cloudwatch_log_group = false
  cluster_enabled_log_types   = []

  # 👇 加上呢段：正式授權你個 SSO 身份成為 Cluster Admin
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
  # cluster_addons = {
  #   aws-ebs-csi-driver = {
  #     service_account_role_arn = module.irsa-ebs-csi.iam_role_arn
  #   }
  # }

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
    Environment = "demo" # 識別環境
    Owner       = "me"   # 識別邊個負責比錢/維護
  }
}



# # https://aws.amazon.com/blogs/containers/amazon-ebs-csi-driver-is-now-generally-available-in-amazon-eks-add-ons/
# data "aws_iam_policy" "ebs_csi_policy" {
#   arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
# }

# module "irsa-ebs-csi" {
#   source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
#   version = "5.39.0"

#   create_role                   = true
#   role_name                     = "AmazonEKSTFEBSCSIRole-${module.eks.cluster_name}"
#   provider_url                  = module.eks.oidc_provider
#   role_policy_arns              = [data.aws_iam_policy.ebs_csi_policy.arn]
#   oidc_fully_qualified_subjects = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
# }

# resource "aws_iam_policy" "alb_controller" {
#   name        = "AWSLoadBalancerControllerIAMPolicy"
#   path        = "/"
#   description = "IAM policy for AWS Load Balancer Controller"
#   policy      = file("${path.module}/iam_policy.json")  # 下載官方 JSON
# }

# module "alb_irsa" {
#   source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
#   role_name = "aws-load-balancer-controller"

#   oidc_providers = {
#     main = {
#       provider_arn               = module.eks.oidc_provider_arn
#       namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
#     }
#   }

#   tags = {
#     Name = "alb-irsa"
#   }
# }

# resource "aws_iam_role_policy_attachment" "alb_controller_attach" {
#   role       = module.alb_irsa.iam_role_name
#   policy_arn = aws_iam_policy.alb_controller.arn
# }
