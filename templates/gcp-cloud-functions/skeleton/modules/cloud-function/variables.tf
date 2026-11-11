# =============================================================================
# GCP Cloud Run Functions Module - Variables
# =============================================================================
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

variable "project_id" {
  description = "Google Cloud project that holds the resources"
  type        = string
}

variable "region" {
  description = "Google Cloud region for regional resources"
  type        = string
}

variable "description" {
  description = "Purpose of the resources"
  type        = string
  default     = ""
}

variable "owner" {
  description = "Owner of the resources, added as a label"
  type        = string
  default     = ""
}

variable "labels" {
  description = "Additional labels for all resources"
  type        = map(string)
  default     = {}
}

# -----------------------------------------------------------------------------
# Build
# -----------------------------------------------------------------------------

variable "runtime" {
  description = "Runtime of the function, such as nodejs24"
  type        = string
}

variable "entry_point" {
  description = "Name the function is registered under in its source"
  type        = string
  default     = "handler"
}

variable "source_dir" {
  description = "Directory with the function source, relative to the root of the repository"
  type        = string
  default     = "function"
}

# -----------------------------------------------------------------------------
# Trigger
# -----------------------------------------------------------------------------

variable "trigger_type" {
  description = "What invokes the function: http (HTTPS requests) or pubsub (messages on a topic created here)"
  type        = string
  default     = "http"

  validation {
    condition     = contains(["http", "pubsub"], var.trigger_type)
    error_message = "The trigger type must be http or pubsub."
  }
}

variable "allow_unauthenticated" {
  description = "Let anyone on the internet invoke an HTTP function. Off, callers need an identity token and a place in invokers"
  type        = bool
  default     = false

  validation {
    condition     = !var.allow_unauthenticated || var.trigger_type == "http"
    error_message = "Only an HTTP function can allow unauthenticated invocations."
  }
}

variable "invokers" {
  description = "IAM members that may invoke an HTTP function, such as serviceAccount:name@project.iam.gserviceaccount.com or group:team@domain"
  type        = set(string)
  default     = []
}

variable "ingress_settings" {
  description = "Networks that reach the function: ALLOW_ALL, ALLOW_INTERNAL_ONLY or ALLOW_INTERNAL_AND_GCLB. null picks ALLOW_ALL for http (IAM still applies) and ALLOW_INTERNAL_ONLY for pubsub"
  type        = string
  default     = null

  validation {
    condition     = var.ingress_settings == null || contains(["ALLOW_ALL", "ALLOW_INTERNAL_ONLY", "ALLOW_INTERNAL_AND_GCLB"], coalesce(var.ingress_settings, "ALLOW_ALL"))
    error_message = "The ingress settings must be ALLOW_ALL, ALLOW_INTERNAL_ONLY or ALLOW_INTERNAL_AND_GCLB."
  }
}

# -----------------------------------------------------------------------------
# Runtime
# -----------------------------------------------------------------------------

variable "available_memory" {
  description = "Memory of an instance, such as 256M or 1Gi"
  type        = string
  default     = "256M"
}

variable "timeout_seconds" {
  description = "Seconds after which an invocation is stopped"
  type        = number
  default     = 60
}

variable "min_instance_count" {
  description = "Instances kept warm; 0 scales to zero"
  type        = number
  default     = 0
}

variable "max_instance_count" {
  description = "Upper limit of instances"
  type        = number
  default     = 10
}

variable "environment_variables" {
  description = "Environment variables of the function. Not for secrets: use secret_environment_variables"
  type        = map(string)
  default     = {}
}

variable "secret_environment_variables" {
  description = "Environment variables read from Secret Manager: variable name to the secret (in this project) and its version. The function's service account is granted access to each"
  type = map(object({
    secret  = string
    version = optional(string, "latest")
  }))
  default = {}
}

variable "runtime_service_account_roles" {
  description = "Project roles for the function's service account, such as roles/datastore.user. It starts with none"
  type        = set(string)
  default     = []
}

variable "enable_apis" {
  description = "Enable the Google Cloud APIs the function needs. Switch off when the pipeline may not manage services"
  type        = bool
  default     = true
}
