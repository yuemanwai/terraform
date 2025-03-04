# terraform

## 使用 Terraform 創建 Kubernetes 服務

以下是使用 Terraform 在三個主要雲提供商（AWS、Azure 和 GCP）上創建 Kubernetes 服務的步驟。

## learn-terraform-multicloud-kubernetes 教學網址 (aws eks + azure aks)

https://developer.hashicorp.com/terraform/tutorials/networking/multicloud-kubernetes#provision-an-aks-cluster

For this tutorial, you will need:

- Terraform 0.14+ installed locally
- an AWS account with credentials configured for Terraform
- the AWS CLI
- an Azure account
- the Azure CLI
- kubectl

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

#### 安裝 Azure CLI

```sh
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
```

#### 安裝 kubectl

```sh
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
kubectl version --client --output=yaml
```

#### 配置 Azure CLI

1. 登錄 Azure：

   ```sh
   az login
   ```

2. 創建服務主體：

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

### 配置 GCP

請參考 [terraform_gcp/README.md](./terraform_gcp/README.md) 以獲取詳細步驟。

## 其他參考

印度老師的教學視頻：
https://www.youtube.com/watch?v=RUoejLILgyA&ab_channel=KodeKloud
