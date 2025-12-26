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

| Service            | Purpose                 | Use Case                              |
| ------------------ | ----------------------- | ------------------------------------- |
| **EC2**            | Virtual servers         | Application hosting, batch processing |
| **ECS/EKS**        | Container orchestration | Microservices, containerized apps     |
| **Lambda**         | Serverless compute      | Event-driven functions, APIs          |
| **S3**             | Object storage          | Static assets, backups, data lakes    |
| **RDS**            | Managed databases       | PostgreSQL, MySQL, SQL Server         |
| **VPC**            | Networking              | Network isolation, security           |
| **IAM**            | Identity & access       | Authentication, authorization         |
| **CloudFormation** | Infrastructure as Code  | Automated provisioning                |

## Features

- **Multi-Account Management**: Centralized control across AWS accounts using AWS Organizations
- **Infrastructure as Code**: CloudFormation and Terraform templates for reproducible deployments
- **Security First**: IAM roles, security groups, and KMS encryption by default
- **Cost Optimization**: Reserved instances, Savings Plans, and resource tagging
- **Monitoring**: CloudWatch metrics, alarms, and dashboards

## Architecture Overview

```d2
direction: down

title: AWS Cloud Architecture {
  shape: text
  near: top-center
  style.font-size: 24
}

users: Users {
  shape: person
  style.fill: "#E3F2FD"
}

edge: Edge Services {
  shape: rectangle
  style.fill: "#FFE0B2"

  route53: Route 53 {
    shape: hexagon
    style.fill: "#FF9800"
    style.font-color: white
    label: "DNS"
  }

  cloudfront: CloudFront {
    shape: hexagon
    style.fill: "#FF9800"
    style.font-color: white
    label: "CDN"
  }
}

network: VPC {
  shape: rectangle
  style.fill: "#E8F5E9"

  alb: Application Load Balancer {
    shape: hexagon
    style.fill: "#4CAF50"
    style.font-color: white
  }

  public: Public Subnets {
    shape: rectangle
    style.fill: "#C8E6C9"
    nat: NAT Gateway
    bastion: Bastion Host
  }

  private: Private Subnets {
    shape: rectangle
    style.fill: "#A5D6A7"

    compute: Compute Layer {
      shape: rectangle
      style.fill: "#81C784"

      ecs: ECS/EKS {
        shape: rectangle
        style.fill: "#2196F3"
        style.font-color: white
      }

      lambda: Lambda {
        shape: rectangle
        style.fill: "#FF9800"
        style.font-color: white
      }

      ec2: EC2 {
        shape: rectangle
        style.fill: "#9C27B0"
        style.font-color: white
      }
    }
  }
}

data: Data Layer {
  shape: rectangle
  style.fill: "#E1BEE7"

  rds: RDS {
    shape: cylinder
    style.fill: "#9C27B0"
    style.font-color: white
  }

  elasticache: ElastiCache {
    shape: cylinder
    style.fill: "#9C27B0"
    style.font-color: white
  }

  s3: S3 {
    shape: cylinder
    style.fill: "#9C27B0"
    style.font-color: white
  }
}

users -> edge.route53: DNS lookup
edge.route53 -> edge.cloudfront
edge.cloudfront -> network.alb: origin
network.alb -> network.private.compute
network.private.compute -> data
```

## Related Documentation

- [Overview](overview.md) - Detailed architecture and components
- [Usage](usage.md) - Practical examples and configurations
