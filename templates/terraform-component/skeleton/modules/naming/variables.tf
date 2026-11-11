variable "convention" {
  description = "Naming convention: enterprise (company-project-env-type-nnn), team (team-project-type-env-nnn) or project (project-type-env-nnn)."
  type        = string

  validation {
    condition     = contains(["enterprise", "team", "project"], var.convention)
    error_message = "convention must be enterprise, team or project."
  }
}

variable "company" {
  description = "Company segment of enterprise names."
  type        = string
}

variable "team" {
  description = "Team segment of team names."
  type        = string
}

variable "project" {
  description = "Project segment of every name."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project))
    error_message = "project may contain only lowercase letters, digits and hyphens."
  }
}

variable "environment" {
  description = "Short environment name: dev, stg or prod."
  type        = string

  validation {
    condition     = contains(["dev", "stg", "prod"], var.environment)
    error_message = "environment must be dev, stg or prod."
  }
}

variable "instance" {
  description = "Three-digit instance number that ends every name."
  type        = string
  default     = "001"

  validation {
    condition     = can(regex("^[0-9]{3}$", var.instance))
    error_message = "instance must be a three-digit number."
  }
}

variable "unique_suffix" {
  description = "Short lowercase alphanumeric string appended to names that must be unique across the whole cloud, such as buckets."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]{4,8}$", var.unique_suffix))
    error_message = "unique_suffix must be 4 to 8 lowercase letters or digits."
  }
}

variable "resource_types" {
  description = "Short resource type codes to build names for, for example [\"st\", \"vnet\"]."
  type        = set(string)

  validation {
    condition     = alltrue([for t in var.resource_types : can(regex("^[a-z0-9]{1,8}$", t))])
    error_message = "Each resource type code must be 1 to 8 lowercase letters or digits."
  }
}
