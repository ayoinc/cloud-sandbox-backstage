# -----------------------------------------------------------------------------
# AWS ECR Repository Module
# -----------------------------------------------------------------------------
# Creates ECR repositories with lifecycle policies and scanning
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
  description = "Name of the ECR repository"
  type        = string
}

variable "image_tag_mutability" {
  description = "Tag mutability setting (MUTABLE or IMMUTABLE)"
  type        = string
  default     = "IMMUTABLE"

  validation {
    condition     = contains(["MUTABLE", "IMMUTABLE"], var.image_tag_mutability)
    error_message = "Image tag mutability must be MUTABLE or IMMUTABLE."
  }
}

variable "scan_on_push" {
  description = "Enable image scanning on push"
  type        = bool
  default     = true
}

variable "encryption_type" {
  description = "Encryption type (AES256 or KMS)"
  type        = string
  default     = "AES256"
}

variable "kms_key_arn" {
  description = "KMS key ARN for encryption (required if encryption_type is KMS)"
  type        = string
  default     = null
}

variable "force_delete" {
  description = "Force delete repository even if it contains images"
  type        = bool
  default     = false
}

variable "lifecycle_policy" {
  description = "Lifecycle policy JSON document"
  type        = string
  default     = null
}

variable "max_image_count" {
  description = "Maximum number of images to keep (used if lifecycle_policy is null)"
  type        = number
  default     = 30
}

variable "repository_policy" {
  description = "Repository policy JSON document"
  type        = string
  default     = null
}

variable "cross_account_read_access" {
  description = "List of account IDs for cross-account read access"
  type        = list(string)
  default     = []
}

variable "cross_account_full_access" {
  description = "List of account IDs for cross-account full access"
  type        = list(string)
  default     = []
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
  account_id = data.aws_caller_identity.current.account_id
  partition  = data.aws_partition.current.partition

  # Default lifecycle policy
  default_lifecycle_policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last ${var.max_image_count} images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = var.max_image_count
        }
        action = {
          type = "expire"
        }
      }
    ]
  })

  # Build repository policy for cross-account access
  cross_account_policy = length(var.cross_account_read_access) > 0 || length(var.cross_account_full_access) > 0 ? jsonencode({
    Version = "2012-10-17"
    Statement = concat(
      length(var.cross_account_read_access) > 0 ? [{
        Sid    = "CrossAccountReadAccess"
        Effect = "Allow"
        Principal = {
          AWS = [for account in var.cross_account_read_access : "arn:${local.partition}:iam::${account}:root"]
        }
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability",
          "ecr:DescribeRepositories",
          "ecr:DescribeImages",
          "ecr:ListImages"
        ]
      }] : [],
      length(var.cross_account_full_access) > 0 ? [{
        Sid    = "CrossAccountFullAccess"
        Effect = "Allow"
        Principal = {
          AWS = [for account in var.cross_account_full_access : "arn:${local.partition}:iam::${account}:root"]
        }
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:DescribeRepositories",
          "ecr:DescribeImages",
          "ecr:ListImages"
        ]
      }] : []
    )
  }) : null
}

# -----------------------------------------------------------------------------
# ECR Repository
# -----------------------------------------------------------------------------

resource "aws_ecr_repository" "this" {
  name                 = var.name
  image_tag_mutability = var.image_tag_mutability
  force_delete         = var.force_delete

  image_scanning_configuration {
    scan_on_push = var.scan_on_push
  }

  encryption_configuration {
    encryption_type = var.encryption_type
    kms_key         = var.encryption_type == "KMS" ? var.kms_key_arn : null
  }

  tags = merge(var.tags, {
    Name = var.name
  })
}

# -----------------------------------------------------------------------------
# Lifecycle Policy
# -----------------------------------------------------------------------------

resource "aws_ecr_lifecycle_policy" "this" {
  repository = aws_ecr_repository.this.name
  policy     = var.lifecycle_policy != null ? var.lifecycle_policy : local.default_lifecycle_policy
}

# -----------------------------------------------------------------------------
# Repository Policy
# -----------------------------------------------------------------------------

resource "aws_ecr_repository_policy" "this" {
  count = var.repository_policy != null || local.cross_account_policy != null ? 1 : 0

  repository = aws_ecr_repository.this.name
  policy     = var.repository_policy != null ? var.repository_policy : local.cross_account_policy
}

# -----------------------------------------------------------------------------
# Outputs
# -----------------------------------------------------------------------------

output "repository_arn" {
  description = "ARN of the ECR repository"
  value       = aws_ecr_repository.this.arn
}

output "repository_url" {
  description = "URL of the ECR repository"
  value       = aws_ecr_repository.this.repository_url
}

output "repository_name" {
  description = "Name of the ECR repository"
  value       = aws_ecr_repository.this.name
}

output "registry_id" {
  description = "Registry ID (account ID)"
  value       = aws_ecr_repository.this.registry_id
}
