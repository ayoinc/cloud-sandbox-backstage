# =============================================================================
# AWS S3 Module
# =============================================================================
# Reusable module for creating an S3 bucket with versioning, encryption,
# lifecycle rules, and access logging.
# =============================================================================

locals {
  bucket_name = "${var.org_prefix}-${var.name}-${var.environment}"
}

# -----------------------------------------------------------------------------
# S3 Bucket
# -----------------------------------------------------------------------------
resource "aws_s3_bucket" "this" {
  bucket = local.bucket_name

  tags = merge(var.tags, {
    Name = local.bucket_name
  })
}

# -----------------------------------------------------------------------------
# Bucket Versioning
# -----------------------------------------------------------------------------
resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id

  versioning_configuration {
    status = var.versioning_enabled ? "Enabled" : "Disabled"
  }
}

# -----------------------------------------------------------------------------
# Server-Side Encryption
# -----------------------------------------------------------------------------
resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.encryption_type
      kms_master_key_id = var.encryption_type == "aws:kms" ? var.kms_key_id : null
    }
    bucket_key_enabled = var.encryption_type == "aws:kms"
  }
}

# -----------------------------------------------------------------------------
# Block Public Access
# -----------------------------------------------------------------------------
resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = var.block_public_acls
  block_public_policy     = var.block_public_policy
  ignore_public_acls      = var.ignore_public_acls
  restrict_public_buckets = var.restrict_public_buckets
}

# -----------------------------------------------------------------------------
# Lifecycle Configuration
# -----------------------------------------------------------------------------
resource "aws_s3_bucket_lifecycle_configuration" "this" {
  count  = var.lifecycle_enabled ? 1 : 0
  bucket = aws_s3_bucket.this.id

  rule {
    id     = "transition-to-glacier"
    status = "Enabled"

    filter {
      prefix = var.lifecycle_prefix
    }

    transition {
      days          = var.transition_to_ia_days
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = var.transition_to_glacier_days
      storage_class = "GLACIER"
    }

    dynamic "noncurrent_version_transition" {
      for_each = var.versioning_enabled ? [1] : []
      content {
        noncurrent_days = var.noncurrent_version_transition_days
        storage_class   = "STANDARD_IA"
      }
    }

    dynamic "noncurrent_version_expiration" {
      for_each = var.versioning_enabled ? [1] : []
      content {
        noncurrent_days = var.noncurrent_version_expiration_days
      }
    }

    dynamic "expiration" {
      for_each = var.expiration_days > 0 ? [1] : []
      content {
        days = var.expiration_days
      }
    }
  }

  depends_on = [aws_s3_bucket_versioning.this]
}

# -----------------------------------------------------------------------------
# Bucket Logging
# -----------------------------------------------------------------------------
resource "aws_s3_bucket_logging" "this" {
  count  = var.logging_enabled ? 1 : 0
  bucket = aws_s3_bucket.this.id

  target_bucket = var.logging_bucket
  target_prefix = var.logging_prefix != null ? var.logging_prefix : "${var.name}/"
}

# -----------------------------------------------------------------------------
# CORS Configuration
# -----------------------------------------------------------------------------
resource "aws_s3_bucket_cors_configuration" "this" {
  count  = length(var.cors_rules) > 0 ? 1 : 0
  bucket = aws_s3_bucket.this.id

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
# Bucket Policy (Optional)
# -----------------------------------------------------------------------------
resource "aws_s3_bucket_policy" "this" {
  count  = var.bucket_policy != null ? 1 : 0
  bucket = aws_s3_bucket.this.id
  policy = var.bucket_policy
}

# -----------------------------------------------------------------------------
# Object Ownership Controls
# -----------------------------------------------------------------------------
resource "aws_s3_bucket_ownership_controls" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    object_ownership = var.object_ownership
  }
}
