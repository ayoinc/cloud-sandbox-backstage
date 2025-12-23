# Terraform Infrastructure Template

This template creates enterprise-grade cloud infrastructure with Terraform, including networking, compute, security, monitoring, and compliance controls.

## Overview

Provision production-ready cloud infrastructure across AWS, Azure, GCP, or multi-cloud environments with built-in security, monitoring, and compliance features.

## Features

### Cloud Providers
- Amazon Web Services (AWS)
- Microsoft Azure
- Google Cloud Platform (GCP)
- Multi-Cloud Setup

### Infrastructure Types
- Web Application Stack
- Data Platform
- ML/AI Platform
- Container Platform (EKS/AKS/GKE)
- Serverless Platform
- Networking Foundation

### Components
| Component | Description |
|-----------|-------------|
| Networking | VPC/VNet with subnets, NAT, routing |
| Compute | Kubernetes, VMs, serverless |
| Database | Managed database services |
| Storage | Object storage, file storage |
| Security | WAF, secrets management, KMS |
| Monitoring | Logging, metrics, alerting |

## Configuration Options

| Parameter | Description | Default |
|-----------|-------------|---------|
| `cloud_provider` | Target cloud | aws |
| `infrastructure_type` | Infrastructure pattern | web-application |
| `enable_kubernetes` | Deploy K8s cluster | false |
| `compliance_framework` | Compliance target | none |
| `environments` | Target environments | staging, production |

## Getting Started

### Prerequisites
- Terraform >= 1.5
- Cloud provider CLI (aws, az, gcloud)
- Proper IAM credentials

### Initial Setup

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd <infrastructure-name>
   ```

2. **Initialize Terraform**
   ```bash
   terraform init
   ```

3. **Configure backend** (recommended)
   ```hcl
   # backend.tf
   terraform {
     backend "s3" {
       bucket = "my-terraform-state"
       key    = "infrastructure/terraform.tfstate"
       region = "us-east-1"
     }
   }
   ```

4. **Set variables**
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars
   ```

### Deployment

```bash
# Format code
terraform fmt -recursive

# Validate configuration
terraform validate

# Plan changes
terraform plan -out=tfplan

# Apply changes
terraform apply tfplan

# Destroy (when needed)
terraform destroy
```

## Project Structure

```
├── main.tf                 # Main configuration
├── variables.tf            # Input variables
├── outputs.tf              # Output values
├── versions.tf             # Provider versions
├── terraform.tfvars        # Variable values
├── modules/
│   ├── networking/         # VPC/VNet module
│   ├── compute/            # Compute resources
│   ├── database/           # Database module
│   ├── storage/            # Storage module
│   ├── security/           # Security module
│   └── monitoring/         # Monitoring module
├── environments/
│   ├── dev/
│   ├── staging/
│   └── production/
└── .github/
    └── workflows/
        └── terraform.yml   # CI/CD workflow
```

## Module Architecture

### Networking Module
```hcl
module "networking" {
  source = "./modules/networking"

  name        = var.name
  environment = var.environment
  cidr_block  = var.vpc_cidr

  public_subnets  = var.public_subnets
  private_subnets = var.private_subnets
  
  enable_nat_gateway = true
  single_nat_gateway = var.environment != "production"
}
```

### Kubernetes Module
```hcl
module "kubernetes" {
  source = "./modules/compute/kubernetes"

  cluster_name    = var.name
  cluster_version = var.kubernetes_version
  
  vpc_id          = module.networking.vpc_id
  subnet_ids      = module.networking.private_subnet_ids
  
  node_groups = {
    general = {
      instance_types = ["t3.medium"]
      min_size       = 2
      max_size       = 10
      desired_size   = 3
    }
  }
}
```

## Security Features

### Secrets Management
```hcl
resource "aws_secretsmanager_secret" "app_secrets" {
  name        = "${var.name}-secrets"
  description = "Application secrets"
  
  tags = local.common_tags
}
```

### KMS Encryption
```hcl
resource "aws_kms_key" "main" {
  description             = "Main encryption key"
  deletion_window_in_days = 30
  enable_key_rotation     = true
}
```

### WAF Configuration
```hcl
resource "aws_wafv2_web_acl" "main" {
  name  = "${var.name}-waf"
  scope = "REGIONAL"

  default_action {
    allow {}
  }

  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 1
    
    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }
  }
}
```

## Compliance Frameworks

### CIS Benchmarks
- Encrypted storage at rest
- VPC flow logs enabled
- CloudTrail logging
- Security group restrictions

### PCI DSS
- Network segmentation
- Encryption in transit and at rest
- Access logging
- Vulnerability management

### HIPAA
- PHI data encryption
- Audit logging
- Access controls
- Backup and recovery

## Monitoring and Alerting

### CloudWatch/Azure Monitor/Cloud Monitoring
```hcl
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "${var.name}-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "CPU utilization exceeded 80%"
  alarm_actions       = [aws_sns_topic.alerts.arn]
}
```

### Log Retention
- Development: 7 days
- Staging: 30 days
- Production: 90-365 days

## Cost Optimization

### Features Included
- Auto-scaling configurations
- Spot/preemptible instance support
- Reserved capacity recommendations
- Cost allocation tags
- Budget alerts

### Best Practices
```hcl
resource "aws_budgets_budget" "monthly" {
  name         = "${var.name}-monthly-budget"
  budget_type  = "COST"
  limit_amount = var.monthly_budget
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  notification {
    comparison_operator = "GREATER_THAN"
    threshold           = 80
    threshold_type      = "PERCENTAGE"
    notification_type   = "FORECASTED"
    subscriber_email_addresses = var.alert_emails
  }
}
```

## Disaster Recovery

### Multi-Region Setup
- Primary region with full deployment
- Secondary region with standby resources
- Cross-region replication for critical data
- Route 53 health checks and failover

## CI/CD Integration

### GitHub Actions Workflow
```yaml
name: Terraform
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  terraform:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: hashicorp/setup-terraform@v3
      
      - name: Terraform Init
        run: terraform init
        
      - name: Terraform Plan
        run: terraform plan -no-color
```

## Related Templates

- [AWS EKS](../aws-eks) - AWS Kubernetes cluster
- [Azure AKS](../azure-aks) - Azure Kubernetes cluster  
- [GCP GKE](../gcp-gke) - GCP Kubernetes cluster
- [Terraform Module](../terraform-module) - Reusable module template
