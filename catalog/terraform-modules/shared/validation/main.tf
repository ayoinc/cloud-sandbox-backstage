# =============================================================================
# SHARED VALIDATION MODULE
# =============================================================================
# Generic input validation framework for all Terraform modules
# Provides consistent validation patterns across all resources
# =============================================================================

# -----------------------------------------------------------------------------
# Variables
# -----------------------------------------------------------------------------

variable "validations" {
  description = "List of validation rules to check"
  type = list(object({
    name      = string
    condition = bool
    message   = string
  }))
  default = []
}

variable "required_variables" {
  description = "Map of required variables with their values"
  type        = map(string)
  default     = {}
}

variable "optional_variables" {
  description = "Map of optional variables with their values and defaults"
  type = map(object({
    value   = string
    default = string
  }))
  default = {}
}

variable "patterns" {
  description = "Regex patterns to validate strings"
  type = map(object({
    value   = string
    pattern = string
    message = string
  }))
  default = {}
}

variable "ranges" {
  description = "Numeric range validations"
  type = map(object({
    value = number
    min   = number
    max   = number
  }))
  default = {}
}

variable "enums" {
  description = "Enum validations (value must be in allowed list)"
  type = map(object({
    value   = string
    allowed = list(string)
  }))
  default = {}
}

variable "lengths" {
  description = "String length validations"
  type = map(object({
    value = string
    min   = number
    max   = number
  }))
  default = {}
}

variable "fail_on_error" {
  description = "Whether to fail the plan on validation errors"
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------
# Locals - Validation Logic
# -----------------------------------------------------------------------------

locals {
  # Check required variables are not empty
  required_errors = [
    for name, value in var.required_variables :
    "Required variable '${name}' is empty or not set"
    if value == "" || value == null
  ]

  # Check custom validations
  custom_errors = [
    for v in var.validations :
    v.message
    if !v.condition
  ]

  # Check pattern validations
  pattern_errors = [
    for name, p in var.patterns :
    "Variable '${name}' value '${p.value}' does not match pattern: ${p.message}"
    if !can(regex(p.pattern, p.value))
  ]

  # Check range validations
  range_errors = [
    for name, r in var.ranges :
    "Variable '${name}' value ${r.value} is out of range [${r.min}, ${r.max}]"
    if r.value < r.min || r.value > r.max
  ]

  # Check enum validations
  enum_errors = [
    for name, e in var.enums :
    "Variable '${name}' value '${e.value}' is not in allowed values: ${join(", ", e.allowed)}"
    if !contains(e.allowed, e.value)
  ]

  # Check length validations
  length_errors = [
    for name, l in var.lengths :
    "Variable '${name}' length ${length(l.value)} is out of range [${l.min}, ${l.max}]"
    if length(l.value) < l.min || length(l.value) > l.max
  ]

  # Collect all errors
  all_errors = concat(
    local.required_errors,
    local.custom_errors,
    local.pattern_errors,
    local.range_errors,
    local.enum_errors,
    local.length_errors
  )

  # Check if validation passed
  validation_passed = length(local.all_errors) == 0

  # Error summary
  error_summary = local.validation_passed ? "All validations passed" : join("\n", local.all_errors)

  # Resolve optional variables (use value if set, otherwise default)
  resolved_optionals = {
    for name, opt in var.optional_variables :
    name => opt.value != "" && opt.value != null ? opt.value : opt.default
  }
}

# -----------------------------------------------------------------------------
# Validation Check (fails plan if errors and fail_on_error is true)
# -----------------------------------------------------------------------------

resource "terraform_data" "validation" {
  count = var.fail_on_error && !local.validation_passed ? 1 : 0

  lifecycle {
    precondition {
      condition     = local.validation_passed
      error_message = "Validation failed:\n${local.error_summary}"
    }
  }
}

# -----------------------------------------------------------------------------
# Outputs
# -----------------------------------------------------------------------------

output "valid" {
  description = "Whether all validations passed"
  value       = local.validation_passed
}

output "errors" {
  description = "List of validation errors"
  value       = local.all_errors
}

output "error_count" {
  description = "Number of validation errors"
  value       = length(local.all_errors)
}

output "error_summary" {
  description = "Human-readable error summary"
  value       = local.error_summary
}

output "resolved_optionals" {
  description = "Optional variables with resolved values"
  value       = local.resolved_optionals
}

output "validation_report" {
  description = "Full validation report"
  value = {
    passed             = local.validation_passed
    total_errors       = length(local.all_errors)
    required_errors    = length(local.required_errors)
    custom_errors      = length(local.custom_errors)
    pattern_errors     = length(local.pattern_errors)
    range_errors       = length(local.range_errors)
    enum_errors        = length(local.enum_errors)
    length_errors      = length(local.length_errors)
    errors             = local.all_errors
    resolved_optionals = local.resolved_optionals
  }
}

# -----------------------------------------------------------------------------
# Common Validation Patterns (for reference)
# -----------------------------------------------------------------------------

output "common_patterns" {
  description = "Common regex patterns for validation"
  value = {
    # Naming patterns
    lowercase_alphanumeric     = "^[a-z][a-z0-9]*$"
    lowercase_with_hyphens     = "^[a-z][a-z0-9-]*[a-z0-9]$"
    lowercase_with_underscores = "^[a-z][a-z0-9_]*[a-z0-9]$"

    # Azure specific
    azure_resource_group  = "^[a-zA-Z0-9._-]+$"
    azure_storage_account = "^[a-z0-9]{3,24}$"
    azure_key_vault       = "^[a-zA-Z][a-zA-Z0-9-]{1,22}[a-zA-Z0-9]$"

    # AWS specific
    aws_s3_bucket = "^[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]$"
    aws_iam_role  = "^[a-zA-Z_][a-zA-Z0-9_+=,.@-]{0,63}$"

    # GCP specific
    gcp_project_id = "^[a-z][a-z0-9-]{4,28}[a-z0-9]$"
    gcp_bucket     = "^[a-z0-9][a-z0-9_-]{1,61}[a-z0-9]$"

    # Network patterns
    ipv4_address = "^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$"
    ipv4_cidr    = "^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)/(?:3[0-2]|[12]?[0-9])$"

    # Email and URL
    email = "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$"
    url   = "^https?://[a-zA-Z0-9.-]+(?:/[a-zA-Z0-9._~:/?#\\[\\]@!$&'()*+,;=-]*)?$"

    # Date/Time
    iso8601_date     = "^\\d{4}-\\d{2}-\\d{2}$"
    iso8601_datetime = "^\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}(?:Z|[+-]\\d{2}:\\d{2})$"
  }
}
