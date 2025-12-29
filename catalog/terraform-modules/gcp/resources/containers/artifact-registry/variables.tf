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

variable "region" {
  description = "The GCP region for the repository"
  type        = string
}

variable "repository_id" {
  description = "The ID of the repository"
  type        = string
}

variable "description" {
  description = "The description of the repository"
  type        = string
  default     = null
}

variable "format" {
  description = "The format of the repository (DOCKER, MAVEN, NPM, PYTHON, APT, YUM, GO)"
  type        = string
  default     = "DOCKER"

  validation {
    condition     = contains(["DOCKER", "MAVEN", "NPM", "PYTHON", "APT", "YUM", "GO"], var.format)
    error_message = "Format must be one of: DOCKER, MAVEN, NPM, PYTHON, APT, YUM, GO."
  }
}

variable "mode" {
  description = "The mode of the repository (STANDARD_REPOSITORY, VIRTUAL_REPOSITORY, REMOTE_REPOSITORY)"
  type        = string
  default     = "STANDARD_REPOSITORY"

  validation {
    condition     = contains(["STANDARD_REPOSITORY", "VIRTUAL_REPOSITORY", "REMOTE_REPOSITORY"], var.mode)
    error_message = "Mode must be one of: STANDARD_REPOSITORY, VIRTUAL_REPOSITORY, REMOTE_REPOSITORY."
  }
}

variable "kms_key_name" {
  description = "The Cloud KMS key name for CMEK encryption"
  type        = string
  default     = null
}

variable "cleanup_policy_dry_run" {
  description = "If true, cleanup policies will only log what would be deleted without actually deleting"
  type        = bool
  default     = false
}

variable "cleanup_policies" {
  description = "List of cleanup policies for the repository"
  type = list(object({
    id     = string
    action = optional(string, "DELETE")
    condition = optional(object({
      tag_state             = optional(string)
      tag_prefixes          = optional(list(string))
      version_name_prefixes = optional(list(string))
      package_name_prefixes = optional(list(string))
      older_than            = optional(string)
      newer_than            = optional(string)
    }))
    most_recent_versions = optional(object({
      package_name_prefixes = optional(list(string))
      keep_count            = optional(number)
    }))
  }))
  default = []
}

variable "iam_members" {
  description = "List of IAM members to grant access to the repository"
  type = list(object({
    role   = string
    member = string
  }))
  default = []
}

variable "labels" {
  description = "Additional labels to apply to the repository"
  type        = map(string)
  default     = {}
}
