# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-2"
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