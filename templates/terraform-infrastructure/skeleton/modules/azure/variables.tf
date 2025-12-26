# Azure Module Variables

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "East US"
}

# Networking
variable "enable_networking" {
  description = "Enable VNet and networking"
  type        = bool
  default     = true
}

variable "vnet_cidr" {
  description = "CIDR block for VNet"
  type        = string
  default     = "10.1.0.0/16"
}

# Kubernetes
variable "enable_kubernetes" {
  description = "Enable AKS cluster"
  type        = bool
  default     = false
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.28"
}

variable "node_instance_type" {
  description = "VM size for nodes"
  type        = string
  default     = "Standard_D2s_v3"
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
  description = "Enable PostgreSQL database"
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
  description = "Enable Azure Storage"
  type        = bool
  default     = false
}

variable "enable_cdn" {
  description = "Enable Azure CDN"
  type        = bool
  default     = false
}

# Security
variable "enable_key_vault" {
  description = "Enable Key Vault"
  type        = bool
  default     = false
}

variable "enable_security_group_rules" {
  description = "Enable NSG rules"
  type        = bool
  default     = true
}

# Monitoring
variable "enable_monitoring" {
  description = "Enable Azure Monitor"
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
