# -----------------------------------------------------------------------------
# S3 bucket
# -----------------------------------------------------------------------------
resource "aws_s3_bucket" "main" {
  # checkov:skip=CKV_AWS_145: Encryption with the stack key or the S3 managed key is a choice made when the repository is created (s3_bucket_encryption)
  # checkov:skip=CKV_AWS_21: Versioning is a choice made when the repository is created (s3_versioning)
  # checkov:skip=CKV_AWS_18: The stack has no log bucket; add aws_s3_bucket_logging when one exists
  # checkov:skip=CKV_AWS_144: Cross-region replication is not part of this stack; add it where recovery objectives require a second region
  # checkov:skip=CKV2_AWS_62: Event notifications depend on the consumers of the bucket and are configured by them
  count = var.enable_storage ? 1 : 0

  # Bucket names are global, so the account ID keeps this one unique.
  bucket = "${local.name}-data-${local.account_id}"
}

resource "aws_s3_bucket_public_access_block" "main" {
  count = var.enable_storage ? 1 : 0

  bucket                  = aws_s3_bucket.main[0].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "main" {
  count = var.enable_storage ? 1 : 0

  bucket = aws_s3_bucket.main[0].id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_versioning" "main" {
  count = var.enable_storage ? 1 : 0

  bucket = aws_s3_bucket.main[0].id

  versioning_configuration {
    status = var.s3_versioning ? "Enabled" : "Suspended"
  }
}

# Without this resource S3 still encrypts every object with its own managed key.
resource "aws_s3_bucket_server_side_encryption_configuration" "main" {
  count = var.enable_storage && var.s3_bucket_encryption ? 1 : 0

  bucket = aws_s3_bucket.main[0].id

  rule {
    bucket_key_enabled = true

    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.main.arn
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "main" {
  count = var.enable_storage ? 1 : 0

  bucket = aws_s3_bucket.main[0].id

  rule {
    id     = "housekeeping"
    status = "Enabled"

    filter {}

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }

    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }

  depends_on = [aws_s3_bucket_versioning.main]
}

resource "aws_s3_bucket_policy" "main" {
  count = var.enable_storage ? 1 : 0

  bucket = aws_s3_bucket.main[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "DenyInsecureTransport"
      Effect    = "Deny"
      Principal = "*"
      Action    = "s3:*"
      Resource = [
        aws_s3_bucket.main[0].arn,
        "${aws_s3_bucket.main[0].arn}/*"
      ]
      Condition = {
        Bool = { "aws:SecureTransport" = "false" }
      }
    }]
  })

  depends_on = [aws_s3_bucket_public_access_block.main]
}

# -----------------------------------------------------------------------------
# EFS file system (optional)
# -----------------------------------------------------------------------------
resource "aws_efs_file_system" "main" {
  # checkov:skip=CKV2_AWS_18: Daily automatic backups are enabled through aws_efs_backup_policy instead of a separate backup plan
  count = var.enable_storage && var.enable_efs ? 1 : 0

  creation_token = local.name
  encrypted      = true
  kms_key_id     = aws_kms_key.main.arn

  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }

  tags = {
    Name = local.name
  }
}

resource "aws_efs_backup_policy" "main" {
  count = var.enable_storage && var.enable_efs ? 1 : 0

  file_system_id = aws_efs_file_system.main[0].id

  backup_policy {
    status = "ENABLED"
  }
}

resource "aws_security_group" "efs" {
  count = var.enable_storage && var.enable_efs ? 1 : 0

  name        = "${local.name}-efs"
  description = "Mount targets of the ${local.name} file system"
  vpc_id      = local.vpc_id

  tags = {
    Name = "${local.name}-efs"
  }
}

resource "aws_vpc_security_group_ingress_rule" "efs_nfs" {
  count = var.enable_storage && var.enable_efs ? 1 : 0

  security_group_id = aws_security_group.efs[0].id
  description       = "NFS from inside the VPC"
  ip_protocol       = "tcp"
  from_port         = 2049
  to_port           = 2049
  cidr_ipv4         = var.vpc_cidr
}

resource "aws_efs_mount_target" "main" {
  count = var.enable_storage && var.enable_efs ? length(local.private_subnet_ids) : 0

  file_system_id  = aws_efs_file_system.main[0].id
  subnet_id       = local.private_subnet_ids[count.index]
  security_groups = [aws_security_group.efs[0].id]
}
