# -----------------------------------------------------------------------------
# AWS Storage Module - Main Resources
# -----------------------------------------------------------------------------

locals {
  # Lowercase, hyphen-separated and short enough for every AWS name limit.
  project     = trimsuffix(substr(replace(lower(var.project_name), "/[^a-z0-9]+/", "-"), 0, 23), "-")
  name_prefix = "${local.project}-${var.environment}"
}

# S3 Bucket
resource "random_id" "bucket" {
  byte_length = 4
}

resource "aws_s3_bucket" "main" {
  bucket        = "${local.name_prefix}-${var.bucket_suffix}-${random_id.bucket.hex}"
  force_destroy = var.force_destroy

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-${var.bucket_suffix}"
  })
}

# Bucket Versioning
resource "aws_s3_bucket_versioning" "main" {
  bucket = aws_s3_bucket.main.id

  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Suspended"
  }
}

# Bucket Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "main" {
  bucket = aws_s3_bucket.main.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.kms_key_arn != null ? "aws:kms" : "AES256"
      kms_master_key_id = var.kms_key_arn
    }
    bucket_key_enabled = var.kms_key_arn != null
  }
}

# Block Public Access
resource "aws_s3_bucket_public_access_block" "main" {
  bucket = aws_s3_bucket.main.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Objects are owned by the bucket owner and ACLs are disabled.
resource "aws_s3_bucket_ownership_controls" "main" {
  bucket = aws_s3_bucket.main.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

# Requests that do not use TLS are rejected.
resource "aws_s3_bucket_policy" "tls_only" {
  bucket = aws_s3_bucket.main.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "DenyInsecureTransport"
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
    }]
  })

  depends_on = [aws_s3_bucket_public_access_block.main]
}

# Lifecycle Rules
resource "aws_s3_bucket_lifecycle_configuration" "main" {
  count  = length(var.lifecycle_rules) > 0 ? 1 : 0
  bucket = aws_s3_bucket.main.id

  dynamic "rule" {
    for_each = var.lifecycle_rules
    content {
      id     = rule.value.id
      status = rule.value.enabled ? "Enabled" : "Disabled"

      filter {
        prefix = rule.value.prefix
      }

      abort_incomplete_multipart_upload {
        days_after_initiation = 7
      }

      dynamic "transition" {
        for_each = rule.value.transitions
        content {
          days          = transition.value.days
          storage_class = transition.value.storage_class
        }
      }

      dynamic "expiration" {
        for_each = rule.value.expiration_days != null ? [rule.value.expiration_days] : []
        content {
          days = expiration.value
        }
      }

      dynamic "noncurrent_version_transition" {
        for_each = rule.value.noncurrent_transitions
        content {
          noncurrent_days = noncurrent_version_transition.value.days
          storage_class   = noncurrent_version_transition.value.storage_class
        }
      }

      dynamic "noncurrent_version_expiration" {
        for_each = rule.value.noncurrent_expiration_days != null ? [rule.value.noncurrent_expiration_days] : []
        content {
          noncurrent_days = noncurrent_version_expiration.value
        }
      }
    }
  }

  # Noncurrent-version actions need the versioning state to be set first.
  depends_on = [aws_s3_bucket_versioning.main]
}

# Bucket Logging
resource "aws_s3_bucket_logging" "main" {
  count  = var.access_logging_bucket != null ? 1 : 0
  bucket = aws_s3_bucket.main.id

  target_bucket = var.access_logging_bucket
  target_prefix = "${local.name_prefix}-${var.bucket_suffix}/"
}

# CORS Configuration
resource "aws_s3_bucket_cors_configuration" "main" {
  count  = length(var.cors_rules) > 0 ? 1 : 0
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
# EFS File System
# -----------------------------------------------------------------------------

resource "aws_efs_file_system" "main" {
  count = var.enable_efs ? 1 : 0

  creation_token                  = "${local.name_prefix}-efs"
  encrypted                       = true
  kms_key_id                      = var.kms_key_arn
  performance_mode                = var.efs_performance_mode
  throughput_mode                 = var.efs_throughput_mode
  provisioned_throughput_in_mibps = var.efs_throughput_mode == "provisioned" ? var.efs_provisioned_throughput_mibps : null

  dynamic "lifecycle_policy" {
    for_each = var.efs_lifecycle_policy != null ? [var.efs_lifecycle_policy] : []
    content {
      transition_to_ia = lifecycle_policy.value
    }
  }

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-efs"
  })
}

# Clients must mount over TLS.
resource "aws_efs_file_system_policy" "tls_only" {
  count = var.enable_efs ? 1 : 0

  file_system_id = aws_efs_file_system.main[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "DenyInsecureTransport"
      Effect    = "Deny"
      Principal = { AWS = "*" }
      Action    = "*"
      Resource  = aws_efs_file_system.main[0].arn
      Condition = {
        Bool = {
          "aws:SecureTransport" = "false"
        }
      }
    }]
  })
}

resource "aws_security_group" "efs" {
  count = var.enable_efs ? 1 : 0

  name_prefix = "${local.name_prefix}-efs-"
  description = "Security group for EFS mount targets"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-efs-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "efs_nfs" {
  count = var.enable_efs ? length(var.efs_allowed_security_groups) : 0

  security_group_id            = aws_security_group.efs[0].id
  description                  = "NFS from an allowed security group"
  ip_protocol                  = "tcp"
  from_port                    = 2049
  to_port                      = 2049
  referenced_security_group_id = var.efs_allowed_security_groups[count.index]

  tags = var.tags
}

resource "aws_efs_mount_target" "main" {
  count = var.enable_efs ? length(var.efs_subnet_ids) : 0

  file_system_id  = aws_efs_file_system.main[0].id
  subnet_id       = var.efs_subnet_ids[count.index]
  security_groups = [aws_security_group.efs[0].id]
}

# EFS Access Point
resource "aws_efs_access_point" "main" {
  count = var.enable_efs ? 1 : 0

  file_system_id = aws_efs_file_system.main[0].id

  posix_user {
    gid = 1000
    uid = 1000
  }

  root_directory {
    path = "/app"
    creation_info {
      owner_gid   = 1000
      owner_uid   = 1000
      permissions = "755"
    }
  }

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-efs-ap"
  })
}

# EFS Backup Policy
resource "aws_efs_backup_policy" "main" {
  count = var.enable_efs && var.efs_enable_backup ? 1 : 0

  file_system_id = aws_efs_file_system.main[0].id

  backup_policy {
    status = "ENABLED"
  }
}
