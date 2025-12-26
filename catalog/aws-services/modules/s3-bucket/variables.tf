################################################################################
# S3 Bucket Variables
################################################################################

variable "bucket_name" {
  description = "Name of the S3 bucket"
  type        = string
}

variable "force_destroy" {
  description = "Allow bucket to be destroyed even with objects"
  type        = bool
  default     = false
}

variable "versioning_enabled" {
  description = "Enable versioning"
  type        = bool
  default     = true
}

variable "mfa_delete" {
  description = "Enable MFA delete"
  type        = bool
  default     = false
}

variable "kms_key_arn" {
  description = "KMS key ARN for encryption"
  type        = string
  default     = null
}

variable "bucket_key_enabled" {
  description = "Enable S3 bucket key for SSE-KMS"
  type        = bool
  default     = true
}

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

variable "object_ownership" {
  description = "Object ownership setting"
  type        = string
  default     = "BucketOwnerEnforced"
}

variable "acl" {
  description = "Bucket ACL"
  type        = string
  default     = null
}

variable "logging_bucket" {
  description = "Target bucket for access logging"
  type        = string
  default     = null
}

variable "logging_prefix" {
  description = "Prefix for log objects"
  type        = string
  default     = "logs/"
}

variable "lifecycle_rules" {
  description = "Lifecycle rules for the bucket"
  type        = list(any)
  default     = []
}

variable "cors_rules" {
  description = "CORS rules for the bucket"
  type        = list(any)
  default     = []
}

variable "bucket_policy" {
  description = "Bucket policy JSON"
  type        = string
  default     = null
}

variable "replication_configuration" {
  description = "Replication configuration"
  type        = any
  default     = null
}

variable "notification_configuration" {
  description = "Event notification configuration"
  type        = any
  default     = null
}

variable "website_configuration" {
  description = "Static website hosting configuration"
  type        = any
  default     = null
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
