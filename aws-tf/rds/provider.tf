terraform {
  cloud {
    organization = "it_dog"
    workspaces {
      name = "rds"
    }
  }
  required_version = "~> 1.3"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.92.0"
    }
  }
}

provider "aws" {
  region = data.terraform_remote_state.vpc_eks.outputs.region
  access_key = var.aws_access_key_id
  secret_key = var.aws_secret_access_key
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