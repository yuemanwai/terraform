# Learn Terraform - Provision AKS Cluster

This repository is a companion to the [Provision an AKS Cluster tutorial](https://developer.hashicorp.com/terraform/tutorials/kubernetes/aks). It contains Terraform configuration files for creating an AKS cluster on Azure.

**Required AzureRM Provider Version:** `3.93.0`

To check the available Kubernetes versions for your region, run the following command:

```bash
az aks get-versions --location westus2
```

terraform output -raw kube_config > ~/.kube/config

export KUBECONFIG=~/.kube/config
kubectl config current-context
kubectl config use-context <context-name>
kubectl cluster-info
kubectl get node

export KUBERNETES_MASTER=https://<master-node-ip>:<port>