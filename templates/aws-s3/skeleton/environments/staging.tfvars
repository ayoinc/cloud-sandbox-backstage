# =============================================================================
# AWS S3 - Staging Environment Configuration
# =============================================================================
# Production-like settings for testing.
# - Versioning, encryption and lifecycle rules as chosen at creation
# - Access logging optional
# =============================================================================

# -----------------------------------------------------------------------------
# Project Configuration
# -----------------------------------------------------------------------------
name        = "${{ values.name }}"
environment = "staging"
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
