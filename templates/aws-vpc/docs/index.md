# AWS VPC

This template provisions an Amazon Virtual Private Cloud (VPC) with public and private subnets across multiple Availability Zones, NAT gateways for outbound internet access, and VPC Flow Logs for network monitoring. The infrastructure follows AWS Well-Architected Framework best practices.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                                    VPC                                       │
│                              (10.0.0.0/16)                                   │
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────────┐│
│  │                         Internet Gateway                                 ││
│  └─────────────────────────────────────────────────────────────────────────┘│
│                                    │                                         │
│         ┌──────────────────────────┼──────────────────────────┐             │
│         │                          │                          │             │
│         ▼                          ▼                          ▼             │
│  ┌─────────────┐           ┌─────────────┐           ┌─────────────┐       │
│  │   Public    │           │   Public    │           │   Public    │       │
│  │  Subnet A   │           │  Subnet B   │           │  Subnet C   │       │
│  │ 10.0.0.0/24 │           │ 10.0.1.0/24 │           │ 10.0.2.0/24 │       │
│  └──────┬──────┘           └──────┬──────┘           └──────┬──────┘       │
│         │                          │                          │             │
│    ┌────┴────┐                ┌────┴────┐                ┌────┴────┐       │
│    │   NAT   │                │   NAT   │                │   NAT   │       │
│    │ Gateway │                │ Gateway │                │ Gateway │       │
│    └────┬────┘                └────┬────┘                └────┬────┘       │
│         │                          │                          │             │
│         ▼                          ▼                          ▼             │
│  ┌─────────────┐           ┌─────────────┐           ┌─────────────┐       │
│  │  Private    │           │  Private    │           │  Private    │       │
│  │  Subnet A   │           │  Subnet B   │           │  Subnet C   │       │
│  │ 10.0.3.0/24 │           │ 10.0.4.0/24 │           │ 10.0.5.0/24 │       │
│  └─────────────┘           └─────────────┘           └─────────────┘       │
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────────┐│
│  │                         VPC Flow Logs → CloudWatch                       ││
│  └─────────────────────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────────────────────┘
```

## Features

### Networking Components

| Component            | Description                                               |
| -------------------- | --------------------------------------------------------- |
| **VPC**              | Isolated virtual network with configurable CIDR block     |
| **Public Subnets**   | Internet-accessible subnets with auto-assigned public IPs |
| **Private Subnets**  | Internal subnets with NAT gateway egress                  |
| **Internet Gateway** | Enables internet connectivity for public subnets          |
| **NAT Gateways**     | One per AZ for high-availability outbound access          |
| **Route Tables**     | Separate routing for public and private subnets           |

### High Availability

| Feature                    | Implementation                                                     |
| -------------------------- | ------------------------------------------------------------------ |
| **Multi-AZ Deployment**    | Subnets distributed across 2-3 Availability Zones                  |
| **Redundant NAT**          | One NAT Gateway per AZ eliminates single point of failure          |
| **Automatic AZ Selection** | Uses `aws_availability_zones` data source for dynamic AZ discovery |

### Kubernetes Integration

The subnets include tags required for Amazon EKS:

| Tag                               | Value | Purpose                                           |
| --------------------------------- | ----- | ------------------------------------------------- |
| `kubernetes.io/role/elb`          | 1     | Public subnets for internet-facing load balancers |
| `kubernetes.io/role/internal-elb` | 1     | Private subnets for internal load balancers       |

### Monitoring & Security

| Feature           | Description                                                   |
| ----------------- | ------------------------------------------------------------- |
| **VPC Flow Logs** | Captures IP traffic metadata to CloudWatch Logs               |
| **Traffic Types** | Configurable: ALL, ACCEPT, or REJECT                          |
| **Log Retention** | Configurable retention period (default: 7 days)               |
| **IAM Role**      | Dedicated role with least-privilege permissions for flow logs |

## Prerequisites

- **AWS Account** with appropriate IAM permissions
- **Terraform** >= 1.0
- **AWS CLI** configured with credentials

### Required IAM Permissions

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:CreateVpc",
        "ec2:CreateSubnet",
        "ec2:CreateInternetGateway",
        "ec2:CreateNatGateway",
        "ec2:CreateRouteTable",
        "ec2:AllocateAddress",
        "ec2:CreateFlowLogs",
        "logs:CreateLogGroup",
        "iam:CreateRole",
        "iam:PutRolePolicy"
      ],
      "Resource": "*"
    }
  ]
}
```

## Quick Start

### 1. Initialize Terraform

```bash
terraform init
```

### 2. Configure Environment

Edit the appropriate environment file in `environments/`:

```hcl
# environments/dev.tfvars
name                     = "my-app-dev"
environment              = "dev"
vpc_cidr                 = "10.0.0.0/16"
availability_zones_count = 2
enable_nat_gateway       = true
enable_flow_logs         = true
```

### 3. Deploy

```bash
# Plan changes
terraform plan -var-file=environments/dev.tfvars

# Apply infrastructure
terraform apply -var-file=environments/dev.tfvars
```

## Configuration Reference

### Required Variables

| Variable      | Type   | Description                           |
| ------------- | ------ | ------------------------------------- |
| `name`        | string | VPC name identifier                   |
| `vpc_cidr`    | string | VPC CIDR block (e.g., 10.0.0.0/16)    |
| `environment` | string | Environment name (dev, staging, prod) |

### Networking Variables

| Variable                   | Type   | Default | Description                                    |
| -------------------------- | ------ | ------- | ---------------------------------------------- |
| `availability_zones_count` | number | 2       | Number of AZs to use (2-3)                     |
| `enable_dns_hostnames`     | bool   | true    | Enable DNS hostnames in VPC                    |
| `enable_dns_support`       | bool   | true    | Enable DNS resolution in VPC                   |
| `subnet_newbits`           | number | 8       | Bits to add to VPC CIDR for subnet calculation |

### NAT Gateway Variables

| Variable             | Type | Default | Description                             |
| -------------------- | ---- | ------- | --------------------------------------- |
| `enable_nat_gateway` | bool | true    | Create NAT gateways for private subnets |

### Flow Logs Variables

| Variable                   | Type   | Default | Description                       |
| -------------------------- | ------ | ------- | --------------------------------- |
| `enable_flow_logs`         | bool   | false   | Enable VPC Flow Logs              |
| `flow_logs_traffic_type`   | string | ALL     | Traffic type: ALL, ACCEPT, REJECT |
| `flow_logs_retention_days` | number | 7       | CloudWatch log retention period   |

## Outputs

| Output                   | Description                          |
| ------------------------ | ------------------------------------ |
| `vpc_id`                 | VPC identifier                       |
| `vpc_cidr_block`         | VPC CIDR block                       |
| `public_subnet_ids`      | List of public subnet IDs            |
| `private_subnet_ids`     | List of private subnet IDs           |
| `nat_gateway_ids`        | List of NAT Gateway IDs              |
| `nat_gateway_public_ips` | Elastic IPs assigned to NAT gateways |
| `internet_gateway_id`    | Internet Gateway ID                  |

## Subnet CIDR Calculation

The module automatically calculates subnet CIDRs using `cidrsubnet()`:

| Subnet           | CIDR (with default settings) |
| ---------------- | ---------------------------- |
| Public Subnet 1  | 10.0.0.0/24                  |
| Public Subnet 2  | 10.0.1.0/24                  |
| Public Subnet 3  | 10.0.2.0/24                  |
| Private Subnet 1 | 10.0.3.0/24                  |
| Private Subnet 2 | 10.0.4.0/24                  |
| Private Subnet 3 | 10.0.5.0/24                  |

## Cost Considerations

| Resource          | Pricing Factor                              |
| ----------------- | ------------------------------------------- |
| **NAT Gateway**   | ~$0.045/hour + $0.045/GB processed          |
| **Elastic IP**    | Free when attached, $0.005/hour when idle   |
| **VPC Flow Logs** | CloudWatch Logs ingestion and storage costs |

### Cost Optimization Tips

1. **Development environments**: Set `enable_nat_gateway = false` if private subnets don't need internet access
2. **Flow Logs**: Use `REJECT` traffic type only for security analysis to reduce log volume
3. **Single NAT**: For non-production, modify to use a single NAT gateway

## CI/CD Integration

The included GitHub Actions workflow provides:

- **Pull Request**: Format check, validation, and plan
- **Main Branch**: Automatic apply with environment-specific configurations
- **Terraform State**: Configured for remote backend (S3 + DynamoDB)

## Testing

Run Terraform native tests:

```bash
terraform test
```

## Troubleshooting

### Private Instances Can't Reach Internet

1. Verify NAT gateway is created and associated with correct route table
2. Check private subnet route table has 0.0.0.0/0 → NAT gateway route
3. Confirm NAT gateway has an Elastic IP attached

### Flow Logs Not Appearing

1. Allow 10-15 minutes for logs to start appearing
2. Verify IAM role has correct permissions
3. Check CloudWatch Log Group exists at `/aws/vpc/{vpc-name}/flow-logs`

### EKS Load Balancers Not Provisioning

1. Verify subnet tags are correctly applied
2. Ensure at least 2 subnets in different AZs
3. Check EKS cluster has proper IAM permissions

## Related Resources

- [AWS VPC Documentation](https://docs.aws.amazon.com/vpc/)
- [VPC Flow Logs](https://docs.aws.amazon.com/vpc/latest/userguide/flow-logs.html)
- [NAT Gateway](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-nat-gateway.html)
- [EKS Subnet Requirements](https://docs.aws.amazon.com/eks/latest/userguide/network_reqs.html)
