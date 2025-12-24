# =============================================================================
# AWS S3 - Production Environment Configuration
# =============================================================================
# Full production settings with security and compliance.
# - Versioning enabled
# - KMS encryption (optional, can use AES256)
# - Full lifecycle rules
# - Access logging enabled
# =============================================================================

# -----------------------------------------------------------------------------
# Project Configuration
# -----------------------------------------------------------------------------
name        = "${{ values.name }}"
environment = "prod"
org_prefix  = "${{ values.orgPrefix }}"

# -----------------------------------------------------------------------------
# Versioning (REQUIRED for production)
# -----------------------------------------------------------------------------
versioning_enabled = true

# -----------------------------------------------------------------------------
# Encryption (KMS recommended for production)
# -----------------------------------------------------------------------------
encryption_type = "${{ values.encryption }}"
# kms_key_id    = "arn:aws:kms:region:account:key/key-id"  # Uncomment if using KMS

# -----------------------------------------------------------------------------
# Public Access Block (always enabled)
# -----------------------------------------------------------------------------
block_public_acls       = true
block_public_policy     = true
ignore_public_acls      = true
restrict_public_buckets = true

# -----------------------------------------------------------------------------
# Lifecycle Rules (full production settings)
# -----------------------------------------------------------------------------
lifecycle_enabled                  = true
transition_to_ia_days              = 60
transition_to_glacier_days         = 120
noncurrent_version_transition_days = 30
noncurrent_version_expiration_days = 180

# -----------------------------------------------------------------------------
# Logging (enabled for production compliance)
# -----------------------------------------------------------------------------
logging_enabled = false  # Set to true and configure logging_bucket when available
# logging_bucket  = "my-logging-bucket"

# -----------------------------------------------------------------------------
# Object Ownership
# -----------------------------------------------------------------------------
object_ownership = "BucketOwnerEnforced"

# -----------------------------------------------------------------------------
# Tags
# -----------------------------------------------------------------------------
tags = {
  Project     = "${{ values.name }}"
  Environment = "prod"
  Owner       = "${{ values.owner }}"
  CostCenter  = "production"
  ManagedBy   = "terraform"
  Compliance  = "required"
}
