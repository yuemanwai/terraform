# ================================================================================================================== #
# shared workspace變數
variable "region" {
  description = "AWS region"
  type        = string
  default     = ""
}

variable "cloudflare_api_token" {
  description = "Cloudflare API token"
  type        = string
  default     = ""
}

variable "domain_name" {
  description = "The domain name for the Flask Ingress (e.g., example.com)."
  type        = string
  default     = ""
}

variable "cloudflare_zone_id" {
  description = "Cloudflare Zone ID for the domain."
  type        = string
  default     = ""
}

# ================================================================================================================== #
# 獨立workspace變數

variable "db_username" {
  description = "Database username"
  type        = string
  default     = ""
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = ""
}

variable "db_port" {
  description = "Database port"
  type        = string
  default     = "5432"
}
