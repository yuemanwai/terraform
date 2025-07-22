variable "region" {
  description = "AWS region"
  type        = string
  default     = ""
}

variable "aws_access_key_id" {
  description = "AWS access key ID"
  type        = string
  default     = ""
}

variable "aws_secret_access_key" {
  description = "AWS secret access key"
  type        = string
  default     = ""
}

variable "cloudflare_api_token" {
  description = "Cloudflare API token"
  type        = string
  default     = ""
}

# ================================================================================================================== #

variable "domain_name" {
  description = "The domain name for the Flask Ingress (e.g., example.com)."
  type        = string
  default     = ""
}

# ================================================================================================================== #

variable "app_name" {
  description = "Name of the Flask application."
  type        = string
}

variable "app_namespace" {
  description = "Namespace for the Flask application deployment."
  type        = string
}

variable "app_image" {
  description = "Docker image for the Flask application."
  type        = string
}

variable "app_port" {
  description = "Port the Flask application listens on inside the container."
  type        = number
}

variable "service_port" {
  description = "Port the Kubernetes Service exposes to the Ingress."
  type        = number
}


