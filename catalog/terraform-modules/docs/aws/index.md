# AWS Modules

Enterprise-grade AWS infrastructure modules following AWS Well-Architected Framework best practices.

## Available Modules

| Module | Description | Key Features |
|--------|-------------|--------------|
| [VPC](vpc.md) | Virtual Private Cloud | Multi-AZ subnets, NAT Gateway, VPC endpoints |
| [EKS](eks.md) | Elastic Kubernetes Service | Managed node groups, IRSA, add-ons |
| [S3](s3.md) | Simple Storage Service | Encryption, versioning, lifecycle |
| [RDS](rds.md) | Relational Database Service | Multi-AZ, Performance Insights, Secrets Manager |

## Architecture Patterns

### Standard Three-Tier Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                         VPC                                  │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │
│  │   Public    │  │   Private   │  │  Database   │         │
│  │   Subnet    │  │   Subnet    │  │   Subnet    │         │
│  │  (ALB/NLB)  │  │  (EKS/EC2)  │  │   (RDS)     │         │
│  └─────────────┘  └─────────────┘  └─────────────┘         │
│         │                │                │                 │
│         └────────────────┼────────────────┘                 │
│                          │                                  │
│              ┌───────────┴───────────┐                     │
│              │     NAT Gateway       │                     │
│              └───────────────────────┘                     │
└─────────────────────────────────────────────────────────────┘
```

## Provider Requirements

All AWS modules require:

```hcl
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0"
    }
  }
}
```

## Security Best Practices

### Encryption
- All storage encrypted at rest (S3, RDS, EBS)
- KMS customer-managed keys supported
- SSL/TLS enforced for data in transit

### Network Security
- Private subnets for workloads
- Security groups with least-privilege access
- VPC endpoints for AWS service access
- VPC Flow Logs enabled by default

### Identity & Access
- IAM Roles for Service Accounts (IRSA) for EKS
- Secrets Manager for database credentials
- No hardcoded credentials

## Cost Optimization

### Development Environments
```hcl
# Use single NAT Gateway
single_nat_gateway = true

# Use smaller instances
instance_class = "db.t3.micro"

# Disable Multi-AZ
multi_az = false
```

### Production Environments
```hcl
# Multi-AZ NAT Gateways
single_nat_gateway = false

# Right-sized instances
instance_class = "db.r6g.large"

# Enable Multi-AZ
multi_az = true
```

## Tagging Strategy

All modules apply consistent tags:

```hcl
tags = {
  Environment = var.environment
  ManagedBy   = "terraform"
  Project     = var.name
  CostCenter  = "infrastructure"
}
```

## Related Resources

- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)
- [AWS Security Best Practices](https://docs.aws.amazon.com/wellarchitected/latest/security-pillar/welcome.html)
- [Terraform AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
