variable "project_name" {
  description = "The name of the GCP project"
  type        = string
}

variable "project_id" {
  description = "The ID of the GCP project"
  type        = string
}

variable "environment" {
  description = "The environment for the resources (e.g., dev, staging, prod)"
  type        = string
}

variable "log_buckets" {
  description = "List of custom log buckets to create"
  type = list(object({
    bucket_id      = string
    location       = string
    retention_days = number
    description    = string
  }))
  default = []
}

variable "log_sinks" {
  description = "List of log sinks for routing logs to BigQuery, Cloud Storage, or Pub/Sub destinations"
  type = list(object({
    name                   = string
    destination            = string
    filter                 = string
    unique_writer_identity = bool
    exclusions = optional(list(object({
      name        = string
      filter      = string
      description = optional(string)
      disabled    = optional(bool, false)
    })))
  }))
  default = []
}

variable "log_exclusions" {
  description = "List of log exclusions for filtering out unwanted logs"
  type = list(object({
    name        = string
    filter      = string
    description = string
    disabled    = bool
  }))
  default = []
}

variable "log_metrics" {
  description = "List of log-based metrics for monitoring"
  type = list(object({
    name   = string
    filter = string
    metric_descriptor = optional(object({
      metric_kind = string
      value_type  = string
      unit        = optional(string, "1")
      labels = optional(list(object({
        key         = string
        value_type  = optional(string, "STRING")
        description = optional(string)
      })))
    }))
    bucket_options = optional(object({
      linear_buckets = optional(object({
        num_finite_buckets = number
        width              = number
        offset             = number
      }))
      exponential_buckets = optional(object({
        num_finite_buckets = number
        growth_factor      = number
        scale              = number
      }))
      explicit_buckets = optional(object({
        bounds = list(number)
      }))
    }))
    value_extractor  = optional(string)
    label_extractors = optional(map(string))
    bucket_name      = optional(string)
    disabled         = optional(bool, false)
  }))
  default = []
}
