mock_provider "aws" {}

variables {
  project_name = "My_Project"
  environment  = "dev"
}

run "defaults" {
  command = plan

  assert {
    condition     = aws_s3_bucket.main.force_destroy == false && aws_s3_bucket.main.tags["Name"] == "my-project-dev-data"
    error_message = "The bucket must be protected from forced deletion and named after the prefix and suffix."
  }

  assert {
    condition     = aws_s3_bucket_versioning.main.versioning_configuration[0].status == "Enabled"
    error_message = "Versioning must be enabled by default."
  }

  assert {
    condition     = one(aws_s3_bucket_server_side_encryption_configuration.main.rule).apply_server_side_encryption_by_default[0].sse_algorithm == "AES256"
    error_message = "Without a KMS key the bucket must fall back to SSE-S3."
  }

  assert {
    condition = alltrue([
      aws_s3_bucket_public_access_block.main.block_public_acls,
      aws_s3_bucket_public_access_block.main.block_public_policy,
      aws_s3_bucket_public_access_block.main.ignore_public_acls,
      aws_s3_bucket_public_access_block.main.restrict_public_buckets,
    ])
    error_message = "All public access must be blocked."
  }

  assert {
    condition     = length(aws_s3_bucket_lifecycle_configuration.main) == 1 && aws_s3_bucket_lifecycle_configuration.main[0].rule[0].id == "archive-old-objects"
    error_message = "The default lifecycle rule must be applied."
  }

  assert {
    condition     = length(aws_s3_bucket_logging.main) == 0 && length(aws_s3_bucket_cors_configuration.main) == 0
    error_message = "Access logging and CORS are opt-in."
  }

  assert {
    condition     = length(aws_efs_file_system.main) == 0 && length(aws_security_group.efs) == 0 && output.efs_id == null
    error_message = "EFS is opt-in."
  }
}

run "kms_logging_cors" {
  command = plan

  variables {
    kms_key_arn           = "arn:aws:kms:eu-west-2:123456789012:key/11111111-2222-3333-4444-555555555555"
    bucket_suffix         = "assets"
    enable_versioning     = false
    access_logging_bucket = "central-access-logs"
    lifecycle_rules       = []
    cors_rules = [{
      allowed_methods = ["GET"]
      allowed_origins = ["https://app.example.com"]
    }]
  }

  assert {
    condition     = one(aws_s3_bucket_server_side_encryption_configuration.main.rule).apply_server_side_encryption_by_default[0].sse_algorithm == "aws:kms"
    error_message = "A supplied KMS key must switch the bucket to SSE-KMS."
  }

  assert {
    condition     = one(aws_s3_bucket_server_side_encryption_configuration.main.rule).apply_server_side_encryption_by_default[0].kms_master_key_id == var.kms_key_arn
    error_message = "The supplied KMS key must be used."
  }

  assert {
    condition     = aws_s3_bucket_versioning.main.versioning_configuration[0].status == "Suspended"
    error_message = "enable_versioning = false must suspend versioning."
  }

  assert {
    condition     = aws_s3_bucket_logging.main[0].target_bucket == "central-access-logs" && aws_s3_bucket_logging.main[0].target_prefix == "my-project-dev-assets/"
    error_message = "Access logs must go to the given bucket under the bucket's own prefix."
  }

  assert {
    condition     = length(aws_s3_bucket_lifecycle_configuration.main) == 0
    error_message = "An empty rule list must not create a lifecycle configuration."
  }

  assert {
    condition     = one(aws_s3_bucket_cors_configuration.main[0].cors_rule).max_age_seconds == 3600
    error_message = "CORS rules must be applied with their defaults."
  }
}

run "efs" {
  command = plan

  variables {
    enable_efs                  = true
    vpc_id                      = "vpc-0123456789abcdef0"
    efs_subnet_ids              = ["subnet-0123456789abcdef0", "subnet-0123456789abcdef1"]
    efs_allowed_security_groups = ["sg-0123456789abcdef0"]
    efs_throughput_mode         = "elastic"
    efs_enable_backup           = false
  }

  assert {
    condition     = aws_efs_file_system.main[0].encrypted == true && aws_efs_file_system.main[0].throughput_mode == "elastic"
    error_message = "The file system must be encrypted and use the requested throughput mode."
  }

  assert {
    condition     = aws_efs_file_system.main[0].lifecycle_policy[0].transition_to_ia == "AFTER_30_DAYS"
    error_message = "The default Infrequent Access transition must be applied."
  }

  assert {
    condition     = length(aws_efs_mount_target.main) == 2 && aws_efs_mount_target.main[1].subnet_id == "subnet-0123456789abcdef1"
    error_message = "One mount target per subnet is expected."
  }

  assert {
    condition     = length(aws_vpc_security_group_ingress_rule.efs_nfs) == 1 && aws_vpc_security_group_ingress_rule.efs_nfs[0].from_port == 2049 && aws_vpc_security_group_ingress_rule.efs_nfs[0].referenced_security_group_id == "sg-0123456789abcdef0"
    error_message = "NFS must only be allowed from the given security groups."
  }

  assert {
    condition     = length(aws_efs_backup_policy.main) == 0
    error_message = "efs_enable_backup = false must not create a backup policy."
  }
}

run "efs_provisioned" {
  command = plan

  variables {
    enable_efs                       = true
    vpc_id                           = "vpc-0123456789abcdef0"
    efs_subnet_ids                   = ["subnet-0123456789abcdef0"]
    efs_throughput_mode              = "provisioned"
    efs_provisioned_throughput_mibps = 16
    efs_lifecycle_policy             = null
  }

  assert {
    condition     = aws_efs_file_system.main[0].provisioned_throughput_in_mibps == 16
    error_message = "Provisioned throughput must be applied."
  }

  assert {
    condition     = length(aws_efs_file_system.main[0].lifecycle_policy) == 0
    error_message = "A null lifecycle policy must not create a transition."
  }

  assert {
    condition     = aws_efs_backup_policy.main[0].backup_policy[0].status == "ENABLED"
    error_message = "Backups must be enabled by default."
  }
}

run "efs_requires_network" {
  command = plan

  variables {
    enable_efs = true
  }

  expect_failures = [var.enable_efs]
}

run "provisioned_requires_throughput" {
  command = plan

  variables {
    efs_throughput_mode = "provisioned"
  }

  expect_failures = [var.efs_provisioned_throughput_mibps]
}

run "rejects_invalid_bucket_suffix" {
  command = plan

  variables {
    bucket_suffix = "Not_Valid"
  }

  expect_failures = [var.bucket_suffix]
}
