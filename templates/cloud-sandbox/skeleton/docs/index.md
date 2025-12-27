# ${{ values.name }}

${{ values.description }}

## Overview

This Cloud Sandbox environment provides an isolated, fully-configured cloud infrastructure for development, testing, and experimentation. Built on **${{ values.cloud_provider | upper }}** in the **${{ values.region }}** region, it includes networking, optional compute resources, and database services.

## Architecture

```d2
direction: down

title: {
  label: Cloud Sandbox Architecture
  near: top-center
  shape: text
  style.font-size: 24
  style.bold: true
}

internet: Internet {
  shape: cloud
  style.fill: "#E3F2FD"
  style.stroke: "#1976D2"
}

vpc: VPC (${{ values.vpc_cidr }}) {
  style.fill: "#E8F5E9"
  style.stroke: "#388E3C"

  public: Public Subnets {
    style.fill: "#C8E6C9"
    style.stroke: "#388E3C"

    igw: Internet Gateway {
      shape: hexagon
      style.fill: "#FFFFFF"
    }

    nat: NAT Gateway {
      shape: hexagon
      style.fill: "#FFF3E0"
      style.stroke: "#FF9800"
    }

    bastion: Bastion Host {
      shape: rectangle
      style.fill: "#E1F5FE"
      style.stroke: "#0288D1"
    }
  }

  private: Private Subnets {
    style.fill: "#FCE4EC"
    style.stroke: "#C2185B"

    eks: EKS Cluster {
      shape: rectangle
      style.fill: "#F3E5F5"
      style.stroke: "#7B1FA2"

      nodes: Worker Nodes {
        shape: rectangle
        style.fill: "#E1BEE7"
      }
    }

    rds: RDS PostgreSQL {
      shape: cylinder
      style.fill: "#E3F2FD"
      style.stroke: "#1976D2"
    }
  }

  public.igw -> public.nat
  public.nat -> private
}

internet -> vpc.public.igw
internet -> vpc.public.bastion: SSH (22)
vpc.public.bastion -> vpc.private: Internal Access
vpc.private.eks -> vpc.private.rds: PostgreSQL (5432)
```

## Configuration Summary

| Setting | Value |
|---------|-------|
| **Sandbox Name** | `${{ values.name }}` |
| **Cloud Provider** | ${{ values.cloud_provider | upper }} |
| **Region** | `${{ values.region }}` |
| **Environment** | `${{ values.environment }}` |
| **VPC CIDR** | `${{ values.vpc_cidr }}` |
| **Public Subnets** | ${{ values.public_subnets }} |
| **Private Subnets** | ${{ values.private_subnets }} |

## Components

### Core Infrastructure

| Component | Status | Description |
|-----------|--------|-------------|
| **VPC** | Always included | Virtual Private Cloud with isolated networking |
| **Public Subnets** | ${{ values.public_subnets }} subnets | Internet-accessible subnets across availability zones |
| **Private Subnets** | ${{ values.private_subnets }} subnets | Internal subnets for workloads and databases |
| **NAT Gateway** | Auto-enabled if private subnets exist | Allows private subnet internet access |
| **Internet Gateway** | Always included | Provides public internet connectivity |

### Optional Components

| Component | Enabled | Description |
|-----------|---------|-------------|
| **Bastion Host** | ${{ values.include_bastion }} | SSH jump server for secure access |
| **EKS Cluster** | ${{ values.include_eks }} | Managed Kubernetes (v1.28) with worker nodes |
| **RDS Database** | ${{ values.include_rds }} | PostgreSQL 15 on db.t3.micro |

---

## CI/CD Pipeline

This repository includes a GitHub Actions pipeline for infrastructure management:

```d2
direction: right

pr: Pull Request {
  shape: oval
  style.fill: "#E3F2FD"
  style.stroke: "#1976D2"
}

validate: Validate {
  style.fill: "#E8F5E9"
  style.stroke: "#388E3C"
  label: "terraform fmt\nterraform validate\ntflint"
}

security: Security Scan {
  style.fill: "#FFCDD2"
  style.stroke: "#D32F2F"
  label: "tfsec\nCheckov\nTrivy"
}

plan: Plan {
  style.fill: "#E3F2FD"
  style.stroke: "#1976D2"
  label: "terraform plan\nCost Estimate"
}

approval: Approval {
  shape: diamond
  style.fill: "#FFECB3"
  style.stroke: "#FFA000"
  label: "Manual\nReview"
}

apply: Apply {
  style.fill: "#E8F5E9"
  style.stroke: "#388E3C"
  label: "terraform apply"
}

pr -> validate -> security -> plan -> approval -> apply
```

### Pipeline Triggers

| Trigger | Actions |
|---------|---------|
| **Pull Request** | Validate, Security Scan, Plan |
| **Push to main** | Validate, Security Scan, Plan, Apply (with approval) |
| **Manual dispatch** | Plan, Apply, or Destroy |

---

## Prerequisites

### 1. AWS Account Setup

#### Create OIDC Identity Provider

GitHub Actions uses OpenID Connect (OIDC) for secure, keyless authentication:

```bash
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1
```

#### Required IAM Permissions

The IAM role needs permissions for:

- **VPC**: Create/manage VPCs, subnets, route tables, NAT/Internet gateways
- **EC2**: Launch instances (bastion), manage security groups
- **EKS**: Create/manage clusters and node groups (if enabled)
- **RDS**: Create/manage database instances (if enabled)
- **S3/DynamoDB**: Terraform state backend access

### 2. GitHub Repository Setup

#### Required Secrets

| Secret | Description |
|--------|-------------|
| `AWS_ROLE_ARN` | IAM role ARN for OIDC authentication |
| `TF_STATE_BUCKET` | S3 bucket for Terraform state |
| `TF_STATE_LOCK_TABLE` | DynamoDB table for state locking |

#### Terraform Backend

```bash
# Create S3 bucket for state
aws s3 mb s3://your-terraform-state-bucket --region ${{ values.region }}
aws s3api put-bucket-versioning --bucket your-terraform-state-bucket \
  --versioning-configuration Status=Enabled

# Create DynamoDB table for locking
aws dynamodb create-table \
  --table-name terraform-state-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST
```

---

## Usage

### Local Development

```bash
# Clone repository
git clone <repository-url>
cd ${{ values.name }}

# Initialize Terraform
terraform init

# Format and validate
terraform fmt -recursive
terraform validate

# Plan changes
terraform plan -out=tfplan

# Apply changes
terraform apply tfplan
```

### Environment-Specific Deployment

```bash
# Development
terraform plan -var-file=environments/dev.tfvars

# Staging
terraform plan -var-file=environments/staging.tfvars
```

### Accessing Resources

#### Bastion Host (if enabled)

```bash
# Get bastion IP
BASTION_IP=$(terraform output -raw bastion_public_ip)

# SSH to bastion
ssh -i ~/.ssh/your-key.pem ec2-user@$BASTION_IP
```

#### EKS Cluster (if enabled)

```bash
# Update kubeconfig
aws eks update-kubeconfig --name ${{ values.name }} --region ${{ values.region }}

# Verify connection
kubectl get nodes
```

#### RDS Database (if enabled)

```bash
# Get connection string
terraform output rds_endpoint

# Connect via bastion
ssh -L 5432:<rds-endpoint>:5432 ec2-user@$BASTION_IP
psql -h localhost -U admin -d ${{ values.name | replace("-", "_") }}
```

---

## Outputs

| Output | Description |
|--------|-------------|
| `vpc_id` | VPC identifier |
| `public_subnet_ids` | List of public subnet IDs |
| `private_subnet_ids` | List of private subnet IDs |
| `bastion_public_ip` | Bastion host public IP (if enabled) |
| `eks_cluster_endpoint` | EKS API endpoint (if enabled) |
| `rds_endpoint` | Database connection endpoint (if enabled) |

```bash
# View all outputs
terraform output

# Get specific output
terraform output -raw vpc_id
```

---

## Security Considerations

### Network Security

```d2
direction: right

internet: Internet {
  shape: cloud
}

waf: Security Controls {
  style.fill: "#FFCDD2"
  style.stroke: "#D32F2F"

  sg_bastion: Bastion SG {
    label: "Ingress: SSH (22)\nfrom: 0.0.0.0/0"
  }

  sg_eks: EKS SG {
    label: "Ingress: Internal\nfrom: VPC CIDR"
  }

  sg_rds: RDS SG {
    label: "Ingress: PostgreSQL (5432)\nfrom: VPC CIDR"
  }
}

private: Private Resources {
  style.fill: "#E8F5E9"

  eks: EKS
  rds: RDS
}

internet -> waf.sg_bastion: "SSH Only"
waf.sg_bastion -> private: "Internal"
waf.sg_eks -> private.eks
waf.sg_rds -> private.rds
```

### Best Practices

| Practice | Implementation |
|----------|---------------|
| **No public databases** | RDS in private subnets only |
| **SSH via bastion** | No direct SSH to private instances |
| **Least privilege** | Security groups restrict by port and source |
| **Encryption** | RDS encryption at rest enabled |
| **State protection** | Remote state with locking |

### Sandbox-Specific Warnings

> ⚠️ **This is a sandbox environment**
>
> - Do NOT store production data
> - Resources may be auto-destroyed after inactivity
> - No SLA or backup guarantees
> - Enable deletion protection for long-running sandboxes

---

## Cost Estimation

Estimated monthly costs (USD) for this configuration:

| Resource | Quantity | Monthly Cost |
|----------|----------|-------------|
| **NAT Gateway** | 1 | ~$32 |
| **Elastic IP** | 1 | ~$3.60 |
| **Bastion (t3.micro)** | 1 | ~$8.50 |
| **EKS Cluster** | 1 | ~$72 |
| **EKS Nodes (t3.medium)** | 2 | ~$60 |
| **RDS (db.t3.micro)** | 1 | ~$15 |
| **Storage (20GB)** | 1 | ~$2 |
| **Data Transfer** | Variable | ~$5-20 |

**Estimated Total**: $50-200/month depending on options enabled

---

## Cleanup

To destroy the sandbox environment:

```bash
# Review what will be destroyed
terraform plan -destroy

# Destroy all resources
terraform destroy

# Confirm by typing 'yes'
```

Or use the GitHub Actions workflow:
1. Go to **Actions** tab
2. Select **Terraform** workflow
3. Click **Run workflow**
4. Set action to `destroy`
5. Type `DESTROY` to confirm

---

## Troubleshooting

### Common Issues

| Issue | Resolution |
|-------|------------|
| **EKS nodes not joining** | Check IAM roles and security groups |
| **Cannot connect to RDS** | Verify security group allows VPC CIDR |
| **NAT Gateway timeout** | Check route tables for private subnets |
| **Terraform state lock** | Wait or manually remove DynamoDB lock |

### Getting Help

- **Platform Team**: Contact via Slack `#platform-support`
- **Documentation**: [Internal Wiki](https://wiki.example.com/cloud-sandbox)
- **Issues**: Create a GitHub issue in this repository

---

## Related Resources

| Template | Description |
|----------|-------------|
| [aws-vpc](/docs/default/template/aws-vpc) | Standalone VPC configuration |
| [aws-eks](/docs/default/template/aws-eks) | Production EKS cluster |
| [aws-rds](/docs/default/template/aws-rds) | Production RDS database |
| [terraform-infrastructure](/docs/default/template/terraform-infrastructure) | Multi-cloud infrastructure |

---

## References

- [AWS VPC Documentation](https://docs.aws.amazon.com/vpc/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/)
- [EKS Best Practices](https://aws.github.io/aws-eks-best-practices/)
- [GitHub Actions OIDC](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services)
