# =============================================================================
# AWS S3 MODULE
# =============================================================================
# Creates S3 bucket with encryption, versioning, and lifecycle policies
# Follows AWS Well-Architected Framework and security best practices
# Provider version: ~> 5.0
# =============================================================================

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
  description = "Bucket name (will be made globally unique)"
  type        = string
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
}

variable "force_destroy" {
  description = "Allow bucket deletion with objects"
  type        = bool
  default     = false
}

variable "versioning_enabled" {
  description = "Enable versioning"
  type        = bool
  default     = true
}

variable "encryption_type" {
  description = "Encryption type: AES256, aws:kms, or aws:kms:dsse"
  type        = string
  default     = "AES256"
}

variable "kms_key_arn" {
  description = "KMS key ARN for encryption (if using KMS)"
  type        = string
  default     = null
}

variable "block_public_access" {
  description = "Block all public access"
  type        = bool
  default     = true
}

variable "enable_logging" {
  description = "Enable access logging"
  type        = bool
  default     = true
}

variable "logging_bucket" {
  description = "Target bucket for access logs"
  type        = string
  default     = null
}

variable "lifecycle_rules" {
  description = "Lifecycle rules for the bucket"
  type = list(object({
    id                                 = string
    enabled                            = optional(bool, true)
    prefix                             = optional(string, "")
    expiration_days                    = optional(number)
    noncurrent_version_expiration_days = optional(number)
    transition = optional(list(object({
      days          = number
      storage_class = string
    })), [])
  }))
  default = []
}

variable "cors_rules" {
  description = "CORS rules for the bucket"
  type = list(object({
    allowed_headers = optional(list(string), ["*"])
    allowed_methods = list(string)
    allowed_origins = list(string)
    expose_headers  = optional(list(string), [])
    max_age_seconds = optional(number, 3000)
  }))
  default = []
}

variable "enable_replication" {
  description = "Enable cross-region replication"
  type        = bool
  default     = false
}

variable "replication_destination_bucket_arn" {
  description = "Destination bucket ARN for replication"
  type        = string
  default     = null
}

variable "replication_destination_kms_key_arn" {
  description = "KMS key ARN in destination region"
  type        = string
  default     = null
}

variable "object_lock_enabled" {
  description = "Enable object lock"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# -----------------------------------------------------------------------------
# Data Sources
# -----------------------------------------------------------------------------

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# -----------------------------------------------------------------------------
# Locals
# -----------------------------------------------------------------------------

locals {
  bucket_name = "${var.name}-${var.environment}-${data.aws_caller_identity.current.account_id}"

  common_tags = merge(var.tags, {
    Name        = local.bucket_name
    Environment = var.environment
    ManagedBy   = "terraform"
  })
}

# -----------------------------------------------------------------------------
# S3 Bucket
# -----------------------------------------------------------------------------

resource "aws_s3_bucket" "main" {
  bucket        = local.bucket_name
  force_destroy = var.force_destroy

  object_lock_enabled = var.object_lock_enabled

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# Bucket Versioning
# -----------------------------------------------------------------------------

resource "aws_s3_bucket_versioning" "main" {
  bucket = aws_s3_bucket.main.id

  versioning_configuration {
    status = var.versioning_enabled ? "Enabled" : "Disabled"
  }
}

# -----------------------------------------------------------------------------
# Server-Side Encryption
# -----------------------------------------------------------------------------

resource "aws_s3_bucket_server_side_encryption_configuration" "main" {
  bucket = aws_s3_bucket.main.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.encryption_type == "AES256" ? "AES256" : "aws:kms"
      kms_master_key_id = var.encryption_type != "AES256" ? var.kms_key_arn : null
    }
    bucket_key_enabled = var.encryption_type != "AES256" ? true : false
  }
}

# -----------------------------------------------------------------------------
# Block Public Access
# -----------------------------------------------------------------------------

resource "aws_s3_bucket_public_access_block" "main" {
  bucket = aws_s3_bucket.main.id

  block_public_acls       = var.block_public_access
  block_public_policy     = var.block_public_access
  ignore_public_acls      = var.block_public_access
  restrict_public_buckets = var.block_public_access
}

# -----------------------------------------------------------------------------
# Bucket Policy (Enforce SSL)
# -----------------------------------------------------------------------------

resource "aws_s3_bucket_policy" "ssl_enforcement" {
  bucket = aws_s3_bucket.main.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "EnforceSSLOnly"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.main.arn,
          "${aws_s3_bucket.main.arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.main]
}

# -----------------------------------------------------------------------------
# Access Logging
# -----------------------------------------------------------------------------

resource "aws_s3_bucket_logging" "main" {
  count = var.enable_logging && var.logging_bucket != null ? 1 : 0

  bucket = aws_s3_bucket.main.id

  target_bucket = var.logging_bucket
  target_prefix = "${local.bucket_name}/logs/"
}

# -----------------------------------------------------------------------------
# Lifecycle Rules
# -----------------------------------------------------------------------------

resource "aws_s3_bucket_lifecycle_configuration" "main" {
  count = length(var.lifecycle_rules) > 0 ? 1 : 0

  bucket = aws_s3_bucket.main.id

  dynamic "rule" {
    for_each = var.lifecycle_rules
    content {
      id     = rule.value.id
      status = rule.value.enabled ? "Enabled" : "Disabled"

      filter {
        prefix = rule.value.prefix
      }

      dynamic "expiration" {
        for_each = rule.value.expiration_days != null ? [1] : []
        content {
          days = rule.value.expiration_days
        }
      }

      dynamic "noncurrent_version_expiration" {
        for_each = rule.value.noncurrent_version_expiration_days != null ? [1] : []
        content {
          noncurrent_days = rule.value.noncurrent_version_expiration_days
        }
      }

      dynamic "transition" {
        for_each = rule.value.transition
        content {
          days          = transition.value.days
          storage_class = transition.value.storage_class
        }
      }
    }
  }

  depends_on = [aws_s3_bucket_versioning.main]
}

# -----------------------------------------------------------------------------
# CORS Configuration
# -----------------------------------------------------------------------------

resource "aws_s3_bucket_cors_configuration" "main" {
  count = length(var.cors_rules) > 0 ? 1 : 0

  bucket = aws_s3_bucket.main.id

  dynamic "cors_rule" {
    for_each = var.cors_rules
    content {
      allowed_headers = cors_rule.value.allowed_headers
      allowed_methods = cors_rule.value.allowed_methods
      allowed_origins = cors_rule.value.allowed_origins
      expose_headers  = cors_rule.value.expose_headers
      max_age_seconds = cors_rule.value.max_age_seconds
    }
  }
}

# -----------------------------------------------------------------------------
# Outputs
# -----------------------------------------------------------------------------

output "bucket_id" {
  description = "Bucket ID"
  value       = aws_s3_bucket.main.id
}

output "bucket_arn" {
  description = "Bucket ARN"
  value       = aws_s3_bucket.main.arn
}

output "bucket_name" {
  description = "Bucket name"
  value       = aws_s3_bucket.main.bucket
}

output "bucket_domain_name" {
  description = "Bucket domain name"
  value       = aws_s3_bucket.main.bucket_domain_name
}

output "bucket_regional_domain_name" {
  description = "Bucket regional domain name"
  value       = aws_s3_bucket.main.bucket_regional_domain_name
}
