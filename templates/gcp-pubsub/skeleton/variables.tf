# =============================================================================
# GCP Pub/Sub - Root Variables
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

variable "project_id" {
  description = "Google Cloud project that holds the resources"
  type        = string
}

variable "region" {
  description = "Google Cloud region for regional resources"
  type        = string
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
# Topic
# -----------------------------------------------------------------------------

variable "message_retention_duration" {
  description = "How long the topic keeps messages for replay, in seconds with an s suffix (10 minutes to 31 days)"
  type        = string
  default     = "604800s"
}

variable "allowed_persistence_regions" {
  description = "Regions where messages may be stored; empty restricts them to the region"
  type        = set(string)
  default     = []
}

variable "kms_key_name" {
  description = "Cloud KMS key (projects/.../cryptoKeys/...) that encrypts the messages; null uses Google-managed keys"
  type        = string
  default     = null
}

# -----------------------------------------------------------------------------
# Schema
# -----------------------------------------------------------------------------

variable "schema_type" {
  description = "Schema that published messages must match: NONE, AVRO or PROTOCOL_BUFFER"
  type        = string
  default     = "NONE"

  validation {
    condition     = contains(["NONE", "AVRO", "PROTOCOL_BUFFER"], var.schema_type)
    error_message = "The schema type must be NONE, AVRO or PROTOCOL_BUFFER."
  }
}

variable "schema_definition_file" {
  description = "File with the schema definition, relative to the root of the repository; required unless schema_type is NONE"
  type        = string
  default     = null

  validation {
    condition     = var.schema_type == "NONE" || var.schema_definition_file != null
    error_message = "Set schema_definition_file when schema_type is AVRO or PROTOCOL_BUFFER."
  }
}

variable "schema_encoding" {
  description = "Encoding of messages validated against the schema: JSON or BINARY"
  type        = string
  default     = "JSON"

  validation {
    condition     = contains(["JSON", "BINARY"], var.schema_encoding)
    error_message = "The schema encoding must be JSON or BINARY."
  }
}

# -----------------------------------------------------------------------------
# Subscriptions
# -----------------------------------------------------------------------------

variable "subscriptions" {
  description = "Subscriptions by short name. A subscription with push_endpoint is delivered over HTTPS with an OIDC token of push_service_account_email; the others are pulled"
  type = map(object({
    ack_deadline_seconds         = optional(number, 30)
    message_retention_duration   = optional(string, "604800s")
    retain_acked_messages        = optional(bool, false)
    filter                       = optional(string)
    enable_message_ordering      = optional(bool, false)
    enable_exactly_once_delivery = optional(bool, false)
    minimum_backoff              = optional(string, "10s")
    maximum_backoff              = optional(string, "600s")
    push_endpoint                = optional(string)
    push_service_account_email   = optional(string)
  }))
  default = {}

  validation {
    condition     = alltrue([for subscription in values(var.subscriptions) : subscription.push_endpoint == null || subscription.push_service_account_email != null])
    error_message = "A push subscription needs push_service_account_email, so the endpoint can verify the sender."
  }

  validation {
    condition     = alltrue([for subscription in values(var.subscriptions) : subscription.push_endpoint == null || startswith(coalesce(subscription.push_endpoint, "https://"), "https://")])
    error_message = "Push endpoints must use HTTPS."
  }
}

variable "dead_letter_enabled" {
  description = "Move messages that keep failing to a dead-letter topic instead of redelivering them forever"
  type        = bool
  default     = true
}

variable "max_delivery_attempts" {
  description = "Delivery attempts before a message goes to the dead-letter topic (5 to 100)"
  type        = number
  default     = 5

  validation {
    condition     = var.max_delivery_attempts >= 5 && var.max_delivery_attempts <= 100
    error_message = "max_delivery_attempts must be between 5 and 100."
  }
}

# -----------------------------------------------------------------------------
# Access
# -----------------------------------------------------------------------------

variable "publishers" {
  description = "IAM members that may publish to the topic, such as serviceAccount:name@project.iam.gserviceaccount.com"
  type        = set(string)
  default     = []
}

variable "subscribers" {
  description = "IAM members that may receive from every subscription, including the dead-letter subscription"
  type        = set(string)
  default     = []
}

variable "enable_apis" {
  description = "Enable the Pub/Sub API. Switch off when the pipeline may not manage services"
  type        = bool
  default     = true
}
