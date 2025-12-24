# =============================================================================
# AWS CloudFront - Staging Environment Configuration
# =============================================================================
# Production-like settings for testing.
# - Standard price class
# - Production-like cache TTLs
# - Optional custom domain
# - Access logging optional
# =============================================================================

# -----------------------------------------------------------------------------
# Project Configuration
# -----------------------------------------------------------------------------
name        = "${{ values.name }}"
environment = "staging"
org_prefix  = "myorg"

# -----------------------------------------------------------------------------
# Origin Configuration
# -----------------------------------------------------------------------------
origin_domain_name = "${{ values.origin_domain_name }}"

# -----------------------------------------------------------------------------
# Distribution Configuration
# -----------------------------------------------------------------------------
enabled             = true
comment             = "Staging CloudFront distribution for ${{ values.name }}"
default_root_object = "index.html"
price_class         = "${{ values.price_class }}"
ipv6_enabled        = true
wait_for_deployment = true

# -----------------------------------------------------------------------------
# Cache Behavior (production-like TTLs)
# -----------------------------------------------------------------------------
viewer_protocol_policy = "${{ values.viewer_protocol_policy }}"
min_ttl                = 0
default_ttl            = ${{ values.default_ttl }}
max_ttl                = 31536000  # 1 year
enable_compression     = ${{ values.enable_compression }}
forward_query_string   = false
forward_cookies        = "none"

# -----------------------------------------------------------------------------
# Custom Error Responses (SPA friendly)
# -----------------------------------------------------------------------------
custom_error_responses = [
  {
    error_code            = 403
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = 300
  },
  {
    error_code            = 404
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = 300
  }
]

# -----------------------------------------------------------------------------
# Geo Restrictions (none for staging)
# -----------------------------------------------------------------------------
geo_restriction_type = "none"

# -----------------------------------------------------------------------------
# Custom Domain (optional for staging)
# -----------------------------------------------------------------------------
custom_domain       = ""
acm_certificate_arn = ""

# -----------------------------------------------------------------------------
# Logging (optional for staging)
# -----------------------------------------------------------------------------
logging_enabled = false

# -----------------------------------------------------------------------------
# Tags
# -----------------------------------------------------------------------------
tags = {
  Project     = "${{ values.name }}"
  Environment = "staging"
  Owner       = "${{ values.owner }}"
  CostCenter  = "staging"
  ManagedBy   = "terraform"
}
