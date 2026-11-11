# =============================================================================
# Cloudflare Workers - Variables
# =============================================================================

variable "account_id" {
  description = "ID of the Cloudflare account. Supplied as TF_VAR_account_id."
  type        = string

  validation {
    condition     = can(regex("^[a-f0-9]{32}$", var.account_id))
    error_message = "The account ID is a 32 character hexadecimal string."
  }
}

variable "name" {
  description = "Name of the Worker; the environment is appended."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]*[a-z0-9]$", var.name))
    error_message = "Use lowercase letters, digits and hyphens, starting with a letter."
  }
}

variable "environment" {
  description = "Environment: dev, staging or prod."
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "The environment must be dev, staging or prod."
  }
}

variable "data_store" {
  description = "Store bound to the Worker next to the R2 bucket: d1 (SQL database) or kv (key-value namespace)."
  type        = string
  default     = "d1"

  validation {
    condition     = contains(["d1", "kv"], var.data_store)
    error_message = "The data store must be d1 or kv."
  }
}

variable "r2_location" {
  description = "Location hint of the R2 bucket and the D1 database. It only takes effect at creation."
  type        = string
  default     = "weur"

  validation {
    condition     = contains(["weur", "eeur", "enam", "wnam", "apac", "oc"], var.r2_location)
    error_message = "The location must be weur, eeur, enam, wnam, apac or oc."
  }
}

variable "custom_hostname" {
  description = "Hostname that serves the Worker, in a zone of the same account. Empty for none."
  type        = string
  default     = ""
}

variable "routes" {
  description = "Route patterns that send part of a zone's traffic to the Worker, for instance { pattern = \"shop.tld/api/*\", zone_id = \"...\" }."
  type = list(object({
    pattern = string
    zone_id = string
  }))
  default = []
}

variable "workers_dev_enabled" {
  description = "Serve the Worker on its workers.dev address. Turn it off when a custom hostname or route is the only intended entrance."
  type        = bool
  default     = false
}

variable "compatibility_date" {
  description = "Workers runtime compatibility date."
  type        = string
  default     = "2026-11-01"
}

variable "log_sampling_rate" {
  description = "Share of requests whose logs are kept, from 0 to 1."
  type        = number
  default     = 1

  validation {
    condition     = var.log_sampling_rate >= 0 && var.log_sampling_rate <= 1
    error_message = "The sampling rate must be between 0 and 1."
  }
}
