variable "name" {
  description = "Name of the Cloud Run service"
  type        = string
  default     = "${{ values.name }}"
}

variable "description" {
  description = "Description of the service purpose"
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

variable "memory" {
  description = "Memory allocation"
  type        = string
  default     = "${{ values.memory }}"
}

variable "cpu" {
  description = "CPU allocation"
  type        = string
  default     = "${{ values.cpu }}"
}

variable "max_instances" {
  description = "Maximum number of instances"
  type        = number
  default     = ${{ values.maxInstances }}
}

variable "allow_unauthenticated" {
  description = "Allow unauthenticated invocations"
  type        = bool
  default     = ${{ values.allowUnauthenticated }}
}
