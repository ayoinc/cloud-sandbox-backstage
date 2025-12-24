# =============================================================================
# AWS CloudFront - Root Variables
# =============================================================================
# Input variables for the root module. Values are provided via tfvars files
# in the environments/ directory.
# =============================================================================

# -----------------------------------------------------------------------------
# Project Configuration
# -----------------------------------------------------------------------------
variable "name" {
  description = "Name identifier for the CloudFront distribution"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "region" {
  description = "AWS Region for the origin S3 bucket"
  type        = string
  default     = "us-east-1"
}

variable "org_prefix" {
  description = "Organization prefix for naming"
  type        = string
  default     = "myorg"
}

# -----------------------------------------------------------------------------
# Origin Configuration
# -----------------------------------------------------------------------------
variable "origin_domain_name" {
  description = "Domain name of the S3 bucket or custom origin"
  type        = string
}

variable "origin_path" {
  description = "Path that CloudFront uses to request content from the origin"
  type        = string
  default     = ""
}

variable "origin_custom_headers" {
  description = "Custom headers to include in origin requests"
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

# -----------------------------------------------------------------------------
# Distribution Configuration
# -----------------------------------------------------------------------------
variable "enabled" {
  description = "Whether the distribution is enabled"
  type        = bool
  default     = true
}

variable "ipv6_enabled" {
  description = "Whether IPv6 is enabled for the distribution"
  type        = bool
  default     = true
}

variable "comment" {
  description = "Comment for the distribution"
  type        = string
  default     = ""
}

variable "default_root_object" {
  description = "Object that CloudFront returns when end user requests the root URL"
  type        = string
  default     = "index.html"
}

variable "price_class" {
  description = "Price class for the distribution"
  type        = string
  default     = "PriceClass_100"
}

variable "web_acl_id" {
  description = "AWS WAF web ACL ID to associate with the distribution"
  type        = string
  default     = null
}

variable "wait_for_deployment" {
  description = "Wait for the distribution to be deployed before returning"
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------
# Cache Behavior Configuration
# -----------------------------------------------------------------------------
variable "allowed_methods" {
  description = "HTTP methods CloudFront allows"
  type        = list(string)
  default     = ["GET", "HEAD", "OPTIONS"]
}

variable "cached_methods" {
  description = "HTTP methods CloudFront caches responses for"
  type        = list(string)
  default     = ["GET", "HEAD"]
}

variable "viewer_protocol_policy" {
  description = "Protocol policy for viewers"
  type        = string
  default     = "redirect-to-https"
}

variable "min_ttl" {
  description = "Minimum TTL for cached objects in seconds"
  type        = number
  default     = 0
}

variable "default_ttl" {
  description = "Default TTL for cached objects in seconds"
  type        = number
  default     = 86400
}

variable "max_ttl" {
  description = "Maximum TTL for cached objects in seconds"
  type        = number
  default     = 31536000
}

variable "enable_compression" {
  description = "Whether CloudFront compresses content automatically"
  type        = bool
  default     = true
}

variable "forward_query_string" {
  description = "Whether to forward query strings to the origin"
  type        = bool
  default     = false
}

variable "forward_headers" {
  description = "Headers to forward to the origin"
  type        = list(string)
  default     = []
}

variable "forward_cookies" {
  description = "Cookie forwarding mode (none, whitelist, all)"
  type        = string
  default     = "none"
}

variable "whitelisted_cookie_names" {
  description = "Cookie names to forward when forward_cookies is whitelist"
  type        = list(string)
  default     = []
}

# -----------------------------------------------------------------------------
# Edge Function Configuration
# -----------------------------------------------------------------------------
variable "function_associations" {
  description = "CloudFront function associations"
  type = list(object({
    event_type   = string
    function_arn = string
  }))
  default = []
}

variable "lambda_function_associations" {
  description = "Lambda@Edge function associations"
  type = list(object({
    event_type   = string
    lambda_arn   = string
    include_body = optional(bool, false)
  }))
  default = []
}

# -----------------------------------------------------------------------------
# Custom Error Responses
# -----------------------------------------------------------------------------
variable "custom_error_responses" {
  description = "Custom error response configurations"
  type = list(object({
    error_code            = number
    response_code         = optional(number)
    response_page_path    = optional(string)
    error_caching_min_ttl = optional(number)
  }))
  default = []
}

# -----------------------------------------------------------------------------
# Geo Restrictions
# -----------------------------------------------------------------------------
variable "geo_restriction_type" {
  description = "Geo restriction type (none, whitelist, blacklist)"
  type        = string
  default     = "none"
}

variable "geo_restriction_locations" {
  description = "List of country codes for geo restriction"
  type        = list(string)
  default     = []
}

# -----------------------------------------------------------------------------
# Custom Domain & SSL Configuration
# -----------------------------------------------------------------------------
variable "custom_domain" {
  description = "Custom domain name (CNAME) for the distribution"
  type        = string
  default     = ""
}

variable "acm_certificate_arn" {
  description = "ARN of the ACM certificate for custom domain (must be in us-east-1)"
  type        = string
  default     = ""
}

variable "ssl_support_method" {
  description = "SSL support method (sni-only, vip)"
  type        = string
  default     = "sni-only"
}

variable "minimum_protocol_version" {
  description = "Minimum TLS protocol version"
  type        = string
  default     = "TLSv1.2_2021"
}

# -----------------------------------------------------------------------------
# Logging Configuration
# -----------------------------------------------------------------------------
variable "logging_enabled" {
  description = "Enable access logging"
  type        = bool
  default     = false
}

variable "logging_bucket" {
  description = "S3 bucket for access logs (must include .s3.amazonaws.com suffix)"
  type        = string
  default     = ""
}

variable "logging_prefix" {
  description = "Prefix for log file names"
  type        = string
  default     = ""
}

variable "logging_include_cookies" {
  description = "Include cookies in access logs"
  type        = bool
  default     = false
}

# -----------------------------------------------------------------------------
# Tags
# -----------------------------------------------------------------------------
variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
