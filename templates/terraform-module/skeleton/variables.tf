# Core variables
variable "name" {
  description = "Name prefix for resources"
  type        = string
  validation {
    condition     = can(regex("^[a-zA-Z0-9-]+$", var.name))
    error_message = "Name must contain only alphanumeric characters and hyphens."
  }
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

{%- if values.provider == 'aws' %}
variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}
{%- elif values.provider == 'azure' %}
variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "East US"
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}
{%- elif values.provider == 'gcp' %}
variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region for resources"
  type        = string
  default     = "us-central1"
}
{%- endif %}

# Tagging and labeling
variable "default_tags" {
  description = "Default tags to apply to all resources"
  type        = map(string)
  default = {
    ManagedBy   = "terraform"
    Module      = "${{ values.name }}"
    Environment = "dev"
  }
}

{%- if 'compute' in values.resource_type %}
# Compute-specific variables
variable "instance_type" {
  description = "Instance type for compute resources"
  type        = string
  {%- if values.provider == 'aws' %}
  default     = "t3.micro"
  {%- elif values.provider == 'azure' %}
  default     = "Standard_B1s"
  {%- elif values.provider == 'gcp' %}
  default     = "e2-micro"
  {%- endif %}
}

variable "min_size" {
  description = "Minimum number of instances"
  type        = number
  default     = 1
  
  validation {
    condition     = var.min_size >= 0
    error_message = "Minimum size must be non-negative."
  }
}

variable "max_size" {
  description = "Maximum number of instances"
  type        = number
  default     = 3
  
  validation {
    condition     = var.max_size >= var.min_size
    error_message = "Maximum size must be greater than or equal to minimum size."
  }
}
{%- endif %}
{%- if 'network' in values.resource_type %}
# Network-specific variables
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  {%- if values.provider == 'aws' %}
  default     = "10.0.0.0/16"
  {%- elif values.provider == 'azure' %}
  default     = "10.0.0.0/16"
  {%- elif values.provider == 'gcp' %}
  default     = "10.0.0.0/16"
  {%- endif %}
  
  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR must be a valid IPv4 CIDR block."
  }
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = []
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for private subnets"
  type        = bool
  default     = true
}
{%- endif %}
{%- if 'storage' in values.resource_type %}
# Storage-specific variables
variable "storage_encrypted" {
  description = "Enable encryption for storage"
  type        = bool
  default     = true
}

variable "backup_retention_days" {
  description = "Number of days to retain backups"
  type        = number
  default     = 7
  
  validation {
    condition     = var.backup_retention_days >= 1 && var.backup_retention_days <= 35
    error_message = "Backup retention must be between 1 and 35 days."
  }
}
{%- endif %}
{%- if 'database' in values.resource_type %}
# Database-specific variables
variable "engine_version" {
  description = "Database engine version"
  type        = string
  {%- if values.provider == 'aws' %}
  default     = "15.3"  # PostgreSQL
  {%- elif values.provider == 'azure' %}
  default     = "15"
  {%- elif values.provider == 'gcp' %}
  default     = "POSTGRES_15"
  {%- endif %}
}

variable "instance_class" {
  description = "Database instance class"
  type        = string
  {%- if values.provider == 'aws' %}
  default     = "db.t3.micro"
  {%- elif values.provider == 'azure' %}
  default     = "GP_Gen5_2"
  {%- elif values.provider == 'gcp' %}
  default     = "db-f1-micro"
  {%- endif %}
}

variable "allocated_storage" {
  description = "Allocated storage in GB"
  type        = number
  default     = 20
  
  validation {
    condition     = var.allocated_storage >= 20
    error_message = "Allocated storage must be at least 20 GB."
  }
}

variable "multi_az" {
  description = "Enable Multi-AZ deployment"
  type        = bool
  default     = false
}
{%- endif %}

# Security variables
{%- if values.enable_compliance %}
variable "enable_encryption" {
  description = "Enable encryption at rest"
  type        = bool
  default     = true
}

variable "enable_backup" {
  description = "Enable automated backups"
  type        = bool
  default     = true
}

variable "deletion_protection" {
  description = "Enable deletion protection"
  type        = bool
  default     = true
}
{%- endif %}

# Monitoring and logging
variable "enable_monitoring" {
  description = "Enable detailed monitoring"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "Log retention period in days"
  type        = number
  default     = 14
  
  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653], var.log_retention_days)
    error_message = "Log retention days must be a valid CloudWatch Logs retention period."
  }
}
