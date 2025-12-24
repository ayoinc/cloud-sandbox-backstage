# =============================================================================
# AWS S3 Module - Outputs
# =============================================================================
# Output values from the S3 module for use by other modules or resources.
# =============================================================================

# -----------------------------------------------------------------------------
# Bucket Outputs
# -----------------------------------------------------------------------------
output "bucket_id" {
  description = "The name of the bucket"
  value       = aws_s3_bucket.this.id
}

output "bucket_arn" {
  description = "The ARN of the bucket"
  value       = aws_s3_bucket.this.arn
}

output "bucket_domain_name" {
  description = "The bucket domain name"
  value       = aws_s3_bucket.this.bucket_domain_name
}

output "bucket_regional_domain_name" {
  description = "The bucket region-specific domain name"
  value       = aws_s3_bucket.this.bucket_regional_domain_name
}

output "bucket_region" {
  description = "The AWS region this bucket resides in"
  value       = aws_s3_bucket.this.region
}

output "bucket_hosted_zone_id" {
  description = "The Route 53 Hosted Zone ID for this bucket's region"
  value       = aws_s3_bucket.this.hosted_zone_id
}

# -----------------------------------------------------------------------------
# Configuration Outputs
# -----------------------------------------------------------------------------
output "versioning_enabled" {
  description = "Whether versioning is enabled"
  value       = var.versioning_enabled
}

output "encryption_type" {
  description = "The encryption type used"
  value       = var.encryption_type
}

output "lifecycle_enabled" {
  description = "Whether lifecycle rules are enabled"
  value       = var.lifecycle_enabled
}

# -----------------------------------------------------------------------------
# Access Configuration
# -----------------------------------------------------------------------------
output "public_access_block" {
  description = "Public access block configuration"
  value = {
    block_public_acls       = aws_s3_bucket_public_access_block.this.block_public_acls
    block_public_policy     = aws_s3_bucket_public_access_block.this.block_public_policy
    ignore_public_acls      = aws_s3_bucket_public_access_block.this.ignore_public_acls
    restrict_public_buckets = aws_s3_bucket_public_access_block.this.restrict_public_buckets
  }
}

# -----------------------------------------------------------------------------
# Website Configuration (if enabled)
# -----------------------------------------------------------------------------
output "bucket_website_endpoint" {
  description = "The website endpoint, if the bucket is configured with a website"
  value       = try(aws_s3_bucket.this.website_endpoint, null)
}

output "bucket_website_domain" {
  description = "The domain of the website endpoint, if configured"
  value       = try(aws_s3_bucket.this.website_domain, null)
}
