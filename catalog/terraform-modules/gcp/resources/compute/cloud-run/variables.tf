variable "project_name" {
  description = "The name of the project"
  type        = string
}

variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "environment" {
  description = "The deployment environment (e.g., dev, staging, prod)"
  type        = string
}

variable "region" {
  description = "The GCP region to deploy the Cloud Run service"
  type        = string
}

variable "service_name" {
  description = "The name of the Cloud Run service"
  type        = string
}

variable "description" {
  description = "Description of the Cloud Run service"
  type        = string
  default     = null
}

variable "image" {
  description = "The container image to deploy"
  type        = string
}

variable "cpu" {
  description = "CPU allocation for the container"
  type        = string
  default     = "1"
}

variable "memory" {
  description = "Memory allocation for the container"
  type        = string
  default     = "512Mi"
}

variable "port" {
  description = "The port the container listens on"
  type        = number
  default     = 8080
}

variable "min_instance_count" {
  description = "Minimum number of instances"
  type        = number
  default     = 0
}

variable "max_instance_count" {
  description = "Maximum number of instances"
  type        = number
  default     = 100
}

variable "timeout_seconds" {
  description = "Request timeout in seconds"
  type        = number
  default     = 300
}

variable "service_account_email" {
  description = "The service account email to use for the Cloud Run service"
  type        = string
  default     = null
}

variable "env_vars" {
  description = "Environment variables to set in the container"
  type        = map(string)
  default     = {}
}

variable "secrets" {
  description = "Secret environment variables from Secret Manager"
  type = list(object({
    env_name    = string
    secret_name = string
    version     = string
  }))
  default = []
}

variable "volumes" {
  description = "Volume configurations for the Cloud Run service"
  type = list(object({
    name       = string
    mount_path = string
    secret = optional(object({
      secret_name = string
      items = list(object({
        path    = string
        version = string
      }))
    }))
    cloud_sql_instance = optional(object({
      instances = list(string)
    }))
    gcs = optional(object({
      bucket    = string
      read_only = optional(bool, true)
    }))
  }))
  default = []
}

variable "vpc_access_connector" {
  description = "VPC Access connector name for the Cloud Run service"
  type        = string
  default     = null
}

variable "vpc_access_egress" {
  description = "VPC egress setting"
  type        = string
  default     = "PRIVATE_RANGES_ONLY"

  validation {
    condition     = contains(["ALL_TRAFFIC", "PRIVATE_RANGES_ONLY"], var.vpc_access_egress)
    error_message = "vpc_access_egress must be one of: ALL_TRAFFIC, PRIVATE_RANGES_ONLY"
  }
}

variable "ingress" {
  description = "Ingress traffic setting"
  type        = string
  default     = "INGRESS_TRAFFIC_ALL"

  validation {
    condition     = contains(["INGRESS_TRAFFIC_ALL", "INGRESS_TRAFFIC_INTERNAL_ONLY", "INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER"], var.ingress)
    error_message = "ingress must be one of: INGRESS_TRAFFIC_ALL, INGRESS_TRAFFIC_INTERNAL_ONLY, INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER"
  }
}

variable "allow_unauthenticated" {
  description = "Whether to allow unauthenticated access to the service"
  type        = bool
  default     = false
}

variable "traffic_allocations" {
  description = "Traffic allocation configuration for revisions"
  type = list(object({
    revision = optional(string)
    percent  = number
    type     = optional(string)
  }))
  default = []
}

variable "labels" {
  description = "Additional labels to apply to the Cloud Run service"
  type        = map(string)
  default     = {}
}
