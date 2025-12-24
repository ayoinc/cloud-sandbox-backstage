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

```d2
direction: down

vpc: AWS VPC {
  style.fill: "#e3f2fd"

  az1-public: Public Subnet (AZ-1) {
    style.fill: "#c8e6c9"
  }

  az2-public: Public Subnet (AZ-2) {
    style.fill: "#c8e6c9"
  }

  az1-private: Private Subnet (AZ-1) {
    style.fill: "#b3e5fc"
    nodes1: Nodes
  }

  az2-private: Private Subnet (AZ-2) {
    style.fill: "#b3e5fc"
    nodes2: Nodes
  }

  control-plane: EKS Control Plane (Managed) {
    style.fill: "#fff3e0"
  }

  az1-public -> az1-private
  az2-public -> az2-private
  control-plane -> az1-private.nodes1
  control-plane -> az2-private.nodes2
}
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

| Variable              | Description                  | Default         |
| --------------------- | ---------------------------- | --------------- |
| `cluster_name`        | Name of the EKS cluster      | -               |
| `cluster_version`     | Kubernetes version           | `1.28`          |
| `vpc_cidr`            | VPC CIDR block               | `10.0.0.0/16`   |
| `node_instance_types` | EC2 instance types for nodes | `["t3.medium"]` |
| `node_desired_size`   | Desired number of nodes      | `2`             |

## Outputs

- `cluster_endpoint` - EKS cluster API endpoint
- `cluster_certificate_authority` - Cluster CA certificate
- `node_security_group_id` - Security group for worker nodes

## Support

Contact the Platform Team for assistance.
