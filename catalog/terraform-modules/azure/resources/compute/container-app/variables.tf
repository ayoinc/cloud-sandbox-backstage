variable "project_name" {
  description = "The name of the project"
  type        = string
}

variable "environment" {
  description = "The environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
}

variable "location" {
  description = "The Azure region where resources will be created"
  type        = string
}

variable "container_app_environment_name" {
  description = "The name of the Container App Environment"
  type        = string
}

variable "log_analytics_workspace_id" {
  description = "The ID of the Log Analytics Workspace for the Container App Environment"
  type        = string
}

variable "container_app_name" {
  description = "The name of the Container App"
  type        = string
}

variable "revision_mode" {
  description = "The revision mode of the Container App (Single or Multiple)"
  type        = string
  default     = "Single"

  validation {
    condition     = contains(["Single", "Multiple"], var.revision_mode)
    error_message = "revision_mode must be either 'Single' or 'Multiple'."
  }
}

variable "container_name" {
  description = "The name of the container"
  type        = string
}

variable "image" {
  description = "The container image to deploy"
  type        = string
}

variable "cpu" {
  description = "The CPU allocation for the container"
  type        = number
  default     = 0.25

  validation {
    condition     = contains([0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0], var.cpu)
    error_message = "cpu must be one of: 0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0."
  }
}

variable "memory" {
  description = "The memory allocation for the container"
  type        = string
  default     = "0.5Gi"

  validation {
    condition     = can(regex("^[0-9]+(\\.[0-9]+)?Gi$", var.memory))
    error_message = "memory must be in the format '<number>Gi' (e.g., '0.5Gi', '1Gi')."
  }
}

variable "min_replicas" {
  description = "The minimum number of replicas"
  type        = number
  default     = 0

  validation {
    condition     = var.min_replicas >= 0 && var.min_replicas <= 300
    error_message = "min_replicas must be between 0 and 300."
  }
}

variable "max_replicas" {
  description = "The maximum number of replicas"
  type        = number
  default     = 10

  validation {
    condition     = var.max_replicas >= 1 && var.max_replicas <= 300
    error_message = "max_replicas must be between 1 and 300."
  }
}

variable "target_port" {
  description = "The target port for ingress traffic"
  type        = number
  default     = 80

  validation {
    condition     = var.target_port >= 1 && var.target_port <= 65535
    error_message = "target_port must be between 1 and 65535."
  }
}

variable "external_enabled" {
  description = "Whether the Container App is accessible from outside the Container App Environment"
  type        = bool
  default     = true
}

variable "ingress_transport" {
  description = "The transport protocol for ingress (auto, http, http2, tcp)"
  type        = string
  default     = "auto"

  validation {
    condition     = contains(["auto", "http", "http2", "tcp"], var.ingress_transport)
    error_message = "ingress_transport must be one of: auto, http, http2, tcp."
  }
}

variable "env_vars" {
  description = "List of environment variables for the container"
  type = list(object({
    name        = string
    value       = optional(string)
    secret_name = optional(string)
  }))
  default = []
}

variable "secrets" {
  description = "List of secrets for the Container App"
  type = list(object({
    name  = string
    value = string
  }))
  default   = []
  sensitive = true
}

variable "enable_dapr" {
  description = "Whether to enable Dapr for the Container App"
  type        = bool
  default     = false
}

variable "dapr_app_id" {
  description = "The Dapr application ID"
  type        = string
  default     = null
}

variable "dapr_app_port" {
  description = "The port Dapr uses to communicate with the application"
  type        = number
  default     = null
}

variable "custom_domains" {
  description = "List of custom domains for the Container App"
  type = list(object({
    name           = string
    certificate_id = optional(string)
  }))
  default = []
}

variable "custom_scale_rules" {
  description = "List of custom scale rules"
  type = list(object({
    name             = string
    custom_rule_type = string
    metadata         = map(string)
  }))
  default = []
}

variable "http_scale_rules" {
  description = "List of HTTP scale rules"
  type = list(object({
    name                = string
    concurrent_requests = number
  }))
  default = []
}

variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}
