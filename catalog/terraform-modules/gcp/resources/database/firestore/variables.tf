variable "project_name" {
  description = "The name of the project"
  type        = string
}

variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "environment" {
  description = "The environment (e.g., dev, staging, prod)"
  type        = string
}

variable "location_id" {
  description = "The location of the Firestore database"
  type        = string
}

variable "database_id" {
  description = "The ID of the Firestore database"
  type        = string
  default     = "(default)"
}

variable "type" {
  description = "The type of the database (FIRESTORE_NATIVE or DATASTORE_MODE)"
  type        = string
  default     = "FIRESTORE_NATIVE"

  validation {
    condition     = contains(["FIRESTORE_NATIVE", "DATASTORE_MODE"], var.type)
    error_message = "Type must be either FIRESTORE_NATIVE or DATASTORE_MODE."
  }
}

variable "concurrency_mode" {
  description = "The concurrency control mode (OPTIMISTIC, PESSIMISTIC, OPTIMISTIC_WITH_ENTITY_GROUPS)"
  type        = string
  default     = "PESSIMISTIC"

  validation {
    condition     = contains(["OPTIMISTIC", "PESSIMISTIC", "OPTIMISTIC_WITH_ENTITY_GROUPS"], var.concurrency_mode)
    error_message = "Concurrency mode must be OPTIMISTIC, PESSIMISTIC, or OPTIMISTIC_WITH_ENTITY_GROUPS."
  }
}

variable "app_engine_integration_mode" {
  description = "The App Engine integration mode (ENABLED or DISABLED)"
  type        = string
  default     = "DISABLED"

  validation {
    condition     = contains(["ENABLED", "DISABLED"], var.app_engine_integration_mode)
    error_message = "App Engine integration mode must be either ENABLED or DISABLED."
  }
}

variable "point_in_time_recovery_enablement" {
  description = "Whether point-in-time recovery is enabled (POINT_IN_TIME_RECOVERY_ENABLED or POINT_IN_TIME_RECOVERY_DISABLED)"
  type        = string
  default     = "POINT_IN_TIME_RECOVERY_ENABLED"

  validation {
    condition     = contains(["POINT_IN_TIME_RECOVERY_ENABLED", "POINT_IN_TIME_RECOVERY_DISABLED"], var.point_in_time_recovery_enablement)
    error_message = "Point-in-time recovery enablement must be POINT_IN_TIME_RECOVERY_ENABLED or POINT_IN_TIME_RECOVERY_DISABLED."
  }
}

variable "delete_protection_state" {
  description = "The delete protection state (DELETE_PROTECTION_ENABLED or DELETE_PROTECTION_DISABLED)"
  type        = string
  default     = "DELETE_PROTECTION_DISABLED"

  validation {
    condition     = contains(["DELETE_PROTECTION_ENABLED", "DELETE_PROTECTION_DISABLED"], var.delete_protection_state)
    error_message = "Delete protection state must be DELETE_PROTECTION_ENABLED or DELETE_PROTECTION_DISABLED."
  }
}

variable "cmek_key_name" {
  description = "The full resource name of the Cloud KMS key for CMEK encryption"
  type        = string
  default     = null
}

variable "indexes" {
  description = "List of composite indexes to create"
  type = list(object({
    collection = string
    fields = list(object({
      field_path       = string
      order            = optional(string)
      array_config     = optional(string)
      vector_dimension = optional(number)
    }))
  }))
  default = []
}

variable "field_configs" {
  description = "List of field-level configurations for indexes and TTL"
  type = list(object({
    collection = string
    field      = string
    indexes = optional(list(object({
      order        = optional(string)
      array_config = optional(string)
      query_scope  = optional(string)
    })), [])
    ttl_config = optional(object({
      state = optional(string)
    }))
  }))
  default = []
}

variable "labels" {
  description = "A map of labels to apply to the Firestore database"
  type        = map(string)
  default     = {}
}
