#!/bin/bash

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

[profile my-profile]
role_arn = YOUR_LABROLE_ARN
source_profile = default
EOL

# 安裝 kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
kubectl version --client --output=yaml

# 安裝 Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

cat <<EOL > terraform.tfvars
appId    = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
password = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
EOL

# 安裝 gcloud CLI (有步驟要手動)
sudo apt-get update
sudo apt-get install apt-transport-https ca-certificates gnupg curl
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg -y
echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list -y
sudo apt-get update && sudo apt-get install google-cloud-cli
gcloud init
gcloud auth application-default login

# 驗證安裝
aws --version
kubectl version
az version