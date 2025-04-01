# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

provider "kubernetes" {
  config_path = "~/.kube/azure-kubeconfig"
  
  host                   = azurerm_kubernetes_cluster.default.kube_config.0.host
  client_certificate     = base64decode(azurerm_kubernetes_cluster.default.kube_config.0.client_certificate)
  client_key             = base64decode(azurerm_kubernetes_cluster.default.kube_config.0.client_key)
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.default.kube_config.0.cluster_ca_certificate)
}


data "kubernetes_service" "nginx_ingress" {
  metadata {
    name      = helm_release.nginx.metadata[0].name
    namespace = "default"
  }
  depends_on = [helm_release.nginx]
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

output "nginx_ingress_ip" {
  value = data.kubernetes_service.nginx_ingress.status[0].load_balancer[0].ingress[0].ip
}

# output "nginx_ingress_hostname" {
#   value = data.kubernetes_service.nginx_ingress.status[0].load_balancer[0].ingress[0].hostname
# }

