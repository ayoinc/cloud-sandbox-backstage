# -----------------------------------------------------------------------------
# AWS Security Module - Variables
# -----------------------------------------------------------------------------

variable "project_name" {
  description = "Project name used as the prefix of every resource name"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9._-]*$", var.project_name))
    error_message = "project_name must start with a letter and contain only letters, digits, dots, underscores and hyphens."
  }
}

variable "environment" {
  description = "Environment name (for example dev, staging, prod)"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]{1,8}$", var.environment))
    error_message = "environment must be 1-8 lowercase letters or digits."
  }
}

variable "vpc_id" {
  description = "VPC ID the bastion security group is created in. Required when enable_bastion_sg is true"
  type        = string
  default     = null
}

# KMS Configuration
variable "kms_multi_region" {
  description = "Create the KMS key as a multi-region primary key"
  type        = bool
  default     = false
}

# Bastion Configuration
variable "enable_bastion_sg" {
  description = "Create a security group for a bastion host. Requires vpc_id"
  type        = bool
  default     = false

  validation {
    condition     = !var.enable_bastion_sg || var.vpc_id != null
    error_message = "vpc_id must be set when enable_bastion_sg is true."
  }
}

variable "bastion_allowed_cidrs" {
  description = "IPv4 CIDR blocks allowed to SSH to the bastion. Empty means no SSH ingress"
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for cidr in var.bastion_allowed_cidrs : can(cidrhost(cidr, 0)) && !endswith(cidr, "/0")])
    error_message = "bastion_allowed_cidrs must be valid IPv4 CIDR blocks and must not include 0.0.0.0/0."
  }
}

# WAF Configuration
variable "enable_waf" {
  description = "Create a regional WAFv2 web ACL (for ALB, API Gateway or AppSync) with AWS managed rule groups and a rate limit"
  type        = bool
  default     = false
}

variable "waf_rate_limit" {
  description = "Requests allowed per 5 minutes per source IP before the WAF blocks it"
  type        = number
  default     = 2000

  validation {
    condition     = var.waf_rate_limit >= 10
    error_message = "waf_rate_limit must be at least 10."
  }
}

variable "tags" {
  description = "Tags for all resources"
  type        = map(string)
  default     = {}
}
