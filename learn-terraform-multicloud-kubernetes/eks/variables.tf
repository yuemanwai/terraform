# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

variable "region" {
  default     = "us-east-2"
  description = "AWS region"
}

variable "aws_profile" {
  description = "The AWS profile to use from the .aws/config file"
  type        = string
  default     = "default"
}