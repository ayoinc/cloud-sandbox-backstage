# Azure Services Integration

Comprehensive Microsoft Azure cloud services and infrastructure management for the Cloud Sandbox platform.

## Quick Start

```bash
# Install Azure CLI
brew install azure-cli  # macOS
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash  # Linux

# Login to Azure
az login

# Set default subscription
az account set --subscription "My Subscription"

# Verify access
az account show
```

## Core Services

| Service               | Purpose                | Use Case                              |
| --------------------- | ---------------------- | ------------------------------------- |
| **Virtual Machines**  | IaaS compute           | Application hosting, custom workloads |
| **AKS**               | Managed Kubernetes     | Container orchestration               |
| **Azure Functions**   | Serverless compute     | Event-driven functions                |
| **Blob Storage**      | Object storage         | Files, backups, data lakes            |
| **Azure SQL**         | Managed databases      | Relational workloads                  |
| **Virtual Network**   | Networking             | Network isolation, connectivity       |
| **Azure AD/Entra ID** | Identity & access      | Authentication, authorization         |
| **ARM/Bicep**         | Infrastructure as Code | Automated provisioning                |

## Features

- **Hybrid Cloud**: Seamless integration with on-premises infrastructure via Azure Arc
- **Enterprise Security**: Azure AD, RBAC, Key Vault, and Defender for Cloud
- **Global Scale**: 60+ regions worldwide with availability zones
- **Cost Management**: Azure Cost Management, Reserved Instances, and Spot VMs
- **DevOps Integration**: Azure DevOps, GitHub Actions, and native CI/CD

## Architecture Overview

```d2
direction: down

title: Azure Architecture {
  shape: text
  near: top-center
  style.font-size: 24
}

dns: Azure DNS {
  shape: rectangle
  style.fill: "#2196F3"
  style.font-color: white
}

frontdoor: Front Door\n(Global LB) {
  shape: hexagon
  style.fill: "#64B5F6"
  style.font-color: white
}

appgw: App Gateway\n(Regional LB) {
  shape: hexagon
  style.fill: "#64B5F6"
  style.font-color: white
}

compute: Compute Tier {
  style.fill: "#E8F5E9"

  aks: AKS Cluster {
    shape: hexagon
    style.fill: "#4CAF50"
    style.font-color: white
  }
  functions: Azure Functions {
    shape: hexagon
    style.fill: "#4CAF50"
    style.font-color: white
  }
  vms: Virtual Machines {
    shape: hexagon
    style.fill: "#4CAF50"
    style.font-color: white
  }
}

data: Data Tier {
  style.fill: "#FFF3E0"

  sql: Azure SQL\nDatabase {
    shape: cylinder
    style.fill: "#FF9800"
    style.font-color: white
  }
  redis: Azure Cache\nfor Redis {
    shape: cylinder
    style.fill: "#FF9800"
    style.font-color: white
  }
  blob: Blob Storage {
    shape: cylinder
    style.fill: "#FF9800"
    style.font-color: white
  }
}

dns -> frontdoor
frontdoor -> appgw
appgw -> compute.aks
appgw -> compute.functions
appgw -> compute.vms
compute.aks -> data
compute.functions -> data
compute.vms -> data
```

## Related Documentation

- [Overview](overview.md) - Detailed architecture and components
- [Usage](usage.md) - Practical examples and configurations
