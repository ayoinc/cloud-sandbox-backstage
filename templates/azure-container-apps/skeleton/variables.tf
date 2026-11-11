# =============================================================================
# Azure Container Apps - Root Variables
# =============================================================================
# Passed to the child module unchanged.
# Values come from environments/<environment>.tfvars.
# =============================================================================

variable "name" {
  description = "Name used in resource names"
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]*[a-z0-9]$", var.name))
    error_message = "The name must start with a letter and contain only lowercase letters, digits and hyphens."
  }
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "The environment must be dev, staging or prod."
  }
}

variable "location" {
  description = "Azure region for all resources"
  type        = string
}

variable "description" {
  description = "Purpose of the resources, added as a tag"
  type        = string
  default     = ""
}

variable "owner" {
  description = "Owner of the resources, added as a tag"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Additional tags for all resources"
  type        = map(string)
  default     = {}
}

# -----------------------------------------------------------------------------
# Container
# -----------------------------------------------------------------------------

variable "container_image" {
  description = "Image to run, with its tag or digest"
  type        = string
}

variable "container_cpu" {
  description = "vCPUs per replica: 0.25, 0.5, 0.75, 1, 1.25, 1.5, 1.75 or 2"
  type        = number
  default     = 0.5
}

variable "container_memory" {
  description = "Memory per replica; the Consumption profile needs 2Gi for each vCPU"
  type        = string
  default     = "1Gi"
}

variable "environment_variables" {
  description = "Environment variables of the container. Not for secrets: use secret_environment_variables"
  type        = map(string)
  default     = {}
}

variable "secret_environment_variables" {
  description = "Environment variables read from Key Vault: variable name to the versionless ID of the secret. The app reads them with its managed identity"
  type        = map(string)
  default     = {}
}

variable "key_vault_id" {
  description = "Key Vault (using Azure RBAC) holding the secrets; the app identity is granted Key Vault Secrets User on it. null grants nothing"
  type        = string
  default     = null
}

variable "container_registry" {
  description = "Azure Container Registry to pull the image from; the app identity is granted AcrPull on it. null for public images"
  type = object({
    id           = string
    login_server = string
  })
  default = null
}

# -----------------------------------------------------------------------------
# Scaling
# -----------------------------------------------------------------------------

variable "min_replicas" {
  description = "Minimum number of replicas; 0 scales to zero when idle"
  type        = number
  default     = 0
}

variable "max_replicas" {
  description = "Maximum number of replicas"
  type        = number
  default     = 3

  validation {
    condition     = var.max_replicas >= 1 && var.max_replicas >= var.min_replicas
    error_message = "max_replicas must be at least 1 and not below min_replicas."
  }
}

variable "concurrent_requests_per_replica" {
  description = "Concurrent HTTP requests per replica above which a replica is added"
  type        = number
  default     = 50
}

# -----------------------------------------------------------------------------
# Ingress
# -----------------------------------------------------------------------------

variable "target_port" {
  description = "Port the container listens on"
  type        = number
  default     = 8080
}

variable "external_ingress_enabled" {
  description = "Accept requests from outside the Container Apps environment. Off, only other apps in the environment reach the app"
  type        = bool
  default     = false
}

variable "health_probe_path" {
  description = "HTTP path that answers 200 when the container is healthy"
  type        = string
  default     = "/"
}

# -----------------------------------------------------------------------------
# Environment
# -----------------------------------------------------------------------------

variable "infrastructure_subnet_id" {
  description = "Subnet (at least /27, delegated to Microsoft.App/environments) to run the environment in; null uses a network managed by Azure"
  type        = string
  default     = null
}

variable "internal_load_balancer_enabled" {
  description = "Give the environment a private address only. Needs infrastructure_subnet_id"
  type        = bool
  default     = false

  validation {
    condition     = !var.internal_load_balancer_enabled || var.infrastructure_subnet_id != null
    error_message = "An internal load balancer needs infrastructure_subnet_id."
  }
}

variable "zone_redundancy_enabled" {
  description = "Spread replicas over availability zones. Needs infrastructure_subnet_id and cannot be changed after creation"
  type        = bool
  default     = false

  validation {
    condition     = !var.zone_redundancy_enabled || var.infrastructure_subnet_id != null
    error_message = "Zone redundancy needs infrastructure_subnet_id."
  }
}

variable "log_retention_days" {
  description = "Days the Log Analytics workspace keeps container logs"
  type        = number
  default     = 30
}
