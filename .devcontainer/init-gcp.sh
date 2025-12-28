#!/bin/bash

echo "=== Google Cloud Platform 初始化 ==="

# 檢查是否已經認證
if gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q "@"; then
    echo "✓ 已找到活躍的 GCP 認證"
    gcloud config list
else
    echo "需要進行 GCP 認證，請按照以下步驟："
    echo ""
    echo "1. 初始化 gcloud："
    echo "   gcloud init"
    echo ""
    echo "2. 設定應用程式預設認證："
    echo "   gcloud auth application-default login"
    echo ""
    echo "3. (可選) 如果需要用戶認證："
    echo "   gcloud auth login"
    echo ""
    echo "執行完成後，可以用以下命令驗證："
    echo "   gcloud auth list"
    echo "   gcloud config list"
fi

# 設定 GCP 專案 ID (如果有的話)
if [ ! -z "$GCP_PROJECT_ID" ]; then
    echo "設定預設專案: $GCP_PROJECT_ID"
    gcloud config set project $GCP_PROJECT_ID
fi

# 啟用必要的 API
echo ""
echo "如果需要啟用 GCP API，請執行："
echo "gcloud services enable container.googleapis.com"
echo "gcloud services enable compute.googleapis.com"
echo "gcloud services enable cloudbuild.googleapis.com"
