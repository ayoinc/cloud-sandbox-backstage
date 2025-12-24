# =============================================================================
# AWS S3 Terraform Tests
# =============================================================================
# These tests validate the S3 bucket configuration using the module structure.
# Tests use root module outputs to validate behavior.
# Run with: terraform test
# =============================================================================

# -----------------------------------------------------------------------------
# Mock Providers - Prevent actual AWS API calls
# -----------------------------------------------------------------------------
mock_provider "aws" {
  alias = "mock"
}

# -----------------------------------------------------------------------------
# Test: Basic S3 Bucket Configuration
# -----------------------------------------------------------------------------
run "basic_bucket_configuration" {
  command = plan

  variables {
    name               = "test-bucket"
    environment        = "development"
    region             = "us-east-1"
    org_prefix         = "myorg"
    versioning_enabled = true
    encryption_type    = "AES256"
    kms_key_id         = null
    lifecycle_enabled  = false
  }

  # Verify S3 bucket is created with correct name via output
  assert {
    condition     = output.bucket_id == "myorg-test-bucket-development"
    error_message = "Bucket name should follow naming convention: {org_prefix}-{name}-{environment}"
  }

  # Verify versioning output
  assert {
    condition     = output.versioning_enabled == true
    error_message = "Versioning should be enabled"
  }

  # Verify encryption type output
  assert {
    condition     = output.encryption_type == "AES256"
    error_message = "Encryption type should be AES256"
  }
}

# -----------------------------------------------------------------------------
# Test: Versioning Enabled
# -----------------------------------------------------------------------------
run "versioning_enabled" {
  command = plan

  variables {
    name               = "versioned-bucket"
    environment        = "staging"
    region             = "us-east-1"
    org_prefix         = "myorg"
    versioning_enabled = true
    encryption_type    = "AES256"
    lifecycle_enabled  = false
  }

  assert {
    condition     = output.versioning_enabled == true
    error_message = "Versioning should be enabled when versioning_enabled is true"
  }
}

run "versioning_disabled" {
  command = plan

  variables {
    name               = "unversioned-bucket"
    environment        = "development"
    region             = "us-east-1"
    org_prefix         = "myorg"
    versioning_enabled = false
    encryption_type    = "AES256"
    lifecycle_enabled  = false
  }

  assert {
    condition     = output.versioning_enabled == false
    error_message = "Versioning should be disabled when versioning_enabled is false"
  }
}

# -----------------------------------------------------------------------------
# Test: AES256 Encryption
# -----------------------------------------------------------------------------
run "aes256_encryption" {
  command = plan

  variables {
    name               = "aes-bucket"
    environment        = "development"
    region             = "us-east-1"
    org_prefix         = "myorg"
    versioning_enabled = true
    encryption_type    = "AES256"
    kms_key_id         = null
    lifecycle_enabled  = false
  }

  assert {
    condition     = output.encryption_type == "AES256"
    error_message = "Encryption type should be AES256"
  }
}

# -----------------------------------------------------------------------------
# Test: KMS Encryption
# -----------------------------------------------------------------------------
run "kms_encryption" {
  command = plan

  variables {
    name               = "kms-bucket"
    environment        = "production"
    region             = "us-east-1"
    org_prefix         = "myorg"
    versioning_enabled = true
    encryption_type    = "aws:kms"
    kms_key_id         = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"
    lifecycle_enabled  = false
  }

  assert {
    condition     = output.encryption_type == "aws:kms"
    error_message = "Encryption type should be aws:kms"
  }
}

# -----------------------------------------------------------------------------
# Test: Public Access Block (All Blocked)
# -----------------------------------------------------------------------------
run "public_access_blocked" {
  command = plan

  variables {
    name                    = "private-bucket"
    environment             = "production"
    region                  = "us-east-1"
    org_prefix              = "myorg"
    versioning_enabled      = true
    encryption_type         = "AES256"
    lifecycle_enabled       = false
    block_public_acls       = true
    block_public_policy     = true
    ignore_public_acls      = true
    restrict_public_buckets = true
  }

  assert {
    condition     = output.public_access_block.block_public_acls == true
    error_message = "block_public_acls should be true"
  }

  assert {
    condition     = output.public_access_block.block_public_policy == true
    error_message = "block_public_policy should be true"
  }

  assert {
    condition     = output.public_access_block.ignore_public_acls == true
    error_message = "ignore_public_acls should be true"
  }

  assert {
    condition     = output.public_access_block.restrict_public_buckets == true
    error_message = "restrict_public_buckets should be true"
  }
}

# -----------------------------------------------------------------------------
# Test: Lifecycle Rules Enabled
# -----------------------------------------------------------------------------
run "lifecycle_enabled" {
  command = plan

  variables {
    name               = "lifecycle-bucket"
    environment        = "production"
    region             = "us-east-1"
    org_prefix         = "myorg"
    versioning_enabled = true
    encryption_type    = "AES256"
    lifecycle_enabled  = true
  }

  assert {
    condition     = output.lifecycle_enabled == true
    error_message = "Lifecycle should be enabled when lifecycle_enabled is true"
  }
}

run "lifecycle_disabled" {
  command = plan

  variables {
    name               = "no-lifecycle-bucket"
    environment        = "development"
    region             = "us-east-1"
    org_prefix         = "myorg"
    versioning_enabled = false
    encryption_type    = "AES256"
    lifecycle_enabled  = false
  }

  assert {
    condition     = output.lifecycle_enabled == false
    error_message = "Lifecycle should be disabled when lifecycle_enabled is false"
  }
}

# -----------------------------------------------------------------------------
# Test: Environment Validation
# -----------------------------------------------------------------------------
run "valid_development_environment" {
  command = plan

  variables {
    name               = "dev-bucket"
    environment        = "development"
    region             = "us-east-1"
    org_prefix         = "myorg"
    versioning_enabled = false
    encryption_type    = "AES256"
    lifecycle_enabled  = false
  }

  assert {
    condition     = can(output.bucket_id)
    error_message = "Development environment should produce valid bucket_id"
  }

  assert {
    condition     = output.bucket_id == "myorg-dev-bucket-development"
    error_message = "Development bucket name should follow convention"
  }
}

run "valid_staging_environment" {
  command = plan

  variables {
    name               = "staging-bucket"
    environment        = "staging"
    region             = "us-east-1"
    org_prefix         = "myorg"
    versioning_enabled = true
    encryption_type    = "AES256"
    lifecycle_enabled  = false
  }

  assert {
    condition     = can(output.bucket_id)
    error_message = "Staging environment should produce valid bucket_id"
  }

  assert {
    condition     = output.bucket_id == "myorg-staging-bucket-staging"
    error_message = "Staging bucket name should follow convention"
  }
}

run "valid_production_environment" {
  command = plan

  variables {
    name               = "prod-bucket"
    environment        = "production"
    region             = "us-east-1"
    org_prefix         = "myorg"
    versioning_enabled = true
    encryption_type    = "aws:kms"
    kms_key_id         = "arn:aws:kms:us-east-1:123456789012:key/test-key"
    lifecycle_enabled  = true
  }

  assert {
    condition     = output.bucket_id == "myorg-prod-bucket-production"
    error_message = "Production bucket name should be correct"
  }
}

# -----------------------------------------------------------------------------
# Test: Encryption Type Validation
# -----------------------------------------------------------------------------
run "valid_aes256_encryption_type" {
  command = plan

  variables {
    name               = "aes-test"
    environment        = "development"
    region             = "us-east-1"
    org_prefix         = "myorg"
    versioning_enabled = false
    encryption_type    = "AES256"
    lifecycle_enabled  = false
  }

  assert {
    condition     = output.encryption_type == "AES256"
    error_message = "AES256 encryption type should be valid"
  }
}

run "valid_kms_encryption_type" {
  command = plan

  variables {
    name               = "kms-test"
    environment        = "production"
    region             = "us-east-1"
    org_prefix         = "myorg"
    versioning_enabled = true
    encryption_type    = "aws:kms"
    kms_key_id         = "arn:aws:kms:us-east-1:123456789012:key/test-key"
    lifecycle_enabled  = false
  }

  assert {
    condition     = output.encryption_type == "aws:kms"
    error_message = "KMS encryption type should be valid"
  }
}

# -----------------------------------------------------------------------------
# Test: Bucket Naming Across Environments
# -----------------------------------------------------------------------------
run "bucket_naming_development" {
  command = plan

  variables {
    name               = "app-data"
    environment        = "development"
    region             = "us-east-1"
    org_prefix         = "acme"
    versioning_enabled = false
    encryption_type    = "AES256"
    lifecycle_enabled  = false
  }

  assert {
    condition     = output.bucket_id == "acme-app-data-development"
    error_message = "Development bucket name should be acme-app-data-development"
  }
}

run "bucket_naming_staging" {
  command = plan

  variables {
    name               = "app-data"
    environment        = "staging"
    region             = "us-east-1"
    org_prefix         = "acme"
    versioning_enabled = true
    encryption_type    = "AES256"
    lifecycle_enabled  = false
  }

  assert {
    condition     = output.bucket_id == "acme-app-data-staging"
    error_message = "Staging bucket name should be acme-app-data-staging"
  }
}

run "bucket_naming_production" {
  command = plan

  variables {
    name               = "app-data"
    environment        = "production"
    region             = "us-east-1"
    org_prefix         = "acme"
    versioning_enabled = true
    encryption_type    = "AES256"
    lifecycle_enabled  = true
  }

  assert {
    condition     = output.bucket_id == "acme-app-data-production"
    error_message = "Production bucket name should be acme-app-data-production"
  }
}

# -----------------------------------------------------------------------------
# Test: Different Regions
# -----------------------------------------------------------------------------
run "us_west_2_region" {
  command = plan

  variables {
    name               = "west-bucket"
    environment        = "development"
    region             = "us-west-2"
    org_prefix         = "myorg"
    versioning_enabled = false
    encryption_type    = "AES256"
    lifecycle_enabled  = false
  }

  assert {
    condition     = can(output.bucket_id)
    error_message = "Bucket should be creatable in us-west-2"
  }
}

run "eu_west_1_region" {
  command = plan

  variables {
    name               = "eu-bucket"
    environment        = "production"
    region             = "eu-west-1"
    org_prefix         = "myorg"
    versioning_enabled = true
    encryption_type    = "AES256"
    lifecycle_enabled  = false
  }

  assert {
    condition     = can(output.bucket_id)
    error_message = "Bucket should be creatable in eu-west-1"
  }
}

# -----------------------------------------------------------------------------
# Test: Production Best Practices
# -----------------------------------------------------------------------------
run "production_best_practices" {
  command = plan

  variables {
    name                    = "prod-data"
    environment             = "production"
    region                  = "us-east-1"
    org_prefix              = "enterprise"
    versioning_enabled      = true
    encryption_type         = "aws:kms"
    kms_key_id              = "arn:aws:kms:us-east-1:123456789012:key/prod-key"
    lifecycle_enabled       = true
    logging_enabled         = true
    logging_bucket          = "enterprise-logs-production"
    block_public_acls       = true
    block_public_policy     = true
    ignore_public_acls      = true
    restrict_public_buckets = true
  }

  # Versioning should be enabled for production
  assert {
    condition     = output.versioning_enabled == true
    error_message = "Production buckets should have versioning enabled"
  }

  # KMS encryption for production
  assert {
    condition     = output.encryption_type == "aws:kms"
    error_message = "Production buckets should use KMS encryption"
  }

  # Lifecycle rules for cost optimization
  assert {
    condition     = output.lifecycle_enabled == true
    error_message = "Production buckets should have lifecycle rules"
  }

  # All public access blocked
  assert {
    condition     = output.public_access_block.block_public_acls == true
    error_message = "Production buckets should block public ACLs"
  }

  # Bucket name follows convention
  assert {
    condition     = output.bucket_id == "enterprise-prod-data-production"
    error_message = "Production bucket should follow naming convention"
  }
}

# -----------------------------------------------------------------------------
# Test: Org Prefix Variations
# -----------------------------------------------------------------------------
run "custom_org_prefix" {
  command = plan

  variables {
    name               = "data-lake"
    environment        = "production"
    region             = "us-east-1"
    org_prefix         = "bigcorp-analytics"
    versioning_enabled = true
    encryption_type    = "AES256"
    lifecycle_enabled  = true
  }

  assert {
    condition     = output.bucket_id == "bigcorp-analytics-data-lake-production"
    error_message = "Bucket name should use custom org prefix"
  }
}

# -----------------------------------------------------------------------------
# Test: Bucket Info Summary Output
# -----------------------------------------------------------------------------
run "bucket_info_summary" {
  command = plan

  variables {
    name               = "summary-test"
    environment        = "staging"
    region             = "us-east-1"
    org_prefix         = "testorg"
    versioning_enabled = true
    encryption_type    = "AES256"
    lifecycle_enabled  = false
  }

  # Verify bucket_info summary output contains expected fields
  assert {
    condition     = output.bucket_info.name == "testorg-summary-test-staging"
    error_message = "Bucket info name should match bucket_id"
  }

  assert {
    condition     = output.bucket_info.versioning_enabled == true
    error_message = "Bucket info should show versioning enabled"
  }

  assert {
    condition     = output.bucket_info.encryption_type == "AES256"
    error_message = "Bucket info should show encryption type"
  }

  assert {
    condition     = output.bucket_info.lifecycle_enabled == false
    error_message = "Bucket info should show lifecycle disabled"
  }
}
