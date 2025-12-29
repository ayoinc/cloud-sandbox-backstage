# -----------------------------------------------------------------------------
# AWS IAM Role Module
# -----------------------------------------------------------------------------
# Creates IAM roles with customizable trust policies and permissions
# -----------------------------------------------------------------------------

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0"
    }
  }
}

# -----------------------------------------------------------------------------
# Variables
# -----------------------------------------------------------------------------

variable "name" {
  description = "Name of the IAM role"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9_+=,.@-]{0,63}$", var.name))
    error_message = "Role name must be 1-64 characters, start with a letter, and contain only alphanumeric characters and +=,.@-_"
  }
}

variable "description" {
  description = "Description of the IAM role"
  type        = string
  default     = ""
}

variable "path" {
  description = "Path for the IAM role"
  type        = string
  default     = "/"
}

variable "max_session_duration" {
  description = "Maximum session duration in seconds (3600-43200)"
  type        = number
  default     = 3600

  validation {
    condition     = var.max_session_duration >= 3600 && var.max_session_duration <= 43200
    error_message = "Max session duration must be between 3600 and 43200 seconds."
  }
}

variable "assume_role_policy" {
  description = "JSON policy document for trust relationship"
  type        = string
  default     = null
}

variable "trusted_services" {
  description = "List of AWS services that can assume this role"
  type        = list(string)
  default     = []
}

variable "trusted_accounts" {
  description = "List of AWS account IDs that can assume this role"
  type        = list(string)
  default     = []
}

variable "trusted_roles" {
  description = "List of IAM role ARNs that can assume this role"
  type        = list(string)
  default     = []
}

variable "managed_policy_arns" {
  description = "List of managed policy ARNs to attach"
  type        = list(string)
  default     = []
}

variable "inline_policies" {
  description = "Map of inline policy names to policy documents"
  type        = map(string)
  default     = {}
}

variable "permissions_boundary" {
  description = "ARN of the permissions boundary policy"
  type        = string
  default     = null
}

variable "force_detach_policies" {
  description = "Force detach policies before destroying role"
  type        = bool
  default     = true
}

variable "create_instance_profile" {
  description = "Create an instance profile for EC2"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

# -----------------------------------------------------------------------------
# Data Sources
# -----------------------------------------------------------------------------

data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

# -----------------------------------------------------------------------------
# Local Values
# -----------------------------------------------------------------------------

locals {
  # Build trust policy from components if not provided directly
  trust_policy = var.assume_role_policy != null ? var.assume_role_policy : jsonencode({
    Version = "2012-10-17"
    Statement = concat(
      # Service principals
      length(var.trusted_services) > 0 ? [{
        Effect = "Allow"
        Principal = {
          Service = var.trusted_services
        }
        Action = "sts:AssumeRole"
      }] : [],
      # Account principals
      length(var.trusted_accounts) > 0 ? [{
        Effect = "Allow"
        Principal = {
          AWS = [for account in var.trusted_accounts : "arn:${data.aws_partition.current.partition}:iam::${account}:root"]
        }
        Action = "sts:AssumeRole"
      }] : [],
      # Role principals
      length(var.trusted_roles) > 0 ? [{
        Effect = "Allow"
        Principal = {
          AWS = var.trusted_roles
        }
        Action = "sts:AssumeRole"
      }] : []
    )
  })
}

# -----------------------------------------------------------------------------
# IAM Role
# -----------------------------------------------------------------------------

resource "aws_iam_role" "this" {
  name                  = var.name
  description           = var.description
  path                  = var.path
  max_session_duration  = var.max_session_duration
  assume_role_policy    = local.trust_policy
  permissions_boundary  = var.permissions_boundary
  force_detach_policies = var.force_detach_policies

  tags = merge(var.tags, {
    Name = var.name
  })
}

# -----------------------------------------------------------------------------
# Managed Policy Attachments
# -----------------------------------------------------------------------------

resource "aws_iam_role_policy_attachment" "managed" {
  for_each = toset(var.managed_policy_arns)

  role       = aws_iam_role.this.name
  policy_arn = each.value
}

# -----------------------------------------------------------------------------
# Inline Policies
# -----------------------------------------------------------------------------

resource "aws_iam_role_policy" "inline" {
  for_each = var.inline_policies

  name   = each.key
  role   = aws_iam_role.this.name
  policy = each.value
}

# -----------------------------------------------------------------------------
# Instance Profile (Optional)
# -----------------------------------------------------------------------------

resource "aws_iam_instance_profile" "this" {
  count = var.create_instance_profile ? 1 : 0

  name = var.name
  path = var.path
  role = aws_iam_role.this.name

  tags = merge(var.tags, {
    Name = var.name
  })
}

# -----------------------------------------------------------------------------
# Outputs
# -----------------------------------------------------------------------------

output "role_arn" {
  description = "ARN of the IAM role"
  value       = aws_iam_role.this.arn
}

output "role_name" {
  description = "Name of the IAM role"
  value       = aws_iam_role.this.name
}

output "role_id" {
  description = "Unique ID of the IAM role"
  value       = aws_iam_role.this.unique_id
}

output "instance_profile_arn" {
  description = "ARN of the instance profile (if created)"
  value       = var.create_instance_profile ? aws_iam_instance_profile.this[0].arn : null
}

output "instance_profile_name" {
  description = "Name of the instance profile (if created)"
  value       = var.create_instance_profile ? aws_iam_instance_profile.this[0].name : null
}
