variable "name" {
  description = "Project name used in resource names"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "resource_group_id" {
  description = "Resource group the budget and the tag policies apply to"
  type        = string
}

variable "monthly_budget" {
  description = "Monthly budget of the resource group, in the billing currency"
  type        = number
}

variable "budget_contact_roles" {
  description = "Roles on the resource group whose members receive budget alerts"
  type        = list(string)
  default     = ["Owner", "Contributor"]
}

variable "required_tags" {
  description = "Tags every resource in the resource group should carry"
  type        = list(string)
  default     = []
}
