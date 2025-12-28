# Azure Full Infrastructure Stack

{{ .description }}

## Overview

This Terraform stack provides a complete Azure infrastructure with configurable modules for networking, compute, storage, database, security, identity, monitoring, integration, and governance.

### Architecture

```
.
├── environments/
│   ├── dev.tfvars          # Development environment configuration
│   ├── stg.tfvars          # Staging environment configuration
│   └── prod.tfvars         # Production environment configuration
├── modules/
│   ├── networking/         # Virtual Network, Subnets, Load Balancers, Firewall
│   ├── compute/            # Virtual Machines, App Service, Container Instances
│   ├── containers/         # AKS, Container Registry, Container Apps
│   ├── storage/            # Storage Accounts, Data Lake, Managed Disks
│   ├── database/           # SQL Databases, PostgreSQL, MySQL, Cosmos DB
│   ├── security/           # Key Vault, Managed Identities, Security Center
│   ├── identity/           # Azure AD, RBAC, Conditional Access
│   ├── monitoring/         # Log Analytics, App Insights, Alerts
│   ├── integration/        # Service Bus, Event Grid, Logic Apps
│   └── governance/         # Policies, Cost Management, Blueprints
├── tests/
│   └── main.tftest.hcl     # Native Terraform tests
├── main.tf                 # Orchestrates all modules with flags
├── variables.tf            # All module enable/disable flags
└── outputs.tf              # Stack outputs
```

## Prerequisites

- Terraform >= 1.6.0
- Azure CLI or Service Principal authentication
- Azure subscription with appropriate permissions

## Getting Started

1. Configure environment:

```bash
cp environments/dev.tfvars terraform.tfvars
# Edit terraform.tfvars with your settings
```

2. Initialize Terraform:

```bash
terraform init
```

3. Plan the deployment:

```bash
terraform plan -var-file=environments/{{ .environment }}.tfvars
```

4. Apply the infrastructure:

```bash
terraform apply -var-file=environments/{{ .environment }}.tfvars
```

## Module Configuration

Enable/disable modules in `terraform.tfvars` or via command line:

```hcl
# Enable modules
enable_networking = {{ .enableNetworking }}
enable_compute = {{ .enableCompute }}
enable_containers = {{ .enableContainers }}
enable_storage = {{ .enableStorage }}
enable_database = {{ .enableDatabase }}
enable_security = {{ .enableSecurity }}
enable_identity = {{ .enableIdentity }}
enable_monitoring = {{ .enableMonitoring }}
enable_integration = {{ .enableIntegration }}
enable_governance = {{ .enableGovernance }}

# Advanced features
enable_dr = {{ .enableDR }}
enable_high_availability = {{ .enableHighAvailability }}
enable_auto_shutdown = {{ .enableAutoShutdown }}
auto_shutdown_schedule = "{{ .autoShutdownSchedule }}"
```

## Module Descriptions

### 🌐 Networking Module (`{{ .enableNetworking }}`)

- Virtual Network (VNet) with address space
- Subnets (public, private, database, app gateway)
- Network Security Groups (NSG) with security rules
- Application Security Groups (ASG)
- Azure Load Balancer (public and internal)
- Application Gateway with WAF
- Azure Firewall
- VPN Gateway for hybrid connectivity
- NAT Gateway for outbound connectivity
- Private Link endpoints
- Azure Bastion for secure access
- Route Tables with custom routes

### 💻 Compute Module (`{{ .enableCompute }}`)

- Virtual Machines (Windows/Linux) with managed disks
- Virtual Machine Scale Sets with autoscaling
- Azure App Service Plan and Web Apps
- Azure Function Apps (serverless)
- Azure Container Instances
- Availability Sets and Zones
- Custom Script Extensions

### 🐳 Containers Module (`{{ .enableContainers }}`)

- Azure Kubernetes Service (AKS) cluster
- Azure Container Registry (ACR) for images
- Azure Container Apps (serverless containers)
- AKS node pools (system and user)
- Container monitoring and insights
- Kubernetes RBAC and security policies

### 📦 Storage Module (`{{ .enableStorage }}`)

- Azure Storage Accounts (Blob, File, Queue, Table)
- Azure Data Lake Storage Gen2
- Managed Disks (OS and data disks)
- Azure NetApp Files
- Azure Files (SMB and NFS shares)
- Blob lifecycle management policies
- Private endpoints for storage
- Storage replication (LRS, ZRS, GRS)

### 🗄️ Database Module (`{{ .enableDatabase }}`)

- Azure SQL Database (single/elastic pool)
- SQL Managed Instance
- Azure Database for PostgreSQL
- Azure Database for MySQL
- Azure Database for MariaDB
- Azure Cosmos DB (SQL, MongoDB, Cassandra API)
- Azure Cache for Redis
- Database monitoring and alerting
- Geo-replication for DR

### 🔒 Security Module (`{{ .enableSecurity }}`)

- Azure Key Vault for secrets and keys
- Managed Identities for Azure resources
- Microsoft Defender for Cloud
- DDoS Protection plans
- Web Application Firewall (WAF) policies
- Security Center standard tier
- Private Link for secure access
- Azure Policy for compliance

### 🆔 Identity Module (`{{ .enableIdentity }}`)

- Azure AD Groups for RBAC
- Custom RBAC role definitions
- Role assignments at subscription/resource group scope
- Conditional Access policies
- Managed Identity assignments
- Service Principal credentials rotation

### 📊 Monitoring Module (`{{ .enableMonitoring }}`)

- Log Analytics workspace
- Application Insights for APM
- Azure Monitor alerts and action groups
- Diagnostic settings for all resources
- Azure Dashboard for visualization
- Workbooks for custom reports
- Log retention and archiving policies
- Integration with external SIEM

### 🔗 Integration Module (`{{ .enableIntegration }}`)

- Azure Service Bus (queues and topics)
- Azure Event Grid (event routing)
- Azure Event Hubs (streaming)
- Azure Logic Apps (workflow automation)
- API Management service
- Private Endpoints for integration services

### 📋 Governance Module (`{{ .enableGovernance }}`)

- Azure Policy definitions and assignments
- Management Group hierarchy
- Cost Management budgets and alerts
- Azure Blueprints for environment provisioning
- Resource tagging policies
- Compliance dashboard

## Testing

Run tests without credentials:

```bash
cd tests/
terraform init -backend=false
terraform test -verbose
```

## Monitoring

Once deployed, monitoring is available at:

- **Azure Portal**: View resources in the resource group
- **Log Analytics**: Query logs with KQL
- **Application Insights**: Application performance monitoring
- **Azure Dashboard**: Custom dashboard with key metrics

## Cost Estimation

Use Infracost to estimate costs:

```bash
infracost breakdown --path .
```

## Security Scanning

Terraform code is automatically scanned for security issues using:

- TFSec
- Checkov
- Azure Security Center recommendations

## DR and High Availability

{{ if .enableDR }}

- Cross-region replication enabled for storage and databases
- Geo-redundant storage (GRS) configured
- Secondary region: {{ .secondaryRegion }}
  {{ else }}
- DR can be enabled by setting `enable_dr = true`
- Cross-region replication for critical resources
  {{ end }}

{{ if .enableHighAvailability }}

- Zone-redundant configuration for supported resources
- Availability Zones used where available
- Multi-site deployment pattern
  {{ end }}

## Tags

All resources are tagged with:

```yaml
Project: {{ .projectName }}
Environment: {{ .environment }}
BusinessUnit: {{ .businessUnit }}
CostCenter: {{ .businessUnit }}
ManagedBy: terraform
Tier: {{ if eq .enableDR "true" }}critical{{ else }}standard{{ end }}
SLA: {{ if eq .environment "prod" }}24x7{{ else }}business-hours{{ end }}
DR: {{ .enableDR }}
AutoShutdown: {{ .enableAutoShutdown }}
TerraformWorkspace: {{ .projectName }}-{{ .environment }}
```

## Documentation Links

- [Azure Architecture Center](https://docs.microsoft.com/en-us/azure/architecture/)
- [Cloud Adoption Framework](https://docs.microsoft.com/en-us/azure/cloud-adoption-framework/)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest)

## Contributing

To add new modules:

1. Create module in `modules/`
2. Add enable flag in `variables.tf`
3. Wire in `main.tf`
4. Add tests
5. Update documentation

## License

This project is licensed under the MIT License.
