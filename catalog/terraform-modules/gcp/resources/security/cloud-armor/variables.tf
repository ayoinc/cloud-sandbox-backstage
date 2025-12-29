variable "project_name" {
  description = "The name of the project for resource naming"
  type        = string
}

variable "project_id" {
  description = "The GCP project ID where resources will be created"
  type        = string
}

variable "environment" {
  description = "The environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "name" {
  description = "The name of the security policy"
  type        = string
}

variable "description" {
  description = "Description of the security policy"
  type        = string
  default     = null
}

variable "type" {
  description = "The type of security policy. Valid values: CLOUD_ARMOR, CLOUD_ARMOR_EDGE"
  type        = string
  default     = "CLOUD_ARMOR"

  validation {
    condition     = contains(["CLOUD_ARMOR", "CLOUD_ARMOR_EDGE"], var.type)
    error_message = "Type must be either CLOUD_ARMOR or CLOUD_ARMOR_EDGE."
  }
}

variable "adaptive_protection_config" {
  description = "Adaptive protection configuration for the security policy"
  type = object({
    layer_7_ddos_defense_config = optional(object({
      enable          = optional(bool, false)
      rule_visibility = optional(string, "STANDARD")
    }))
  })
  default = null
}

variable "rules" {
  description = "List of security policy rules"
  type = list(object({
    action               = string
    priority             = number
    description          = optional(string)
    match_versioned_expr = optional(string, "SRC_IPS_V1")
    match_config = optional(object({
      src_ip_ranges = list(string)
    }))
    match_expr = optional(object({
      expression = string
    }))
    rate_limit_options = optional(object({
      conform_action = optional(string, "allow")
      exceed_action  = optional(string, "deny(429)")
      enforce_on_key_configs = optional(list(object({
        enforce_on_key_type = string
        enforce_on_key_name = optional(string)
      })))
      rate_limit_threshold = optional(object({
        count        = number
        interval_sec = number
      }))
      ban_threshold = optional(object({
        count        = number
        interval_sec = number
      }))
      ban_duration_sec = optional(number)
    }))
    preconfigured_waf_config = optional(object({
      exclusions = optional(list(object({
        target_rule_set = string
        target_rule_ids = optional(list(string))
        request_headers = optional(list(object({
          operator = string
          value    = optional(string)
        })))
        request_cookies = optional(list(object({
          operator = string
          value    = optional(string)
        })))
        request_uris = optional(list(object({
          operator = string
          value    = optional(string)
        })))
        request_query_params = optional(list(object({
          operator = string
          value    = optional(string)
        })))
      })))
    }))
    preview = optional(bool, false)
  }))
}

variable "default_rule_action" {
  description = "The action to take for the default rule. Valid values: allow, deny(STATUS)"
  type        = string
  default     = "allow"
}
