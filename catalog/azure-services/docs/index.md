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

| Service | Purpose | Use Case |
|---------|---------|----------|
| **Virtual Machines** | IaaS compute | Application hosting, custom workloads |
| **AKS** | Managed Kubernetes | Container orchestration |
| **Azure Functions** | Serverless compute | Event-driven functions |
| **Blob Storage** | Object storage | Files, backups, data lakes |
| **Azure SQL** | Managed databases | Relational workloads |
| **Virtual Network** | Networking | Network isolation, connectivity |
| **Azure AD/Entra ID** | Identity & access | Authentication, authorization |
| **ARM/Bicep** | Infrastructure as Code | Automated provisioning |

## Features

- **Hybrid Cloud**: Seamless integration with on-premises infrastructure via Azure Arc
- **Enterprise Security**: Azure AD, RBAC, Key Vault, and Defender for Cloud
- **Global Scale**: 60+ regions worldwide with availability zones
- **Cost Management**: Azure Cost Management, Reserved Instances, and Spot VMs
- **DevOps Integration**: Azure DevOps, GitHub Actions, and native CI/CD

## Architecture Overview

```
                         ┌─────────────────┐
                         │   Azure DNS     │
                         └────────┬────────┘
                                  │
                         ┌────────▼────────┐
                         │  Front Door     │
                         │  (Global LB)    │
                         └────────┬────────┘
                                  │
                         ┌────────▼────────┐
                         │  App Gateway    │
                         │  (Regional LB)  │
                         └────────┬────────┘
                                  │
              ┌───────────────────┼───────────────────┐
              │                   │                   │
     ┌────────▼────────┐ ┌────────▼────────┐ ┌────────▼────────┐
     │      AKS        │ │ Azure Functions │ │  Virtual        │
     │   Cluster       │ │                 │ │  Machines       │
     └────────┬────────┘ └────────┬────────┘ └────────┬────────┘
              │                   │                   │
              └───────────────────┼───────────────────┘
                                  │
              ┌───────────────────┼───────────────────┐
              │                   │                   │
     ┌────────▼────────┐ ┌────────▼────────┐ ┌────────▼────────┐
     │   Azure SQL     │ │  Azure Cache    │ │  Blob Storage   │
     │   Database      │ │  for Redis      │ │                 │
     └─────────────────┘ └─────────────────┘ └─────────────────┘
```

## Related Documentation

- [Overview](overview.md) - Detailed architecture and components
- [Usage](usage.md) - Practical examples and configurations
