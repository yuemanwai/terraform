# terraform

## 使用 Terraform 創建 Kubernetes 服務

以下是使用 Terraform 在三個主要雲提供商（AWS、Azure 和 GCP）上創建 Kubernetes 服務的步驟。

### 安裝 Terraform

1. 下載並安裝 Terraform，請參考 [官方文檔](https://learn.hashicorp.com/tutorials/terraform/install-cli)。
2. 驗證安裝是否成功：
   ```sh
   terraform -v
   ```

### 配置 AWS

請參考 [官方文檔](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) 以獲取詳細步驟。

#### 配置 AWS CLI

在使用 Terraform 配置 AWS 之前，您需要在 `~/.aws/config` 和 `~/.aws/credentials` 文件中添加必要的內容。

##### ~/.aws/config

```plaintext
[default]
region = us-east-1
output = json

[profile my-profile]
role_arn = YOUR_LABROLE_ARN
source_profile = default
```

##### ~/.aws/credentials

```plaintext
[default]
aws_access_key_id = YOUR_ACCESS_KEY_ID
aws_secret_access_key = YOUR_SECRET_ACCESS_KEY
```

### 配置 Azure

請參考 [terraform_azure_fyp/README.md](./terraform_azure_fyp/README.md) 以獲取詳細步驟。

### 配置 GCP

請參考 [terraform_gcp_fyp/README.md](./terraform_gcp_fyp/README.md) 以獲取詳細步驟。
