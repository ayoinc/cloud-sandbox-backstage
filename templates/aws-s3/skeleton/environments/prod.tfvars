# =============================================================================
# AWS S3 - Production Environment Configuration
# =============================================================================
# Full production settings with security and compliance.
# - Versioning, encryption and lifecycle rules as chosen at creation
# - Access logging once a log bucket exists
# =============================================================================

# -----------------------------------------------------------------------------
# Project Configuration
# -----------------------------------------------------------------------------
name        = "${{ values.name }}"
environment = "prod"
org_prefix  = "${{ values.orgPrefix }}"
region      = "${{ values.region }}"

# -----------------------------------------------------------------------------
# Versioning
# -----------------------------------------------------------------------------
versioning_enabled = ${{ values.versioning }}

# -----------------------------------------------------------------------------
# Encryption
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
# Lifecycle Rules
# -----------------------------------------------------------------------------
lifecycle_enabled                  = ${{ values.lifecycleEnabled }}
transition_to_ia_days              = 60
transition_to_glacier_days         = 120
noncurrent_version_transition_days = 30
noncurrent_version_expiration_days = 180

# -----------------------------------------------------------------------------
# Logging
# -----------------------------------------------------------------------------
# Set to true and configure logging_bucket when a log bucket exists
logging_enabled = false
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
