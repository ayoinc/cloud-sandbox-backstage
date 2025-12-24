# =============================================================================
# AWS CloudFront - Production Environment Configuration
# =============================================================================
# Full production settings with security and performance.
# - Full price class for global edge locations
# - Optimized cache TTLs
# - Custom domain with SSL
# - Access logging enabled
# =============================================================================

# -----------------------------------------------------------------------------
# Project Configuration
# -----------------------------------------------------------------------------
name        = "${{ values.name }}"
environment = "prod"
org_prefix  = "myorg"

# -----------------------------------------------------------------------------
# Origin Configuration
# -----------------------------------------------------------------------------
origin_domain_name = "${{ values.origin_domain_name }}"

# -----------------------------------------------------------------------------
# Distribution Configuration
# -----------------------------------------------------------------------------
enabled             = true
comment             = "Production CloudFront distribution for ${{ values.name }}"
default_root_object = "index.html"
price_class         = "${{ values.price_class }}"
ipv6_enabled        = true
wait_for_deployment = true

# -----------------------------------------------------------------------------
# Cache Behavior (optimized for production)
# -----------------------------------------------------------------------------
viewer_protocol_policy = "https-only"
min_ttl                = 0
default_ttl            = ${{ values.default_ttl }}
max_ttl                = 31536000  # 1 year
enable_compression     = true
forward_query_string   = false
forward_cookies        = "none"

# -----------------------------------------------------------------------------
# Custom Error Responses (SPA friendly with longer caching)
# -----------------------------------------------------------------------------
custom_error_responses = [
  {
    error_code            = 403
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = 600
  },
  {
    error_code            = 404
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = 600
  }
]

# -----------------------------------------------------------------------------
# Geo Restrictions (none by default, configure as needed)
# -----------------------------------------------------------------------------
geo_restriction_type = "none"

# -----------------------------------------------------------------------------
# Custom Domain (configure for production)
# -----------------------------------------------------------------------------
# Uncomment and configure when custom domain is ready
# custom_domain       = "${{ values.custom_domain }}"
# acm_certificate_arn = "${{ values.acm_certificate_arn }}"
custom_domain       = ""
acm_certificate_arn = ""

# -----------------------------------------------------------------------------
# Logging (enabled for production compliance)
# -----------------------------------------------------------------------------
logging_enabled = false  # Set to true and configure logging_bucket when available
# logging_bucket  = "my-logging-bucket.s3.amazonaws.com"
# logging_prefix  = "cloudfront/${{ values.name }}/"

# -----------------------------------------------------------------------------
# Tags
# -----------------------------------------------------------------------------
tags = {
  Project     = "${{ values.name }}"
  Environment = "prod"
  Owner       = "${{ values.owner }}"
  CostCenter  = "production"
  ManagedBy   = "terraform"
  Compliance  = "required"
}
