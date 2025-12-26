################################################################################
# AWS S3 Bucket Module
# Creates an S3 bucket with versioning, encryption, logging, and lifecycle rules
################################################################################

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

################################################################################
# Local Variables
################################################################################

locals {
  bucket_name = var.bucket_name

  tags = merge(
    var.tags,
    {
      Module = "s3-bucket"
    }
  )
}

################################################################################
# S3 Bucket
################################################################################

resource "aws_s3_bucket" "this" {
  bucket        = local.bucket_name
  force_destroy = var.force_destroy
  tags          = local.tags
}

################################################################################
# Bucket Versioning
################################################################################

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id
  versioning_configuration {
    status     = var.versioning_enabled ? "Enabled" : "Suspended"
    mfa_delete = var.mfa_delete ? "Enabled" : "Disabled"
  }
}

################################################################################
# Server-Side Encryption
################################################################################

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.kms_key_arn != null ? "aws:kms" : "AES256"
      kms_master_key_id = var.kms_key_arn
    }
    bucket_key_enabled = var.bucket_key_enabled
  }
}

################################################################################
# Public Access Block
################################################################################

resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = var.block_public_acls
  block_public_policy     = var.block_public_policy
  ignore_public_acls      = var.ignore_public_acls
  restrict_public_buckets = var.restrict_public_buckets
}

################################################################################
# Bucket Ownership Controls
################################################################################

resource "aws_s3_bucket_ownership_controls" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    object_ownership = var.object_ownership
  }

  depends_on = [aws_s3_bucket_public_access_block.this]
}

################################################################################
# Bucket ACL
################################################################################

resource "aws_s3_bucket_acl" "this" {
  count  = var.acl != null ? 1 : 0
  bucket = aws_s3_bucket.this.id
  acl    = var.acl

  depends_on = [aws_s3_bucket_ownership_controls.this]
}

################################################################################
# Logging
################################################################################

resource "aws_s3_bucket_logging" "this" {
  count  = var.logging_bucket != null ? 1 : 0
  bucket = aws_s3_bucket.this.id

  target_bucket = var.logging_bucket
  target_prefix = var.logging_prefix
}

################################################################################
# Lifecycle Rules
################################################################################

resource "aws_s3_bucket_lifecycle_configuration" "this" {
  count  = length(var.lifecycle_rules) > 0 ? 1 : 0
  bucket = aws_s3_bucket.this.id

  dynamic "rule" {
    for_each = var.lifecycle_rules
    content {
      id     = rule.value.id
      status = lookup(rule.value, "enabled", true) ? "Enabled" : "Disabled"

      dynamic "filter" {
        for_each = lookup(rule.value, "prefix", null) != null || lookup(rule.value, "tags", null) != null ? [1] : []
        content {
          prefix = lookup(rule.value, "prefix", null)
          dynamic "tag" {
            for_each = lookup(rule.value, "tags", {})
            content {
              key   = tag.key
              value = tag.value
            }
          }
        }
      }

      dynamic "transition" {
        for_each = lookup(rule.value, "transitions", [])
        content {
          days          = lookup(transition.value, "days", null)
          storage_class = transition.value.storage_class
        }
      }

      dynamic "expiration" {
        for_each = lookup(rule.value, "expiration", null) != null ? [rule.value.expiration] : []
        content {
          days                         = lookup(expiration.value, "days", null)
          expired_object_delete_marker = lookup(expiration.value, "expired_object_delete_marker", null)
        }
      }

      dynamic "noncurrent_version_transition" {
        for_each = lookup(rule.value, "noncurrent_version_transitions", [])
        content {
          noncurrent_days = noncurrent_version_transition.value.days
          storage_class   = noncurrent_version_transition.value.storage_class
        }
      }

      dynamic "noncurrent_version_expiration" {
        for_each = lookup(rule.value, "noncurrent_version_expiration", null) != null ? [rule.value.noncurrent_version_expiration] : []
        content {
          noncurrent_days = noncurrent_version_expiration.value.days
        }
      }

      dynamic "abort_incomplete_multipart_upload" {
        for_each = lookup(rule.value, "abort_incomplete_multipart_upload_days", null) != null ? [1] : []
        content {
          days_after_initiation = rule.value.abort_incomplete_multipart_upload_days
        }
      }
    }
  }

  depends_on = [aws_s3_bucket_versioning.this]
}

################################################################################
# CORS Configuration
################################################################################

resource "aws_s3_bucket_cors_configuration" "this" {
  count  = length(var.cors_rules) > 0 ? 1 : 0
  bucket = aws_s3_bucket.this.id

  dynamic "cors_rule" {
    for_each = var.cors_rules
    content {
      allowed_headers = lookup(cors_rule.value, "allowed_headers", ["*"])
      allowed_methods = cors_rule.value.allowed_methods
      allowed_origins = cors_rule.value.allowed_origins
      expose_headers  = lookup(cors_rule.value, "expose_headers", [])
      max_age_seconds = lookup(cors_rule.value, "max_age_seconds", 3600)
    }
  }
}

################################################################################
# Bucket Policy
################################################################################

resource "aws_s3_bucket_policy" "this" {
  count  = var.bucket_policy != null ? 1 : 0
  bucket = aws_s3_bucket.this.id
  policy = var.bucket_policy

  depends_on = [aws_s3_bucket_public_access_block.this]
}

################################################################################
# Replication Configuration
################################################################################

resource "aws_s3_bucket_replication_configuration" "this" {
  count  = var.replication_configuration != null ? 1 : 0
  bucket = aws_s3_bucket.this.id
  role   = var.replication_configuration.role

  dynamic "rule" {
    for_each = var.replication_configuration.rules
    content {
      id       = rule.value.id
      priority = lookup(rule.value, "priority", null)
      status   = lookup(rule.value, "status", "Enabled")

      dynamic "filter" {
        for_each = lookup(rule.value, "filter", null) != null ? [rule.value.filter] : []
        content {
          prefix = lookup(filter.value, "prefix", null)
        }
      }

      destination {
        bucket        = rule.value.destination.bucket
        storage_class = lookup(rule.value.destination, "storage_class", "STANDARD")

        dynamic "encryption_configuration" {
          for_each = lookup(rule.value.destination, "replica_kms_key_id", null) != null ? [1] : []
          content {
            replica_kms_key_id = rule.value.destination.replica_kms_key_id
          }
        }
      }

      dynamic "source_selection_criteria" {
        for_each = lookup(rule.value, "source_selection_criteria", null) != null ? [rule.value.source_selection_criteria] : []
        content {
          dynamic "sse_kms_encrypted_objects" {
            for_each = lookup(source_selection_criteria.value, "sse_kms_encrypted_objects", null) != null ? [1] : []
            content {
              status = source_selection_criteria.value.sse_kms_encrypted_objects.status
            }
          }
        }
      }

      delete_marker_replication {
        status = lookup(rule.value, "delete_marker_replication_status", "Disabled")
      }
    }
  }

  depends_on = [aws_s3_bucket_versioning.this]
}

################################################################################
# Event Notifications
################################################################################

resource "aws_s3_bucket_notification" "this" {
  count  = var.notification_configuration != null ? 1 : 0
  bucket = aws_s3_bucket.this.id

  dynamic "lambda_function" {
    for_each = lookup(var.notification_configuration, "lambda_functions", [])
    content {
      lambda_function_arn = lambda_function.value.lambda_function_arn
      events              = lambda_function.value.events
      filter_prefix       = lookup(lambda_function.value, "filter_prefix", null)
      filter_suffix       = lookup(lambda_function.value, "filter_suffix", null)
    }
  }

  dynamic "queue" {
    for_each = lookup(var.notification_configuration, "queues", [])
    content {
      queue_arn     = queue.value.queue_arn
      events        = queue.value.events
      filter_prefix = lookup(queue.value, "filter_prefix", null)
      filter_suffix = lookup(queue.value, "filter_suffix", null)
    }
  }

  dynamic "topic" {
    for_each = lookup(var.notification_configuration, "topics", [])
    content {
      topic_arn     = topic.value.topic_arn
      events        = topic.value.events
      filter_prefix = lookup(topic.value, "filter_prefix", null)
      filter_suffix = lookup(topic.value, "filter_suffix", null)
    }
  }
}

################################################################################
# Website Configuration
################################################################################

resource "aws_s3_bucket_website_configuration" "this" {
  count  = var.website_configuration != null ? 1 : 0
  bucket = aws_s3_bucket.this.id

  index_document {
    suffix = lookup(var.website_configuration, "index_document", "index.html")
  }

  dynamic "error_document" {
    for_each = lookup(var.website_configuration, "error_document", null) != null ? [1] : []
    content {
      key = var.website_configuration.error_document
    }
  }

  dynamic "routing_rule" {
    for_each = lookup(var.website_configuration, "routing_rules", [])
    content {
      dynamic "condition" {
        for_each = lookup(routing_rule.value, "condition", null) != null ? [routing_rule.value.condition] : []
        content {
          http_error_code_returned_equals = lookup(condition.value, "http_error_code_returned_equals", null)
          key_prefix_equals               = lookup(condition.value, "key_prefix_equals", null)
        }
      }
      redirect {
        host_name               = lookup(routing_rule.value.redirect, "host_name", null)
        http_redirect_code      = lookup(routing_rule.value.redirect, "http_redirect_code", null)
        protocol                = lookup(routing_rule.value.redirect, "protocol", null)
        replace_key_prefix_with = lookup(routing_rule.value.redirect, "replace_key_prefix_with", null)
        replace_key_with        = lookup(routing_rule.value.redirect, "replace_key_with", null)
      }
    }
  }
}
