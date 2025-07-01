# EKS Pod 與 RDS 連線測試模組

此 Terraform 模組用於在 Amazon EKS 叢集中部署測試 Pod，以驗證 Kubernetes Pod 與 Amazon RDS 資料庫之間的網路連線和身份驗證。

## 功能概述

- 建立一個使用 PostgreSQL 客戶端映像檔的測試 Pod
- 從 Terraform Cloud 的遠端狀態獲取 EKS 叢集和 RDS 資訊
- 自動配置資料庫連線參數和憑證
- 支援從 AWS Secrets Manager 安全獲取資料庫密碼

## 架構組件

### 資料來源 (Data Sources)
- **EKS 叢集資訊**: 從 `learn-terraform-eks` workspace 獲取叢集詳細資訊
- **RDS 資訊**: 從 `rds` workspace 獲取資料庫端點和憑證
- **Secrets Manager**: 安全獲取資料庫密碼

### Kubernetes 資源
- **測試 Pod**: `psql-debug`
  - 映像檔: `bitnami/postgresql:16`
  - 模式: 長時間運行 (sleep 3600) 便於除錯
  - 包含完整的資料庫連線環境變數

## 環境變數配置

Pod 會自動配置以下環境變數：

| 變數名稱 | 來源 | 描述 |
|---------|------|------|
| `DB_HOST` | RDS Terraform 狀態 | 資料庫端點地址 |
| `DB_USER` | RDS Terraform 狀態 | 資料庫使用者名稱 |
| `DB_PASSWORD` | AWS Secrets Manager | 資料庫密碼 (安全獲取) |
| `DB_NAME` | RDS Terraform 狀態 | 資料庫名稱 |

## 使用方式

### 前置需求
1. 已建立並運行的 EKS 叢集 (來自 `learn-terraform-eks` workspace)
2. 已建立的 RDS 實例 (來自 `rds` workspace)
3. 適當的 AWS 憑證和權限
4. Terraform Cloud 組織存取權限

### 部署步驟

1. **配置變數**
   ```bash
   # 在 Terraform Cloud 或 terraform.tfvars 中設定
   # region 必須與 learn-terraform-eks workspace 的 VPC 區域一致
   region = "us-east-2"  # 請確保與 EKS 叢集所在區域相同
   aws_access_key_id = "your-access-key"
   aws_secret_access_key = "your-secret-key"
   ```

2. **初始化並部署**
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

3. **測試連線**
   ```bash
   # 連接到測試 Pod
   kubectl exec -it psql-debug -- bash
   
   # 在 Pod 內測試資料庫連線
   PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -U $DB_USER -d $DB_NAME -c "SELECT version();"
   ```

### 連線測試命令

在 Pod 內執行以下命令測試資料庫連線：

```bash
# 基本連線測試
PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -U $DB_USER -d $DB_NAME -c "SELECT 1;"

# 查看資料庫版本
PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -U $DB_USER -d $DB_NAME -c "SELECT version();"

# 列出資料庫
PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -U $DB_USER -d $DB_NAME -c "\l"

# 檢查連線狀態
PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -U $DB_USER -d $DB_NAME -c "SELECT current_database(), current_user, inet_server_addr(), inet_server_port();"
```

## 除錯指南

### 常見問題

1. **連線超時**
   - 檢查 RDS 安全群組是否允許來自 EKS 節點的流量
   - 確認 RDS 子網路群組配置正確

2. **身份驗證失敗**
   - 驗證 Secrets Manager 中的密碼是否正確
   - 確認資料庫使用者權限設定

3. **DNS 解析問題**
   - 檢查 EKS 叢集的 DNS 配置
   - 確認 RDS 端點可以從 Pod 內解析

### 除錯命令

```bash
# 檢查 Pod 狀態
kubectl get pods
kubectl describe pod psql-debug

# 查看 Pod 日誌
kubectl logs psql-debug

# 進入 Pod 進行互動式除錯
kubectl exec -it psql-debug -- bash

# 在 Pod 內測試網路連線
nslookup $DB_HOST
ping $DB_HOST
telnet $DB_HOST 5432
```

## 安全考量

- 資料庫密碼通過 AWS Secrets Manager 安全管理
- 建議在生產環境中使用 IAM 角色進行身份驗證
- 確保 RDS 安全群組僅開放必要的存取權限
- 定期輪換資料庫憑證

## 清理資源

```bash
terraform destroy
```

## 相依模組

- `../` - 主要 EKS 模組 (learn-terraform-eks workspace)
- `../rds/` - RDS 模組 (rds workspace)

## 版本需求

- Terraform >= 1.0
- AWS Provider >= 4.48.0
- Kubernetes Provider >= 2.16.1

## 授權

請參考專案根目錄的 LICENSE 檔案。