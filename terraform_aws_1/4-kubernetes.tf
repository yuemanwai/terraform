# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

# data "terraform_remote_state" "eks" {
#   backend = "local"
#   config = {
#     path = "./terraform.tfstate"
#   }
# }

# # Retrieve EKS cluster configuration
# data "aws_eks_cluster" "cluster" {
#   depends_on = [module.eks]
#   name       = module.eks.cluster_name
# }

# data "aws_eks_cluster_auth" "cluster" {
#   depends_on = [module.eks]
#   name       = module.eks.cluster_name
# }

# provider "kubernetes" {
#   host                   = data.aws_eks_cluster.cluster.endpoint
#   cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
#   exec {
#     api_version = "client.authentication.k8s.io/v1"
#     args        = ["eks", "get-token", "--cluster-name", data.aws_eks_cluster.cluster.name]
#     command     = "aws"
#   }
# }

# data "kubernetes_service" "nginx" {
#   depends_on = [helm_release.nginx]
#   metadata {
#     name = "nginx"
#   }
# }

# provider "helm" {
#   kubernetes {
#     host                   = data.aws_eks_cluster.cluster.endpoint
#     cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
#     exec {
#       api_version = "client.authentication.k8s.io/v1"
#       args        = ["eks", "get-token", "--cluster-name", data.aws_eks_cluster.cluster.name]
#       command     = "aws"
#     }
#   }
# }

# resource "helm_release" "nginx" {
#   depends_on = [module.eks]
#   name       = "nginx"
#   repository = "oci://registry-1.docker.io/bitnamicharts"
#   chart      = "nginx"
#   version    = "13.2.30"

#   values = [
#     file("${path.module}/nginx-values.yaml")
#   ]
# }

# output "nginx_endpoint" {
#   value = "http://${data.kubernetes_service.nginx.status.0.load_balancer.0.ingress.0.hostname}"
# }

data "terraform_remote_state" "eks" {
  backend = "local"

  config = {
    path = "./terraform.tfstate"
  }
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

resource "kubernetes_deployment" "nginx" {
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
          image = "nginx:1.7.8"
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
        }
      }
    }
  }
}
