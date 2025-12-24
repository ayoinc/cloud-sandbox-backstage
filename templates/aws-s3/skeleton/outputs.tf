# =============================================================================
# AWS S3 - Root Outputs
# =============================================================================
# Output values from the S3 module exposed at the root level.
# =============================================================================

# -----------------------------------------------------------------------------
# Bucket Outputs
# -----------------------------------------------------------------------------
output "bucket_id" {
  description = "The name of the bucket"
  value       = module.s3.bucket_id
}

output "bucket_arn" {
  description = "The ARN of the bucket"
  value       = module.s3.bucket_arn
}

output "bucket_domain_name" {
  description = "The bucket domain name"
  value       = module.s3.bucket_domain_name
}

output "bucket_regional_domain_name" {
  description = "The bucket region-specific domain name"
  value       = module.s3.bucket_regional_domain_name
}

output "bucket_region" {
  description = "The AWS region this bucket resides in"
  value       = module.s3.bucket_region
}

output "bucket_hosted_zone_id" {
  description = "The Route 53 Hosted Zone ID for this bucket's region"
  value       = module.s3.bucket_hosted_zone_id
}

# -----------------------------------------------------------------------------
# Configuration Outputs
# -----------------------------------------------------------------------------
output "versioning_enabled" {
  description = "Whether versioning is enabled"
  value       = module.s3.versioning_enabled
}

output "encryption_type" {
  description = "The encryption type used"
  value       = module.s3.encryption_type
}

output "lifecycle_enabled" {
  description = "Whether lifecycle rules are enabled"
  value       = module.s3.lifecycle_enabled
}

# -----------------------------------------------------------------------------
# Access Configuration
# -----------------------------------------------------------------------------
output "public_access_block" {
  description = "Public access block configuration"
  value       = module.s3.public_access_block
}

# -----------------------------------------------------------------------------
# Bucket Information Summary
# -----------------------------------------------------------------------------
output "bucket_info" {
  description = "Summary of bucket configuration"
  value = {
    name               = module.s3.bucket_id
    arn                = module.s3.bucket_arn
    region             = module.s3.bucket_region
    domain_name        = module.s3.bucket_domain_name
    versioning_enabled = module.s3.versioning_enabled
    encryption_type    = module.s3.encryption_type
    lifecycle_enabled  = module.s3.lifecycle_enabled
  }
}
