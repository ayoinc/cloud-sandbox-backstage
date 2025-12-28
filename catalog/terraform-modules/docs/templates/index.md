# Infrastructure Templates

Full-stack infrastructure templates that combine multiple resource modules with enable/disable flags for flexible deployment.

## Available Templates

| Template | Cloud | Description |
|----------|-------|-------------|
| [Azure Full Infrastructure](azure-full-infrastructure.md) | Azure | Complete Azure stack with 10+ module categories |
| AWS Full Infrastructure | AWS | Complete AWS stack (Coming Soon) |
| GCP Full Infrastructure | GCP | Complete GCP stack (Coming Soon) |

## Template Strategy

Our templates follow **Option C** strategy:

1. **Single-Resource Templates** - Individual modules (VNet, S3, GKE, etc.)
2. **Full Infrastructure Templates** - Complete stacks with enable/disable flags

This provides flexibility for both greenfield deployments and incremental additions.

## How Templates Work

```
┌────────────────────────────────────────────────────────────┐
│                   Backstage Scaffolder                      │
│                                                             │
│  1. User selects template                                  │
│  2. User fills in parameters                               │
│  3. User enables/disables modules                          │
│  4. Backstage generates code from skeleton                 │
│  5. Code is pushed to Git repository                       │
│  6. Component is registered in catalog                     │
└────────────────────────────────────────────────────────────┘
                           │
                           ▼
┌────────────────────────────────────────────────────────────┐
│              Generated Terraform Project                    │
│                                                             │
│  infrastructure/                                            │
│  ├── main.tf           # Root module                       │
│  ├── variables.tf      # Input variables                   │
│  ├── outputs.tf        # Output values                     │
│  ├── providers.tf      # Provider configuration            │
│  ├── terraform.tfvars  # Environment values                │
│  └── modules/          # Enabled module references         │
│      ├── networking/                                        │
│      ├── containers/                                        │
│      ├── storage/                                          │
│      └── ...                                               │
└────────────────────────────────────────────────────────────┘
```

## Module Categories

### Core Modules (Usually Enabled)

| Module | Azure | AWS | GCP |
|--------|-------|-----|-----|
| Networking | VNet, NSG, Firewall | VPC, Security Groups | VPC, Firewall Rules |
| Security | Key Vault, Managed Identity | KMS, Secrets Manager | Secret Manager, KMS |
| Monitoring | Log Analytics, App Insights | CloudWatch | Cloud Monitoring |

### Workload Modules (Optional)

| Module | Azure | AWS | GCP |
|--------|-------|-----|-----|
| Containers | AKS, ACR | EKS, ECR | GKE, Artifact Registry |
| Compute | VMs, VMSS, App Service | EC2, Auto Scaling | GCE, Instance Groups |
| Storage | Storage Account | S3 | Cloud Storage |
| Database | SQL, PostgreSQL, Cosmos DB | RDS, DynamoDB | Cloud SQL, Spanner |

### Advanced Modules (Optional)

| Module | Azure | AWS | GCP |
|--------|-------|-----|-----|
| Integration | Service Bus, Event Grid | SNS, SQS, EventBridge | Pub/Sub |
| Governance | Azure Policy | Service Control Policies | Organization Policy |
| Identity | Azure AD | IAM Identity Center | Cloud Identity |

## Using Templates in Backstage

### 1. Navigate to Templates

Go to **Create** > **Templates** in Backstage

### 2. Select a Template

Choose the appropriate full infrastructure template for your cloud provider

### 3. Configure Parameters

Fill in required parameters:

```yaml
projectName: my-application
environment: prod
businessUnit: engineering
description: Production infrastructure for my-application
primaryRegion: eastus
```

### 4. Enable Modules

Toggle modules based on your needs:

- ✅ Networking (VNet, subnets, NSGs)
- ✅ Security (Key Vault, Managed Identity)
- ✅ Monitoring (Log Analytics)
- ❌ Compute (not needed for containerized apps)
- ✅ Containers (AKS cluster)
- ✅ Storage (Storage Account)
- ✅ Database (PostgreSQL)

### 5. Review and Create

Review configuration and create the repository

## Environment Presets

Templates include smart defaults per environment:

### Development
```hcl
enable_high_availability = false
enable_dr               = false
enable_auto_shutdown    = true
sku_tier                = "Standard"
```

### Staging
```hcl
enable_high_availability = true
enable_dr               = false
enable_auto_shutdown    = false
sku_tier                = "Standard"
```

### Production
```hcl
enable_high_availability = true
enable_dr               = true
enable_auto_shutdown    = false
sku_tier                = "Premium"
```

## Customizing Templates

### Adding New Modules

1. Create module in `/terraform-modules/{cloud}/resources/`
2. Add skeleton files to `/templates/{cloud}-full-infrastructure/skeleton/`
3. Update template.yaml with new parameter
4. Update main.tf.njk to conditionally include module

### Modifying Defaults

Edit the template.yaml `properties` section:

```yaml
properties:
  enableNetworking:
    title: 'Networking Module'
    type: boolean
    default: true  # Change default here
```

## Best Practices

### Template Design

1. **Sensible Defaults** - Production-ready defaults that can be overridden
2. **Environment Awareness** - Different configurations per environment
3. **Module Independence** - Modules should work standalone or together
4. **Documentation** - Every template includes README and examples

### Usage Guidelines

1. Start with minimal modules, add as needed
2. Use development environment for testing
3. Review generated code before deploying
4. Customize tfvars for your organization
