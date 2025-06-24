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
    path = "../terraform_aws_2_cluster/terraform.tfstate"
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

resource "kubernetes_secret" "name" {
  metadata {

    name = "my-secret-1" # Name of the secret
  }
  data = {
    username = base64encode("demo-Username-Admin3456") # Replace with your actual username
    password = base64encode("demo-Pw-hfds78hafhU") # Replace with your actual password
  }
}



resource "kubernetes_secret_v1" "name" {
  metadata {
    name = "my-secret" # Name of the secret
  }
  data = {
    username = base64encode("demo-Username-Admin3456") # Replace with your actual username
    password = base64encode("demo-Pw-hfds78hafhU") # Replace with your actual password
  }
  # Note: The `data` block must contain base64-encoded values for the keys you want to store in the secret.
  # Ensure that the keys in the `data` block match the environment variable names in the deployment if used.
  # The `data` block can contain multiple key-value pairs, and each value must be base64-encoded.
  # Example: `username` and `password` are used in the deployment's environment variables.
  
}

resource "kubernetes_deployment" "nginx" {
  # depends_on = [ kubernetes_secret_v1_data.name ] # Ensure the secret is created before the deployment

  metadata {
    name = "scalable-nginx-example"
    labels = {
      App = "ScalableNginxExample"
    }
  }

  spec {
    replicas = 2
    selector {
      match_labels = {
        App = "ScalableNginxExample"
      }
    }
    template {
      metadata {
        labels = {
          App = "ScalableNginxExample"
        }
      }
      spec {
        container {
          image = "yuemanwai/simple-website:latest" # nginx:1.7.8
          name  = "example"

          port {
            container_port = 80 # This should match the port exposed by the container
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
            name  = "USERNAME" # Example environment variable
            value_from {
              secret_key_ref {
                name = kubernetes_secret_v1.name.metadata[0].name # This should match the name of the secret created above
                key = "username" # Ensure this key exists in the secret
                # Note: `key` should match the keys defined in the `kubernetes_secret_v1_data` resource.
                # This will fetch the value of `username` from the secret and set it as an environment variable in the container.
              }
            }
          }

          env {
            name  = "PASSWORD" # Another example environment variable
            value_from {
              secret_key_ref {
                name = kubernetes_secret_v1.name.metadata[0].name
                key  = "password" # Ensure this key exists in the secret
                # Note: `key` should match the keys defined in the `kubernetes_secret_v1_data` resource.
                # This will fetch the value of `password` from the secret and set it as an environment variable in the container.
              }
            }
          }


        }
      }
    }
  }
}


resource "kubernetes_service" "nginx" {
  metadata {
    name = "nginx-example"
    namespace = "default"

  }
  spec {
    selector = {
      App = kubernetes_deployment.nginx.spec.0.template.0.metadata[0].labels.App
    }
    port {
      port        = 80 # This is the port on which the service will be exposed
      target_port = 80 # This should match the container port in the deployment
    }

    type = "LoadBalancer"
  }
}

