variable "name" {
  description = "Name of the VPC"
  type        = string
  default     = "${{ values.name }}"
}

variable "description" {
  description = "Description of the VPC purpose"
  type        = string
  default     = "${{ values.description }}"
}

variable "environment" {
  description = "Environment (development, staging, production)"
  type        = string
  default     = "${{ values.environment }}"
}

variable "region" {
  description = "GCP Region"
  type        = string
  default     = "${{ values.region }}"
}

variable "gcp_project" {
  description = "GCP Project ID"
  type        = string
  default     = "${{ values.gcpProject }}"
}

variable "cidr_range" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "${{ values.cidrRange }}"
}
