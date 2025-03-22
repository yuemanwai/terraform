# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

# provider "azurerm" {
#   features {}
#   skip_provider_registration = true
# }

# data "terraform_remote_state" "aks" {
#   backend = "local"
#   config = {
#     path = "../terraform.tfstate"
#   }
# }

# # Retrieve aks cluster configuration
# data "azurerm_kubernetes_cluster" "cluster" {
#   name                = data.terraform_remote_state.aks.outputs.azurerm_kubernetes_cluster
#   resource_group_name = data.terraform_remote_state.aks.outputs.resource_group_name
# }

# data "azurerm_kubernetes_cluster_auth" "cluster" {
#   name = data.terraform_remote_state.aks.outputs.azurerm_kubernetes_cluster
# }

# provider "kubernetes" {
#   host                   = data.azurerm_kubernetes_cluster.cluster.endpoint
#   cluster_ca_certificate = base64decode(data.azurerm_kubernetes_cluster.cluster.certificate_authority.0.data)
#   exec {
#     api_version = "client.authentication.k8s.io/v1beta1"
#     args        = ["az", "get-token", "--cluster-name", data.azurerm_kubernetes_cluster.cluster.name]
#     command     = "az"
#   }
# }

# data "kubernetes_service" "nginx" {
#   depends_on = [helm_release.nginx]
#   metadata {
#     name = "nginx"
#   }
# }

# output "nginx_endpoint" {
#     value = "http://${data.kubernetes_service.nginx.status.0.load_balancer.0.ingress.0.hostname}"
# }



provider "kubernetes" {
  config_path = "~/.kube/config"
  
  host                   = azurerm_kubernetes_cluster.default.kube_config.0.host
  client_certificate     = base64decode(azurerm_kubernetes_cluster.default.kube_config.0.client_certificate)
  client_key             = base64decode(azurerm_kubernetes_cluster.default.kube_config.0.client_key)
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.default.kube_config.0.cluster_ca_certificate)
}

provider "helm" {
  kubernetes {
    host                   = azurerm_kubernetes_cluster.default.kube_config.0.host
    client_certificate     = base64decode(azurerm_kubernetes_cluster.default.kube_config.0.client_certificate)
    client_key             = base64decode(azurerm_kubernetes_cluster.default.kube_config.0.client_key)
    cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.default.kube_config.0.cluster_ca_certificate)
  }
}


resource "helm_release" "nginx" {
  name       = "nginx"
  repository = "oci://registry-1.docker.io/bitnamicharts"
  chart      = "nginx"
  version    = "13.2.30"
  namespace  = "default"

  values = [
    file("${path.module}/nginx-values.yaml")
  ]
}

data "kubernetes_service" "nginx_ingress" {
  metadata {
    name      = helm_release.nginx.metadata[0].name
    namespace = "default"
  }
  depends_on = [helm_release.nginx]
}

output "nginx_ingress_ip" {
  value = data.kubernetes_service.nginx_ingress.status[0].load_balancer[0].ingress[0].ip
}

output "nginx_ingress_hostname" {
  value = data.kubernetes_service.nginx_ingress.status[0].load_balancer[0].ingress[0].hostname
}

# resource "kubernetes_deployment" "nginx" {
#   metadata {
#     name      = "nginx-deployment"
#     namespace = "default"
#   }

#   spec {
#     replicas = 3

#     selector {
#       match_labels = {
#         app = "nginx"
#       }
#     }

#     template {
#       metadata {
#         labels = {
#           app = "nginx"
#         }
#       }

#       spec {
#         container {
#           name  = "nginx"
#           image = "nginx:1.14.2"

#           port {
#             container_port = 80
#           }
#         }
#       }
#     }
#   }
# }

# resource "kubernetes_service" "nginx" {
#   metadata {
#     name      = "nginx-service"
#     namespace = "default"
#   }

#   spec {
#     selector = {
#       app = "nginx"
#     }

#     port {
#       port        = 80
#       target_port = 80
#     }

#     type = "LoadBalancer"
#   }
# }