# Usage Guide

## Getting Started

### Prerequisites

1. Azure CLI installed
2. Valid Azure subscription
3. Appropriate RBAC permissions

### Initial Setup

```bash
# Install Azure CLI (macOS)
brew install azure-cli

# Install Azure CLI (Linux)
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Login to Azure
az login

# List subscriptions
az account list --output table

# Set default subscription
az account set --subscription "My Subscription"
```

## Examples

### Resource Group Management

```bash
# Create resource group
az group create \
  --name myResourceGroup \
  --location eastus \
  --tags Environment=production Project=myapp

# List resource groups
az group list --output table

# Delete resource group
az group delete --name myResourceGroup --yes --no-wait
```

### Virtual Machine Management

```bash
# List available VM sizes
az vm list-sizes --location eastus --output table

# Create a VM
az vm create \
  --resource-group myResourceGroup \
  --name myVM \
  --image Ubuntu2204 \
  --size Standard_B2s \
  --admin-username azureuser \
  --generate-ssh-keys \
  --public-ip-sku Standard

# Start/Stop VM
az vm start --resource-group myResourceGroup --name myVM
az vm stop --resource-group myResourceGroup --name myVM
az vm deallocate --resource-group myResourceGroup --name myVM

# List VMs
az vm list --resource-group myResourceGroup --output table

# Get VM public IP
az vm show \
  --resource-group myResourceGroup \
  --name myVM \
  --show-details \
  --query publicIps -o tsv
```

### Storage Account Operations

```bash
# Create storage account
az storage account create \
  --name mystorageaccount \
  --resource-group myResourceGroup \
  --location eastus \
  --sku Standard_LRS \
  --kind StorageV2 \
  --https-only true \
  --min-tls-version TLS1_2

# Create blob container
az storage container create \
  --account-name mystorageaccount \
  --name mycontainer \
  --auth-mode login

# Upload blob
az storage blob upload \
  --account-name mystorageaccount \
  --container-name mycontainer \
  --name myblob \
  --file ./local-file.txt \
  --auth-mode login

# Download blob
az storage blob download \
  --account-name mystorageaccount \
  --container-name mycontainer \
  --name myblob \
  --file ./downloaded-file.txt \
  --auth-mode login

# List blobs
az storage blob list \
  --account-name mystorageaccount \
  --container-name mycontainer \
  --auth-mode login \
  --output table
```

### Virtual Network

```bash
# Create VNet
az network vnet create \
  --resource-group myResourceGroup \
  --name myVNet \
  --address-prefix 10.0.0.0/16 \
  --subnet-name default \
  --subnet-prefix 10.0.0.0/24

# Add subnet
az network vnet subnet create \
  --resource-group myResourceGroup \
  --vnet-name myVNet \
  --name backendSubnet \
  --address-prefix 10.0.1.0/24

# Create NSG and associate with subnet
az network nsg create \
  --resource-group myResourceGroup \
  --name myNSG

az network vnet subnet update \
  --resource-group myResourceGroup \
  --vnet-name myVNet \
  --name backendSubnet \
  --network-security-group myNSG
```

### AKS Cluster

```bash
# Create AKS cluster
az aks create \
  --resource-group myResourceGroup \
  --name myAKSCluster \
  --node-count 3 \
  --node-vm-size Standard_DS2_v2 \
  --enable-managed-identity \
  --generate-ssh-keys \
  --network-plugin azure \
  --enable-addons monitoring

# Get credentials
az aks get-credentials \
  --resource-group myResourceGroup \
  --name myAKSCluster

# Scale cluster
az aks scale \
  --resource-group myResourceGroup \
  --name myAKSCluster \
  --node-count 5

# Upgrade cluster
az aks upgrade \
  --resource-group myResourceGroup \
  --name myAKSCluster \
  --kubernetes-version 1.28.0
```

### Azure SQL Database

```bash
# Create SQL server
az sql server create \
  --resource-group myResourceGroup \
  --name mysqlserver \
  --admin-user sqladmin \
  --admin-password 'SecurePassword123!'

# Create database
az sql db create \
  --resource-group myResourceGroup \
  --server mysqlserver \
  --name myDatabase \
  --service-objective S0

# Configure firewall
az sql server firewall-rule create \
  --resource-group myResourceGroup \
  --server mysqlserver \
  --name AllowAzure \
  --start-ip-address 0.0.0.0 \
  --end-ip-address 0.0.0.0

# Get connection string
az sql db show-connection-string \
  --server mysqlserver \
  --name myDatabase \
  --client ado.net
```

### Azure Functions

```bash
# Create function app
az functionapp create \
  --resource-group myResourceGroup \
  --consumption-plan-location eastus \
  --runtime python \
  --runtime-version 3.11 \
  --functions-version 4 \
  --name myFunctionApp \
  --storage-account mystorageaccount

# Deploy function
func azure functionapp publish myFunctionApp

# View function logs
az functionapp log tail \
  --resource-group myResourceGroup \
  --name myFunctionApp
```

## Terraform Examples

### Basic Resource Group and VNet

```hcl
provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "main" {
  name     = "my-resource-group"
  location = "eastus"

  tags = {
    Environment = "production"
    ManagedBy   = "terraform"
  }
}

resource "azurerm_virtual_network" "main" {
  name                = "my-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  subnet {
    name           = "default"
    address_prefix = "10.0.1.0/24"
  }

  subnet {
    name           = "backend"
    address_prefix = "10.0.2.0/24"
  }
}
```

### AKS Cluster

```hcl
resource "azurerm_kubernetes_cluster" "main" {
  name                = "my-aks-cluster"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  dns_prefix          = "myaks"

  default_node_pool {
    name       = "default"
    node_count = 3
    vm_size    = "Standard_DS2_v2"
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin = "azure"
    network_policy = "calico"
  }
}
```

## Bicep Examples

### Storage Account

```bicep
param location string = resourceGroup().location
param storageAccountName string

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
    accessTier: 'Hot'
  }
}

output storageAccountId string = storageAccount.id
```

## Troubleshooting

### Common Issues

| Issue                     | Cause                             | Solution                                              |
| ------------------------- | --------------------------------- | ----------------------------------------------------- |
| AuthorizationFailed       | Missing RBAC permissions          | Check role assignments with `az role assignment list` |
| QuotaExceeded             | Subscription limits reached       | Request quota increase in portal                      |
| ResourceNotFound          | Wrong subscription/resource group | Verify with `az account show`                         |
| InvalidTemplateDeployment | ARM/Bicep syntax error            | Validate with `az deployment group validate`          |

### Debugging Commands

```bash
# Check current context
az account show

# List role assignments
az role assignment list --assignee $(az account show --query user.name -o tsv)

# View activity log
az monitor activity-log list \
  --resource-group myResourceGroup \
  --start-time 2024-01-01 \
  --output table

# Check resource health
az resource show \
  --ids /subscriptions/{sub}/resourceGroups/{rg}/providers/{provider}/{resource}
```

### Cost Management

```bash
# View current costs
az consumption usage list \
  --start-date 2024-01-01 \
  --end-date 2024-01-31 \
  --output table

# List budgets
az consumption budget list --output table

# Find unused resources
az resource list \
  --query "[?tags.Environment==null]" \
  --output table
```
