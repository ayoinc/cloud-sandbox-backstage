# -----------------------------------------------------------------------------
# AWS Storage Module - Main Resources
# -----------------------------------------------------------------------------

# S3 Bucket
resource "aws_s3_bucket" "main" {
  bucket        = "${var.project_name}-${var.environment}-${var.bucket_suffix}-${random_id.bucket.hex}"
  force_destroy = var.force_destroy

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-bucket"
  })
}

resource "random_id" "bucket" {
  byte_length = 4
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

      dynamic "transition" {
        for_each = rule.value.transitions
        content {
          days          = transition.value.days
          storage_class = transition.value.storage_class
        }
      }

      dynamic "expiration" {
        for_each = rule.value.expiration_days != null ? [1] : []
        content {
          days = rule.value.expiration_days
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
        for_each = rule.value.noncurrent_expiration_days != null ? [1] : []
        content {
          noncurrent_days = rule.value.noncurrent_expiration_days
        }
      }
    }
  }
}

# Bucket Logging
resource "aws_s3_bucket_logging" "main" {
  count  = var.access_logging_bucket != null ? 1 : 0
  bucket = aws_s3_bucket.main.id

  target_bucket = var.access_logging_bucket
  target_prefix = "${var.project_name}-${var.environment}/"
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

  creation_token   = "${var.project_name}-${var.environment}-efs"
  encrypted        = true
  kms_key_id       = var.kms_key_arn
  performance_mode = var.efs_performance_mode
  throughput_mode  = var.efs_throughput_mode

  dynamic "lifecycle_policy" {
    for_each = var.efs_lifecycle_policy != null ? [1] : []
    content {
      transition_to_ia = var.efs_lifecycle_policy
    }
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-efs"
  })
}

resource "aws_efs_mount_target" "main" {
  count = var.enable_efs ? length(var.efs_subnet_ids) : 0

  file_system_id  = aws_efs_file_system.main[0].id
  subnet_id       = var.efs_subnet_ids[count.index]
  security_groups = [aws_security_group.efs[0].id]
}

resource "aws_security_group" "efs" {
  count = var.enable_efs ? 1 : 0

  name_prefix = "${var.project_name}-${var.environment}-efs-"
  description = "Security group for EFS"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = var.efs_allowed_security_groups
    description     = "NFS from allowed security groups"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-efs-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
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
    Name = "${var.project_name}-${var.environment}-efs-ap"
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
