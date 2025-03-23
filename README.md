# terraform
以下教學基於 Linux Ubuntu 環境。

## 使用 Terraform 創建 Kubernetes 服務

以下是使用 Terraform 在三個主要雲提供商（AWS、Azure 和 GCP）上創建 Kubernetes 服務的步驟。

### 前置準備

如果您使用 devcontainer 開啟 Codespace，應該已自動運行 `setup.sh`，該腳本會安裝基本工具，包括 AWS CLI、Azure CLI、kubectl 和 gcloud CLI。其中，gcloud CLI 的安裝過程需要手動驗證身份，請按照指示操作。

接下來，您需要根據以下步驟完成登入及驗證。

---

## 配置 AWS CLI

運行 `setup.sh` 後，請在 `~/.aws/config` 和 `~/.aws/credentials` 文件中添加必要內容。

### 配置文件示例

#### `~/.aws/config`

```plaintext
[default]
region = us-east-1
output = json
```

#### `~/.aws/credentials`

```plaintext
[default]
aws_access_key_id = YOUR_ACCESS_KEY_ID
aws_secret_access_key = YOUR_SECRET_ACCESS_KEY
```

> **注意**: 如果使用 AWS Academy Learner Lab，每次重新創建 Session 都需更新憑證。

---

## 配置 Azure CLI

1. 登錄 Azure：

   ```sh
   az login
   ```

2. 創建服務主體並記錄生成的 `appId` 和 `password`：

   ```sh
   az ad sp create-for-rbac --skip-assignment
   ```

   > **注意**: 請妥善保存生成的密碼，因為它只會顯示一次。

3. 更新 `terraform.tfvars` 文件，填入真實的 `appId` 和 `password`：

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

### 重置 Azure CLI 憑證

1. 列出服務主體，確認目標服務主體的 `AppId`：

   ```sh
   az ad sp list --query "[?contains(displayName, 'azure-cli')].{Name:displayName, AppId:appId}" --output table
   ```

2. 重置服務主體憑證：

   ```sh
   az ad sp credential reset --id <your-app-id>
   ```

---

## 安裝 AWS IAM Authenticator

1. 下載 AWS IAM Authenticator：

   ```sh
   curl -o aws-iam-authenticator https://amazon-eks.s3.us-west-2.amazonaws.com/1.15.10/2020-02-22/bin/linux/amd64/aws-iam-authenticator
   ```

2. 添加執行權限：

   ```sh
   chmod +x ./aws-iam-authenticator
   ```

3. 移動到 PATH 中的目錄：

   ```sh
   sudo mv ./aws-iam-authenticator /usr/local/bin
   ```

4. 測試安裝：

   ```sh
   aws-iam-authenticator help
   ```

---

## 安裝 Helm

1. 添加 Helm 的 GPG 密鑰：

   ```sh
   curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
   ```

2. 安裝 `apt-transport-https`：

   ```sh
   sudo apt-get install apt-transport-https --yes
   ```

3. 添加 Helm 的 APT 存儲庫：

   ```sh
   echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
   ```

4. 更新 APT 包索引：

   ```sh
   sudo apt-get update
   ```

5. 安裝 Helm：

   ```sh
   sudo apt-get install helm
   ```

6. 驗證安裝：

   ```sh
   helm version
   ```

---

## 配置多個 Kubernetes 集群上下文

1. 更新 kubeconfig 文件：

   ```sh
   aws eks --region $(terraform output -raw region) update-kubeconfig --name $(terraform output -raw cluster_name) --kubeconfig ~/.kube/config
   ```

2. 合併多個 kubeconfig 文件：

   ```sh
   export KUBECONFIG=~/.kube/config:~/.kube/aws-kubeconfig:~/.kube/gcp-kubeconfig:~/.kube/azure-kubeconfig
   kubectl config view --merge --flatten > ~/.kube/config
   ```

3. 查看當前上下文列表：

   ```sh
   kubectl config get-contexts
   ```

4. 切換上下文並檢查 Pod：

   ```sh
   kubectl config use-context <context-name>
   kubectl get pods
   ```

---

## 參考資源

- [gcloud CLI 安裝文檔](https://cloud.google.com/sdk/docs/install?hl=zh-cn#deb)
- [kubectl 安裝文檔](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/)
- [Terraform 安裝文檔](https://learn.hashicorp.com/tutorials/terraform/install-cli)
- [AWS CLI 安裝文檔](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
- [learn-terraform-multicloud-kubernetes 教學](https://developer.hashicorp.com/terraform/tutorials/networking/multicloud-kubernetes#provision-an-aks-cluster)

---

## 其他命令示例

創建 Kubernetes Secret：

```sh
kubectl create secret generic db-secret --from-literal=username=my-db-user --from-literal=password=my-db-password
```

導出 Secret 為 YAML 文件：

```sh
kubectl get secrets db-secret -o yaml > ./kubernetes_manifest/db-secret.yaml
```

更新 Deployment 並添加環境變量：

```sh
kubectl patch deployment <deployment name> --type='json' -p='[{"op": "add", "path": "/spec/template/spec/containers/0/env", "value": [{"name": "DB_USERNAME", "valueFrom": {"secretKeyRef": {"name": "db-secret", "key": "username"}}}, {"name": "DB_PASSWORD", "valueFrom": {"secretKeyRef": {"name": "db-secret", "key": "password"}}}]}]'
```



使用 kubectl.kubernetes.io/last-applied-configuration 注解：

kubectl get <resource-type> <resource-name> -o yaml | \
yq r - 'metadata.annotations."kubectl.kubernetes.io/last-applied-configuration"'



檢視資源的最後應用配置：

```sh
kubectl apply view-last-applied <resource-type>/<resource-name> -o yaml
```