#!/bin/bash

# 設定執行權限
chmod +x /workspaces/terraform/.devcontainer/post-create.sh

# 驗證安裝
echo "=== 驗證工具安裝 ==="
echo "Terraform version:"
terraform version

echo -e "\nAWS CLI version:"
aws --version

echo -e "\nkubectl version:"
kubectl version --client --output=yaml 2>/dev/null || echo "kubectl client installed"

echo -e "\nAzure CLI version:"
az version --output table

echo -e "\nGoogle Cloud CLI version:"
gcloud version

echo -e "\nHelm version:"
helm version

echo -e "\nAWS IAM Authenticator:"
aws-iam-authenticator version

# 建立 terraform.tfvars 範本（如果不存在）
if [ ! -f "/workspace/azure-tf/terraform.tfvars" ]; then
    mkdir -p /workspace/azure-tf
    cat <<EOL > /workspace/azure-tf/terraform.tfvars
appId    = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
password = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
EOL
    echo "Created terraform.tfvars template in azure-tf/"
fi

# 建立 GCP 認證腳本
cat <<'EOL' > /workspace/gcp-auth.sh
#!/bin/bash
echo "=== GCP 認證設定 ==="
echo "1. 設定專案和區域"
gcloud init

echo "2. 應用程式預設認證"
gcloud auth application-default login

echo "3. 用戶認證"
gcloud auth login

echo "4. 驗證認證狀態"
gcloud auth list
gcloud config list

echo "=== GCP 認證完成 ==="
EOL

chmod +x /workspace/gcp-auth.sh

echo -e "\n=== Dev Container 設定完成 ==="
echo "請執行以下命令完成雲端服務認證："
echo "1. AWS: aws configure"
echo "2. Azure: az login"
echo "3. GCP 認證步驟："
echo "   ./gcp-auth.sh"
echo "   或手動執行："
echo "   gcloud init"
echo "   gcloud auth application-default login"
echo "   gcloud auth login"
echo ""
echo "建立了 gcp-auth.sh 腳本，請在容器啟動後執行："
echo "./gcp-auth.sh"
