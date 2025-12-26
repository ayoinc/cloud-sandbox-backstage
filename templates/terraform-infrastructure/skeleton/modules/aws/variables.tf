# AWS Module Variables

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

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
}

# Kubernetes
variable "enable_kubernetes" {
  description = "Enable EKS cluster"
  type        = bool
  default     = false
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.28"
}

variable "node_instance_type" {
  description = "Instance type for nodes"
  type        = string
  default     = "t3.medium"
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
  description = "Enable RDS database"
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
  description = "Enable S3 storage"
  type        = bool
  default     = false
}

variable "enable_cdn" {
  description = "Enable CloudFront CDN"
  type        = bool
  default     = false
}

# Security
variable "enable_kms" {
  description = "Enable KMS encryption"
  type        = bool
  default     = false
}

variable "enable_secrets_manager" {
  description = "Enable Secrets Manager"
  type        = bool
  default     = false
}

variable "enable_security_group_rules" {
  description = "Enable security group rules"
  type        = bool
  default     = true
}

variable "enable_waf" {
  description = "Enable WAF"
  type        = bool
  default     = false
}

# Monitoring
variable "enable_monitoring" {
  description = "Enable CloudWatch monitoring"
  type        = bool
  default     = true
}

variable "enable_alerting" {
  description = "Enable CloudWatch alerting"
  type        = bool
  default     = false
}

variable "log_retention_days" {
  description = "Log retention in days"
  type        = number
  default     = 30
}

# Compliance
variable "compliance_framework" {
  description = "Compliance framework"
  type        = string
  default     = "none"
}

variable "enable_backup" {
  description = "Enable backup"
  type        = bool
  default     = true
}
