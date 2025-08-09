
# ================================================================================================================== #
# 當用module "eks_blueprints_addons" 時，曾經出現 Warning: Deprecated attribute
# 提示 region = data.aws_region.current.name 寫法錯誤
# 更新了 region 的寫法 region = data.aws_region.current.region 後就不再出warning
# 詳情可以睇 terraform > aws > aws_region 的官方文檔
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region
# ================================================================================================================== #

# https://registry.terraform.io/modules/aws-ia/eks-blueprints-addons/aws/latest
module "eks_blueprints_addons" {
  source = "aws-ia/eks-blueprints-addons/aws"
  version = "~> 1.22.0" #ensure to update this to the latest/desired version

  cluster_name      = data.terraform_remote_state.vpc_eks.outputs.cluster_name
  cluster_endpoint  = data.terraform_remote_state.vpc_eks.outputs.cluster_endpoint
  cluster_version   = data.terraform_remote_state.vpc_eks.outputs.cluster_version
  oidc_provider_arn = data.terraform_remote_state.vpc_eks.outputs.oidc_provider_arn

  eks_addons = {
    # aws-ebs-csi-driver = {
    #   most_recent = true
    # }
    coredns = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
  }

  enable_aws_load_balancer_controller    = true
  enable_cluster_proportional_autoscaler = false
  enable_karpenter                       = false
  enable_kube_prometheus_stack           = false
  enable_metrics_server                  = false
  enable_external_dns                    = false
  enable_cert_manager                    = false

  tags = {
    Environment = "demo"
  }
}
# ================================================================================================================== #

# https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/deployment_v1
resource "kubernetes_deployment_v1" "flask_app_deployment" {
  depends_on = [module.eks_blueprints_addons]

  metadata {
    name = "${var.app_name}-deployment"
    namespace = var.app_namespace
    labels = {
      app = var.app_name
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = var.app_name
      }
    }

    template {
      metadata {
        labels = {
          app = var.app_name
        }
      }

      spec {
        container {
          name  = var.app_name
          image = var.app_image
          port {
            container_port = var.app_port # Flask 應用監聽的端口
          }
          env {
            name  = "SQLALCHEMY_DATABASE_URI"
            value = data.terraform_remote_state.rds.outputs.db_url # 使用 RDS 的連接字符串
          }
          env {
            name  = "GEMINI_API_KEY"
            value = var.GEMINI_API_KEY # 使用 RDS 的連接字符串
          }

          resources {
            limits = {
              cpu    = "500m"
              memory = "512Mi"
            }
            requests = {
              cpu    = "250m"
              memory = "128Mi"
            }
          }

          # liveness_probe {
          #   http_get {
          #     path = "/"
          #     port = var.app_port
          #   }
          #   initial_delay_seconds = 30
          #   period_seconds        = 10
          # }

          # readiness_probe {
          #   http_get {
          #     path = "/"
          #     port = var.app_port
          #   }
          #   initial_delay_seconds = 5
          #   period_seconds        = 5
          # }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "flask_app_service" {
  depends_on = [kubernetes_deployment_v1.flask_app_deployment]

  metadata {
    name      = "${var.app_name}-service"
    namespace = var.app_namespace
    labels = {
      app = var.app_name
    }
  }
  spec {
    selector = {
      app = var.app_name
    }
    port {
      protocol    = "TCP"
      port        = var.service_port    # Service 暴露給 ALB 的端口 (80)
      target_port = var.app_port # 映射到 Pod 內部 Flask 應用監聽的端口 (5000)
    }
    type = "ClusterIP" # 內部服務類型
  }


}

resource "kubernetes_ingress_v1" "flask_app_ingress" {
  depends_on = [aws_acm_certificate.web_cert, kubernetes_service_v1.flask_app_service]

  metadata {
    name      = "${var.app_name}-ingress"
    namespace = var.app_namespace
    labels = {
      app = var.app_name
    }
    annotations = {
      "kubernetes.io/ingress.class"                         = "alb"
      "alb.ingress.kubernetes.io/scheme"                    = "internet-facing"
      "alb.ingress.kubernetes.io/listen-ports"              = jsonencode([{"HTTP" : 80}, {"HTTPS" : 443}])
      "alb.ingress.kubernetes.io/ssl-redirect"              = "443"
      "alb.ingress.kubernetes.io/backend-protocol"          = "HTTP"
      "alb.ingress.kubernetes.io/healthcheck-path"          = "/"
      "alb.ingress.kubernetes.io/success-codes"             = "200-399"
      "alb.ingress.kubernetes.io/manage-backend-security-group-rules" = "true"
      "alb.ingress.kubernetes.io/certificate-arn"           = aws_acm_certificate.web_cert.arn # 使用 ACM 證書 ARN
      "alb.ingress.kubernetes.io/target-type"               = "ip" # EKS Fargate 或直接到 Pod IP
    }
  }
  spec {
    rule {
      host = var.domain_name
      http {
        path {
          path     = "/"
          path_type = "Prefix"
          backend {
            service {
              name = kubernetes_service_v1.flask_app_service.metadata[0].name
              port {
                number = var.service_port
              }
            }
          }
        }
      }
    }
    # TLS 配置，讓 ALB 知道要為哪個 Host 處理 SSL/TLS
    tls {
      hosts        = [var.domain_name]
      # 這裡不需要 secretName，因為 ALB Ingress Controller 會直接使用 certificate-arn
      # secret_name = "" 
    }
  }
}
