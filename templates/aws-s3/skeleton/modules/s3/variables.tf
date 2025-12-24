# =============================================================================
# AWS S3 Module - Variables
# =============================================================================
# Input variables for the S3 module. These are passed from the root module.
# No Jinja2 template values - pure Terraform.
# =============================================================================

# -----------------------------------------------------------------------------
# Required Variables
# -----------------------------------------------------------------------------
variable "name" {
  description = "Name of the S3 bucket (will be combined with org_prefix and environment)"
  type        = string

  validation {
    condition     = length(var.name) > 0 && length(var.name) <= 63
    error_message = "Bucket name component must be between 1 and 63 characters"
  }
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod", "production", "development"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod, production, development"
  }
}

variable "org_prefix" {
  description = "Organization prefix for bucket naming (must be globally unique)"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]*[a-z0-9]$", var.org_prefix)) || length(var.org_prefix) == 1
    error_message = "Org prefix must be lowercase alphanumeric with optional hyphens"
  }
}

# -----------------------------------------------------------------------------
# Versioning Configuration
# -----------------------------------------------------------------------------
variable "versioning_enabled" {
  description = "Enable versioning on the bucket"
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------
# Encryption Configuration
# -----------------------------------------------------------------------------
variable "encryption_type" {
  description = "Server-side encryption type (AES256 or aws:kms)"
  type        = string
  default     = "AES256"

  validation {
    condition     = contains(["AES256", "aws:kms"], var.encryption_type)
    error_message = "Encryption type must be AES256 or aws:kms"
  }
}

variable "kms_key_id" {
  description = "KMS Key ID for encryption (required if encryption_type is aws:kms)"
  type        = string
  default     = null
}

# -----------------------------------------------------------------------------
# Public Access Configuration
# -----------------------------------------------------------------------------
variable "block_public_acls" {
  description = "Block public ACLs"
  type        = bool
  default     = true
}

variable "block_public_policy" {
  description = "Block public bucket policies"
  type        = bool
  default     = true
}

variable "ignore_public_acls" {
  description = "Ignore public ACLs"
  type        = bool
  default     = true
}

variable "restrict_public_buckets" {
  description = "Restrict public bucket policies"
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------
# Lifecycle Configuration
# -----------------------------------------------------------------------------
variable "lifecycle_enabled" {
  description = "Enable lifecycle rules for automatic storage class transitions"
  type        = bool
  default     = false
}

variable "lifecycle_prefix" {
  description = "Prefix filter for lifecycle rules"
  type        = string
  default     = ""
}

variable "transition_to_ia_days" {
  description = "Days after which to transition objects to STANDARD_IA"
  type        = number
  default     = 90
}

variable "transition_to_glacier_days" {
  description = "Days after which to transition objects to GLACIER"
  type        = number
  default     = 180
}

variable "noncurrent_version_transition_days" {
  description = "Days after which to transition non-current versions to STANDARD_IA"
  type        = number
  default     = 30
}

variable "noncurrent_version_expiration_days" {
  description = "Days after which to expire non-current versions"
  type        = number
  default     = 365
}

variable "expiration_days" {
  description = "Days after which to expire objects (0 to disable)"
  type        = number
  default     = 0
}

# -----------------------------------------------------------------------------
# Logging Configuration
# -----------------------------------------------------------------------------
variable "logging_enabled" {
  description = "Enable access logging"
  type        = bool
  default     = false
}

variable "logging_bucket" {
  description = "Target bucket for access logging"
  type        = string
  default     = null
}

variable "logging_prefix" {
  description = "Prefix for log objects"
  type        = string
  default     = null
}

# -----------------------------------------------------------------------------
# CORS Configuration
# -----------------------------------------------------------------------------
variable "cors_rules" {
  description = "List of CORS rules for the bucket"
  type = list(object({
    allowed_headers = list(string)
    allowed_methods = list(string)
    allowed_origins = list(string)
    expose_headers  = list(string)
    max_age_seconds = number
  }))
  default = []
}

# -----------------------------------------------------------------------------
# Bucket Policy
# -----------------------------------------------------------------------------
variable "bucket_policy" {
  description = "JSON bucket policy document"
  type        = string
  default     = null
}

# -----------------------------------------------------------------------------
# Object Ownership
# -----------------------------------------------------------------------------
variable "object_ownership" {
  description = "Object ownership setting (BucketOwnerPreferred, ObjectWriter, BucketOwnerEnforced)"
  type        = string
  default     = "BucketOwnerEnforced"

  validation {
    condition     = contains(["BucketOwnerPreferred", "ObjectWriter", "BucketOwnerEnforced"], var.object_ownership)
    error_message = "Object ownership must be BucketOwnerPreferred, ObjectWriter, or BucketOwnerEnforced"
  }
}

# -----------------------------------------------------------------------------
# Tags
# -----------------------------------------------------------------------------
variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
