variable "aws_region" {
  default = "us-east-1"
}

variable "aws_profile" {
  description = "The AWS profile to use from the .aws/config file"
  type        = string
  default     = "default"
}

variable "cluster_name" {
  default = "terraform-eks-demo"
  type    = string
}