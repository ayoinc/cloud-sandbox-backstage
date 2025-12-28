# Tagging Module

Standardized tagging and labeling for all cloud resources.

## Features

- **Environment isolation** tags
- **Compliance** tracking (PCI, HIPAA, SOX, GDPR)
- **Cost management** tags
- **Auto-shutdown** for non-prod environments
- Provider-specific formatting (Azure tags, AWS tags, GCP labels)

## Usage

```hcl
module "tags" {
  source = "path/to/shared/tagging"

  project             = "myapp"
  environment         = "prod"
  layer               = "application"
  owner               = "platform-team"
  cost_center         = "cc-12345"
  department          = "engineering"
  data_classification = "confidential"
  compliance          = ["pci", "gdpr"]
  auto_shutdown       = true
  
  additional_tags = {
    CustomTag = "custom-value"
  }
}
```

## Outputs

| Output | Description |
|--------|-------------|
| `tags` | All tags as a map |
| `azure_tags` | Tags formatted for Azure |
| `aws_tags` | Tags formatted for AWS |
| `gcp_labels` | Labels formatted for GCP (lowercase) |
| `required_tags` | Only mandatory tags |
| `is_production` | Boolean if prod environment |
| `auto_shutdown_enabled` | Boolean if auto-shutdown is on |

## Tag Categories

### Required Tags
| Tag | Description |
|-----|-------------|
| Project | Project/application name |
| Environment | dev, staging, prod, etc. |
| Layer | platform, application, data, network, security, monitoring |
| ManagedBy | terraform |
| DataClassification | public, internal, confidential, restricted |

### Ownership Tags
| Tag | Description |
|-----|-------------|
| Owner | Team or individual responsible |
| CostCenter | Billing cost center |
| Department | Owning department |

### Operational Tags
| Tag | Description |
|-----|-------------|
| BackupPolicy | none, daily, weekly, monthly |
| AutoShutdown | enabled/disabled |
| Compliance | pci, hipaa, sox, gdpr, iso27001 |
| ShutdownSchedule | Cron schedule for shutdown |
| StartupSchedule | Cron schedule for startup |

### Audit Tags
| Tag | Description |
|-----|-------------|
| CreatedAt | Creation date |
| TerraformWorkspace | Workspace name |
| Repository | Source code repository |
| Pipeline | CI/CD pipeline URL |

## Auto-Shutdown

Auto-shutdown is automatically enabled for non-production environments:

```hcl
module "tags" {
  source = "path/to/shared/tagging"

  project       = "myapp"
  environment   = "dev"      # Non-prod triggers auto-shutdown
  auto_shutdown = true       # Default: true
  
  shutdown_schedule = "0 20 * * 1-5"  # 8 PM weekdays
  startup_schedule  = "0 8 * * 1-5"   # 8 AM weekdays
}

# For prod, auto-shutdown is always disabled
# output.auto_shutdown_enabled = false for prod
```

## GCP Labels

GCP labels have specific requirements (lowercase, 63 chars max):

```hcl
# Input
additional_tags = {
  MyCustomTag = "Some-Value-123"
}

# GCP output (automatically formatted)
gcp_labels = {
  mycustomtag = "some-value-123"
}
```
