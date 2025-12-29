variable "project_name" {
  description = "The name of the project"
  type        = string
}

variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "environment" {
  description = "The environment (e.g., dev, staging, prod)"
  type        = string
}

variable "name" {
  description = "The name of the load balancer"
  type        = string
}

variable "enable_https" {
  description = "Enable HTTPS (true) or HTTP (false)"
  type        = bool
  default     = true
}

variable "ssl_certificates" {
  description = "List of SSL certificate self-links to use with HTTPS proxy"
  type        = list(string)
  default     = []
}

variable "managed_ssl_certificate_domains" {
  description = "List of domains for Google-managed SSL certificate"
  type        = list(string)
  default     = []
}

variable "backends" {
  description = "List of backend configurations"
  type = list(object({
    group                 = string
    balancing_mode        = string
    capacity_scaler       = number
    max_rate_per_instance = number
    max_utilization       = number
  }))
}

variable "health_check" {
  description = "Health check configuration"
  type = object({
    check_interval_sec  = number
    timeout_sec         = number
    healthy_threshold   = number
    unhealthy_threshold = number
    port                = number
    request_path        = string
  })
}

variable "enable_cdn" {
  description = "Enable Cloud CDN"
  type        = bool
  default     = false
}

variable "cdn_cache_mode" {
  description = "CDN cache mode"
  type        = string
  default     = "CACHE_ALL_STATIC"

  validation {
    condition     = contains(["USE_ORIGIN_HEADERS", "FORCE_CACHE_ALL", "CACHE_ALL_STATIC"], var.cdn_cache_mode)
    error_message = "cdn_cache_mode must be one of: USE_ORIGIN_HEADERS, FORCE_CACHE_ALL, CACHE_ALL_STATIC"
  }
}

variable "security_policy" {
  description = "Cloud Armor security policy self-link"
  type        = string
  default     = null
}

variable "custom_request_headers" {
  description = "Custom request headers to add to requests"
  type        = list(string)
  default     = []
}

variable "custom_response_headers" {
  description = "Custom response headers to add to responses"
  type        = list(string)
  default     = []
}

variable "connection_draining_timeout_sec" {
  description = "Connection draining timeout in seconds"
  type        = number
  default     = 300
}

variable "log_config_enable" {
  description = "Enable logging for the backend service"
  type        = bool
  default     = true
}

variable "log_config_sample_rate" {
  description = "Sample rate for logging (0.0 to 1.0)"
  type        = number
  default     = 1.0

  validation {
    condition     = var.log_config_sample_rate >= 0.0 && var.log_config_sample_rate <= 1.0
    error_message = "log_config_sample_rate must be between 0.0 and 1.0"
  }
}
