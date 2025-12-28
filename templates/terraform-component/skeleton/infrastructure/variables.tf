variable "environment" {
  description = "Deployment environment (dev, staging, prod)"
  type        = string
}

variable "region" {
  description = "Default region for resources"
  type        = string
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
  default     = null
}

variable "tags" {
  description = "Default tags for all resources"
  type        = map(string)
  default     = {}
}

# Module-specific variables will be added based on resources used