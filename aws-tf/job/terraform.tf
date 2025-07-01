terraform {
  cloud {
    organization = "it_dog"
    workspaces {
      name = "job"
    }
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.48.0"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.16.1"
    }
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


data "terraform_remote_state" "rds" {
  backend = "remote"
  config = {
    organization = "it_dog"
    workspaces = {
      name = "rds"
    }
  }
}

provider "aws" {
  region     = var.region
  access_key = var.aws_access_key_id
  secret_key = var.aws_secret_access_key
}