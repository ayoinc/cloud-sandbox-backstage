# =============================================================================
# AWS CloudFront - Development Environment Configuration
# =============================================================================
# Cost-optimized settings for development workloads.
# - Minimum price class for lowest cost
# - Short cache TTLs for faster iteration
# - No custom domain
# - No access logging
# =============================================================================

# -----------------------------------------------------------------------------
# Project Configuration
# -----------------------------------------------------------------------------
name        = "${{ values.name }}"
environment = "dev"
org_prefix  = "myorg"

# -----------------------------------------------------------------------------
# Origin Configuration
# -----------------------------------------------------------------------------
origin_domain_name = "${{ values.origin_domain_name }}"

# -----------------------------------------------------------------------------
# Distribution Configuration
# -----------------------------------------------------------------------------
enabled             = true
comment             = "Development CloudFront distribution for ${{ values.name }}"
default_root_object = "index.html"
price_class         = "PriceClass_100"
ipv6_enabled        = true
wait_for_deployment = false

# -----------------------------------------------------------------------------
# Cache Behavior (short TTLs for development)
# -----------------------------------------------------------------------------
viewer_protocol_policy = "${{ values.viewer_protocol_policy }}"
min_ttl                = 0
default_ttl            = 3600      # 1 hour for dev
max_ttl                = 86400     # 1 day max
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
    error_caching_min_ttl = 60
  },
  {
    error_code            = 404
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = 60
  }
]

# -----------------------------------------------------------------------------
# Geo Restrictions (none for dev)
# -----------------------------------------------------------------------------
geo_restriction_type = "none"

# -----------------------------------------------------------------------------
# Custom Domain (disabled for dev)
# -----------------------------------------------------------------------------
custom_domain       = ""
acm_certificate_arn = ""

# -----------------------------------------------------------------------------
# Logging (disabled for dev)
# -----------------------------------------------------------------------------
logging_enabled = false

# -----------------------------------------------------------------------------
# Tags
# -----------------------------------------------------------------------------
tags = {
  Project     = "${{ values.name }}"
  Environment = "dev"
  Owner       = "${{ values.owner }}"
  CostCenter  = "development"
  ManagedBy   = "terraform"
}
