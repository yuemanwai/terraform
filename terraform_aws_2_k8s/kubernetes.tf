terraform {
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

data "terraform_remote_state" "eks" {
  backend = "local"

  config = {
    path = "../learn-terraform-provision-eks-cluster/terraform.tfstate"
  }
}

# Retrieve EKS cluster information
provider "aws" {
  region = data.terraform_remote_state.eks.outputs.region
}

data "aws_eks_cluster" "cluster" {
  name = data.terraform_remote_state.eks.outputs.cluster_name
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args = [
      "eks",
      "get-token",
      "--cluster-name",
      data.aws_eks_cluster.cluster.name
    ]
  }
}

resource "kubernetes_deployment" "demo" {
  metadata {
    name = "my-deployment" # Name of the deployment
    namespace = "default" # Ensure this matches the namespace where your deployment will be created
    labels = {
      App = "my-app"
    }
  }

  spec {
    replicas = 2
    selector {
      match_labels = {
        App = "my-app"
      }
    }
    template {
      metadata {
        labels = {
          App = "my-app"
        }
      }
      spec {
        container {
          image = "yuemanwai/simple-website:latest"
          name  = "example"

          port {
            container_port = 80
          }

          resources {
            limits = {
              cpu    = "0.5"
              memory = "512Mi"
            }
            requests = {
              cpu    = "250m"
              memory = "50Mi"
            }
          }

          env {
            name = "username"
            value_from {
              secret_key_ref {
                name = "db-secret" # Ensure this secret exists in the same namespace
                key  = "username"  # The key in the secret you want to reference
              }
            }
          }

          env {
            name = "ANOTHER_ENV_VAR"
            value_from {
              secret_key_ref {
                name = "db-secret"
                key  = "password"
              }
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "demo" {
  metadata {
    name = "my-service" # Name of the service
    namespace = "default" # Ensure this matches the namespace where your deployment is running
  }
  spec {
    selector = {
      App = kubernetes_deployment.demo.spec.0.template.0.metadata[0].labels.App
    }
    port {
      port        = 80
      target_port = 80
    }

    type = "LoadBalancer"
  }
}


resource "kubernetes_secret" "demo" {
  metadata {
    name = "my-secret" # Name of the secret, can be referenced in the deployment
    namespace = "default" # Ensure this matches the namespace where your deployment is running
  }
  data = {
    # Base64 encode your values for username and password
    username = base64encode("admin") # Example username
    password = base64encode("password123") # Example password
  }
  type = "Opaque" # Default type for generic secrets
}
