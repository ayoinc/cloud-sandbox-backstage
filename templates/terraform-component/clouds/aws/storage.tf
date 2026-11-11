# -----------------------------------------------------------------------------
# Object storage: S3 bucket, with a replica in the secondary region when set
# -----------------------------------------------------------------------------

variable "secondary_region" {
  description = "AWS region that receives a replica of the bucket. Null disables replication."
  type        = string
  default     = null
}

locals {
  storage_replication_enabled = var.secondary_region != null
}

# Region of the replica. Falls back to the primary region so that the
# provider is valid when no secondary region is set.
provider "aws" {
  alias  = "secondary"
  region = coalesce(var.secondary_region, var.region)

  default_tags {
    tags = module.tagging.tags
  }
}

resource "aws_kms_key" "storage" {
  description             = "Encrypts the ${var.component_name} bucket"
  enable_key_rotation     = true
  deletion_window_in_days = 7
}

resource "aws_s3_bucket" "this" {
  bucket = module.naming.global["s3"]
}

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    bucket_key_enabled = true

    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.storage.arn
    }
  }
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "this" {
  bucket = aws_s3_bucket.this.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "DenyInsecureTransport"
      Effect    = "Deny"
      Principal = "*"
      Action    = "s3:*"
      Resource  = [aws_s3_bucket.this.arn, "${aws_s3_bucket.this.arn}/*"]
      Condition = { Bool = { "aws:SecureTransport" = "false" } }
    }]
  })

  depends_on = [aws_s3_bucket_public_access_block.this]
}

# Disaster-recovery replica in the secondary region.
resource "aws_kms_key" "storage_replica" {
  count    = local.storage_replication_enabled ? 1 : 0
  provider = aws.secondary

  description             = "Encrypts the replica of the ${var.component_name} bucket"
  enable_key_rotation     = true
  deletion_window_in_days = 7
}

resource "aws_s3_bucket" "replica" {
  count    = local.storage_replication_enabled ? 1 : 0
  provider = aws.secondary

  bucket = module.naming.global["s3dr"]
}

resource "aws_s3_bucket_versioning" "replica" {
  count    = local.storage_replication_enabled ? 1 : 0
  provider = aws.secondary

  bucket = aws_s3_bucket.replica[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "replica" {
  count    = local.storage_replication_enabled ? 1 : 0
  provider = aws.secondary

  bucket = aws_s3_bucket.replica[0].id

  rule {
    bucket_key_enabled = true

    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.storage_replica[0].arn
    }
  }
}

resource "aws_s3_bucket_public_access_block" "replica" {
  count    = local.storage_replication_enabled ? 1 : 0
  provider = aws.secondary

  bucket = aws_s3_bucket.replica[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_iam_role" "storage_replication" {
  count = local.storage_replication_enabled ? 1 : 0

  name = module.naming.standard["s3rep"]

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = "s3.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "storage_replication" {
  count = local.storage_replication_enabled ? 1 : 0

  name = "replicate"
  role = aws_iam_role.storage_replication[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:GetReplicationConfiguration", "s3:ListBucket"]
        Resource = aws_s3_bucket.this.arn
      },
      {
        Effect   = "Allow"
        Action   = ["s3:GetObjectVersionForReplication", "s3:GetObjectVersionAcl", "s3:GetObjectVersionTagging"]
        Resource = "${aws_s3_bucket.this.arn}/*"
      },
      {
        Effect   = "Allow"
        Action   = ["s3:ReplicateObject", "s3:ReplicateDelete", "s3:ReplicateTags"]
        Resource = "${aws_s3_bucket.replica[0].arn}/*"
      },
      {
        Effect   = "Allow"
        Action   = "kms:Decrypt"
        Resource = aws_kms_key.storage.arn
      },
      {
        Effect   = "Allow"
        Action   = "kms:Encrypt"
        Resource = aws_kms_key.storage_replica[0].arn
      },
    ]
  })
}

resource "aws_s3_bucket_replication_configuration" "this" {
  count = local.storage_replication_enabled ? 1 : 0

  bucket = aws_s3_bucket.this.id
  role   = aws_iam_role.storage_replication[0].arn

  rule {
    id     = "disaster-recovery"
    status = "Enabled"

    filter {}

    delete_marker_replication {
      status = "Enabled"
    }

    source_selection_criteria {
      sse_kms_encrypted_objects {
        status = "Enabled"
      }
    }

    destination {
      bucket = aws_s3_bucket.replica[0].arn

      encryption_configuration {
        replica_kms_key_id = aws_kms_key.storage_replica[0].arn
      }
    }
  }

  # Replication needs versioning on both buckets.
  depends_on = [
    aws_s3_bucket_versioning.this,
    aws_s3_bucket_versioning.replica,
  ]
}

output "storage_bucket_name" {
  description = "Name of the S3 bucket."
  value       = aws_s3_bucket.this.bucket
}

output "storage_bucket_arn" {
  description = "ARN of the S3 bucket."
  value       = aws_s3_bucket.this.arn
}

output "storage_replica_bucket_name" {
  description = "Name of the replica bucket in the secondary region. Null without a secondary region."
  value       = one(aws_s3_bucket.replica[*].bucket)
}
