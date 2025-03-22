terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.93.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0.1"
    }
  }

  # required_version = ">= 0.14"
}

provider "azurerm" {
  features {}
  skip_provider_registration = true
}