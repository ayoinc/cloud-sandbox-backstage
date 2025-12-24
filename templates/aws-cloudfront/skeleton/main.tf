# =============================================================================
# AWS CloudFront Infrastructure
# =============================================================================
# Root module that calls the CloudFront child module.
# Environment-specific values are provided via -var-file.
# =============================================================================

terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# -----------------------------------------------------------------------------
# CloudFront Module
# -----------------------------------------------------------------------------
module "cloudfront" {
  source = "./modules/cloudfront"

  # Project Configuration
  name        = var.name
  environment = var.environment
  org_prefix  = var.org_prefix

  # Origin Configuration
  origin_domain_name    = var.origin_domain_name
  origin_path           = var.origin_path
  origin_custom_headers = var.origin_custom_headers

  # Distribution Configuration
  enabled             = var.enabled
  comment             = var.comment
  default_root_object = var.default_root_object
  price_class         = var.price_class
  ipv6_enabled        = var.ipv6_enabled
  web_acl_id          = var.web_acl_id
  wait_for_deployment = var.wait_for_deployment

  # Cache Behavior
  allowed_methods          = var.allowed_methods
  cached_methods           = var.cached_methods
  viewer_protocol_policy   = var.viewer_protocol_policy
  min_ttl                  = var.min_ttl
  default_ttl              = var.default_ttl
  max_ttl                  = var.max_ttl
  enable_compression       = var.enable_compression
  forward_query_string     = var.forward_query_string
  forward_headers          = var.forward_headers
  forward_cookies          = var.forward_cookies
  whitelisted_cookie_names = var.whitelisted_cookie_names

  # Edge Functions
  function_associations        = var.function_associations
  lambda_function_associations = var.lambda_function_associations

  # Error Responses
  custom_error_responses = var.custom_error_responses

  # Geo Restrictions
  geo_restriction_type      = var.geo_restriction_type
  geo_restriction_locations = var.geo_restriction_locations

  # Custom Domain & SSL
  custom_domain            = var.custom_domain
  acm_certificate_arn      = var.acm_certificate_arn
  ssl_support_method       = var.ssl_support_method
  minimum_protocol_version = var.minimum_protocol_version

  # Logging
  logging_enabled         = var.logging_enabled
  logging_bucket          = var.logging_bucket
  logging_prefix          = var.logging_prefix
  logging_include_cookies = var.logging_include_cookies

  # Tags
  tags = var.tags
}
