variable "name" {
  description = "Name of the VNet"
  type        = string
  default     = "${{ values.name }}"
}

variable "description" {
  description = "Description of the VNet purpose"
  type        = string
  default     = "${{ values.description }}"
}

variable "environment" {
  description = "Environment (development, staging, production)"
  type        = string
  default     = "${{ values.environment }}"
}

variable "location" {
  description = "Azure Region"
  type        = string
  default     = "${{ values.location }}"
}

variable "address_space" {
  description = "CIDR block for the VNet"
  type        = string
  default     = "${{ values.addressSpace }}"
}
