# -----------------------------------------------------------------------------
# AWS KMS Key Module
# -----------------------------------------------------------------------------
# Creates KMS keys with key policies, aliases, and rotation
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

variable "alias" {
  description = "Alias for the KMS key (without alias/ prefix)"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9/_-]+$", var.alias))
    error_message = "Alias must contain only alphanumeric characters, forward slashes, underscores, and hyphens."
  }
}

variable "description" {
  description = "Description of the KMS key"
  type        = string
  default     = "KMS key managed by Terraform"
}

variable "key_usage" {
  description = "Intended use of the key (ENCRYPT_DECRYPT or SIGN_VERIFY)"
  type        = string
  default     = "ENCRYPT_DECRYPT"

  validation {
    condition     = contains(["ENCRYPT_DECRYPT", "SIGN_VERIFY", "GENERATE_VERIFY_MAC"], var.key_usage)
    error_message = "Key usage must be ENCRYPT_DECRYPT, SIGN_VERIFY, or GENERATE_VERIFY_MAC."
  }
}

variable "customer_master_key_spec" {
  description = "Key spec for the KMS key"
  type        = string
  default     = "SYMMETRIC_DEFAULT"

  validation {
    condition = contains([
      "SYMMETRIC_DEFAULT",
      "RSA_2048", "RSA_3072", "RSA_4096",
      "ECC_NIST_P256", "ECC_NIST_P384", "ECC_NIST_P521", "ECC_SECG_P256K1",
      "HMAC_224", "HMAC_256", "HMAC_384", "HMAC_512"
    ], var.customer_master_key_spec)
    error_message = "Invalid key spec."
  }
}

variable "enable_key_rotation" {
  description = "Enable automatic key rotation (symmetric keys only)"
  type        = bool
  default     = true
}

variable "rotation_period_in_days" {
  description = "Key rotation period in days (90-2560)"
  type        = number
  default     = 365

  validation {
    condition     = var.rotation_period_in_days >= 90 && var.rotation_period_in_days <= 2560
    error_message = "Rotation period must be between 90 and 2560 days."
  }
}

variable "deletion_window_in_days" {
  description = "Waiting period before key deletion (7-30 days)"
  type        = number
  default     = 30

  validation {
    condition     = var.deletion_window_in_days >= 7 && var.deletion_window_in_days <= 30
    error_message = "Deletion window must be between 7 and 30 days."
  }
}

variable "multi_region" {
  description = "Create a multi-region primary key"
  type        = bool
  default     = false
}

variable "policy" {
  description = "Custom key policy JSON document"
  type        = string
  default     = null
}

variable "key_administrators" {
  description = "List of IAM ARNs for key administrators"
  type        = list(string)
  default     = []
}

variable "key_users" {
  description = "List of IAM ARNs for key users"
  type        = list(string)
  default     = []
}

variable "key_service_users" {
  description = "List of AWS service principals that can use the key"
  type        = list(string)
  default     = []
}

variable "grants" {
  description = "Map of grants to create"
  type = map(object({
    grantee_principal     = string
    operations            = list(string)
    retiring_principal    = optional(string)
    grant_creation_tokens = optional(list(string))
    constraints = optional(object({
      encryption_context_equals = optional(map(string))
      encryption_context_subset = optional(map(string))
    }))
  }))
  default = {}
}

variable "enable_default_policy" {
  description = "Enable default key policy allowing root account access"
  type        = bool
  default     = true
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

data "aws_region" "current" {}

# -----------------------------------------------------------------------------
# Local Values
# -----------------------------------------------------------------------------

locals {
  account_id = data.aws_caller_identity.current.account_id
  partition  = data.aws_partition.current.partition

  # Build default key policy
  default_policy = var.policy != null ? var.policy : jsonencode({
    Version = "2012-10-17"
    Statement = concat(
      # Root account access (required for key management)
      var.enable_default_policy ? [{
        Sid    = "EnableRootAccountPermissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:${local.partition}:iam::${local.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      }] : [],
      # Key administrators
      length(var.key_administrators) > 0 ? [{
        Sid    = "KeyAdministrators"
        Effect = "Allow"
        Principal = {
          AWS = var.key_administrators
        }
        Action = [
          "kms:Create*",
          "kms:Describe*",
          "kms:Enable*",
          "kms:List*",
          "kms:Put*",
          "kms:Update*",
          "kms:Revoke*",
          "kms:Disable*",
          "kms:Get*",
          "kms:Delete*",
          "kms:TagResource",
          "kms:UntagResource",
          "kms:ScheduleKeyDeletion",
          "kms:CancelKeyDeletion"
        ]
        Resource = "*"
      }] : [],
      # Key users
      length(var.key_users) > 0 ? [{
        Sid    = "KeyUsers"
        Effect = "Allow"
        Principal = {
          AWS = var.key_users
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
      }] : [],
      # Service users (for AWS services)
      length(var.key_service_users) > 0 ? [{
        Sid    = "AllowServiceUsage"
        Effect = "Allow"
        Principal = {
          Service = var.key_service_users
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
      }] : []
    )
  })
}

# -----------------------------------------------------------------------------
# KMS Key
# -----------------------------------------------------------------------------

resource "aws_kms_key" "this" {
  description              = var.description
  key_usage                = var.key_usage
  customer_master_key_spec = var.customer_master_key_spec
  enable_key_rotation      = var.key_usage == "ENCRYPT_DECRYPT" && var.customer_master_key_spec == "SYMMETRIC_DEFAULT" ? var.enable_key_rotation : false
  rotation_period_in_days  = var.enable_key_rotation ? var.rotation_period_in_days : null
  deletion_window_in_days  = var.deletion_window_in_days
  multi_region             = var.multi_region
  policy                   = local.default_policy

  tags = merge(var.tags, {
    Name = var.alias
  })
}

# -----------------------------------------------------------------------------
# KMS Alias
# -----------------------------------------------------------------------------

resource "aws_kms_alias" "this" {
  name          = "alias/${var.alias}"
  target_key_id = aws_kms_key.this.key_id
}

# -----------------------------------------------------------------------------
# KMS Grants
# -----------------------------------------------------------------------------

resource "aws_kms_grant" "this" {
  for_each = var.grants

  name               = each.key
  key_id             = aws_kms_key.this.key_id
  grantee_principal  = each.value.grantee_principal
  operations         = each.value.operations
  retiring_principal = each.value.retiring_principal

  dynamic "constraints" {
    for_each = each.value.constraints != null ? [each.value.constraints] : []
    content {
      encryption_context_equals = constraints.value.encryption_context_equals
      encryption_context_subset = constraints.value.encryption_context_subset
    }
  }
}

# -----------------------------------------------------------------------------
# Outputs
# -----------------------------------------------------------------------------

output "key_id" {
  description = "ID of the KMS key"
  value       = aws_kms_key.this.key_id
}

output "key_arn" {
  description = "ARN of the KMS key"
  value       = aws_kms_key.this.arn
}

output "alias_arn" {
  description = "ARN of the KMS alias"
  value       = aws_kms_alias.this.arn
}

output "alias_name" {
  description = "Name of the KMS alias"
  value       = aws_kms_alias.this.name
}
