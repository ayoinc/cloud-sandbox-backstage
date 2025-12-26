# GCP Module Variables

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "common_labels" {
  description = "Common labels for all resources"
  type        = map(string)
}

# Networking
variable "enable_networking" {
  description = "Enable VPC and networking"
  type        = bool
  default     = true
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

# Kubernetes
variable "enable_kubernetes" {
  description = "Enable GKE cluster"
  type        = bool
  default     = false
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.28"
}

variable "node_instance_type" {
  description = "Machine type for nodes"
  type        = string
  default     = "e2-standard-2"
}

variable "enable_autoscaling" {
  description = "Enable cluster autoscaling"
  type        = bool
  default     = true
}

variable "min_nodes" {
  description = "Minimum number of nodes"
  type        = number
  default     = 2
}

variable "max_nodes" {
  description = "Maximum number of nodes"
  type        = number
  default     = 10
}

# Database
variable "enable_database" {
  description = "Enable Cloud SQL database"
  type        = bool
  default     = false
}

variable "database_password" {
  description = "Database password"
  type        = string
  sensitive   = true
  default     = ""
}

# Storage
variable "enable_storage" {
  description = "Enable Cloud Storage"
  type        = bool
  default     = false
}

variable "enable_cdn" {
  description = "Enable Cloud CDN"
  type        = bool
  default     = false
}

# Security
variable "enable_kms" {
  description = "Enable Cloud KMS"
  type        = bool
  default     = false
}

variable "enable_secret_manager" {
  description = "Enable Secret Manager"
  type        = bool
  default     = false
}

variable "enable_security_rules" {
  description = "Enable firewall rules"
  type        = bool
  default     = true
}

# Monitoring
variable "enable_monitoring" {
  description = "Enable Cloud Monitoring"
  type        = bool
  default     = true
}

variable "enable_alerting" {
  description = "Enable alerting"
  type        = bool
  default     = false
}

variable "log_retention_days" {
  description = "Log retention in days"
  type        = number
  default     = 30
}
