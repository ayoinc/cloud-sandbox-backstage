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

variable "instance_name" {
  description = "The name of the Spanner instance"
  type        = string
}

variable "display_name" {
  description = "The display name of the Spanner instance"
  type        = string
  default     = null
}

variable "config" {
  description = "The instance configuration (e.g., regional-us-central1, nam3)"
  type        = string
}

variable "num_nodes" {
  description = "The number of nodes allocated to the instance. Use this OR processing_units"
  type        = number
  default     = null
}

variable "processing_units" {
  description = "The number of processing units allocated to the instance. Use this OR num_nodes"
  type        = number
  default     = null
}

variable "databases" {
  description = "List of databases to create in the Spanner instance"
  type = list(object({
    name                     = string
    ddl                      = optional(list(string), [])
    deletion_protection      = optional(bool, true)
    version_retention_period = optional(string, "1h")
    enable_drop_protection   = optional(bool, false)
  }))
  default = []
}

variable "instance_iam_bindings" {
  description = "IAM bindings for the Spanner instance"
  type = list(object({
    role    = string
    members = list(string)
  }))
  default = []
}

variable "database_iam_bindings" {
  description = "IAM bindings for Spanner databases"
  type = list(object({
    database = string
    role     = string
    members  = list(string)
  }))
  default = []
}

variable "labels" {
  description = "Labels to apply to the Spanner instance"
  type        = map(string)
  default     = {}
}
