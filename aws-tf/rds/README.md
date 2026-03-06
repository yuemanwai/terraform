# RDS PostgreSQL 資料庫模組

此 Terraform 模組用於在現有的 VPC 和 EKS 叢集基礎上建立 Amazon RDS PostgreSQL 資料庫實例，並配置適當的安全群組規則以允許 EKS 節點存取。

## 功能概述

- 在現有 VPC 的私有子網路中建立 RDS PostgreSQL 實例
- 自動配置安全群組允許 EKS 節點存取資料庫
- 支援外部 IP 存取（用於開發和除錯）
- 使用 AWS Secrets Manager 自動管理資料庫密碼
- 整合 Terraform Cloud 遠端狀態管理

## 架構組件

### 資料來源 (Data Sources)
- **VPC 資訊**: 從 `learn-terraform-eks` workspace 獲取 VPC 詳細資訊
- **私有子網路**: 從現有 EKS 基礎設施獲取私有子網路 ID
- **EKS 節點安全群組**: 獲取 EKS 節點的安全群組 ID

### 建立資源
- **RDS 安全群組**: 控制資料庫存取權限
- **RDS PostgreSQL 實例**: 使用 terraform-aws-modules/rds/aws 模組
- **DB 子網路群組**: 自動建立跨可用區的子網路群組

## 技術規格

### RDS 實例配置(DEMO)
- **引擎**: PostgreSQL 16.6
- **實例類型**: db.t3.micro
- **儲存空間**: 5 GB
- **資料庫名稱**: demodb
- **連接埠**: 5432
- **備份**: 停用最終快照（適用於開發環境）

### 安全群組規則
- **入站規則 1**: 允許 EKS 節點存取 PostgreSQL (port 5432)
- **入站規則 2**: 允許特定外部 IP 存取 (YOUR_PUBLIC_IP/32)
- **出站規則**: 允許所有出站流量

## 使用方式

### 前置需求
1. 已建立並運行的 EKS 叢集 (來自 `learn-terraform-eks` workspace)
2. 適當的 AWS 憑證和權限
3. Terraform Cloud 組織存取權限
4. 配置您的公共 IP 地址以允許外部存取

# 建立兩個 Symlink
```bash
cd ~/workspaces/terraform/aws-tf/rds
ln -s ../global.auto.tfvars global.auto.tfvars
ln -s ../variables.tf variables.tf
```

### 部署步驟

1. **配置變數**
   ```bash
   # 在 Terraform Cloud 或 terraform.tfvars 中設定
   # region 會自動從 learn-terraform-eks workspace 獲取
   aws_access_key_id = "your-access-key"
   aws_secret_access_key = "your-secret-key"
   db_username = "your-db-username"
   ```

2. **更新外部 IP (可選)**
   ```terraform
   # 在 rds.tf 中更新您的 IP 地址
   cidr_blocks = ["YOUR_PUBLIC_IP/32"]
   ```

3. **初始化並部署**
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

### 連線資訊

部署完成後，您可以使用以下輸出值連接到資料庫：

| 輸出變數 | 描述 | 用途 |
|---------|------|------|
| `rds_endpoint` | 資料庫端點地址 | 連線主機名稱 |
| `rds_port` | 資料庫連接埠 | 連線埠號 (5432) |
| `db_name` | 資料庫名稱 | 預設資料庫 |
| `db_username` | 資料庫使用者名稱 | 登入帳號 |
| `db_password_arn` | Secrets Manager ARN | 密碼位置 (敏感資訊) |

## 連線方式

### 從 EKS Pod 連線
```bash
# 在 Kubernetes Pod 中使用環境變數
PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -U $DB_USER -d $DB_NAME
```

### 從本機連線 (需要配置 IP 白名單)
```bash
# 獲取密碼
aws secretsmanager get-secret-value --secret-id <db_password_arn> --query SecretString --output text

# 連線到資料庫
psql -h <rds_endpoint> -U <db_username> -d <db_name>
```

### 使用 pgAdmin 或其他 GUI 工具
- **主機**: `<rds_endpoint>`
- **連接埠**: `5432`
- **資料庫**: `demodb`
- **使用者名稱**: `<db_username>`
- **密碼**: 從 AWS Secrets Manager 獲取

## 安全配置

### 網路安全
- 資料庫部署在私有子網路中
- 僅允許 EKS 節點安全群組存取
- 可選擇性允許特定外部 IP 存取

### 認證安全
- 資料庫密碼自動產生並儲存在 AWS Secrets Manager
- 支援 IAM 資料庫認證（可進一步配置）
- 傳輸中和靜態資料加密

### 生產環境建議
```terraform
# 建議的生產環境配置
deletion_protection = true
skip_final_snapshot = false
backup_retention_period = 7
backup_window = "03:00-04:00"
maintenance_window = "sun:04:00-sun:05:00"
```

## 監控和維護

### CloudWatch 指標
- CPU 使用率
- 資料庫連線數
- 讀/寫 IOPS
- 儲存空間使用率

### 備份策略
- 目前設定：停用自動備份（開發環境）
- 生產建議：啟用自動備份和多 AZ 部署

### 效能調校
```sql
-- 查看資料庫狀態
SELECT version();
SELECT current_database();

-- 檢查連線
SELECT count(*) FROM pg_stat_activity;

-- 查看資料庫大小
SELECT pg_size_pretty(pg_database_size(current_database()));
```

## 故障排除

### 常見問題

1. **連線被拒絕**
   - 檢查安全群組規則
   - 確認 IP 地址在白名單中
   - 驗證 VPC 和子網路配置

2. **認證失敗**
   - 確認使用者名稱正確
   - 從 Secrets Manager 獲取最新密碼
   - 檢查 IAM 權限

3. **DNS 解析問題**
   - 確認 VPC DNS 設定啟用
   - 檢查路由表配置

### 除錯命令

```bash
# 檢查 RDS 實例狀態
aws rds describe-db-instances --db-instance-identifier demodb

# 獲取密碼
aws secretsmanager get-secret-value --secret-id <arn>

# 測試網路連通性
telnet <rds_endpoint> 5432
nslookup <rds_endpoint>
```

## 成本優化

- **實例類型**: db.t3.micro (適用於開發)
- **儲存**: 5 GB gp2 (可根據需求調整)
- **備份**: 停用以節省成本
- **多 AZ**: 停用以節省成本

### 生產環境升級建議
```terraform
instance_class = "db.t3.small"  # 或更大
allocated_storage = 20
backup_retention_period = 7
multi_az = true
```

## 清理資源

```bash
terraform destroy
```

**注意**: 刪除前請確保已備份重要資料！

## 相依模組

- `../` - 主要 EKS 模組 (learn-terraform-eks workspace)
- VPC 和子網路資源
- EKS 節點安全群組

## 版本需求

- Terraform ~> 1.3
- AWS Provider ~> 5.92.0
- terraform-aws-modules/rds/aws (最新版本)

## 授權

請參考專案根目錄的 LICENSE 檔案。
