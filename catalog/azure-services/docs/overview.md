# Overview

## Architecture

Azure Services Integration provides a comprehensive framework for managing Microsoft Azure cloud infrastructure using Infrastructure as Code (IaC) principles.

### Resource Organization

```
┌─────────────────────────────────────────────────────────────┐
│                    Azure Tenant (Entra ID)                  │
├─────────────────────────────────────────────────────────────┤
│                    Management Groups                         │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │
│  │ Production  │  │ Development │  │  Sandbox    │         │
│  │    MG       │  │     MG      │  │     MG      │         │
│  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘         │
│         │                │                │                 │
│  ┌──────▼──────┐  ┌──────▼──────┐  ┌──────▼──────┐         │
│  │ Prod Subs   │  │  Dev Subs   │  │ Sandbox     │         │
│  │             │  │             │  │ Subs        │         │
│  └─────────────┘  └─────────────┘  └─────────────┘         │
└─────────────────────────────────────────────────────────────┘
```

## Core Components

### Compute Services

| Service | Description | Best For |
|---------|-------------|----------|
| **Virtual Machines** | Full IaaS VMs | Custom workloads, legacy apps |
| **VM Scale Sets** | Auto-scaling VMs | High-availability workloads |
| **AKS** | Managed Kubernetes | Container orchestration |
| **Azure Functions** | Serverless compute | Event-driven workloads |
| **Container Instances** | Serverless containers | Quick container deployments |
| **App Service** | PaaS web hosting | Web apps, APIs |

### Networking

| Component | Purpose |
|-----------|---------|
| **Virtual Network (VNet)** | Isolated network in Azure |
| **Subnets** | Network segmentation |
| **Network Security Groups** | Stateful firewall rules |
| **Azure Firewall** | Managed network firewall |
| **VPN Gateway** | Site-to-site/point-to-site VPN |
| **ExpressRoute** | Private connection to Azure |
| **Private Link** | Private access to Azure services |

### Storage Services

| Service | Type | Use Case |
|---------|------|----------|
| **Blob Storage** | Object storage | Unstructured data, backups |
| **Azure Files** | SMB file shares | Lift-and-shift file servers |
| **Azure Disks** | Block storage | VM disks |
| **Azure Data Lake** | Big data storage | Analytics workloads |
| **Queue Storage** | Message queuing | Async communication |

### Database Services

| Service | Engine | Use Case |
|---------|--------|----------|
| **Azure SQL** | SQL Server | Enterprise relational workloads |
| **Azure Database for PostgreSQL** | PostgreSQL | Open-source relational |
| **Cosmos DB** | Multi-model NoSQL | Global distribution, low latency |
| **Azure Cache for Redis** | Redis | Caching, sessions |
| **Azure Database for MySQL** | MySQL | MySQL workloads |

## Configuration

### Environment Variables

```bash
# Service Principal Authentication
export AZURE_TENANT_ID="your-tenant-id"
export AZURE_CLIENT_ID="your-client-id"
export AZURE_CLIENT_SECRET="your-client-secret"
export AZURE_SUBSCRIPTION_ID="your-subscription-id"

# Alternative: Managed Identity (recommended for Azure resources)
# No environment variables needed - uses system-assigned identity
```

### Azure CLI Configuration

```bash
# Login interactively
az login

# Login with service principal
az login --service-principal \
  --username $AZURE_CLIENT_ID \
  --password $AZURE_CLIENT_SECRET \
  --tenant $AZURE_TENANT_ID

# Set default subscription
az account set --subscription $AZURE_SUBSCRIPTION_ID

# Set default location
az configure --defaults location=eastus

# Set default resource group
az configure --defaults group=my-resource-group
```

### RBAC Best Practices

1. **Use Azure AD Groups** for role assignments instead of individual users
2. **Apply least privilege** - use built-in roles when possible
3. **Use Managed Identities** for Azure resource authentication
4. **Implement PIM** (Privileged Identity Management) for elevated access
5. **Enable Conditional Access** for additional security controls
6. **Audit regularly** using Azure AD access reviews

### Resource Tagging Strategy

```json
{
  "Environment": "production|staging|development",
  "Project": "project-name",
  "Owner": "team-name",
  "CostCenter": "cost-center-id",
  "ManagedBy": "terraform|bicep|manual",
  "CreatedDate": "2024-01-01",
  "ExpirationDate": "2024-12-31"
}
```

## Security Configuration

### Network Security Groups

```bash
# Create NSG
az network nsg create \
  --resource-group myResourceGroup \
  --name myNSG

# Add inbound rule
az network nsg rule create \
  --resource-group myResourceGroup \
  --nsg-name myNSG \
  --name AllowHTTPS \
  --priority 100 \
  --direction Inbound \
  --access Allow \
  --protocol Tcp \
  --destination-port-ranges 443
```

### Key Vault

```bash
# Create Key Vault
az keyvault create \
  --name myKeyVault \
  --resource-group myResourceGroup \
  --location eastus \
  --enable-rbac-authorization

# Store secret
az keyvault secret set \
  --vault-name myKeyVault \
  --name mySecret \
  --value "secret-value"

# Retrieve secret
az keyvault secret show \
  --vault-name myKeyVault \
  --name mySecret \
  --query value -o tsv
```

## Monitoring

### Azure Monitor Metrics

Key metrics to monitor:

| Service | Metric | Threshold |
|---------|--------|-----------|
| VM | Percentage CPU | > 80% |
| Azure SQL | DTU percentage | > 80% |
| Storage | Used capacity | > 80% |
| AKS | Node CPU % | > 80% |
| App Service | Response Time | > 2s |

### Azure Monitor Alerts

```bash
# Create action group
az monitor action-group create \
  --resource-group myResourceGroup \
  --name myActionGroup \
  --short-name myAG \
  --email myemail admin@example.com

# Create metric alert
az monitor metrics alert create \
  --resource-group myResourceGroup \
  --name "High CPU Alert" \
  --scopes "/subscriptions/{sub-id}/resourceGroups/{rg}/providers/Microsoft.Compute/virtualMachines/{vm}" \
  --condition "avg Percentage CPU > 80" \
  --action myActionGroup
```

### Log Analytics

```bash
# Create Log Analytics workspace
az monitor log-analytics workspace create \
  --resource-group myResourceGroup \
  --workspace-name myWorkspace

# Query logs
az monitor log-analytics query \
  --workspace myWorkspace \
  --analytics-query "AzureActivity | where Level == 'Error' | take 10"
```
