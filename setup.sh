#!/bin/bash

# ======================================================
# 此腳本已經改用 Dev Container 取代
# 請使用 .devcontainer/ 目錄中的配置
# 啟動 Dev Container：
# 1. 在 VS Code 中按 Ctrl+Shift+P
# 2. 選擇 "Dev Containers: Reopen in Container"
# ======================================================

echo "⚠️  此腳本已棄用，請使用 Dev Container"
echo "啟動方式："
echo "1. 在 VS Code 中按 Ctrl+Shift+P"
echo "2. 選擇 'Dev Containers: Reopen in Container'"
echo ""
echo "容器啟動後執行認證："
echo "- AWS: aws configure"
echo "- Azure: az login"
echo "- GCP: ./gcp-auth.sh"

exit 1

# 安裝 AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o awscliv2.zip
unzip -u awscliv2.zip
sudo ./aws/install
rm -rf awscliv2.zip aws

# 配置 AWS CLI
mkdir -p ~/.aws
touch ~/.aws/config ~/.aws/credentials

cat <<EOL > ~/.aws/config
[default]
region = us-east-1
output = json
EOL

# 安裝 kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
kubectl version --client --output=yaml

# 安裝 Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

cat <<EOL > ./terraform_azure/terraform.tfvars
appId    = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
password = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
EOL

# 安裝 gcloud CLI (有步驟要手動)
sudo apt-get update
sudo apt-get install apt-transport-https ca-certificates gnupg curl
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg
echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
sudo apt-get update && sudo apt-get install google-cloud-cli
gcloud init
gcloud auth application-default login

# 安裝 AWS IAM Authenticator
curl -o aws-iam-authenticator https://amazon-eks.s3.us-west-2.amazonaws.com/1.15.10/2020-02-22/bin/linux/amd64/aws-iam-authenticator
chmod +x ./aws-iam-authenticator
sudo mv ./aws-iam-authenticator /usr/local/bin

# 驗證安裝
aws --version
kubectl version
az version
aws-iam-authenticator help
