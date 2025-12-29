# Configuration Loader Module
# Loads YAML configurations into Terraform

variable "config_paths" {
  description = "List of configuration file paths to load (ordered by precedence)"
  type        = list(string)
}

variable "environment" {
  description = "Environment name for config selection"
  type        = string
}

variable "required_keys" {
  description = "List of required configuration keys"
  type        = list(string)
  default     = []
}

locals {
  # Load all configuration files
  raw_configs = [for path in var.config_paths : try(yamldecode(file(path)), {})]

  # Merge configurations (later files override earlier ones)
  merged_config = merge(flatten([
    for config in local.raw_configs : config
  ])...)

  # Get environments config safely
  environments = try(lookup(local.merged_config, "environments", {}), {})
  wildcard_env = try(lookup(local.environments, "*", {}), {})
  specific_env = try(lookup(local.environments, var.environment, {}), {})

  # Extract environment-specific config
  env_config = merge(
    local.merged_config,
    local.wildcard_env,
    local.specific_env
  )

  # Validate required keys - check if key exists and has a non-null, non-empty value
  missing_keys = [
    for key in var.required_keys :
    key if !contains(keys(local.env_config), key)
  ]

  # Validation result
  is_valid = length(local.missing_keys) == 0

  # Filter out null/empty values
  cleaned_config = {
    for key, value in local.env_config :
    key => value if value != null && value != "" && key != "environments"
  }
}

output "config" {
  description = "Final merged and cleaned configuration"
  value       = local.is_valid ? local.cleaned_config : tomap({})
}

output "is_valid" {
  description = "Whether all required keys are present"
  value       = local.is_valid
}

output "missing_keys" {
  description = "List of missing required keys"
  value       = local.is_valid ? [] : local.missing_keys
}

output "validation_errors" {
  description = "Validation error messages"
  value = local.is_valid ? [] : [
    "Missing required configuration keys: ${join(", ", local.missing_keys)}"
  ]
}

output "all_keys" {
  description = "All available configuration keys"
  value       = keys(local.cleaned_config)
}

output "config_value" {
  description = "Get a specific config value by key with default"
  value = { for key, default_value in var.required_keys.* :
    key => lookup(local.cleaned_config, key, default_value)
  }
}