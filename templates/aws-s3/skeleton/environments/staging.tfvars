# =============================================================================
# AWS S3 - Staging Environment Configuration
# =============================================================================
# Production-like settings for testing.
# - Versioning enabled
# - AES256 encryption
# - Basic lifecycle rules
# - Access logging optional
# =============================================================================

# -----------------------------------------------------------------------------
# Project Configuration
# -----------------------------------------------------------------------------
name        = "${{ values.name }}"
environment = "staging"
org_prefix  = "${{ values.orgPrefix }}"

# -----------------------------------------------------------------------------
# Versioning (enabled for staging)
# -----------------------------------------------------------------------------
versioning_enabled = true

# -----------------------------------------------------------------------------
# Encryption
# -----------------------------------------------------------------------------
encryption_type = "AES256"

# -----------------------------------------------------------------------------
# Public Access Block (always enabled)
# -----------------------------------------------------------------------------
block_public_acls       = true
block_public_policy     = true
ignore_public_acls      = true
restrict_public_buckets = true

# -----------------------------------------------------------------------------
# Lifecycle Rules (enabled with moderate settings)
# -----------------------------------------------------------------------------
lifecycle_enabled                  = true
transition_to_ia_days              = 90
transition_to_glacier_days         = 180
noncurrent_version_transition_days = 30
noncurrent_version_expiration_days = 365

# -----------------------------------------------------------------------------
# Logging (optional for staging)
# -----------------------------------------------------------------------------
logging_enabled = false

# -----------------------------------------------------------------------------
# Object Ownership
# -----------------------------------------------------------------------------
object_ownership = "BucketOwnerEnforced"

# -----------------------------------------------------------------------------
# Tags
# -----------------------------------------------------------------------------
tags = {
  Project     = "${{ values.name }}"
  Environment = "staging"
  Owner       = "${{ values.owner }}"
  CostCenter  = "staging"
  ManagedBy   = "terraform"
}
