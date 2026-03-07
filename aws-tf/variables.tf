# ================================================================================================================== #

variable "region" {
  description = "AWS region"
  type        = string
}

variable "cloudflare_api_token" {
  description = "Cloudflare API token"
  type        = string
  sensitive   = true
}

variable "domain_name" {
  description = "The domain name for the Flask Ingress (e.g., example.com)."
  type        = string
}

variable "cloudflare_zone_id" {
  description = "Cloudflare Zone ID for the domain."
  type        = string
}

# ================================================================================================================== #
# For RDS workspace only

variable "db_username" {
  description = "Database username"
  type        = string
  sensitive   = true
}

variable "db_name" {
  description = "Database name"
  type        = string
}

variable "db_port" {
  description = "Database port"
  type        = string
}

# ================================================================================================================== #
# For EKS workspace only

# variable "app_name" {
#   description = "Name of the Flask application."
#   type        = string
# }

# variable "app_namespace" {
#   description = "Namespace for the Flask application deployment."
#   type        = string
# }

# variable "app_image" {
#   description = "Docker image for the Flask application."
#   type        = string
# }

# variable "app_port" {
#   description = "Port the Flask application listens on inside the container."
#   type        = number
# }

# variable "service_port" {
#   description = "Port the Kubernetes Service exposes to the Ingress."
#   type        = number
# }

# variable "GEMINI_API_KEY" {
#   description = "Gemini API key."
#   type        = string
#   default     = ""
# }

variable "repoURL" {
  type        = string
  default     = ""
  description = "repoURL for ArgoCD to sync with"
}

variable "github_username" {
  type        = string
  default     = ""
  description = "GitHub username"
}

variable "github_token" {
  type        = string
  default     = ""
  description = "GitHub personal access token (PAT) with repo access"
  sensitive   = true
}
