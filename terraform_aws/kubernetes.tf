# data "terraform_remote_state" "eks" {
#   backend = "local"

#   config = {
#     path = "../terraform_aws/terraform.tfstate"
#   }
# }

# Retrieve EKS cluster information
# provider "aws" {
#   region = data.terraform_remote_state.eks.outputs.region
# }

# data "aws_eks_cluster" "cluster" {
#   name = data.terraform_remote_state.eks.outputs.cluster_name
# }

data "aws_eks_cluster_auth" "eks_cluster" {
  name = aws_eks_cluster.eks_cluster.name
}

resource "local_file" "kubeconfig" {
  depends_on = [aws_eks_cluster.eks_cluster]

  content = templatefile("${path.module}/kubeconfig.tpl", {
    cluster_name = aws_eks_cluster.eks_cluster.name
    endpoint     = aws_eks_cluster.eks_cluster.endpoint
    certificate  = base64decode(aws_eks_cluster.eks_cluster.certificate_authority.0.data)
    token        = nonsensitive(data.aws_eks_cluster_auth.eks_cluster.token)
  })
  filename = "${path.module}/kubeconfig"
}

provider "kubernetes" {

  host                   = aws_eks_cluster.eks_cluster.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.eks_cluster.certificate_authority.0.data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args = [
      "eks",
      "get-token",
      "--cluster-name",
      aws_eks_cluster.eks_cluster.name
    ]
  }

}


resource "kubernetes_config_map" "aws_auth" {
  depends_on = [aws_eks_cluster.eks_cluster, aws_security_group_rule.demo-cluster-ingress-workstation-https]

  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    mapRoles = <<-EOT
      - rolearn: ${data.aws_iam_role.lab_role.arn}
        username: system:node:{{EC2PrivateDNSName}}
        groups:
          - system:bootstrappers
          - system:nodes
    EOT
  }
  
}

resource "kubernetes_deployment" "nginx" {
  depends_on = [kubernetes_config_map.aws_auth]

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
        }
      }
    }
  }
}


resource "kubernetes_service" "nginx" {
  depends_on = [kubernetes_deployment.nginx]

  timeouts {
    create = "3m"
  }

  metadata {
    name = "nginx-example"
    annotations = {
      # "service.beta.kubernetes.io/aws-load-balancer-type" = "elb" # 或 "elb" 根據需要
      "kubernetes.io/ingress.class" = "alb"
      "alb.ingress.kubernetes.io/scheme" = "internet-facing"
    }
  }
  spec {
    selector = {
      App = kubernetes_deployment.nginx.spec.0.template.0.metadata[0].labels.App
    }
    port {
      port        = 80
      target_port = 80
    }

    type = "LoadBalancer"
  }
}


