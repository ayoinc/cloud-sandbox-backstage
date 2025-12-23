# AWS EKS Cluster Template

This template creates an Amazon Elastic Kubernetes Service (EKS) cluster with production-ready configurations.

## Features

- **Managed Kubernetes** - Fully managed control plane by AWS
- **Node groups** - Configurable managed and self-managed node groups
- **Networking** - VPC, subnets, and security groups
- **IAM integration** - IRSA (IAM Roles for Service Accounts)
- **Add-ons** - CoreDNS, kube-proxy, VPC CNI pre-configured

## Prerequisites

- AWS Account with appropriate permissions
- Terraform >= 1.5
- AWS CLI configured
- kubectl installed

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                        AWS VPC                          │
│  ┌─────────────────┐  ┌─────────────────┐              │
│  │  Public Subnet  │  │  Public Subnet  │              │
│  │    (AZ-1)       │  │    (AZ-2)       │              │
│  └────────┬────────┘  └────────┬────────┘              │
│           │                    │                        │
│  ┌────────┴────────┐  ┌────────┴────────┐              │
│  │ Private Subnet  │  │ Private Subnet  │              │
│  │    (AZ-1)       │  │    (AZ-2)       │              │
│  │  ┌──────────┐   │  │  ┌──────────┐   │              │
│  │  │  Nodes   │   │  │  │  Nodes   │   │              │
│  │  └──────────┘   │  │  └──────────┘   │              │
│  └─────────────────┘  └─────────────────┘              │
│                                                         │
│              ┌─────────────────────┐                   │
│              │   EKS Control Plane │                   │
│              │     (Managed)       │                   │
│              └─────────────────────┘                   │
└─────────────────────────────────────────────────────────┘
```

## Quick Start

```bash
# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Apply the configuration
terraform apply

# Configure kubectl
aws eks update-kubeconfig --name <cluster-name> --region <region>
```

## Configuration

| Variable | Description | Default |
|----------|-------------|---------|
| `cluster_name` | Name of the EKS cluster | - |
| `cluster_version` | Kubernetes version | `1.28` |
| `vpc_cidr` | VPC CIDR block | `10.0.0.0/16` |
| `node_instance_types` | EC2 instance types for nodes | `["t3.medium"]` |
| `node_desired_size` | Desired number of nodes | `2` |

## Outputs

- `cluster_endpoint` - EKS cluster API endpoint
- `cluster_certificate_authority` - Cluster CA certificate
- `node_security_group_id` - Security group for worker nodes

## Support

Contact the Platform Team for assistance.
