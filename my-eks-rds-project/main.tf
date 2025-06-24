# main.tf

# 指定 AWS Provider 和地區
provider "aws" {
  region = var.region
}

# --- Kubernetes Provider ---
# 這個 provider 會在 EKS 叢集建立後，自動獲取 kubeconfig 來連接 K8s API
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.main.token
}

# 獲取 EKS Cluster 的認證 token
data "aws_eks_cluster_auth" "main" {
  name = module.eks.cluster_name
}

# --- Helm Provider ---
# Helm provider 需要依賴 Kubernetes provider
provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    token                  = data.aws_eks_cluster_auth.main.token
  }
}

# 數據源：獲取 AWS EKS 模組可用的 AMI (用於 Worker Nodes)
data "aws_ami" "eks_worker" {
  filter {
    name   = "name"
    values = ["amazon-eks-node-${var.eks_kubernetes_version}-v*"]
  }
  most_recent = true
  owners      = ["602401143452"] # Amazon EKS 帳戶 ID
}

---
## VPC 設置 (核心網路)

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  version = "5.0.0"

  name = "${var.project_name}-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["${var.region}a", "${var.region}b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true
  enable_dns_hostnames = true

  tags = {
    Project     = var.project_name
    Environment = "fyp"
  }
}

---
## EKS Cluster (Kubernetes 控制平面)

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.1.0"

  cluster_name    = "${var.project_name}-eks-cluster"
  cluster_version = var.eks_kubernetes_version

  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnets
  control_plane_subnet_ids = module.vpc.private_subnets

  eks_managed_node_groups = {
    my_app_nodes = {
      instance_types = ["t3.small"]
      min_size       = 1
      max_size       = 2
      desired_size   = 1

      ami_id = data.aws_ami.eks_worker.id

      create_iam_role             = true
      create_iam_instance_profile = true
      iam_role_additional_policies = {
        AmazonEC2ContainerRegistryReadOnly = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
      }

      disk_size = 20
    }
  }

  tags = {
    Project     = var.project_name
    Environment = "fyp"
  }
}

---
## AWS Load Balancer Controller (ALB Controller) - EKS 內部組件

# 為 ALB Controller 創建 IAM 角色和策略 (IRSA)
module "iam_assumable_role_with_oidc" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version = "5.3.0"

  create_role                   = true
  role_name                     = "${var.project_name}-aws-load-balancer-controller"
  provider_url                  = replace(module.eks.cluster_oidc_issuer_url, "https://", "")
  role_policy_arns              = [aws_iam_policy.aws_load_balancer_controller.arn]
  # 注意：ServiceAccount 的 namespace 和 name 需要與 Helm Chart 中的設置一致
  oidc_fully_qualified_subjects = ["system:serviceaccount:kube-system:aws-load-balancer-controller"]
}

resource "aws_iam_policy" "aws_load_balancer_controller" {
  name        = "${var.project_name}-AWSLoadBalancerControllerIAMPolicy"
  path        = "/"
  description = "IAM Policy for AWS Load Balancer Controller"
  policy      = file("${path.module}/policies/aws-load-balancer-controller-policy.json")
}

---
## RDS PostgreSQL 資料庫

module "db_postgresql" {
  source  = "terraform-aws-modules/rds/aws"
  version = "6.0.0"

  identifier = "${var.project_name}-postgresdb"

  engine               = "postgresql"
  engine_version       = "15.5"
  instance_class       = "db.t3.micro"
  allocated_storage    = 20
  storage_type         = "gp2"

  name     = "postgres"
  username = "postgres"
  password = random_string.db_password.result

  port = 5432

  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  db_subnet_group_name   = module.vpc.database_subnet_group_name

  multi_az            = false
  publicly_accessible = false

  backup_retention_period = 0
  skip_final_snapshot     = true

  tags = {
    Project     = var.project_name
    Environment = "fyp"
  }
}

# 生成隨機密碼
resource "random_string" "db_password" {
  length  = 16
  special = false
  upper   = true
  lower   = true
  number  = true
}

# RDS 安全組 (允許來自 EKS 節點的連接)
resource "aws_security_group" "rds_sg" {
  name        = "${var.project_name}-rds-sg"
  description = "Allow inbound access to RDS from EKS nodes"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [module.eks.node_security_group_id]
    description     = "Allow PostgreSQL access from EKS nodes"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Project     = var.project_name
    Environment = "fyp"
  }
}

---
## Helm Chart 部署 (透過 Terraform Helm Provider)

### 1. 部署 AWS Load Balancer Controller Helm Chart

resource "helm_release" "aws_load_balancer_controller" {
  # 由於 ALB Controller 需要 ServiceAccount 綁定 IAM 角色，
  # 我們需要確保 ServiceAccount 已經存在於 EKS 叢集中。
  # 由於 ALB Controller 的 Helm Chart 預設會建立 ServiceAccount，
  # 我們要確保它使用的 ServiceAccount 名稱與 IAM role for Service Account (IRSA) 的綁定一致。
  # EKS 模組創建的 OIDC provider 已經在 `iam_assumable_role_with_oidc` 模組中設置。
  # ALB Controller Helm Chart 的 ServiceAccount 名稱預設是 `aws-load-balancer-controller`。

  depends_on = [
    module.eks.eks_managed_node_groups, # 確保 EKS 節點已就緒
    module.iam_assumable_role_with_oidc # 確保 IAM 角色已創建
  ]

  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system" # ALB Controller 建議部署在 kube-system 或 aws-load-balancer-controller namespace
  version    = "1.7.0" # 推薦使用最新穩定版本，但要與你的 EKS 版本兼容

  set {
    name  = "clusterName"
    value = module.eks.cluster_name
  }
  set {
    name  = "serviceAccount.create"
    value = "true" # 讓 Helm Chart 創建 ServiceAccount
  }
  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller" # 使用這個名字，確保與 IRSA 綁定匹配
  }
  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.iam_assumable_role_with_oidc.iam_role_arn # 綁定 IAM 角色到 ServiceAccount
  }

  # 確保 ALB Controller 啟動前有足夠的時間讓 EKS 節點準備好
  timeout = 600 # 增加超时时间以防止因 EKS 节点启动慢而失败
}

### 2. 部署你的 Web 應用程式 Helm Chart

resource "helm_release" "my_webapp_app" {
  depends_on = [
    aws_security_group.rds_sg,      # 確保 RDS 安全組已設置
    module.db_postgresql,           # 確保 RDS 已部署
    helm_release.aws_load_balancer_controller # 確保 ALB Controller 已部署
  ]

  name       = "my-webapp-new"
  chart      = "./my-webapp-chart" # 指向你的本地 Helm Chart 路徑
  namespace  = "default"          # 或你為應用程式創建的 namespace

  # 將 RDS 連接資訊作為 values 傳遞給你的應用程式 Helm Chart
  set {
    name  = "database.db_url"
    value = "postgresql://${module.db_postgresql.db_instance_username}:${random_string.db_password.result}@${module.db_postgresql.db_instance_address}:${module.db_postgresql.db_instance_port}/${module.db_postgresql.db_instance_name}"
  }

  # 暫時不設置 Ingress 和 ALB 憑證，因為你說暫時不理 domain name
  # 如果之後要開放 ALB 外部訪問，需要再啟用 Ingress 並配置 ACM 憑證

  # 如果你的應用程式需要 Ingress 來創建 ALB，即使是暫時測試，也需要啟用。
  # 但由於你說暫時不理 domain name，且 ALB Controller 創建的 ALB 預設是公開可訪問的，
  # 你可以使用 ALB 生成的 URL。
  # 啟用 Ingress 的範例 (如果你的 Helm Chart 支援):
  set {
    name  = "ingress.enabled"
    value = "true"
  }
  set {
    name  = "ingress.className" # 確保使用 ALB Controller
    value = "alb" # 或其他你配置的 Ingress Class 名稱
  }
  set {
    name = "ingress.annotations.alb\\.ingress\\.kubernetes\\.io/scheme"
    value = "internet-facing" # 讓 ALB 面向公網
  }
  set {
    name = "ingress.annotations.alb\\.ingress\\.kubernetes\\.io/target-type"
    value = "ip" # 直接路由到 Pod IP
  }
  # 注意：如果沒有配置 HTTPS，ALB 監聽 80 端口。
  # alb.ingress.kubernetes.io/listen-ports: '[{"HTTP":80}]'
  # 如果你的應用程式沒有處理 HTTPS，請不要配置 certificate-arn
}