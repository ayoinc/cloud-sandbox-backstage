# =============================================================================
# Production Environment
# =============================================================================
# Tiering to colder classes and long retention of versions.
# =============================================================================

name        = "${{ values.name }}"
environment = "prod"
project_id  = "${{ values.gcpProject }}"
region      = "${{ values.region }}"
owner       = "${{ values.owner }}"

{% set fromForm = values.envName == 'prod' -%}
# Bucket{% if fromForm %} (from the template form){% endif %}
location      = "${{ values.bucketLocation }}"
storage_class = "${{ values.storageClass if fromForm else 'STANDARD' }}"
force_destroy = false

# Data protection
versioning_enabled         = ${{ 'true' if values.versioning else 'false' }}
soft_delete_retention_days = 30

# Lifecycle: object age in days; null switches a step off
nearline_after_days               = 30
coldline_after_days               = 90
archive_after_days                = null
expire_after_days                 = null
noncurrent_versions_to_keep       = 5
noncurrent_version_retention_days = 180

# Encryption: a key created here, or an existing one (projects/.../cryptoKeys/...)
customer_managed_encryption = ${{ 'true' if values.encryption == 'customer-managed' else 'false' }}
kms_key_name                = null
kms_key_rotation_period     = "7776000s"

# Access: IAM members such as "group:team@domain" or "serviceAccount:name@project.iam.gserviceaccount.com"
object_viewers = []
object_users   = []
object_admins  = []

enable_apis = true

labels = {
  cost-center = "production"
  criticality = "high"
}
