variable "project_name" {
  description = "The display name of the project"
  type        = string
}

variable "project_id" {
  description = "The unique identifier for the project"
  type        = string
}

variable "environment" {
  description = "The environment for the project (e.g., dev, staging, prod)"
  type        = string
}

variable "org_id" {
  description = "The organization ID to create the project under. Required if folder_id is not set"
  type        = string
  default     = null
}

variable "folder_id" {
  description = "The folder ID to create the project under. Takes precedence over org_id"
  type        = string
  default     = null
}

variable "billing_account" {
  description = "The billing account ID to associate with the project"
  type        = string
}

variable "auto_create_network" {
  description = "Create the default network upon project creation"
  type        = bool
  default     = false
}

variable "activate_apis" {
  description = "List of APIs to enable on the project"
  type        = list(string)
  default = [
    "compute.googleapis.com",
    "iam.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "serviceusage.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
    "storage.googleapis.com",
  ]
}

variable "default_service_account" {
  description = "Action to take on the default service account. Valid values are DISABLE, DELETE, or KEEP"
  type        = string
  default     = "DISABLE"

  validation {
    condition     = contains(["DISABLE", "DELETE", "KEEP"], var.default_service_account)
    error_message = "default_service_account must be one of: DISABLE, DELETE, KEEP"
  }
}

variable "project_metadata" {
  description = "Project-wide metadata to apply to compute instances"
  type        = map(string)
  default     = {}
}

variable "labels" {
  description = "Additional labels to apply to the project"
  type        = map(string)
  default     = {}
}
