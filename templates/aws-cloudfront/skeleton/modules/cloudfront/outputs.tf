# =============================================================================
# AWS CloudFront Module - Outputs
# =============================================================================
# Output values from the CloudFront module for use by other modules or resources.
# =============================================================================

# -----------------------------------------------------------------------------
# Distribution Outputs
# -----------------------------------------------------------------------------
output "distribution_id" {
  description = "The ID of the CloudFront distribution"
  value       = aws_cloudfront_distribution.this.id
}

output "distribution_arn" {
  description = "The ARN of the CloudFront distribution"
  value       = aws_cloudfront_distribution.this.arn
}

output "domain_name" {
  description = "The domain name of the CloudFront distribution"
  value       = aws_cloudfront_distribution.this.domain_name
}

output "hosted_zone_id" {
  description = "The CloudFront Route 53 zone ID for alias records"
  value       = aws_cloudfront_distribution.this.hosted_zone_id
}

output "etag" {
  description = "The current version of the distribution's information"
  value       = aws_cloudfront_distribution.this.etag
}

output "status" {
  description = "The current status of the distribution"
  value       = aws_cloudfront_distribution.this.status
}

# -----------------------------------------------------------------------------
# Origin Access Control Outputs
# -----------------------------------------------------------------------------
output "origin_access_control_id" {
  description = "The ID of the Origin Access Control"
  value       = aws_cloudfront_origin_access_control.this.id
}

# -----------------------------------------------------------------------------
# Configuration Outputs
# -----------------------------------------------------------------------------
output "price_class" {
  description = "The price class for the distribution"
  value       = var.price_class
}

output "enabled" {
  description = "Whether the distribution is enabled"
  value       = var.enabled
}

output "custom_domain" {
  description = "Custom domain name if configured"
  value       = var.custom_domain
}

output "viewer_protocol_policy" {
  description = "The viewer protocol policy"
  value       = var.viewer_protocol_policy
}

output "compression_enabled" {
  description = "Whether compression is enabled"
  value       = var.enable_compression
}
