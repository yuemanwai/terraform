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
  region  = data.terraform_remote_state.vpc_eks.outputs.region
  profile = "fyp-sso"
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
