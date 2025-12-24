# =============================================================================
# AWS S3 - Root Variables
# =============================================================================
# Input variables for the root module. Values are provided via tfvars files
# in the environments/ directory.
# =============================================================================

# -----------------------------------------------------------------------------
# Project Configuration
# -----------------------------------------------------------------------------
variable "name" {
  description = "Name of the S3 bucket"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "region" {
  description = "AWS Region for deployment"
  type        = string
  default     = "us-east-1"
}

variable "org_prefix" {
  description = "Organization prefix for bucket naming (must be globally unique)"
  type        = string
  default     = "myorg"
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
  description = "Object ownership setting"
  type        = string
  default     = "BucketOwnerEnforced"
}

# -----------------------------------------------------------------------------
# Tags
# -----------------------------------------------------------------------------
variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
