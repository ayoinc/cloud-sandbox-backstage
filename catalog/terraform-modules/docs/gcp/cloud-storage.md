# GCP Cloud Storage Module

Creates a secure Cloud Storage bucket with versioning, lifecycle policies, encryption, and access controls following Google Cloud best practices.

## Features

- Uniform bucket-level access
- Public access prevention
- Object versioning
- Lifecycle management
- Customer-managed encryption keys (CMEK)
- Access logging
- Retention policies
- CORS configuration
- IAM bindings

## Usage

### Basic Usage

```hcl
module "storage" {
  source = "../../../gcp/resources/storage/cloud-storage"

  project_id  = "my-project"
  name        = "myapp-data"
  environment = "prod"
  location    = "US"
}
```

### Production Configuration

```hcl
module "storage" {
  source = "../../../gcp/resources/storage/cloud-storage"

  project_id  = "my-project"
  name        = "myapp-data"
  environment = "prod"
  location    = "US"

  storage_class       = "STANDARD"
  versioning_enabled  = true

  # Security
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"
  encryption_key              = google_kms_crypto_key.storage.id

  # Lifecycle management
  lifecycle_rules = [
    {
      action = {
        type          = "SetStorageClass"
        storage_class = "NEARLINE"
      }
      condition = {
        age = 30
      }
    },
    {
      action = {
        type          = "SetStorageClass"
        storage_class = "COLDLINE"
      }
      condition = {
        age = 90
      }
    },
    {
      action = {
        type = "Delete"
      }
      condition = {
        age = 365
      }
    }
  ]

  # Access logging
  logging_bucket = module.logging_bucket.bucket_name

  # Retention policy (compliance)
  retention_policy_days = 90

  # IAM
  iam_bindings = {
    app_read = {
      role    = "roles/storage.objectViewer"
      members = ["serviceAccount:app@my-project.iam.gserviceaccount.com"]
    }
    admin = {
      role    = "roles/storage.admin"
      members = ["group:admins@example.com"]
    }
  }

  labels = {
    data_classification = "confidential"
  }
}
```

### Static Website Hosting

```hcl
module "website" {
  source = "../../../gcp/resources/storage/cloud-storage"

  project_id  = "my-project"
  name        = "myapp-website"
  environment = "prod"
  location    = "US"

  # Required for website
  uniform_bucket_level_access = true
  public_access_prevention    = "inherited"  # Allow public access

  cors = [{
    origin          = ["https://example.com"]
    method          = ["GET", "HEAD"]
    response_header = ["Content-Type"]
    max_age_seconds = 3600
  }]

  iam_bindings = {
    public = {
      role    = "roles/storage.objectViewer"
      members = ["allUsers"]
    }
  }
}
```

### Application Data Bucket

```hcl
module "app_data" {
  source = "../../../gcp/resources/storage/cloud-storage"

  project_id  = "my-project"
  name        = "myapp-uploads"
  environment = "prod"
  location    = "US-CENTRAL1"  # Regional

  storage_class      = "STANDARD"
  versioning_enabled = true

  lifecycle_rules = [
    {
      action = {
        type = "Delete"
      }
      condition = {
        num_newer_versions = 3
        with_state         = "ARCHIVED"
      }
    }
  ]
}
```

## Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `project_id` | GCP Project ID | `string` | - | Yes |
| `name` | Bucket name prefix | `string` | - | Yes |
| `environment` | Environment (dev, staging, prod) | `string` | - | Yes |
| `location` | Bucket location | `string` | `"US"` | No |
| `storage_class` | Storage class | `string` | `"STANDARD"` | No |
| `force_destroy` | Allow deletion with objects | `bool` | `false` | No |
| `versioning_enabled` | Enable versioning | `bool` | `true` | No |
| `uniform_bucket_level_access` | Uniform access control | `bool` | `true` | No |
| `public_access_prevention` | Public access prevention | `string` | `"enforced"` | No |
| `encryption_key` | CMEK key name | `string` | `null` | No |
| `lifecycle_rules` | Lifecycle rules | `list(object)` | `[]` | No |
| `cors` | CORS configuration | `list(object)` | `[]` | No |
| `logging_bucket` | Access logs bucket | `string` | `null` | No |
| `retention_policy_days` | Retention period in days | `number` | `0` | No |
| `iam_bindings` | IAM bindings | `map(object)` | `{}` | No |
| `labels` | Labels to apply | `map(string)` | `{}` | No |

### Lifecycle Rule Configuration

```hcl
lifecycle_rules = [{
  action = {
    type          = "SetStorageClass"  # or "Delete"
    storage_class = "NEARLINE"         # for SetStorageClass
  }
  condition = {
    age                        = 30          # Days
    created_before             = "2024-01-01"
    with_state                 = "LIVE"      # LIVE, ARCHIVED, ANY
    matches_storage_class      = ["STANDARD"]
    num_newer_versions         = 3           # For versioned objects
    days_since_noncurrent_time = 30          # For noncurrent versions
  }
}]
```

### CORS Configuration

```hcl
cors = [{
  origin          = ["https://example.com", "https://www.example.com"]
  method          = ["GET", "HEAD", "PUT", "POST", "DELETE"]
  response_header = ["Content-Type", "Access-Control-Allow-Origin"]
  max_age_seconds = 3600
}]
```

## Outputs

| Name | Description |
|------|-------------|
| `bucket_id` | Bucket ID |
| `bucket_name` | Bucket name |
| `bucket_url` | Bucket URL (gs://...) |
| `bucket_self_link` | Bucket self link |

## Storage Classes

| Class | Use Case | Min Storage | Retrieval Cost |
|-------|----------|-------------|----------------|
| STANDARD | Frequently accessed | None | None |
| NEARLINE | Monthly access | 30 days | Per GB |
| COLDLINE | Quarterly access | 90 days | Per GB |
| ARCHIVE | Annual access | 365 days | Per GB |

## Security Features

### Uniform Bucket-Level Access

Simplifies access control by disabling object ACLs:

```hcl
uniform_bucket_level_access = true
```

### Public Access Prevention

Prevents accidental public exposure:

```hcl
public_access_prevention = "enforced"  # or "inherited"
```

### Customer-Managed Encryption

Use your own Cloud KMS key:

```hcl
encryption_key = google_kms_crypto_key.storage.id
```

### Retention Policy

For compliance requirements (WORM):

```hcl
retention_policy_days = 365  # Objects cannot be deleted for 1 year
```

## Cost Optimization

### Lifecycle Policies

Automatically transition data to cheaper storage:

```hcl
lifecycle_rules = [
  { action = { type = "SetStorageClass", storage_class = "NEARLINE" }, condition = { age = 30 } },
  { action = { type = "SetStorageClass", storage_class = "COLDLINE" }, condition = { age = 90 } },
  { action = { type = "SetStorageClass", storage_class = "ARCHIVE" },  condition = { age = 365 } },
]
```

### Version Cleanup

Delete old versions automatically:

```hcl
lifecycle_rules = [{
  action = { type = "Delete" }
  condition = {
    num_newer_versions = 3
    with_state         = "ARCHIVED"
  }
}]
```

## Cost Considerations

| Component | Cost Factor |
|-----------|-------------|
| Storage | Per GB/month by class |
| Operations | Per 10,000 operations |
| Network | Egress charges |
| Retrieval | Per GB for NEARLINE/COLDLINE/ARCHIVE |

**Tips:**
- Use regional buckets when data locality matters
- Use multi-regional for global access patterns
- Implement lifecycle policies from day one
- Consider Autoclass for unpredictable access patterns
