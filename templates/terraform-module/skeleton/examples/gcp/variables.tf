variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "example"
}

variable "gcp_project_id" {
  description = "GCP project ID"
  type        = string
}

variable "gcp_region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}

variable "gcp_zone" {
  description = "GCP zone"
  type        = string
  default     = "us-central1-a"
}

variable "gcp_network_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.2.0.0/16"
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}
