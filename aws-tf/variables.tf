# ================================================================================================================== #

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-2"
}

variable "cloudflare_api_token" {
  description = "Cloudflare API token"
  type        = string
  default     = ""
}

variable "domain_name" {
  description = "The domain name for the Flask Ingress (e.g., example.com)."
  type        = string
  default     = "ashleyyue.me"
}

variable "cloudflare_zone_id" {
  description = "Cloudflare Zone ID for the domain."
  type        = string
  default     = ""
}
