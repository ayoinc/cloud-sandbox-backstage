variable "validations" {
  description = "Map of variable validations"
  type = map(object({
    value          = string
    required       = optional(bool, true)
    description    = optional(string, "")
    pattern        = optional(string, "")
    allowed_values = optional(list(string), [])
    min_length     = optional(number, 0)
    max_length     = optional(number, 256)
  }))
  default = {}
}

locals {
  # Validate each variable
  validation_results = [for name, config in var.validations : {
    name     = name
    valid    = true
    errors   = []
    warnings = []
    } if try(
    # Check required
    (!config.required || config.value != "") &&
    # Check pattern if specified
    (config.pattern == "" || can(regex(config.pattern, config.value))) &&
    # Check allowed values if specified
    (length(config.allowed_values) == 0 || contains(config.allowed_values, config.value)) &&
    # Check length constraints
    (length(config.value) >= config.min_length && length(config.value) <= config.max_length),
    false
  )]

  # Collect errors
  errors = flatten([for name, config in var.validations : [
    config.required && config.value == "" ? "Required variable '${name}' is not set" : null,
    config.pattern != "" && !can(regex(config.pattern, config.value)) ? "Variable '${name}' does not match pattern: ${config.pattern}" : null,
    length(config.allowed_values) > 0 && !contains(config.allowed_values, config.value) ? "Variable '${name}' must be one of: ${join(", ", config.allowed_values)}" : null,
    length(config.value) < config.min_length ? "Variable '${name}' must be at least ${config.min_length} characters" : null,
    length(config.value) > config.max_length ? "Variable '${name}' must be at most ${config.max_length} characters" : null,
  ]])

  filtered_errors = compact(local.errors)

  is_valid = length(local.filtered_errors) == 0
}

output "is_valid" {
  description = "Whether all validation checks passed"
  value       = local.is_valid
}

output "errors" {
  description = "List of validation errors"
  value       = local.filtered_errors
  sensitive   = true
}

output "validation_passed" {
  description = "Validation passed status for use in conditionals"
  value       = local.is_valid
}