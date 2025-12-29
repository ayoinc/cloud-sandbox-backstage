# {{ componentName }} - Azure Infrastructure

{{ description }}

## Architecture Overview

![Azure Infrastructure Architecture](docs/diagrams/architecture.png)

This diagram shows the complete Azure infrastructure stack deployed by this template.

## Resources Included

| Category | Resources | Status |
|----------|-----------|--------|
| Networking | VNet, Subnets, NSGs, Load Balancers | {% if enable_networking %}✅ Enabled{% else %}❌ Disabled{% endif %} |
| Compute | Virtual Machines, Scale Sets | {% if enable_compute %}✅ Enabled{% else %}❌ Disabled{% endif %} |
| Containers | AKS Cluster, ACR Registry, Container Instances | {% if enable_containers %}✅ Enabled{% else %}❌ Disabled{% endif %} |
| Storage | Storage Accounts, Blob Containers, File Shares | {% if enable_storage %}✅ Enabled{% else %}❌ Disabled{% endif %} |
| Database | SQL Database, Cosmos DB, Redis Cache | {% if enable_database %}✅ Enabled{% else %}❌ Disabled{% endif %} |
| Security | Key Vault, Managed Identities, RBAC | {% if enable_security %}✅ Enabled{% else %}❌ Disabled{% endif %} |
| Monitoring | Log Analytics, Application Insights | {% if enable_monitoring %}✅ Enabled{% else %}❌ Disabled{% endif %} |

## Deployment

```bash
# Initialize Terraform
terraform init

# Plan deployment
terraform plan -var="environment={{ environment }}" -var="location={{ location }}" -out=tfplan

# Apply infrastructure
terraform apply tfplan
```

## Configuration

**Environment:** {{ environment }}
**Location:** {{ location }}
**VNet Address Space:** {{ vnet_address_space }}

{% if enable_containers %}
### Kubernetes Configuration
- **AKS Version:** {{ aks_version }}
- **Node VM Size:** {{ node_vm_size }}
- **Node Count:** {{ node_count }}
- **Auto-scaling:** {{ enable_auto_scaling }}
{% endif %}

{% if enable_compute %}
### Compute Configuration
- **VM Size:** {{ vm_size }}
- **VM Count:** {{ vm_count }}
{% endif %}

{% if enable_database %}
### Database Configuration
- **SQL SKU:** {{ sql_database_sku }}
- **Cosmos DB:** {{ enable_cosmosdb }}
- **Redis Cache:** {{ enable_redis }}
{% endif %}

## Architecture Layers

### Network Layer
- **Virtual Network** with gateway, web, app, and data subnets
- **VPN/ExpressRoute Gateway** for hybrid connectivity
- **Bastion Host** for secure administrative access
- **Load Balancers** (public and internal)
- **Application Gateway** with WAF
- **Network Security Groups** and Route Tables

### Security Layer
- **Azure Key Vault** for secrets and key management
- **Managed Identities** for authentication
- **Azure RBAC** for access control
- **Azure Defender** for threat protection
- **Private Link** for private connectivity

### Container & Compute Layer
- **AKS Cluster** with system and user node pools
- **Virtual Machines** and **VM Scale Sets**
- **Azure Container Registry** for Docker images
- **Azure Container Instances** for serverless containers
- **Azure Functions** for event-driven compute

### Data Layer
- **Azure SQL Database** with geo-replication
- **Azure Cosmos DB** for NoSQL workloads
- **Azure Redis Cache** for caching
- **Storage Accounts** with blob/file/table/queue storage
- **Disk Encryption** for data at rest

### Observability Layer
- **Log Analytics Workspace** for centralized logging
- **Application Insights** for application monitoring
- **Azure Monitor** for infrastructure monitoring
- **VM Insights** for virtual machine monitoring
- **Azure Dashboards** for visualization

## Testing

Run the Terraform test suite:

```bash
cd tests
terraform test
```

## Security Best Practices

✅ All resources encrypted at rest and in transit
✅ Network segmentation with NSGs on all subnets
✅ Managed identities instead of service principals
✅ Azure Key Vault for secrets management
✅ Private Link for private endpoint connectivity
✅ Azure Defender enabled for threat detection
✅ WAF on Application Gateway

## Documentation

See [docs/](docs/) for detailed documentation.

## Support

For issues and questions, contact the platform team or create an issue in the repository.
