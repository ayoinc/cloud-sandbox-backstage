variable "project_name" {
  description = "The name of the project for labeling purposes"
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

variable "topic_name" {
  description = "The name of the Pub/Sub topic"
  type        = string
}

variable "message_retention_duration" {
  description = "The duration to retain messages in the topic (e.g., 86400s for 24 hours)"
  type        = string
  default     = "86400s"
}

variable "kms_key_name" {
  description = "The full resource name of the Cloud KMS key for CMEK encryption"
  type        = string
  default     = null
}

variable "schema_name" {
  description = "The name of the Pub/Sub schema"
  type        = string
  default     = null
}

variable "schema_type" {
  description = "The type of the schema (AVRO or PROTOCOL_BUFFER)"
  type        = string
  default     = "AVRO"

  validation {
    condition     = contains(["AVRO", "PROTOCOL_BUFFER"], var.schema_type)
    error_message = "Schema type must be either AVRO or PROTOCOL_BUFFER."
  }
}

variable "schema_definition" {
  description = "The definition of the schema in the specified format"
  type        = string
  default     = null
}

variable "subscriptions" {
  description = "List of subscription configurations"
  type = list(object({
    name                       = string
    ack_deadline_seconds       = optional(number, 10)
    message_retention_duration = optional(string, "604800s")
    retain_acked_messages      = optional(bool, false)
    expiration_policy_ttl      = optional(string)
    filter                     = optional(string)
    push_config = optional(object({
      push_endpoint = string
      oidc_token = optional(object({
        service_account_email = string
        audience              = optional(string)
      }))
      attributes = optional(map(string))
    }))
    dead_letter_topic     = optional(string)
    max_delivery_attempts = optional(number, 5)
    retry_policy = optional(object({
      minimum_backoff = optional(string, "10s")
      maximum_backoff = optional(string, "600s")
    }))
  }))
  default = []
}

variable "topic_iam_bindings" {
  description = "List of IAM bindings for the topic"
  type = list(object({
    role    = string
    members = list(string)
  }))
  default = []
}

variable "labels" {
  description = "Additional labels to apply to resources"
  type        = map(string)
  default     = {}
}
