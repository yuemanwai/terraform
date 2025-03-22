# terraform

以下教學都係基於 linux ubuntu 環境

## 使用 Terraform 創建 Kubernetes 服務

以下是使用 Terraform 在三個主要雲提供商（AWS、Azure 和 GCP）上創建 Kubernetes 服務的步驟。

首先，如果你使用 devcontainer 開 codespace，應該已經自動運行了 `setup.sh`，這個 script 用來安裝基本工具，包括 AWS CLI、Azure CLI、kubectl、gcloud CLI。其中 gcloud CLI 安裝過程需要手動驗證身份，請照指示操作。

之後，你需要按以下的資料做登入及驗證。

## 配置 AWS CLI

在運行 `setup.sh` 後，您需要在 `~/.aws/config` 和 `~/.aws/credentials` 文件中添加必要的內容。

#### ~/.aws/config (按需要手動更改)

```plaintext
[default]
region = us-east-1
output = json

[profile my-profile]
role_arn = YOUR_LABROLE_ARN
source_profile = default
```

#### ~/.aws/credentials (如果你用 aws academy learner lab, 每次重新 create session 都要更新 credendtial)

```plaintext
[default]
aws_access_key_id = YOUR_ACCESS_KEY_ID
aws_secret_access_key = YOUR_SECRET_ACCESS_KEY
```

## 配置 Azure CLI

1. 登錄 Azure：

   ```sh
   az login
   ```

2. 創建服務主體，取得真實的`appId` 和 `password`：

   ```sh
   az ad sp create-for-rbac --skip-assignment

   {
   "appId": "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
   "displayName": "azure-cli-2021-04-22-17-52-06",
   "name": "http://azure-cli-2021-04-22-17-52-06",
   "password": "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
   "tenant": "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
   }
   ```

   > **注意**: 請妥善保存生成的密碼，因為它只會顯示一次。如果遺失，您需要再次重置憑證。

3. 重命名並更新 `terraform.tfvars` 文件，填入真實的 `appId` 和 `password`：

   ```sh
   mv terraform.tfvars.example terraform.tfvars
   ```

4. 註冊 Microsoft.ContainerService 資源提供者：

   ```sh
   az provider register --namespace Microsoft.ContainerService
   ```

5. 檢查註冊狀態：

   ```sh
   az provider show --namespace Microsoft.ContainerService --query registrationState
   ```

## 重置 Azure CLI 憑證

如果需要更新 Azure CLI 服務主體的憑證，可以使用以下命令：

1. 列出服務主體，確認目標服務主體的 `AppId`：

   ```sh
   az ad sp list --query "[?contains(displayName, 'azure-cli-2025-03-04-09-30-15')].{Name:displayName, AppId:appId}" --output table
   ```

2. 重置服務主體的憑證，生成新的密碼：

   ```sh
   az ad sp credential reset --id <your-app-id>
   ```

   執行後會返回以下內容，請記下新的 `password` 和其他相關信息：

   ```json
   {
     "appId": "azure-cli-2025-03-04-09-30-15",
     "password": "new-generated-password",
     "tenant": "your-tenant-id"
   }
   ```

## 安裝 Helm

以下是安裝 Helm 的步驟：

   ```sh
   curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
   sudo apt-get install apt-transport-https --yes
   echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
   sudo apt-get update
   sudo apt-get install helm
   ```
1. 添加 Helm 的 GPG 密鑰：
2. 安裝 `apt-transport-https`：
3. 添加 Helm 的 APT 存儲庫：
4. 更新 APT 包索引：
5. 安裝 Helm：
6. 驗證 Helm 安裝：

   ```sh
   helm version
   ```

## learn-terraform-multicloud-kubernetes 教學網址 (aws eks + azure aks)

請參考 [官方文檔](https://developer.hashicorp.com/terraform/tutorials/networking/multicloud-kubernetes#provision-an-aks-cluster) 以獲取詳細步驟。

需要以下工具：

- 本地安裝 Terraform 0.14+ 版本
- 已配置 Terraform 憑證的 AWS 帳戶
- AWS CLI
- Azure 帳戶
- Azure CLI
- kubectl

## 參考

### 安裝及配置 gcloud CLI

請參考 [官方文檔](https://cloud.google.com/sdk/docs/install?hl=zh-cn#deb) 以獲取詳細步驟。

### 安裝及配置 kubectl

請參考 [官方文檔](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/) 以獲取詳細步驟。

### 安裝及配置 Terraform

請參考 [官方文檔](https://learn.hashicorp.com/tutorials/terraform/install-cli) 以獲取詳細步驟。

### 安裝及配置 AWS CLI

請參考 [官方文檔](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) 以獲取詳細步驟。

### 印度老師的教學 video

https://www.youtube.com/watch?v=RUoejLILgyA&ab_channel=KodeKloud
