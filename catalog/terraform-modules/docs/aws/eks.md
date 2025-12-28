# AWS EKS Module

Creates a production-ready Amazon EKS cluster with managed node groups, IRSA (IAM Roles for Service Accounts), and essential add-ons.

## Features

- EKS cluster with configurable Kubernetes version
- Managed node groups with auto-scaling
- OIDC provider for IAM Roles for Service Accounts (IRSA)
- Essential add-ons (CoreDNS, kube-proxy, VPC CNI, EBS CSI)
- Control plane logging to CloudWatch
- Public and/or private endpoint access
- SSM access for node troubleshooting

## Usage

### Basic Usage

```hcl
module "eks" {
  source = "../../../aws/resources/kubernetes/eks"

  name        = "myapp"
  environment = "prod"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids

  cluster_version = "1.29"
}
```

### Production Configuration

```hcl
module "eks" {
  source = "../../../aws/resources/kubernetes/eks"

  name        = "myapp"
  environment = "prod"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids

  cluster_version = "1.29"

  # Restrict public access
  cluster_endpoint_public_access       = true
  cluster_endpoint_private_access      = true
  cluster_endpoint_public_access_cidrs = ["203.0.113.0/24"]  # Your office IP

  node_groups = {
    general = {
      instance_types = ["m6i.large", "m5.large"]
      capacity_type  = "ON_DEMAND"
      disk_size      = 100
      desired_size   = 3
      min_size       = 2
      max_size       = 10
      labels = {
        workload = "general"
      }
    }
    spot = {
      instance_types = ["m6i.large", "m5.large", "m6a.large"]
      capacity_type  = "SPOT"
      disk_size      = 50
      desired_size   = 2
      min_size       = 0
      max_size       = 20
      labels = {
        workload = "batch"
      }
      taints = [{
        key    = "spot"
        value  = "true"
        effect = "NO_SCHEDULE"
      }]
    }
  }

  cluster_addons = {
    coredns = {
      resolve_conflicts = "OVERWRITE"
    }
    kube-proxy = {
      resolve_conflicts = "OVERWRITE"
    }
    vpc-cni = {
      resolve_conflicts = "OVERWRITE"
    }
    aws-ebs-csi-driver = {
      resolve_conflicts = "OVERWRITE"
    }
  }

  enable_cluster_autoscaler          = true
  enable_aws_load_balancer_controller = true
  enable_external_dns                 = true
  enable_secrets_manager              = true

  tags = {
    CostCenter = "platform"
  }
}
```

### Development Configuration

```hcl
module "eks" {
  source = "../../../aws/resources/kubernetes/eks"

  name        = "myapp"
  environment = "dev"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids

  cluster_version = "1.29"

  node_groups = {
    default = {
      instance_types = ["t3.medium"]
      capacity_type  = "SPOT"
      disk_size      = 30
      desired_size   = 2
      min_size       = 1
      max_size       = 5
    }
  }
}
```

## Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `name` | Name prefix for resources | `string` | - | Yes |
| `environment` | Environment (dev, staging, prod) | `string` | - | Yes |
| `vpc_id` | VPC ID | `string` | - | Yes |
| `subnet_ids` | Subnet IDs for EKS cluster | `list(string)` | - | Yes |
| `cluster_version` | Kubernetes version | `string` | `"1.29"` | No |
| `cluster_endpoint_public_access` | Enable public endpoint access | `bool` | `true` | No |
| `cluster_endpoint_private_access` | Enable private endpoint access | `bool` | `true` | No |
| `cluster_endpoint_public_access_cidrs` | CIDRs for public endpoint | `list(string)` | `["0.0.0.0/0"]` | No |
| `node_groups` | Node groups configuration | `map(object)` | See below | No |
| `cluster_addons` | EKS add-ons configuration | `map(object)` | See below | No |
| `enable_cluster_autoscaler` | Enable Cluster Autoscaler IAM | `bool` | `true` | No |
| `enable_aws_load_balancer_controller` | Enable ALB Controller IAM | `bool` | `true` | No |
| `enable_external_dns` | Enable External DNS IAM | `bool` | `false` | No |
| `enable_secrets_manager` | Enable Secrets Manager CSI | `bool` | `true` | No |
| `tags` | Tags to apply to resources | `map(string)` | `{}` | No |

### Node Group Configuration

```hcl
node_groups = {
  default = {
    instance_types = ["t3.medium"]    # List of instance types
    capacity_type  = "ON_DEMAND"      # ON_DEMAND or SPOT
    disk_size      = 50               # GB
    desired_size   = 2
    min_size       = 1
    max_size       = 5
    labels         = {}               # Kubernetes labels
    taints         = []               # Kubernetes taints
  }
}
```

## Outputs

| Name | Description |
|------|-------------|
| `cluster_id` | EKS cluster ID |
| `cluster_name` | EKS cluster name |
| `cluster_endpoint` | EKS cluster endpoint |
| `cluster_certificate_authority_data` | Base64 encoded CA data |
| `cluster_version` | EKS cluster version |
| `cluster_security_group_id` | Cluster security group ID |
| `oidc_provider_arn` | OIDC provider ARN for IRSA |
| `oidc_provider_url` | OIDC provider URL |
| `node_group_role_arn` | Node group IAM role ARN |

## Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                         EKS Cluster                           │
│  ┌────────────────────────────────────────────────────────┐  │
│  │                   Control Plane                         │  │
│  │  ┌─────────┐  ┌─────────┐  ┌─────────────────────┐    │  │
│  │  │   API   │  │  etcd   │  │  Controller Manager │    │  │
│  │  │ Server  │  │         │  │     + Scheduler     │    │  │
│  │  └─────────┘  └─────────┘  └─────────────────────┘    │  │
│  └────────────────────────────────────────────────────────┘  │
│                              │                                │
│                    ┌─────────┴─────────┐                     │
│                    │   OIDC Provider   │                     │
│                    │      (IRSA)       │                     │
│                    └───────────────────┘                     │
└──────────────────────────────────────────────────────────────┘
                               │
        ┌──────────────────────┼──────────────────────┐
        │                      │                      │
┌───────┴───────┐      ┌───────┴───────┐      ┌───────┴───────┐
│  Node Group   │      │  Node Group   │      │  Node Group   │
│   (general)   │      │    (spot)     │      │    (gpu)      │
│               │      │               │      │               │
│ ┌───┐ ┌───┐  │      │ ┌───┐ ┌───┐  │      │ ┌───┐ ┌───┐  │
│ │Pod│ │Pod│  │      │ │Pod│ │Pod│  │      │ │Pod│ │Pod│  │
│ └───┘ └───┘  │      │ └───┘ └───┘  │      │ └───┘ └───┘  │
└───────────────┘      └───────────────┘      └───────────────┘
```

## Add-ons

### Default Add-ons

| Add-on | Purpose |
|--------|---------|
| `coredns` | Cluster DNS |
| `kube-proxy` | Network proxy |
| `vpc-cni` | AWS VPC networking |
| `aws-ebs-csi-driver` | EBS persistent volumes |

### IRSA-Ready Components

The module creates OIDC provider for these components:

- **Cluster Autoscaler** - Auto-scales node groups
- **AWS Load Balancer Controller** - Manages ALB/NLB
- **External DNS** - Manages Route53 records
- **Secrets Manager CSI** - Mounts secrets as volumes

## Connecting to Cluster

```bash
# Update kubeconfig
aws eks update-kubeconfig --name myapp-eks --region us-east-1

# Verify connection
kubectl get nodes
```

## Security Features

### Control Plane Logging
All log types enabled:
- API server
- Audit
- Authenticator
- Controller manager
- Scheduler

### Node Security
- SSM Session Manager enabled
- No SSH keys required
- IMDSv2 recommended

### Network Security
- Private endpoint for internal access
- Public endpoint with CIDR restrictions
- Security groups managed automatically

## Cost Considerations

| Component | Cost Factor |
|-----------|-------------|
| Control Plane | ~$0.10/hour (~$73/month) |
| Node Groups | EC2 instance pricing |
| NAT Gateway | Data processing for private nodes |

**Tips:**
- Use Spot instances for non-critical workloads
- Right-size node groups using metrics
- Consider Graviton instances for cost savings
