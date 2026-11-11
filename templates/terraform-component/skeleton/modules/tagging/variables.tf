variable "component_name" {
  description = "Name of the component."
  type        = string
}

variable "component_type" {
  description = "platform for shared infrastructure, application for application-specific resources."
  type        = string

  validation {
    condition     = contains(["platform", "application"], var.component_type)
    error_message = "component_type must be platform or application."
  }
}

variable "project" {
  description = "Project the component belongs to."
  type        = string
}

variable "environment" {
  description = "Deployment environment: development, staging or production."
  type        = string
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

variable "additional_tags" {
  description = "Tags added to the standard set."
  type        = map(string)
  default     = {}
}
