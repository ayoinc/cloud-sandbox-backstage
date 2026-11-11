# =============================================================================
# Cloudflare Zone - Variables
# =============================================================================

variable "account_id" {
  description = "ID of the Cloudflare account that owns the zone. Supplied as TF_VAR_account_id."
  type        = string

  validation {
    condition     = can(regex("^[a-f0-9]{32}$", var.account_id))
    error_message = "The account ID is a 32 character hexadecimal string."
  }
}

variable "zone_name" {
  description = "Apex domain of the zone."
  type        = string
}

variable "zone_id" {
  description = "ID of an existing zone to manage. When null the zone is created."
  type        = string
  default     = null
}

variable "description" {
  description = "Purpose of the zone, used in the descriptions of the rulesets."
  type        = string
}

variable "owner" {
  description = "Team that owns the zone, recorded in the comment of every DNS record."
  type        = string
}

# -----------------------------------------------------------------------------
# TLS
# -----------------------------------------------------------------------------

variable "ssl_mode" {
  description = "Encryption mode between Cloudflare and the origin: strict (validated certificate) or full."
  type        = string
  default     = "strict"

  validation {
    condition     = contains(["strict", "full"], var.ssl_mode)
    error_message = "Use strict or full: the flexible and off modes send traffic to the origin unencrypted."
  }
}

variable "min_tls_version" {
  description = "Lowest TLS version visitors may use."
  type        = string
  default     = "1.2"

  validation {
    condition     = contains(["1.2", "1.3"], var.min_tls_version)
    error_message = "TLS 1.0 and 1.1 are deprecated: use 1.2 or 1.3."
  }
}

variable "hsts" {
  description = "HTTP Strict Transport Security. Enable include_subdomains and preload only when every subdomain serves HTTPS."
  type = object({
    enabled            = bool
    max_age            = number
    include_subdomains = bool
    preload            = bool
  })
  default = {
    enabled            = true
    max_age            = 31536000
    include_subdomains = false
    preload            = false
  }
}

variable "security_level" {
  description = "Security level of the zone."
  type        = string
  default     = "medium"

  validation {
    condition     = contains(["essentially_off", "low", "medium", "high", "under_attack"], var.security_level)
    error_message = "The security level must be essentially_off, low, medium, high or under_attack."
  }
}

# -----------------------------------------------------------------------------
# DNS
# -----------------------------------------------------------------------------

variable "enable_dnssec" {
  description = "Sign the zone with DNSSEC. The DS record in the outputs must then be added at the registrar."
  type        = bool
  default     = true
}

variable "caa_issuers" {
  description = "Certificate authorities allowed to issue certificates for the zone. An empty list creates no CAA records."
  type        = list(string)
  default     = ["letsencrypt.org", "pki.goog", "ssl.com"]
}

variable "dns_records" {
  description = "DNS records, keyed by a name of your choice. `name` is the fully qualified record name."
  type = map(object({
    name     = string
    type     = string
    content  = string
    ttl      = optional(number, 300)
    proxied  = optional(bool, false)
    priority = optional(number)
  }))
  default = {}

  validation {
    condition     = alltrue([for record in values(var.dns_records) : contains(["A", "AAAA", "CNAME", "MX", "NS", "TXT"], record.type)])
    error_message = "Supported record types are A, AAAA, CNAME, MX, NS and TXT."
  }
}

# -----------------------------------------------------------------------------
# WAF and rules
# -----------------------------------------------------------------------------

variable "enable_managed_waf" {
  description = "Deploy the Cloudflare Managed Ruleset and the OWASP Core Ruleset. Requires a paid plan."
  type        = bool
  default     = false
}

variable "firewall_rules" {
  description = "Custom WAF rules, evaluated in order."
  type = list(object({
    ref         = string
    description = string
    expression  = string
    action      = string
    enabled     = optional(bool, true)
  }))
  default = [
    {
      ref         = "block_sensitive_paths"
      description = "Block requests for files that must never be served"
      expression  = "(http.request.uri.path contains \"/.env\") or (http.request.uri.path contains \"/.git/\") or (http.request.uri.path contains \"/.aws/\")"
      action      = "block"
    },
  ]

  validation {
    condition     = alltrue([for rule in var.firewall_rules : contains(["block", "managed_challenge", "js_challenge", "challenge", "log", "skip"], rule.action)])
    error_message = "The action of a custom rule must be block, managed_challenge, js_challenge, challenge, log or skip."
  }
}

variable "rate_limit" {
  description = "Rate limiting rule. The defaults fit the Free plan, which allows one rule with a 10 second period and timeout."
  type = object({
    enabled             = bool
    expression          = string
    requests_per_period = number
    period              = number
    mitigation_timeout  = number
  })
  default = {
    enabled             = true
    expression          = "(http.request.uri.path contains \"/login\") or (http.request.uri.path contains \"/signin\")"
    requests_per_period = 20
    period              = 10
    mitigation_timeout  = 10
  }
}

variable "security_headers" {
  description = "Response headers set on every response. An empty map disables the rule."
  type        = map(string)
  default = {
    "X-Content-Type-Options" = "nosniff"
    "X-Frame-Options"        = "SAMEORIGIN"
    "Referrer-Policy"        = "strict-origin-when-cross-origin"
    "Permissions-Policy"     = "camera=(), microphone=(), geolocation=()"
  }
}
