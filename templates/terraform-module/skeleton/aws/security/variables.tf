# -----------------------------------------------------------------------------
# AWS Security Module - Variables
# -----------------------------------------------------------------------------

variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
  default     = null
}

# KMS Configuration
variable "kms_multi_region" {
  description = "Enable multi-region KMS key"
  type        = bool
  default     = false
}

# Bastion Configuration
variable "enable_bastion_sg" {
  description = "Create bastion security group"
  type        = bool
  default     = true
}

variable "bastion_allowed_cidrs" {
  description = "CIDR blocks allowed SSH access to bastion"
  type        = list(string)
  default     = []
}

# WAF Configuration
variable "enable_waf" {
  description = "Enable AWS WAF"
  type        = bool
  default     = false
}

variable "waf_rate_limit" {
  description = "WAF rate limit (requests per 5 minutes per IP)"
  type        = number
  default     = 2000
}

variable "tags" {
  description = "Tags for all resources"
  type        = map(string)
  default     = {}
}
