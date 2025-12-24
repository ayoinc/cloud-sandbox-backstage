# =============================================================================
# AWS CloudFront - Root Outputs
# =============================================================================
# Output values from the CloudFront module exposed at the root level.
# =============================================================================

# -----------------------------------------------------------------------------
# Distribution Outputs
# -----------------------------------------------------------------------------
output "distribution_id" {
  description = "The ID of the CloudFront distribution"
  value       = module.cloudfront.distribution_id
}

output "distribution_arn" {
  description = "The ARN of the CloudFront distribution"
  value       = module.cloudfront.distribution_arn
}

output "domain_name" {
  description = "The domain name of the CloudFront distribution"
  value       = module.cloudfront.domain_name
}

output "hosted_zone_id" {
  description = "The CloudFront Route 53 zone ID for alias records"
  value       = module.cloudfront.hosted_zone_id
}

output "etag" {
  description = "The current version of the distribution's information"
  value       = module.cloudfront.etag
}

output "status" {
  description = "The current status of the distribution"
  value       = module.cloudfront.status
}

# -----------------------------------------------------------------------------
# Origin Access Control Outputs
# -----------------------------------------------------------------------------
output "origin_access_control_id" {
  description = "The ID of the Origin Access Control"
  value       = module.cloudfront.origin_access_control_id
}

# -----------------------------------------------------------------------------
# Configuration Outputs
# -----------------------------------------------------------------------------
output "price_class" {
  description = "The price class for the distribution"
  value       = module.cloudfront.price_class
}

output "enabled" {
  description = "Whether the distribution is enabled"
  value       = module.cloudfront.enabled
}

output "custom_domain" {
  description = "Custom domain name if configured"
  value       = module.cloudfront.custom_domain
}

output "viewer_protocol_policy" {
  description = "The viewer protocol policy"
  value       = module.cloudfront.viewer_protocol_policy
}

output "compression_enabled" {
  description = "Whether compression is enabled"
  value       = module.cloudfront.compression_enabled
}

# -----------------------------------------------------------------------------
# Distribution Info Summary
# -----------------------------------------------------------------------------
output "distribution_info" {
  description = "Summary of CloudFront distribution configuration"
  value = {
    id                     = module.cloudfront.distribution_id
    arn                    = module.cloudfront.distribution_arn
    domain_name            = module.cloudfront.domain_name
    custom_domain          = module.cloudfront.custom_domain
    price_class            = module.cloudfront.price_class
    enabled                = module.cloudfront.enabled
    compression_enabled    = module.cloudfront.compression_enabled
    viewer_protocol_policy = module.cloudfront.viewer_protocol_policy
  }
}
