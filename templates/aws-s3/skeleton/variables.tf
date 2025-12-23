variable "name" {
  description = "Name of the S3 bucket"
  type        = string
  default     = "${{ values.name }}"
}

variable "description" {
  description = "Description of the bucket purpose"
  type        = string
  default     = "${{ values.description }}"
}

variable "environment" {
  description = "Environment (development, staging, production)"
  type        = string
  default     = "${{ values.environment }}"
  
  validation {
    condition     = contains(["development", "staging", "production"], var.environment)
    error_message = "Environment must be development, staging, or production."
  }
}

variable "region" {
  description = "AWS Region"
  type        = string
  default     = "${{ values.region }}"
}

variable "org_prefix" {
  description = "Organization prefix for bucket naming"
  type        = string
  default     = "myorg"
}

variable "versioning_enabled" {
  description = "Enable versioning on the bucket"
  type        = bool
  default     = ${{ values.versioning }}
}

variable "encryption_type" {
  description = "Server-side encryption type (AES256 or aws:kms)"
  type        = string
  default     = "${{ values.encryption }}"
  
  validation {
    condition     = contains(["AES256", "aws:kms"], var.encryption_type)
    error_message = "Encryption type must be AES256 or aws:kms."
  }
}

variable "kms_key_id" {
  description = "KMS Key ID for encryption (required if encryption_type is aws:kms)"
  type        = string
  default     = null
}

variable "lifecycle_enabled" {
  description = "Enable lifecycle rules for automatic storage class transitions"
  type        = bool
  default     = ${{ values.lifecycleEnabled }}
}

variable "logging_bucket" {
  description = "Target bucket for access logging (optional)"
  type        = string
  default     = null
}
