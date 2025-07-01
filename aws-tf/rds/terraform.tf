terraform {
  cloud {
    organization = "it_dog"
    workspaces {
      name = "rds"
    }
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.47.0"
    }

    required_version = "~> 1.3"
  }
}


data "terraform_remote_state" "vpc" {
  backend = "remote"
  config = {
    organization = "it_dog"
    workspaces = {
      name = "learn-terraform-eks"
    }
  }
}

provider "aws" {
  region = data.terraform_remote_state.vpc.outputs.region
  access_key = var.aws_access_key_id
  secret_key = var.aws_secret_access_key
}