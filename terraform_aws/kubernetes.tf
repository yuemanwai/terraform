provider "kubernetes" {
  host                   = aws_eks_cluster.demo.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.demo.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.demo.token
}

provider "kubectl" {
  host                   = aws_eks_cluster.demo.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.demo.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.demo.token
}

resource "kubernetes_manifest" "nginx_deployment" {
  manifest = file("${path.module}/k8s_manifests/-deployment.yaml")
}

resource "kubernetes_manifest" "website_deployment" {
  manifest = file("${path.module}/k8s_manifests/website-deployment.yaml")
}

resource "kubernetes_manifest" "nginx_service" {
  manifest = file("${path.module}/k8s_manifests/nginx-service.yaml")
}

resource "kubernetes_manifest" "website_service" {
  manifest = file("${path.module}/k8s_manifests/website-service.yaml")
}