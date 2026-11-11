{%- if values.cloud == 'aws' -%}
locals {
  account_id      = data.aws_caller_identity.current.account_id
  partition       = data.aws_partition.current.partition
  log_bucket_name = "${local.prefix}-logs-${local.account_id}"

  # Provider-defined functions build the ARNs that policies need before the
  # resources exist.
  log_bucket_arn = provider::aws::arn_build(local.partition, "s3", "", "", local.log_bucket_name)
  account_root   = provider::aws::arn_build(local.partition, "iam", "", local.account_id, "root")
  flow_log_arns  = provider::aws::arn_build(local.partition, "logs", var.region, local.account_id, "*")
}

resource "aws_kms_key" "logs" {
  description             = "Encrypts the ${local.prefix} log bucket"
  enable_key_rotation     = true
  deletion_window_in_days = 30

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AccountAdministration"
        Effect    = "Allow"
        Principal = { AWS = local.account_root }
        Action    = "kms:*"
        Resource  = "*"
      },
      {
        Sid       = "LogDelivery"
        Effect    = "Allow"
        Principal = { Service = "delivery.logs.amazonaws.com" }
        Action    = ["kms:Encrypt", "kms:Decrypt", "kms:ReEncrypt*", "kms:GenerateDataKey*", "kms:DescribeKey"]
        Resource  = "*"
        Condition = {
          StringEquals = { "aws:SourceAccount" = local.account_id }
        }
      },
    ]
  })
}

resource "aws_kms_alias" "logs" {
  name          = "alias/${local.prefix}-logs"
  target_key_id = aws_kms_key.logs.key_id
}

resource "aws_s3_bucket" "logs" {
  bucket        = local.log_bucket_name
  force_destroy = var.environment != "prod"
}

resource "aws_s3_bucket_ownership_controls" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "logs" {
  bucket = aws_s3_bucket.logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "logs" {
  bucket = aws_s3_bucket.logs.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    bucket_key_enabled = true

    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.logs.arn
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    id     = "expire-logs"
    status = "Enabled"

    filter {}

    expiration {
      days = var.log_retention_days
    }

    noncurrent_version_expiration {
      noncurrent_days = 30
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }

  depends_on = [aws_s3_bucket_versioning.logs]
}

resource "aws_s3_bucket_policy" "logs" {
  bucket = aws_s3_bucket.logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "DenyInsecureTransport"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource  = [local.log_bucket_arn, "${local.log_bucket_arn}/*"]
        Condition = {
          Bool = { "aws:SecureTransport" = "false" }
        }
      },
      {
        Sid       = "AWSLogDeliveryWrite"
        Effect    = "Allow"
        Principal = { Service = "delivery.logs.amazonaws.com" }
        Action    = "s3:PutObject"
        Resource  = "${local.log_bucket_arn}/vpc-flow-logs/AWSLogs/${local.account_id}/*"
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = local.account_id
            "s3:x-amz-acl"      = "bucket-owner-full-control"
          }
          ArnLike = { "aws:SourceArn" = local.flow_log_arns }
        }
      },
      {
        Sid       = "AWSLogDeliveryAclCheck"
        Effect    = "Allow"
        Principal = { Service = "delivery.logs.amazonaws.com" }
        Action    = ["s3:GetBucketAcl", "s3:ListBucket"]
        Resource  = local.log_bucket_arn
        Condition = {
          StringEquals = { "aws:SourceAccount" = local.account_id }
          ArnLike      = { "aws:SourceArn" = local.flow_log_arns }
        }
      },
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.logs]
}
{%- elif values.cloud == 'azure' -%}
locals {
  # Storage account names allow 24 lowercase letters and digits and are unique
  # across Azure, so the name ends in a hash of the subscription and the
  # resource group.
  storage_account_name = join("", [
    "st",
    substr(replace(var.name, "-", ""), 0, 12),
    substr(var.environment, 0, 4),
    substr(sha1("${data.azurerm_client_config.current.subscription_id}/rg-${local.prefix}"), 0, 6),
  ])
}

# Shared keys are disabled: every caller signs in with Entra ID and needs a
# Storage Blob Data role. The firewall admits the private subnet and trusted
# Azure services only.
resource "azurerm_storage_account" "logs" {
  name                = local.storage_account_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  account_kind                      = "StorageV2"
  account_tier                      = "Standard"
  account_replication_type          = var.environment == "prod" ? "GRS" : "LRS"
  min_tls_version                   = "TLS1_2"
  https_traffic_only_enabled        = true
  allow_nested_items_to_be_public   = false
  shared_access_key_enabled         = false
  default_to_oauth_authentication   = true
  infrastructure_encryption_enabled = true

  blob_properties {
    versioning_enabled = true

    delete_retention_policy {
      days = 30
    }

    container_delete_retention_policy {
      days = 30
    }
  }

  network_rules {
    default_action             = "Deny"
    bypass                     = ["AzureServices"]
    virtual_network_subnet_ids = [azurerm_subnet.private.id]
  }

  tags = local.tags
}

resource "azurerm_storage_container" "logs" {
  name                  = "logs"
  storage_account_id    = azurerm_storage_account.logs.id
  container_access_type = "private"
}

resource "azurerm_storage_management_policy" "logs" {
  storage_account_id = azurerm_storage_account.logs.id

  rule {
    name    = "expire-logs"
    enabled = true

    filters {
      blob_types   = ["blockBlob", "appendBlob"]
      prefix_match = ["${azurerm_storage_container.logs.name}/"]
    }

    actions {
      base_blob {
        delete_after_days_since_modification_greater_than = var.log_retention_days
      }

      version {
        delete_after_days_since_creation = 30
      }
    }
  }
}
{%- else -%}
resource "google_kms_key_ring" "main" {
  name     = local.prefix
  location = var.region
}

resource "google_kms_crypto_key" "logs" {
  name            = "logs"
  key_ring        = google_kms_key_ring.main.id
  rotation_period = "7776000s"
}

# Cloud Storage encrypts with the key through its service agent.
resource "google_kms_crypto_key_iam_member" "storage" {
  crypto_key_id = google_kms_crypto_key.logs.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = data.google_storage_project_service_account.current.member
}

resource "google_storage_bucket" "logs" {
  name          = "${var.project_id}-${local.prefix}-logs"
  location      = var.region
  force_destroy = var.environment != "prod"

  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"

  versioning {
    enabled = true
  }

  encryption {
    default_kms_key_name = google_kms_crypto_key.logs.id
  }

  lifecycle_rule {
    condition {
      age = var.log_retention_days
    }

    action {
      type = "Delete"
    }
  }

  lifecycle_rule {
    condition {
      days_since_noncurrent_time = 30
    }

    action {
      type = "Delete"
    }
  }

  depends_on = [google_kms_crypto_key_iam_member.storage]
}
{%- endif %}
