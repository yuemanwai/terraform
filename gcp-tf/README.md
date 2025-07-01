# Kubernetes Engine Example

Example showing how to integrate the Terraform kubernetes provider with a Google Kubernetes Engine cluster.

[![button](http://gstatic.com/cloudssh/images/open-btn.png)](https://console.cloud.google.com/cloudshell/open?git_repo=https://github.com/GoogleCloudPlatform/terraform-google-examples&working_dir=example-gke-k8s-service-lb&page=shell&tutorial=README.md)

<a href="https://concourse-tf.gcp.solutions/teams/main/pipelines/tf-examples-gke-service-lb" target="_blank">
<img src="https://concourse-tf.gcp.solutions/api/v1/teams/main/pipelines/tf-examples-gke-service-lb/badge" /></a>


## Set up the environment

```
cd /terraform_gcp
```

### Configure the environment for Terraform:
The following command is used to authenticate your local environment with Google Cloud.
It allows Terraform to access your Google Cloud resources using your credentials.

```
[[ $CLOUD_SHELL ]] || gcloud auth application-default login
export GOOGLE_PROJECT=$(gcloud config get-value project)
```

### Set the project, replace `YOUR_PROJECT` with your project ID in main.tf line 15:

```
variable "project" {
  default = "YOUR_PROJECT"
}
```

### Run Terraform

```
terraform init
terraform apply
```

## Testing

1. Wait for the load balancer to be provisioned:

```
./test.sh
```

2. Verify response from load balancer:

```
curl http://$(terraform output load-balancer-ip)
```

## Connecting with kubectl

1. Get the cluster credentials and configure kubectl:

```
gcloud container clusters get-credentials $(terraform output cluster_name) --zone $(terraform output cluster_zone)
```

2. Verify kubectl connectivity:

```
kubectl get pods -n staging
```

## Cleanup

1. Delete resources created by terraform:

```
terraform destroy
```