terraform {
  cloud {
    organization = "it_dog"
    workspaces {
      name = "k8s"
    }
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0" # 原本4.48.0
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.9, < 3.0" # 原本2.0
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.20" # 原本2.16.1
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.6"
    }
    time = {
      source  = "hashicorp/time"
      version = ">= 0.9"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.7"
    }
  }
}

data "terraform_remote_state" "vpc_eks" {
  backend = "remote"
  config = {
    organization = "it_dog"
    workspaces = {
      name = "learn-terraform-eks"
    }
  }
}

data "terraform_remote_state" "rds" {
  backend = "remote"
  config = {
    organization = "it_dog"
    workspaces = {
      name = "rds"
    }
  }
}

data "aws_eks_cluster" "cluster" {
  name = data.terraform_remote_state.vpc_eks.outputs.cluster_name
}

data "aws_eks_cluster_auth" "eks" {
  name = data.aws_eks_cluster.cluster.name
}

provider "aws" {
  region  = var.region
  profile = "fyp-sso"
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.eks.token
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
    token                  = data.aws_eks_cluster_auth.eks.token
  }
}
