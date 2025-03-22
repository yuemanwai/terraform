# # Copyright (c) HashiCorp, Inc.
# # SPDX-License-Identifier: MPL-2.0

# provider "helm" {
#   kubernetes {
#     host                   = data.azurerm_kubernetes_cluster.cluster.endpoint
#     cluster_ca_certificate = base64decode(data.azurerm_kubernetes_cluster.cluster.certificate_authority.0.data)
#     exec {
#       api_version = "client.authentication.k8s.io/v1beta1"
#       args        = ["az", "get-token", "--cluster-name", data.azurerm_kubernetes_cluster.cluster.name]
#       command     = "az"
#     }
#   }
# }

# resource "helm_release" "nginx" {
#   name       = "nginx"
#   repository = "https://charts.bitnami.com/bitnami"
#   chart      = "nginx"

#   values = [
#     file("${path.module}/nginx-values.yaml")
#   ]
# }
