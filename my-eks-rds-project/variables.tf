# variables.tf

variable "project_name" {
  description = "Name of the project for tagging and naming resources."
  type        = string
  default     = "fyp-project"
}

variable "region" {
  description = "AWS region for resources."
  type        = string
  default     = "ap-southeast-1"
}

variable "eks_kubernetes_version" {
  description = "Kubernetes version for the EKS cluster."
  type        = string
  default     = "1.28"
}