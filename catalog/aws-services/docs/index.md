# AWS Services Integration

Comprehensive AWS cloud services and infrastructure management for the Cloud Sandbox platform.

## Quick Start

```bash
# Configure AWS CLI
aws configure

# Verify access
aws sts get-caller-identity

# List available regions
aws ec2 describe-regions --output table
```

## Core Services

| Service | Purpose | Use Case |
|---------|---------|----------|
| **EC2** | Virtual servers | Application hosting, batch processing |
| **ECS/EKS** | Container orchestration | Microservices, containerized apps |
| **Lambda** | Serverless compute | Event-driven functions, APIs |
| **S3** | Object storage | Static assets, backups, data lakes |
| **RDS** | Managed databases | PostgreSQL, MySQL, SQL Server |
| **VPC** | Networking | Network isolation, security |
| **IAM** | Identity & access | Authentication, authorization |
| **CloudFormation** | Infrastructure as Code | Automated provisioning |

## Features

- **Multi-Account Management**: Centralized control across AWS accounts using AWS Organizations
- **Infrastructure as Code**: CloudFormation and Terraform templates for reproducible deployments
- **Security First**: IAM roles, security groups, and KMS encryption by default
- **Cost Optimization**: Reserved instances, Savings Plans, and resource tagging
- **Monitoring**: CloudWatch metrics, alarms, and dashboards

## Architecture Overview

```
                         ┌─────────────────┐
                         │    Route 53     │
                         └────────┬────────┘
                                  │
                         ┌────────▼────────┐
                         │   CloudFront    │
                         └────────┬────────┘
                                  │
                         ┌────────▼────────┐
                         │       ALB       │
                         └────────┬────────┘
                                  │
              ┌───────────────────┼───────────────────┐
              │                   │                   │
     ┌────────▼────────┐ ┌────────▼────────┐ ┌────────▼────────┐
     │   ECS/EKS       │ │     Lambda      │ │      EC2        │
     │   Cluster       │ │   Functions     │ │   Instances     │
     └────────┬────────┘ └────────┬────────┘ └────────┬────────┘
              │                   │                   │
              └───────────────────┼───────────────────┘
                                  │
              ┌───────────────────┼───────────────────┐
              │                   │                   │
     ┌────────▼────────┐ ┌────────▼────────┐ ┌────────▼────────┐
     │      RDS        │ │   ElastiCache   │ │       S3        │
     └─────────────────┘ └─────────────────┘ └─────────────────┘
```

## Related Documentation

- [Overview](overview.md) - Detailed architecture and components
- [Usage](usage.md) - Practical examples and configurations
