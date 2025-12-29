variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "name" {
  description = "Name of the WAF Web ACL"
  type        = string
}

variable "scope" {
  description = "Scope of the WAF Web ACL. Valid values are REGIONAL or CLOUDFRONT"
  type        = string
  default     = "REGIONAL"

  validation {
    condition     = contains(["REGIONAL", "CLOUDFRONT"], var.scope)
    error_message = "Scope must be either REGIONAL or CLOUDFRONT."
  }
}

variable "default_action" {
  description = "Default action for the WAF Web ACL. Valid values are allow or block"
  type        = string
  default     = "allow"

  validation {
    condition     = contains(["allow", "block"], var.default_action)
    error_message = "Default action must be either allow or block."
  }
}

variable "managed_rule_groups" {
  description = "List of AWS managed rule groups to apply"
  type = list(object({
    name           = string
    vendor_name    = string
    priority       = number
    excluded_rules = list(string)
  }))
  default = [
    {
      name           = "AWSManagedRulesCommonRuleSet"
      vendor_name    = "AWS"
      priority       = 10
      excluded_rules = []
    },
    {
      name           = "AWSManagedRulesKnownBadInputsRuleSet"
      vendor_name    = "AWS"
      priority       = 20
      excluded_rules = []
    },
    {
      name           = "AWSManagedRulesSQLiRuleSet"
      vendor_name    = "AWS"
      priority       = 30
      excluded_rules = []
    },
    {
      name           = "AWSManagedRulesLinuxRuleSet"
      vendor_name    = "AWS"
      priority       = 40
      excluded_rules = []
    },
    {
      name           = "AWSManagedRulesAmazonIpReputationList"
      vendor_name    = "AWS"
      priority       = 50
      excluded_rules = []
    }
  ]
}

variable "rate_limit_rules" {
  description = "List of rate-based rules for DDoS protection"
  type = list(object({
    name     = string
    priority = number
    limit    = number
    action   = string
  }))
  default = []

  validation {
    condition = alltrue([
      for rule in var.rate_limit_rules : contains(["block", "count"], rule.action)
    ])
    error_message = "Rate limit rule action must be either block or count."
  }

  validation {
    condition = alltrue([
      for rule in var.rate_limit_rules : rule.limit >= 100 && rule.limit <= 2000000000
    ])
    error_message = "Rate limit must be between 100 and 2,000,000,000."
  }
}

variable "ip_set_rules" {
  description = "List of IP set rules for allow/block lists"
  type = list(object({
    name       = string
    priority   = number
    action     = string
    ip_set_arn = string
  }))
  default = []

  validation {
    condition = alltrue([
      for rule in var.ip_set_rules : contains(["allow", "block", "count"], rule.action)
    ])
    error_message = "IP set rule action must be allow, block, or count."
  }
}

variable "custom_rules" {
  description = "List of custom rules with various statement types (byte_match, regex_pattern_set, regex_match)"
  type = list(object({
    name           = string
    priority       = number
    action         = string
    statement_type = string
    statement      = any
  }))
  default = []

  validation {
    condition = alltrue([
      for rule in var.custom_rules : contains(["allow", "block", "count"], rule.action)
    ])
    error_message = "Custom rule action must be allow, block, or count."
  }

  validation {
    condition = alltrue([
      for rule in var.custom_rules : contains(["byte_match", "regex_pattern_set", "regex_match"], rule.statement_type)
    ])
    error_message = "Custom rule statement_type must be byte_match, regex_pattern_set, or regex_match."
  }
}

variable "enable_logging" {
  description = "Enable WAF logging"
  type        = bool
  default     = false
}

variable "log_destination_arns" {
  description = "List of ARNs for log destinations (CloudWatch Log Group, S3 bucket, or Kinesis Firehose)"
  type        = list(string)
  default     = []
}

variable "logging_filter" {
  description = "Logging filter configuration"
  type = object({
    default_behavior = string
    filters = list(object({
      behavior    = string
      requirement = string
      conditions = list(object({
        type       = string
        action     = optional(string)
        label_name = optional(string)
      }))
    }))
  })
  default = null

  validation {
    condition     = var.logging_filter == null || contains(["KEEP", "DROP"], var.logging_filter.default_behavior)
    error_message = "Logging filter default_behavior must be KEEP or DROP."
  }
}

variable "redacted_fields" {
  description = "List of fields to redact from logs"
  type = list(object({
    type = string
    name = optional(string)
  }))
  default = []

  validation {
    condition = alltrue([
      for field in var.redacted_fields : contains(["single_header", "uri_path", "query_string"], field.type)
    ])
    error_message = "Redacted field type must be single_header, uri_path, or query_string."
  }
}

variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}
