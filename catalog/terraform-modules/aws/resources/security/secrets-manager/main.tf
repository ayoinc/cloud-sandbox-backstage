# -----------------------------------------------------------------------------
# AWS Secrets Manager Module
# -----------------------------------------------------------------------------
# Creates secrets with optional rotation and replication
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
  description = "Name of the secret"
  type        = string
}

variable "description" {
  description = "Description of the secret"
  type        = string
  default     = ""
}

variable "kms_key_id" {
  description = "KMS key ID for encryption (uses AWS managed key if not specified)"
  type        = string
  default     = null
}

variable "recovery_window_in_days" {
  description = "Number of days before permanent deletion (0 for immediate, 7-30 for delayed)"
  type        = number
  default     = 30

  validation {
    condition     = var.recovery_window_in_days == 0 || (var.recovery_window_in_days >= 7 && var.recovery_window_in_days <= 30)
    error_message = "Recovery window must be 0 (immediate) or between 7 and 30 days."
  }
}

variable "secret_string" {
  description = "Secret value as a string"
  type        = string
  default     = null
  sensitive   = true
}

variable "secret_binary" {
  description = "Secret value as base64 encoded binary"
  type        = string
  default     = null
  sensitive   = true
}

variable "enable_rotation" {
  description = "Enable automatic rotation"
  type        = bool
  default     = false
}

variable "rotation_lambda_arn" {
  description = "ARN of the Lambda function for rotation"
  type        = string
  default     = null
}

variable "rotation_days" {
  description = "Number of days between rotations"
  type        = number
  default     = 30

  validation {
    condition     = var.rotation_days >= 1 && var.rotation_days <= 365
    error_message = "Rotation days must be between 1 and 365."
  }
}

variable "replica_regions" {
  description = "List of regions for secret replication"
  type = list(object({
    region     = string
    kms_key_id = optional(string)
  }))
  default = []
}

variable "policy" {
  description = "Resource policy JSON for the secret"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

# -----------------------------------------------------------------------------
# Secrets Manager Secret
# -----------------------------------------------------------------------------

resource "aws_secretsmanager_secret" "this" {
  name                    = var.name
  description             = var.description
  kms_key_id              = var.kms_key_id
  recovery_window_in_days = var.recovery_window_in_days

  dynamic "replica" {
    for_each = var.replica_regions
    content {
      region     = replica.value.region
      kms_key_id = replica.value.kms_key_id
    }
  }

  tags = merge(var.tags, {
    Name = var.name
  })
}

# -----------------------------------------------------------------------------
# Secret Version
# -----------------------------------------------------------------------------

resource "aws_secretsmanager_secret_version" "this" {
  count = var.secret_string != null || var.secret_binary != null ? 1 : 0

  secret_id     = aws_secretsmanager_secret.this.id
  secret_string = var.secret_string
  secret_binary = var.secret_binary

  lifecycle {
    ignore_changes = [
      secret_string,
      secret_binary
    ]
  }
}

# -----------------------------------------------------------------------------
# Secret Rotation
# -----------------------------------------------------------------------------

resource "aws_secretsmanager_secret_rotation" "this" {
  count = var.enable_rotation && var.rotation_lambda_arn != null ? 1 : 0

  secret_id           = aws_secretsmanager_secret.this.id
  rotation_lambda_arn = var.rotation_lambda_arn

  rotation_rules {
    automatically_after_days = var.rotation_days
  }
}

# -----------------------------------------------------------------------------
# Secret Policy
# -----------------------------------------------------------------------------

resource "aws_secretsmanager_secret_policy" "this" {
  count = var.policy != null ? 1 : 0

  secret_arn = aws_secretsmanager_secret.this.arn
  policy     = var.policy
}

# -----------------------------------------------------------------------------
# Outputs
# -----------------------------------------------------------------------------

output "secret_id" {
  description = "ID of the secret"
  value       = aws_secretsmanager_secret.this.id
}

output "secret_arn" {
  description = "ARN of the secret"
  value       = aws_secretsmanager_secret.this.arn
}

output "secret_name" {
  description = "Name of the secret"
  value       = aws_secretsmanager_secret.this.name
}

output "version_id" {
  description = "Version ID of the secret"
  value       = var.secret_string != null || var.secret_binary != null ? aws_secretsmanager_secret_version.this[0].version_id : null
}

output "replica_status" {
  description = "Status of secret replicas"
  value       = aws_secretsmanager_secret.this.replica
}
