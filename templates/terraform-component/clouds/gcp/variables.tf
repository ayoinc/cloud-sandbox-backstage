variable "component_name" {
  description = "Name of the component."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.component_name))
    error_message = "component_name may contain only lowercase letters, digits and hyphens."
  }
}

variable "component_type" {
  description = "platform for shared infrastructure, application for application-specific resources."
  type        = string
}

variable "project_name" {
  description = "Project name used in resource names."
  type        = string
}

variable "environment" {
  description = "Deployment environment: development, staging or production."
  type        = string

  validation {
    condition     = contains(["development", "staging", "production"], var.environment)
    error_message = "environment must be development, staging or production."
  }
}

variable "business_unit" {
  description = "Business unit that owns the component."
  type        = string
}

variable "cost_center" {
  description = "Cost center the component is billed to."
  type        = string
}

variable "application_id" {
  description = "Application identifier from the service catalog. Empty when there is none."
  type        = string
  default     = ""
}

variable "owner" {
  description = "Owner of the component in the software catalog."
  type        = string
}

variable "company" {
  description = "Company segment of names in the enterprise naming convention."
  type        = string
}

variable "naming_convention" {
  description = "Naming convention: enterprise, team or project."
  type        = string
  default     = "enterprise"
}

variable "region" {
  description = "Google Cloud region the component is deployed to."
  type        = string
}

variable "additional_tags" {
  description = "Tags added to the standard set."
  type        = map(string)
  default     = {}
}

variable "create_resource_container" {
  description = "Create a new Google Cloud project for this component. When false, project_id names an existing one."
  type        = bool
  default     = true
}

variable "project_id" {
  description = "ID of an existing project to deploy into when create_resource_container is false."
  type        = string
  default     = ""
}

variable "billing_account" {
  description = "Billing account ID of the new project. Required when create_resource_container is true."
  type        = string
  default     = ""
}

variable "folder_id" {
  description = "Folder the new project is created in, for example folders/123456789. Required when create_resource_container is true."
  type        = string
  default     = ""
}
