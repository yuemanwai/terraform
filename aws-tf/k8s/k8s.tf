
# ================================================================================================================== #
# 當用module "eks_blueprints_addons" 時，曾經出現 Warning: Deprecated attribute
# 提示 region = data.aws_region.current.name 寫法錯誤
# 更新了 region 的寫法 region = data.aws_region.current.region 後就不再出warning
# 詳情可以睇 terraform > aws > aws_region 的官方文檔
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region
# ================================================================================================================== #

# https://registry.terraform.io/modules/aws-ia/eks-blueprints-addons/aws/latest
module "eks_blueprints_addons" {
  source  = "aws-ia/eks-blueprints-addons/aws"
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

  enable_aws_load_balancer_controller = true
  enable_external_dns                 = true
  enable_argocd                       = true

  enable_metrics_server                  = true
  enable_kube_prometheus_stack           = false
  enable_karpenter                       = false
  enable_cert_manager                    = false
  enable_cluster_proportional_autoscaler = false

  external_dns_route53_zone_arns = [] # 這裡留空，因為我們使用 Cloudflare 來管理 DNS

  # 新版寫法：直接係度定義 Helm Chart 內容
  external_dns = {
    timeout = 600 # 加長部署 ExternalDNS 的超時時間，避免因為資源創建慢而失敗

    name          = "external-dns"
    chart         = "external-dns"
    chart_version = "1.14.3" # 建議用較新版本
    repository    = "https://kubernetes-sigs.github.io/external-dns/"
    namespace     = "external-dns"

    # 這就是你需要的 values！
    values = [
      <<-EOT
      provider: cloudflare
      cloudflare:
        apiToken: "${var.cloudflare_api_token}" # 記得放入 variable
        proxied: true

      # 安全性設定：如果你驚直接寫 token 唔好，可以用 env 注入 (Optional for FYP)
      env:
        - name: CF_API_TOKEN
          value: "${var.cloudflare_api_token}"

      # 權限：因為唔係用 AWS Route53，唔需要 ServiceAccount 綁 IAM Role
      serviceAccount:
        create: true
        name: external-dns
        annotations: {}
      EOT
    ]
  }
  argocd = {
    timeout = 600 # 加長部署 ArgoCD 的超時時間，避免因為資源創建慢而失敗

    name          = "argocd"
    chart         = "argo-cd"
    chart_version = "9.4.3" # 建議鎖定版本，避免突然升級爛野
    repository    = "https://argoproj.github.io/argo-helm"
    namespace     = "argocd"

    # 這裡就是慳錢的魔法！
    values = [
      <<-EOT
      # 1. 關閉 Redis HA (慳 RAM)
      redis-ha:
        enabled: false

      # 2. 減少各組件 Replicas 到 1 (慳 CPU/RAM)
      controller:
        replicas: 1
        metrics:
          enabled: false
          server:
            enabled: false
      server:
        replicas: 1
        autoscaling:
          enabled: false
        metrics:
          enabled: false
          server:
            enabled: false
      repoServer:
        replicas: 1
        autoscaling:
          enabled: false
        metrics:
          enabled: false
          server:
            enabled: false
      applicationSet:
        enabled: false

      dex:
        enabled: false

      notifications:
        enabled: true

      # 3. (Optional) 如果你想直接用 HTTP 唔想煩自簽證書警告
      server:
        extraArgs:
          - --insecure
      EOT
    ]
  }

  tags = {
    Terraform   = "true"
    Environment = "demo"
    Owner       = "me"
  }
}

# ================================================================================================================== #
# 假設你已經喺 variables.tf 定義咗 repoURL, github_token 同 github_username

resource "kubernetes_secret" "argocd_github_repo" {
  depends_on = [module.eks_blueprints_addons]

  metadata {
    name      = "github-repo-secret"
    namespace = "argocd"
    labels = {
      # 呢個 label 極重要！佢話俾 ArgoCD 聽：呢個 secret 係用嚟連 Git 嘅！
      "argocd.argoproj.io/secret-type" = "repository"
    }
  }

  data = {
    type     = "git"
    url      = var.repoURL
    username = var.github_username
    password = var.github_token # 注入你嘅 PAT
  }
}

# ================================================================================================================== #
# ==========================================================================
# ArgoCD Application Definition (GitOps The Last Mile)
# ==========================================================================

# 確保 ArgoCD 已經裝好先執行呢段
resource "kubernetes_manifest" "argocd_webapp" {
  depends_on = [module.eks_blueprints_addons] # 極度重要：等 ArgoCD 裝好先！

  # 👇 魔法喺呢度：SRE 霸氣宣告，Terraform 有絕對優先權！
  field_manager {
    force_conflicts = true
  }

  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name       = "my-app"
      namespace  = "argocd"
      finalizers = ["resources-finalizer.argocd.argoproj.io"]
    }
    spec = {
      project = "default"
      source = {
        # 👇 記得換返做你放 Helm Chart 嘅 GitHub Repo URL 同埋路徑
        repoURL        = var.repoURL
        targetRevision = "HEAD"
        path           = "gitops/apps/jp"

        helm = {
          # 🔥 直接寫死讀取兩份，取代你 Local 嘅 $useProdValues if-else 邏輯
          valueFiles = ["values.yaml", "values-prod.yaml"]

          # 🔥 將 AWS 資源凌空打入去！
          parameters = [
            {
              name        = "database.host"
              value       = data.terraform_remote_state.rds.outputs.db_instance_address
              forceString = true
            },
            {
              name        = "database.name"
              value       = data.terraform_remote_state.rds.outputs.db_name
              forceString = true
            },
            {
              name        = "env.awsSecretName"
              value       = data.terraform_remote_state.rds.outputs.db_secret_arn
              forceString = true
            },
            {
              name        = "env.awsRegion"
              value       = var.region
              forceString = true
            },
            {
              # ⚠️ 留意寫法：Helm 對於有「點 (.)」嘅 Key，需要用 \\ 來 Escape
              name        = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
              value       = data.terraform_remote_state.rds.outputs.irsa_rds_role_arn
              forceString = true
            },
            {
              # ⚠️ 魔法防護罩再次出動：用 \\ 去 Escape 嗰幾粒點！
              name        = "ingress.annotations.alb\\.ingress\\.kubernetes\\.io/certificate-arn"
              value       = aws_acm_certificate.web_cert.arn # 👈 呢度填返你 Terraform 裡面 ACM Cert 嘅 output/reference
              forceString = true
            }
          ]
        }
      }
      destination = {
        # Terraform 會自動用內部 K8s URL
        server    = "https://kubernetes.default.svc"
        namespace = "default" # 👈 跟返你 Local 設定部署去 default namespace (或者改做 webapp-prod)
      }
      syncPolicy = {
        automated = {
          prune    = true
          selfHeal = true
        }
        syncOptions = ["CreateNamespace=true"]
      }
    }
  }
}
# ================================================================================================================== #
# # Create Kubernetes Service Account (Bind Role)
# resource "kubernetes_service_account" "flask_sa" {
#   metadata {
#     name      = "webapp-sa"
#     namespace = var.app_namespace
#     annotations = {
#       "eks.amazonaws.com/role-arn" = data.terraform_remote_state.rds.outputs.irsa_rds_role_arn
#     }
#   }
# }


# # https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/deployment_v1
# resource "kubernetes_deployment_v1" "flask_app_deployment" {
#   depends_on = [module.eks_blueprints_addons]

#   metadata {
#     name      = "${var.app_name}-deployment"
#     namespace = var.app_namespace
#     labels = {
#       app = var.app_name
#     }
#   }

#   spec {
#     replicas = 1

#     selector {
#       match_labels = {
#         app = var.app_name
#       }
#     }

#     template {
#       metadata {
#         labels = {
#           app = var.app_name
#         }
#       }

#       spec {
#         service_account_name = kubernetes_service_account.flask_sa.metadata.0.name
#         container {
#           name  = var.app_name
#           image = var.app_image
#           port {
#             container_port = var.app_port # Flask 應用監聽的端口
#           }
#           env {
#             name  = "AWS_SECRET_NAME"
#             value = data.terraform_remote_state.rds.outputs.db_secret_arn
#           }
#           env {
#             name  = "AWS_REGION"
#             value = data.terraform_remote_state.vpc_eks.outputs.region
#           }
#           env {
#             name  = "DB_HOST"
#             value = data.terraform_remote_state.rds.outputs.db_instance_address
#           }
#           env {
#             name  = "DB_NAME"
#             value = data.terraform_remote_state.rds.outputs.db_name
#           }

#           # env {
#           #   name  = "GEMINI_API_KEY"
#           #   value = var.GEMINI_API_KEY # 使用 RDS 的連接字符串
#           # }

#           resources {
#             requests = {
#               cpu    = "0.1"
#               memory = "512Mi"
#             }
#             limits = {
#               cpu    = "0.5"
#               memory = "1024Mi"
#             }
#           }

#           # liveness_probe {
#           #   http_get {
#           #     path = "/healthz"
#           #     port = var.app_port
#           #   }
#           #   initial_delay_seconds = 90
#           #   period_seconds        = 30
#           #   timeout_seconds       = 5
#           #   failure_threshold     = 3
#           # }

#           # readiness_probe {
#           #   http_get {
#           #     path = "/readyz"
#           #     port = var.app_port
#           #   }
#           #   initial_delay_seconds = 45
#           #   period_seconds        = 15
#           #   timeout_seconds       = 3
#           #   failure_threshold     = 3
#           # }
#         }
#       }
#     }
#   }
# }

# resource "kubernetes_service_v1" "flask_app_service" {
#   depends_on = [kubernetes_deployment_v1.flask_app_deployment]

#   metadata {
#     name      = "${var.app_name}-service"
#     namespace = var.app_namespace
#     labels = {
#       app = var.app_name
#     }
#   }
#   spec {
#     selector = {
#       app = var.app_name
#     }
#     port {
#       protocol    = "TCP"
#       port        = var.service_port # Service 暴露給 ALB 的端口 (80)
#       target_port = var.app_port     # 映射到 Pod 內部 Flask 應用監聽的端口 (5000)
#     }
#     type = "ClusterIP" # 內部服務類型
#   }


# }

# resource "kubernetes_ingress_v1" "flask_app_ingress" {
#   depends_on             = [aws_acm_certificate.web_cert, kubernetes_service_v1.flask_app_service]
#   wait_for_load_balancer = true

#   metadata {
#     name      = "${var.app_name}-ingress"
#     namespace = var.app_namespace
#     labels = {
#       app = var.app_name
#     }
#     annotations = {
#       "kubernetes.io/ingress.class"                                   = "alb"
#       "alb.ingress.kubernetes.io/scheme"                              = "internet-facing"
#       "alb.ingress.kubernetes.io/listen-ports"                        = jsonencode([{ "HTTP" : 80 }, { "HTTPS" : 443 }])
#       "alb.ingress.kubernetes.io/ssl-redirect"                        = "443"
#       "alb.ingress.kubernetes.io/backend-protocol"                    = "HTTP"
#       "alb.ingress.kubernetes.io/healthcheck-path"                    = "/"
#       "alb.ingress.kubernetes.io/success-codes"                       = "200-399"
#       "alb.ingress.kubernetes.io/manage-backend-security-group-rules" = "true"
#       "alb.ingress.kubernetes.io/certificate-arn"                     = aws_acm_certificate.web_cert.arn # 使用 ACM 證書 ARN
#       "alb.ingress.kubernetes.io/target-type"                         = "ip"                             # EKS Fargate 或直接到 Pod IP
#     }
#   }
#   spec {
#     rule {
#       host = var.domain_name
#       http {
#         path {
#           path      = "/"
#           path_type = "Prefix"
#           backend {
#             service {
#               name = kubernetes_service_v1.flask_app_service.metadata[0].name
#               port {
#                 number = var.service_port
#               }
#             }
#           }
#         }
#       }
#     }
#     # TLS 配置，讓 ALB 知道要為哪個 Host 處理 SSL/TLS
#     tls {
#       hosts = [var.domain_name]
#       # 這裡不需要 secretName，因為 ALB Ingress Controller 會直接使用 certificate-arn
#       # secret_name = ""
#     }
#   }
# }
