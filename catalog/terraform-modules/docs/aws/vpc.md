# AWS VPC Module

Creates a production-ready VPC with public, private, and database subnets following AWS Well-Architected Framework best practices.

## Features

- Multi-AZ deployment with customizable availability zones
- Public subnets with Internet Gateway
- Private subnets with NAT Gateway (single or per-AZ)
- Isolated database subnets with DB subnet group
- VPC Flow Logs to CloudWatch
- VPC Endpoints for S3 and DynamoDB
- Kubernetes-ready subnet tags

## Usage

### Basic Usage

```hcl
module "vpc" {
  source = "../../../aws/resources/network/vpc"

  name        = "myapp"
  environment = "prod"
  vpc_cidr    = "10.0.0.0/16"
}
```

### Production Configuration

```hcl
module "vpc" {
  source = "../../../aws/resources/network/vpc"

  name        = "myapp"
  environment = "prod"
  vpc_cidr    = "10.0.0.0/16"

  availability_zones    = ["us-east-1a", "us-east-1b", "us-east-1c"]
  public_subnet_cidrs   = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnet_cidrs  = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
  database_subnet_cidrs = ["10.0.21.0/24", "10.0.22.0/24", "10.0.23.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = false  # One NAT per AZ for HA

  enable_flow_logs         = true
  flow_logs_retention_days = 90

  tags = {
    CostCenter = "infrastructure"
  }
}
```

### Development Configuration (Cost-Optimized)

```hcl
module "vpc" {
  source = "../../../aws/resources/network/vpc"

  name        = "myapp"
  environment = "dev"
  vpc_cidr    = "10.0.0.0/16"

  enable_nat_gateway = true
  single_nat_gateway = true  # Single NAT to save costs

  enable_flow_logs = false   # Disable for dev
}
```

## Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `name` | Name prefix for resources | `string` | - | Yes |
| `environment` | Environment (dev, staging, prod) | `string` | - | Yes |
| `vpc_cidr` | CIDR block for VPC | `string` | `"10.0.0.0/16"` | No |
| `availability_zones` | List of availability zones | `list(string)` | Auto-detected | No |
| `public_subnet_cidrs` | CIDR blocks for public subnets | `list(string)` | `["10.0.1.0/24", ...]` | No |
| `private_subnet_cidrs` | CIDR blocks for private subnets | `list(string)` | `["10.0.11.0/24", ...]` | No |
| `database_subnet_cidrs` | CIDR blocks for database subnets | `list(string)` | `["10.0.21.0/24", ...]` | No |
| `enable_nat_gateway` | Enable NAT Gateway | `bool` | `true` | No |
| `single_nat_gateway` | Use single NAT Gateway | `bool` | `false` | No |
| `enable_vpn_gateway` | Enable VPN Gateway | `bool` | `false` | No |
| `enable_flow_logs` | Enable VPC Flow Logs | `bool` | `true` | No |
| `flow_logs_retention_days` | Flow logs retention in days | `number` | `30` | No |
| `enable_dns_hostnames` | Enable DNS hostnames | `bool` | `true` | No |
| `enable_dns_support` | Enable DNS support | `bool` | `true` | No |
| `tags` | Tags to apply to resources | `map(string)` | `{}` | No |

## Outputs

| Name | Description |
|------|-------------|
| `vpc_id` | VPC ID |
| `vpc_cidr` | VPC CIDR block |
| `public_subnet_ids` | List of public subnet IDs |
| `private_subnet_ids` | List of private subnet IDs |
| `database_subnet_ids` | List of database subnet IDs |
| `database_subnet_group_name` | Database subnet group name |
| `nat_gateway_ids` | List of NAT Gateway IDs |
| `internet_gateway_id` | Internet Gateway ID |
| `availability_zones` | List of availability zones used |

## Architecture

```
                    Internet
                        │
                ┌───────┴───────┐
                │    Internet   │
                │    Gateway    │
                └───────┬───────┘
                        │
    ┌───────────────────┼───────────────────┐
    │                   │                   │
┌───┴───┐          ┌───┴───┐          ┌───┴───┐
│Public │          │Public │          │Public │
│Subnet │          │Subnet │          │Subnet │
│ AZ-a  │          │ AZ-b  │          │ AZ-c  │
└───┬───┘          └───┬───┘          └───┬───┘
    │NAT               │NAT               │NAT
┌───┴───┐          ┌───┴───┐          ┌───┴───┐
│Private│          │Private│          │Private│
│Subnet │          │Subnet │          │Subnet │
│ AZ-a  │          │ AZ-b  │          │ AZ-c  │
└───────┘          └───────┘          └───────┘

┌───────┐          ┌───────┐          ┌───────┐
│  DB   │          │  DB   │          │  DB   │
│Subnet │          │Subnet │          │Subnet │
│ AZ-a  │          │ AZ-b  │          │ AZ-c  │
└───────┘          └───────┘          └───────┘
    │                   │                   │
    └───────────────────┼───────────────────┘
                        │
              DB Subnet Group (isolated)
```

## Security Features

### VPC Flow Logs
- Captures all traffic metadata
- Stored in CloudWatch Logs
- Configurable retention period
- Useful for security analysis and troubleshooting

### VPC Endpoints
- Gateway endpoints for S3 and DynamoDB
- Traffic stays within AWS network
- No NAT Gateway charges for AWS services

### Subnet Isolation
- Database subnets have no internet access
- Private subnets access internet via NAT
- Public subnets for load balancers only

## Kubernetes Integration

Subnets are automatically tagged for Kubernetes:

```hcl
# Public subnets
"kubernetes.io/role/elb" = "1"

# Private subnets
"kubernetes.io/role/internal-elb" = "1"
```

## Cost Considerations

| Component | Cost Factor |
|-----------|-------------|
| NAT Gateway | ~$0.045/hour + data processing |
| VPC Endpoints | Gateway endpoints are free |
| Flow Logs | CloudWatch Logs ingestion costs |

**Tips:**
- Use `single_nat_gateway = true` for non-production
- VPC endpoints reduce NAT Gateway data costs
- Disable flow logs in development
