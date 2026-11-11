variable "name" {
  description = "Prefix of the resource names: <project>-<environment>."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,28}[a-z0-9]$", var.name))
    error_message = "The name must be 3 to 30 lowercase letters, numbers and hyphens, starting with a letter."
  }
}
{%- if values.cloud == 'aws' %}

variable "kms_key_arn" {
  description = "ARN of the KMS key that encrypts the bucket."
  type        = string
}

variable "log_retention_days" {
  description = "Days that log objects are kept before they are deleted."
  type        = number
  default     = 90

  validation {
    condition     = var.log_retention_days >= 30
    error_message = "Logs must be kept for at least 30 days."
  }
}

variable "force_destroy" {
  description = "Allow the bucket to be destroyed while it holds objects."
  type        = bool
  default     = false
}
{%- elif values.cloud == 'azure' %}

variable "environment" {
  description = "Environment; prod is stored geo-redundantly."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group the storage account is created in."
  type        = string
}

variable "allowed_subnet_ids" {
  description = "IDs of the subnets that may reach the storage account; they need the Microsoft.Storage service endpoint."
  type        = list(string)
  default     = []
}

variable "allowed_ip_ranges" {
  description = "Public IPv4 addresses or CIDR ranges that may reach the storage account."
  type        = list(string)
  default     = []
}

variable "region" {
  description = "Region the resources are created in."
  type        = string
}

variable "log_retention_days" {
  description = "Days that log objects are kept before they are deleted."
  type        = number
  default     = 90

  validation {
    condition     = var.log_retention_days >= 30
    error_message = "Logs must be kept for at least 30 days."
  }
}

variable "tags" {
  description = "Tags recorded on every resource."
  type        = map(string)
  default     = {}
}
{%- else %}

variable "kms_key_id" {
  description = "ID of the Cloud KMS key that encrypts the bucket."
  type        = string
}

variable "region" {
  description = "Region the resources are created in."
  type        = string
}

variable "log_retention_days" {
  description = "Days that log objects are kept before they are deleted."
  type        = number
  default     = 90

  validation {
    condition     = var.log_retention_days >= 30
    error_message = "Logs must be kept for at least 30 days."
  }
}

variable "force_destroy" {
  description = "Allow the bucket to be destroyed while it holds objects."
  type        = bool
  default     = false
}
{%- endif %}
