# =============================================================================
# AWS S3 Infrastructure
# =============================================================================
# Root module that calls the S3 child module.
# Environment-specific values are provided via -var-file.
# =============================================================================

terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# -----------------------------------------------------------------------------
# S3 Module
# -----------------------------------------------------------------------------
module "s3" {
  source = "./modules/s3"

  # Project Configuration
  name        = var.name
  environment = var.environment
  org_prefix  = var.org_prefix

  # Versioning
  versioning_enabled = var.versioning_enabled

  # Encryption
  encryption_type = var.encryption_type
  kms_key_id      = var.kms_key_id

  # Public Access Block
  block_public_acls       = var.block_public_acls
  block_public_policy     = var.block_public_policy
  ignore_public_acls      = var.ignore_public_acls
  restrict_public_buckets = var.restrict_public_buckets

  # Lifecycle Configuration
  lifecycle_enabled                  = var.lifecycle_enabled
  lifecycle_prefix                   = var.lifecycle_prefix
  transition_to_ia_days              = var.transition_to_ia_days
  transition_to_glacier_days         = var.transition_to_glacier_days
  noncurrent_version_transition_days = var.noncurrent_version_transition_days
  noncurrent_version_expiration_days = var.noncurrent_version_expiration_days
  expiration_days                    = var.expiration_days

  # Logging
  logging_enabled = var.logging_enabled
  logging_bucket  = var.logging_bucket
  logging_prefix  = var.logging_prefix

  # CORS
  cors_rules = var.cors_rules

  # Policy
  bucket_policy = var.bucket_policy

  # Object Ownership
  object_ownership = var.object_ownership

  # Tags
  tags = var.tags
}
