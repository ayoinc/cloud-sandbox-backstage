################################################################################
# GCP Cloud Storage Variables
################################################################################

variable "bucket_name" {
  description = "Name of the Cloud Storage bucket"
  type        = string
}

variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "location" {
  description = "Bucket location (region or multi-region)"
  type        = string
  default     = "US"
}

variable "storage_class" {
  description = "Storage class (STANDARD, NEARLINE, COLDLINE, ARCHIVE)"
  type        = string
  default     = "STANDARD"
}

variable "force_destroy" {
  description = "Allow bucket to be destroyed with objects"
  type        = bool
  default     = false
}

variable "uniform_bucket_level_access" {
  description = "Enable uniform bucket-level access"
  type        = bool
  default     = true
}

variable "public_access_prevention" {
  description = "Public access prevention (inherited or enforced)"
  type        = string
  default     = "enforced"
}

variable "versioning_enabled" {
  description = "Enable object versioning"
  type        = bool
  default     = true
}

variable "kms_key_name" {
  description = "Cloud KMS key name for encryption"
  type        = string
  default     = null
}

variable "lifecycle_rules" {
  description = "Lifecycle rules for the bucket"
  type        = list(any)
  default     = []
}

variable "cors_configurations" {
  description = "CORS configurations"
  type        = list(any)
  default     = []
}

variable "website_config" {
  description = "Static website hosting configuration"
  type        = any
  default     = null
}

variable "retention_policy" {
  description = "Retention policy configuration"
  type        = any
  default     = null
}

variable "logging_config" {
  description = "Access logging configuration"
  type        = any
  default     = null
}

variable "autoclass_enabled" {
  description = "Enable Autoclass for automatic storage class management"
  type        = bool
  default     = false
}

variable "iam_bindings" {
  description = "IAM bindings for the bucket"
  type        = map(any)
  default     = {}
}

variable "default_object_acls" {
  description = "Default object ACLs (for non-uniform access)"
  type        = map(any)
  default     = {}
}

variable "notifications" {
  description = "Pub/Sub notifications configuration"
  type        = map(any)
  default     = {}
}

variable "labels" {
  description = "Labels to apply to the bucket"
  type        = map(string)
  default     = {}
}
