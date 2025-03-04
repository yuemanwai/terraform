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

resource "kubectl_manifest" "cluster_autoscaler" {
  yaml_body = file("${path.module}/k8s_manifests/cluster_autoscaler.yaml")
}

resource "kubectl_manifest" "other_resources" {
  yaml_body = file("${path.module}/k8s_manifests/other_resources.yaml")
}