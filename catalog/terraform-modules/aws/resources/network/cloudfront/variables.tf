variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "origin_domain_name" {
  description = "Domain name of the origin (S3 bucket or custom origin)"
  type        = string
}

variable "origin_id" {
  description = "Unique identifier for the origin"
  type        = string
}

variable "origin_type" {
  description = "Type of origin: 's3' or 'custom'"
  type        = string
  default     = "s3"

  validation {
    condition     = contains(["s3", "custom"], var.origin_type)
    error_message = "origin_type must be either 's3' or 'custom'."
  }
}

variable "s3_origin_access_control" {
  description = "Enable Origin Access Control for S3 origins"
  type        = bool
  default     = true
}

variable "default_root_object" {
  description = "Object that CloudFront returns when viewer requests the root URL"
  type        = string
  default     = "index.html"
}

variable "enabled" {
  description = "Whether the distribution is enabled"
  type        = bool
  default     = true
}

variable "is_ipv6_enabled" {
  description = "Whether IPv6 is enabled for the distribution"
  type        = bool
  default     = true
}

variable "price_class" {
  description = "Price class for the distribution (PriceClass_100, PriceClass_200, PriceClass_All)"
  type        = string
  default     = "PriceClass_100"

  validation {
    condition     = contains(["PriceClass_100", "PriceClass_200", "PriceClass_All"], var.price_class)
    error_message = "price_class must be one of: PriceClass_100, PriceClass_200, PriceClass_All."
  }
}

variable "viewer_protocol_policy" {
  description = "Protocol policy for viewers (allow-all, https-only, redirect-to-https)"
  type        = string
  default     = "redirect-to-https"

  validation {
    condition     = contains(["allow-all", "https-only", "redirect-to-https"], var.viewer_protocol_policy)
    error_message = "viewer_protocol_policy must be one of: allow-all, https-only, redirect-to-https."
  }
}

variable "allowed_methods" {
  description = "HTTP methods that CloudFront processes and forwards to the origin"
  type        = list(string)
  default     = ["GET", "HEAD"]
}

variable "cached_methods" {
  description = "HTTP methods for which CloudFront caches responses"
  type        = list(string)
  default     = ["GET", "HEAD"]
}

variable "default_ttl" {
  description = "Default time (in seconds) that objects stay in CloudFront cache"
  type        = number
  default     = 86400
}

variable "max_ttl" {
  description = "Maximum time (in seconds) that objects stay in CloudFront cache"
  type        = number
  default     = 31536000
}

variable "min_ttl" {
  description = "Minimum time (in seconds) that objects stay in CloudFront cache"
  type        = number
  default     = 0
}

variable "compress" {
  description = "Whether CloudFront compresses content automatically"
  type        = bool
  default     = true
}

variable "certificate_arn" {
  description = "ARN of the ACM certificate for HTTPS (must be in us-east-1)"
  type        = string
  default     = null
}

variable "aliases" {
  description = "List of CNAMEs (alternate domain names) for the distribution"
  type        = list(string)
  default     = []
}

variable "web_acl_id" {
  description = "AWS WAF Web ACL ID to associate with the distribution"
  type        = string
  default     = null
}

variable "geo_restriction_type" {
  description = "Type of geo restriction (none, whitelist, blacklist)"
  type        = string
  default     = "none"

  validation {
    condition     = contains(["none", "whitelist", "blacklist"], var.geo_restriction_type)
    error_message = "geo_restriction_type must be one of: none, whitelist, blacklist."
  }
}

variable "geo_restriction_locations" {
  description = "List of ISO 3166-1-alpha-2 country codes for geo restriction"
  type        = list(string)
  default     = []
}

variable "custom_error_responses" {
  description = "List of custom error response configurations"
  type = list(object({
    error_code            = number
    response_code         = optional(number)
    response_page_path    = optional(string)
    error_caching_min_ttl = optional(number)
  }))
  default = []
}

variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}
