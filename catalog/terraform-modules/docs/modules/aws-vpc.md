# AWS VPC Module

This Terraform module creates an AWS VPC with public and private subnets across multiple availability zones.

## Overview

Amazon Virtual Private Cloud (VPC) enables you to launch AWS resources into a virtual network that you've defined. This module provides a production-ready VPC implementation with best practices.

AWS VPC is the foundation of AWS networking, providing:

- **Network Isolation**: Complete control over your virtual networking environment
- **Security**: Multiple layers of security with subnets, security groups, and NACLs
- **Scalability**: Design networks that scale from single instances to enterprise applications
- **Flexibility**: Connect to on-premises networks via VPN or AWS Direct Connect

**Common Use Cases:**

- Web applications with public-facing load balancers and private application/database tiers
- Microservices architectures requiring service-to-service communication
- Data processing pipelines with secure data storage
- Hybrid cloud deployments extending on-premises networks
- Multi-tier enterprise applications requiring isolation between components

## Features

- **Multi-AZ Deployment**: High availability across multiple availability zones
- **Public & Private Subnets**: Separate subnets for internet-facing and internal resources
- **NAT Gateway Options**: Choose between single/multi-AZ NAT Gateway deployments
- **VPC Flow Logs**: Comprehensive network traffic logging for security and troubleshooting
- **DNS Support**: Full DNS hostname and resolution support
- **Network ACLs**: Default secure Network ACL configurations
- **Route Tables**: Automatic route table creation and association
- **VPC Endpoints**: Optional AWS service endpoints (S3, DynamoDB)
- **IP Address Management**: Proper CIDR block allocation and subnet sizing
- **Internet Gateway**: Automatic IGW creation and attachment for public subnets

## Architecture

The module creates a dual-tier network architecture:

```d2
direction: down

title: AWS VPC Architecture {
  shape: text
  near: top-center
  style.font-size: 20
  style.bold: true
}

vpc: AWS VPC {
  style.fill: "#e3f2fd"
  style.stroke: "#1565c2"

  label: "AWS VPC\nCIDR: 10.0.0.0/16"
}

gateways: Gateways {
  style.fill: transparent
  style.stroke: transparent

  igw: Internet Gateway {
    shape: hexagon
    style.fill: "#4caf50"
    style.font-color: white
  }

  nat: NAT Gateway {
    shape: hexagon
    style.fill: "#ff9800"
    style.font-color: white
  }
}

subnets: Subnet Tiers {
  style.fill: transparent
  style.stroke: transparent

  public: Public Subnets (3 AZs) {
    style.fill: "#c8e6c9"
    style.stroke: "#2e7d32"
    label: "Public Subnets\n10.0.1.0/24\n10.0.2.0/24\n10.0.3.0/24"
  }

  private: Private Subnets (3 AZs) {
    style.fill: "#fff3e0"
    style.stroke: "#ef6c00"
    label: "Private Subnets\n10.0.11.0/24\n10.0.12.0/24\n10.0.13.0/24"
  }
}

internet: Internet {
  shape: cloud
  style.fill: "#e0e0e0"
}

vpc -> gateways.igw
vpc -> gateways.nat
gateways.igw -> subnets.public: "Direct access"
gateways.nat -> subnets.private: "Outbound only"
subnets.private -> internet: "via NAT" {style.stroke-dash: 3}
subnets.public -> internet: "Direct"
```

**Public Subnets:**

- Direct internet access via Internet Gateway
- Route tables with 0.0.0.0/0 → Internet Gateway
- Typically host load balancers, NAT Gateways, bastion hosts

**Private Subnets:**

- Internet access only via NAT Gateway
- No direct inbound internet access
- Host application servers, databases, backend services
- Enhanced security layer for sensitive resources

## Usage

### Simple VPC for Development

Basic VPC with public subnets only for development/testing:

```hcl
module "vpc_dev" {
  source = "git::https://github.com/company/terraform-modules.git//aws/vpc?ref=v1.0.0"

  name               = "dev-vpc"
  cidr_block         = "10.0.0.0/16"
  availability_zones = ["us-east-1a", "us-east-1b"]

  # Public subnets only for dev
  public_subnets     = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets    = []

  enable_nat_gateway = false

  tags = {
    Environment = "development"
    CostCenter  = "dev-team"
  }
}
```

### Production VPC with High Availability

Full production setup with private subnets, multi-AZ NAT Gateways, and VPC Flow Logs:

```hcl
module "vpc_production" {
  source = "git::https://github.com/company/terraform-modules.git//aws/vpc?ref=v1.0.0"

  name               = "production-vpc"
  cidr_block         = "10.0.0.0/16"
  availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]

  # Public subnets for load balancers and NAT
  public_subnets     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]

  # Private subnets for application servers
  private_subnets    = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]

  # High availability NAT (one per AZ)
  enable_nat_gateway = true
  single_nat_gateway = false

  # DNS configuration
  enable_dns_hostnames = true
  enable_dns_support   = true

  # VPC Flow Logs for security auditing
  enable_flow_logs  = true
  flow_logs_destination = "cloudwatch" # or "s3"

  tags = {
    Environment = "production"
    ManagedBy   = "terraform"
    Tier        = "network-foundation"
  }
}

# Use VPC outputs for downstream resources
module "app_servers" {
  source = "git::https://github.com/company/terraform-modules.git//aws/ec2-asg?ref=v1.0.0"

  vpc_id            = module.vpc_production.vpc_id
  subnet_ids        = module.vpc_production.private_subnet_ids

  # Security group referencing VPC
  security_group_rules = [
    {
      type        = "ingress"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = [module.vpc_production.vpc_cidr_block]
    }
  ]
}
```

### Private-Only VPC with VPC Endpoints

Isolated VPC with no internet access, using VPC endpoints for AWS services:

```hcl
module "vpc_private" {
  source = "git::https://github.com/company/terraform-modules.git//aws/vpc?ref=v1.0.0"

  name               = "private-vpc"
  cidr_block         = "10.1.0.0/16"
  availability_zones = ["us-east-1a", "us-east-1b"]

  # No public subnets
  public_subnets  = []
  private_subnets = ["10.1.1.0/24", "10.1.2.0/24"]

  # No NAT Gateways
  enable_nat_gateway = false

  # VPC Endpoints for AWS services (no internet required)
  enable_s3_endpoint       = true
  enable_dynamodb_endpoint = true

  # Disable DNS hostnames for enhanced isolation
  enable_dns_hostnames = false

  tags = {
    Environment = "secure"
    Access      = "isolated"
  }
}

# Example: Deploying resources in private VPC
resource "aws_instance" "database" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t3.large"
  subnet_id     = module.vpc_private.private_subnet_ids[0]

  # No public IP - completely isolated
  associate_public_ip_address = false

  # Access S3 via VPC endpoint (no internet required)
  user_data = <<-EOF
              #!/bin/bash
              aws s3 cp s3://my-config-bucket/app-config.yml /etc/app/
              EOF
}
```

## Inputs

### Required Parameters

| Name                 | Description                                       | Type           | Example                                      |
| -------------------- | ------------------------------------------------- | -------------- | -------------------------------------------- |
| `name`               | Name prefix for all VPC resources (max 24 chars)  | `string`       | `"production-vpc"`                           |
| `cidr_block`         | Primary IPv4 CIDR block for the VPC               | `string`       | `"10.0.0.0/16"`                              |
| `availability_zones` | List of availability zones to deploy subnets into | `list(string)` | `["us-east-1a", "us-east-1b", "us-east-1c"]` |

**CIDR Block Sizing Examples:**

```hcl
# Small VPC (254 hosts per subnet)
cidr_block = "10.0.0.0/16"
public_subnets  = ["10.0.1.0/24"]    # 254 IPs
private_subnets = ["10.0.11.0/24"]   # 254 IPs

# Medium VPC (4,094 hosts per subnet)
cidr_block = "10.0.0.0/16"
public_subnets  = ["10.0.1.0/20"]    # 4,094 IPs
private_subnets = ["10.0.16.0/20"]   # 4,094 IPs

# Large VPC with reserved space
cidr_block = "10.0.0.0/16"           # 65,534 IPs total
public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]      # 508 IPs (0.8%)
private_subnets = ["10.0.11.0/24", "10.0.12.0/24"]    # 508 IPs (0.8%)
# Reserved: 10.0.100-254.x.x for future use (~96% of space)
```

### Subnet Configuration

| Name                  | Description                            | Type           | Default | Example                            |
| --------------------- | -------------------------------------- | -------------- | ------- | ---------------------------------- |
| `public_subnets`      | List of public subnet CIDR blocks      | `list(string)` | `[]`    | `["10.0.1.0/24", "10.0.2.0/24"]`   |
| `private_subnets`     | List of private subnet CIDR blocks     | `list(string)` | `[]`    | `["10.0.11.0/24", "10.0.12.0/24"]` |
| `database_subnets`    | List of database subnet CIDR blocks    | `list(string)` | `[]`    | `["10.0.21.0/24", "10.0.22.0/24"]` |
| `elasticache_subnets` | List of ElastiCache subnet CIDR blocks | `list(string)` | `[]`    | `["10.0.31.0/24", "10.0.32.0/24"]` |
| `redshift_subnets`    | List of Redshift subnet CIDR blocks    | `list(string)` | `[]`    | `["10.0.41.0/24", "10.0.42.0/24"]` |

**Subnet Sizing Strategy:**

```hcl
# Conservative sizing for 3-tier application
module "vpc" {
  source = "git::https://github.com/company/terraform-modules.git//aws/vpc?ref=v1.0.0"

  name               = "web-app-vpc"
  cidr_block         = "10.0.0.0/16"
  availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]

  # Public: Load balancers, NAT (small, few hosts)
  public_subnets     = ["10.0.1.0/26", "10.0.1.64/26", "10.0.1.128/26"]  # 62 IPs each

  # Private: Application servers (medium, moderate hosts)
  private_subnets    = ["10.0.2.0/24", "10.0.3.0/24", "10.0.4.0/24"]         # 254 IPs each

  # Database: RDS instances (small, few hosts, high isolation)
  database_subnets   = ["10.0.5.0/28", "10.0.5.16/28", "10.0.5.32/28"]        # 14 IPs each

  # Reserved space: 10.0.6-254.x.x for future expansion
}
```

### NAT Gateway Configuration

| Name                     | Description                                           | Type   | Default |
| ------------------------ | ----------------------------------------------------- | ------ | ------- |
| `enable_nat_gateway`     | Enable NAT Gateway for private subnet internet access | `bool` | `true`  |
| `single_nat_gateway`     | Use single NAT Gateway vs one per AZ                  | `bool` | `false` |
| `enable_eip_nat_gateway` | Allocate Elastic IPs for NAT Gateways                 | `bool` | `true`  |

**Architecture Choice:**

```hcl
# High-Availability (Multi-AZ NAT) - $43.80/mo per AZ
# Recommended for: Production workloads requiring AZ failover capability
single_nat_gateway = false  # One NAT per AZ

# Cost-Optimized (Single NAT) - $32.85/mo total
# Recommended for: Non-critical workloads, cost-sensitive environments
single_nat_gateway = true   # Single NAT in first AZ

# No Internet Access - $0/mo
# Recommended for: Compliance, ultra-secure workloads, batch processing
enable_nat_gateway = false
```

### DNS Configuration

| Name                     | Description                         | Type   | Default |
| ------------------------ | ----------------------------------- | ------ | ------- |
| `enable_dns_hostnames`   | Enable DNS hostnames for instances  | `bool` | `true`  |
| `enable_dns_support`     | Enable DNS resolution within VPC    | `bool` | `true`  |
| `enable_ec2_metadata_v2` | Enable IMDSv2 for enhanced security | `bool` | `true`  |

### VPC Flow Logs Configuration

| Name                    | Description                        | Type     | Default        |
| ----------------------- | ---------------------------------- | -------- | -------------- |
| `enable_flow_logs`      | Enable VPC Flow Logs               | `bool`   | `false`        |
| `flow_logs_destination` | Destination: "cloudwatch" or "s3"  | `string` | `"cloudwatch"` |
| `flow_logs_retention`   | Log retention in days (CloudWatch) | `number` | `90`           |
| `flow_logs_bucket`      | S3 bucket name for flow logs       | `string` | `null`         |

**Flow Logs Setup Examples:**

```hcl
# CloudWatch Logs (simple setup)
enable_flow_logs      = true
flow_logs_destination = "cloudwatch"
flow_logs_retention   = 365  # 1 year retention

# S3 Logs (cost-effective for high-volume)
enable_flow_logs      = true
flow_logs_destination = "s3"
flow_logs_bucket      = "my-vpc-flow-logs-bucket"

# Custom log format
flow_logs_format = "${version} ${account-id} ${interface-id} ${srcaddr} ${dstaddr}
                    ${srcport} ${dstport} ${protocol} ${packets} ${bytes} ${start}
                    ${end} ${action} ${log-status} ${vpc-id} ${subnet-id} ${instance-id}
                    ${tcp-flags} ${type} ${pkt-srcaddr} ${pkt-dstaddr}"
```

### VPC Endpoints Configuration

| Name                       | Description                      | Type   | Default |
| -------------------------- | -------------------------------- | ------ | ------- |
| `enable_s3_endpoint`       | Create VPC endpoint for S3       | `bool` | `true`  |
| `enable_dynamodb_endpoint` | Create VPC endpoint for DynamoDB | `bool` | `false` |
| `endpoint_private_dns`     | Enable private DNS for endpoints | `bool` | `true`  |

### Advanced Configuration

| Name                               | Description                              | Type           | Default |
| ---------------------------------- | ---------------------------------------- | -------------- | ------- |
| `secondary_cidr_blocks`            | List of secondary IPv4 CIDR blocks       | `list(string)` | `[]`    |
| `ipv6_cidr_block`                  | IPv6 CIDR block for VPC                  | `string`       | `null`  |
| `enable_ipv6_gateway`              | Enable IPv6 egress-only gateway          | `bool`         | `false` |
| `assign_generated_ipv6_cidr_block` | Auto-assign IPv6 block                   | `bool`         | `false` |
| `map_public_ip_on_launch`          | Auto-assign public IPs in public subnets | `bool`         | `false` |
| `create_database_subnet_group`     | Create RDS subnet group                  | `bool`         | `true`  |

**Advanced Example:**

```hcl
# IPv6-enabled VPC
module "vpc_ipv6" {
  source = "git::https://github.com/company/terraform-modules.git//aws/vpc?ref=v1.0.0"

  name               = "ipv6-vpc"
  cidr_block         = "10.0.0.0/16"
  availability_zones = ["us-east-1a", "us-east-1b"]

  enable_ipv6_gateway                = true
  assign_generated_ipv6_cidr_block   = true

  public_subnets     = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets    = ["10.0.11.0/24", "10.0.12.0/24"]

  # Optional secondary CIDR for expansion
  secondary_cidr_blocks = ["10.1.0.0/16"]
}
```

## Outputs

### Core VPC Information

| Name             | Description                     | Usage Example                                |
| ---------------- | ------------------------------- | -------------------------------------------- |
| `vpc_id`         | The ID of the VPC               | `vpc_id = module.vpc.vpc_id`                 |
| `vpc_cidr_block` | The CIDR block of the VPC       | `vpc_cidr_block = module.vpc.vpc_cidr_block` |
| `vpc_arn`        | The ARN of the VPC              | `vpc_arn = module.vpc.vpc_arn`               |
| `vpc_owner_id`   | The AWS account ID of VPC owner | `owner_id = module.vpc.vpc_owner_id`         |

**Usage Examples:**

```hcl
# Reference VPC ID in security groups
resource "aws_security_group" "app_sg" {
  name   = "app-sg"
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [module.vpc.vpc_cidr_block]
    description = "Allow HTTP from VPC internal"
  }
}

# Reference VPC CIDR in IAM policies
data "aws_iam_policy_document" "vpc_s3_access" {
  statement {
    actions   = ["s3:*"]
    resources = ["*"]
    condition {
      test     = "IpAddress"
      variable = "aws:SourceIp"
      values   = [module.vpc.vpc_cidr_block]
    }
  }
}
```

### Subnet Outputs

| Name                     | Description                    | Usage Example                                    |
| ------------------------ | ------------------------------ | ------------------------------------------------ |
| `public_subnet_ids`      | List of public subnet IDs      | `subnet_ids = module.vpc.public_subnet_ids`      |
| `public_subnet_arns`     | List of public subnet ARNs     | `subnet_arns = module.vpc.public_subnet_arns`    |
| `private_subnet_ids`     | List of private subnet IDs     | `subnet_ids = module.vpc.private_subnet_ids`     |
| `private_subnet_arns`    | List of private subnet ARNs    | `subnet_arns = module.vpc.private_subnet_arns`   |
| `database_subnet_ids`    | List of database subnet IDs    | `subnet_ids = module.vpc.database_subnet_ids`    |
| `elasticache_subnet_ids` | List of ElastiCache subnet IDs | `subnet_ids = module.vpc.elasticache_subnet_ids` |
| `redshift_subnet_ids`    | List of Redshift subnet IDs    | `subnet_ids = module.vpc.redshift_subnet_ids`    |

**Usage Examples:**

```hcl
# Deploy ALB in public subnets
resource "aws_lb" "app_alb" {
  name               = "app-alb"
  internal           = false
  load_balancer_type = "application"

  subnets            = module.vpc.public_subnet_ids
  security_groups    = [aws_security_group.alb_sg.id]
}

# Deploy RDS in database subnets
module "rds_database" {
  source = "terraform-aws-modules/rds/aws"

  identifier = "app-db"

  # Use database subnet group created by VPC module
  db_subnet_group_name = module.vpc.database_subnet_group_name

  # Place in private database subnets
  vpc_security_group_ids = [module.vpc.security_group_internal_id]
}

# Deploy EC2 instances across private subnets evenly
resource "aws_instance" "app_servers" {
  count = 3

  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t3.medium"
  subnet_id     = module.vpc.private_subnet_ids[count.index % length(module.vpc.private_subnet_ids)]

  tags = {
    Name = "app-server-${count.index + 1}"
  }
}

# Reference specific subnets for AZ-specific deployments
locals {
  first_az_subnet  = module.vpc.private_subnet_ids[0]
  second_az_subnet = module.vpc.private_subnet_ids[1]
  third_az_subnet  = length(module.vpc.private_subnet_ids) > 2 ?
                     module.vpc.private_subnet_ids[2] : null
}
```

### Network Component Outputs

| Name                     | Description                    | Usage Example                                 |
| ------------------------ | ------------------------------ | --------------------------------------------- |
| `internet_gateway_id`    | Internet Gateway ID            | `gateway_id = module.vpc.internet_gateway_id` |
| `nat_gateway_ids`        | List of NAT Gateway IDs        | `nat_ids = module.vpc.nat_gateway_ids`        |
| `nat_gateway_public_ips` | List of NAT Gateway public IPs | `nat_ips = module.vpc.nat_gateway_public_ips` |

### Network Configuration Outputs

| Name                      | Description                     | Usage Example                                          |
| ------------------------- | ------------------------------- | ------------------------------------------------------ |
| `default_route_table_id`  | Default route table ID          | `route_table_id = module.vpc.default_route_table_id`   |
| `public_route_table_ids`  | List of public route table IDs  | `route_table_ids = module.vpc.public_route_table_ids`  |
| `private_route_table_ids` | List of private route table IDs | `route_table_ids = module.vpc.private_route_table_ids` |

### Security Group Outputs

| Name                        | Description                     | Usage Example                                           |
| --------------------------- | ------------------------------- | ------------------------------------------------------- |
| `default_security_group_id` | Default VPC security group ID   | `security_group = module.vpc.default_security_group_id` |
| `shared_security_group_id`  | Shared resources security group | `security_group = module.vpc.shared_security_group_id`  |

**Usage Examples:**

```hcl
# Add routes to private route tables for VPN
resource "aws_route" "vpn_routes" {
  count = length(module.vpc.private_route_table_ids)

  route_table_id         = module.vpc.private_route_table_ids[count.index]
  destination_cidr_block = "192.168.0.0/16"
  vpn_gateway_id         = aws_vpn_gateway.main.id
}

# Reference NAT Gateway IPs in external firewall rules
resource "aws_network_acl_rule" "allow_nat_outbound" {
  network_acl_id = aws_network_acl.main.id
  rule_number    = 100
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = module.vpc.nat_gateway_public_ips[0]
  from_port      = 1024
  to_port        = 65535
}

# VPC endpoints for module integration
output "vpc_endpoint_s3_id" {
  value       = module.vpc.vpc_endpoint_s3_id
  description = "VPC endpoint ID for S3 access"
}
```

## Subnet Design Best Practices

### CIDR Allocation Strategy

```d2
direction: right

title: Recommended Allocation for /16 VPC (10.0.0.0/16) {
  shape: text
  near: top-center
  style.font-size: 16
  style.bold: true
}

zone1: Zone 1 {
  style.fill: "#e3f2fd"
  style.stroke: "#1565c2"

  label: "10.0.0-63.x.x\n(10.0.0.0/18)"

  public1: Public {
    style.fill: "#c8e6c9"
    label: ".1/24"
  }
  private1: Private {
    style.fill: "#fff3e0"
    label: ".11/24"
  }
}

zone2: Zone 2 {
  style.fill: "#e3f2fd"
  style.stroke: "#1565c2"

  label: "10.0.64-127.x.x\n(10.0.64.0/18)"

  public2: Public {
    style.fill: "#c8e6c9"
    label: ".65/24"
  }
  private2: Private {
    style.fill: "#fff3e0"
    label: ".75/24"
  }
}

zone3: Zone 3 {
  style.fill: "#e3f2fd"
  style.stroke: "#1565c2"

  label: "10.0.128-191.x.x\n(10.0.128.0/18)"

  public3: Public {
    style.fill: "#c8e6c9"
    label: ".129/24"
  }
  private3: Private {
    style.fill: "#fff3e0"
    label: ".139/24"
  }
}

zone1 -> zone2 -> zone3
```

### Sizing Formulas

**Calculate Future Capacity:**

```
Current Hosts × Growth Factor × (1 + Buffer Factor)

Example:
  Current: 50 hosts
  Growth: 3x (290% growth)
  Buffer: 25%
Total: 50 × 3 × 1.25 = 188 hosts needed

Subnet Size: /24 (254 hosts) ✓
NOT: /26 (62 hosts) ✗
```

**Application Tier Guidelines:**

- **Public Subnets:** Size for load balancers + NAT + bastion hosts

  - Small apps: 26-50 IPs per AZ → /26 (62 IPs)
  - Large apps: 50+ IPs per AZ → /25 (126 IPs)

- **Application Layer:** Size based on auto-scaling max capacity

  - Example: If max instances = 100 across 3 AZs:
  - 100 instances / 3 AZs = 34 per AZ + 1 per 10 buffer
  - Recommended: /25 subnet (126 IPs per AZ)

- **Database Layer:** Size conservatively (databases don't scale fast)
  - Small: /28 (14 IPs per AZ)
  - Medium: /27 (30 IPs per AZ)
  - Enterprise: /26 (62 IPs per AZ)

### Growth Planning

**Reserve Space Using Hierarchical Planning:**

```hcl
# Current needs
public_subnets  = ["10.0.1.0/24"]
private_subnets = ["10.0.11.0/24"]

# Reserve future space by using classful allocation
# Public: 10.0.1-10.x.x (10 /24s reserved)
# Private: 10.0.11-30.x.x (20 /24s reserved)
# Database: 10.0.31-40.x.x (10 /24s reserved)
# Future: 10.0.41-254.x.x (214 /24s available)
```

**Multi-Region CIDR Strategy:**

```
us-east-1: 10.0.0.0/16 (Production)
us-west-2: 10.1.0.0/16 (DR/Prod)

Shared Services: 10.254.0.0/16 (Management)
```

## NAT Gateway Configuration

### Single vs Multi-AZ Comparison

**Multi-AZ NAT (High Availability)**

```hcl
single_nat_gateway = false
# cost: $43.80 per AZ per month ($0.045/hr × 730hrs × 4AZs = ~$135/mo)
# pros: AZ-independent operation, automatic failover
# cons: Higher cost, egress traffic remains in same AZ
```

**Single NAT (Cost Optimized)**

```hcl
single_nat_gateway = true
# cost: $32.85 per month ($0.045/hr × 730hrs)
# pros: 75% cost savings, simpler architecture
# cons: AZ dependency, manual failover required if AZ fails
```

**Decision Matrix:**

```
Use Single NAT When:
✓ Non-production environments (dev, test, staging)
✓ Batch processing workloads (can tolerate downtime)
✓ Cost is primary concern
✓ Manual failover is acceptable

Use Multi-AZ NAT When:
✓ Production workloads requiring 99.9%+ uptime
✓ Stateful applications that can't handle IP changes
✓ Automated failover required
✓ Multi-AZ architecture already deployed
```

### Cost Optimization Strategies

1. **NAT Instance Alternative** (for development):

```hcl
# Use t3.small NAT Instance: ~$15/mo vs $32/mo NAT Gateway
# Save 50%+ but manage your own instance
module "vpc_dev" {
  source = "git::https://github.com/company/terraform-modules.git//aws/vpc?ref=v1.0.0"

  # Custom NAT instance module
  enable_nat_gateway = false
}

module "nat_instance" {
  source = "terraform-aws-modules/nat-instance/aws"
  vpc_id = module.vpc_dev.vpc_id
  subnet_id = module.vpc_dev.public_subnet_ids[0]
}
```

2. **Gateway Load Balancer for Shared NAT**:

```hcl
# Share NAT across multiple VPCs using GWLB
# Higher upfront, lower cost at scale (>5 VPCs)
cost_per_additional_vpc = (NAT_GW_COST / NUM_VPCS) + GWLB_HOURLY
```

3. **Egress-Only Internet Gateway (IPv6)**:

```hcl
# Free alternative for IPv6-only workloads
# Outbound-only, no NAT charges
enable_ipv6_gateway = true
assign_generated_ipv6_cidr_block = true
```

## Security Configuration

### Network ACLs vs Security Groups

**Network ACLs (Subnet Layer):**

```hcl
# Module creates default deny-all NACLs
# You should customize per subnet tier
resource "aws_network_acl_rule" "public_ingress" {
  network_acl_id = module.vpc.public_network_acl_id
  rule_number    = 100
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 80
  to_port        = 80
}

resource "aws_network_acl_rule" "private_ingress" {
  network_acl_id = module.vpc.private_network_acl_id
  rule_number    = 100
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = module.vpc.vpc_cidr_block  # Only from within VPC
  from_port      = 0
  to_port        = 65535
}
```

**Security Groups (Instance Layer):**

```hcl
# Application tier security group
resource "aws_security_group" "app_tier" {
  name        = "app-tier"
  description = "Application tier security group"
  vpc_id      = module.vpc.vpc_id

  # Allow from load balancer
  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  # Allow all outbound
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"  # All protocols
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```

### VPC Endpoints for Private AWS Access

```hcl
# S3 Gateway Endpoint (No cost, recommended)
resource "aws_vpc_endpoint" "s3" {
  vpc_id       = module.vpc.vpc_id
  service_name = "com.amazonaws.${data.aws_region.current}.s3"

  vpc_endpoint_type = "Gateway"
  route_table_ids   = module.vpc.private_route_table_ids
}

# Interface Endpoints (Cost: $7.20/month per AZ per endpoint)
resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id            = module.vpc.vpc_id
  service_name      = "com.amazonaws.${data.aws_region.current}.ecr.api"
  vpc_endpoint_type = "Interface"

  subnet_ids         = module.vpc.private_subnet_ids
  security_group_ids = [aws_security_group.endpoints.id]
}

# VPC Endpoint for Systems Manager (No public IPs required)
resource "aws_vpc_endpoint" "ssm" {
  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current}.ssm"
  vpc_endpoint_type   = "Interface"

  subnet_ids          = module.vpc.private_subnet_ids
  security_group_ids  = [aws_security_group.ssm_endpoint.id]

  private_dns_enabled = true  # Use AWS service endpoint DNS
}
```

### VPC Flow Logs for Security Monitoring

```hcl
# Enable flow logs with custom format
module "vpc_secure" {
  source = "git::https://github.com/company/terraform-modules.git//aws/vpc?ref=v1.0.0"

  name               = "secure-vpc"
  cidr_block         = "10.0.0.0/16"
  availability_zones = ["us-east-1a", "us-east-1b"]

  # Enable flow logs for security auditing
  enable_flow_logs  = true
  flow_logs_destination = "s3"
  flow_logs_bucket = aws_s3_bucket.flow_logs.id

  # Enrich logs with additional fields
  flow_logs_format = "${version} ${account-id} ${interface-id} ${srcaddr}
                      ${dstaddr} ${srcport} ${dstport} ${protocol} ${packets}
                      ${bytes} ${start} ${end} ${action} ${log-status} ${vpc-id}
                      ${subnet-id} ${instance-id} ${tcp-flags} ${type}
                      ${pkt-srcaddr} ${pkt-dstaddr} ${region} ${az-id}
                      ${sublocation-type} ${sublocation-id} ${pkt-src-aws-service}
                      ${pkt-dst-aws-service} ${flow-direction} ${traffic-path}"
}

# Query suspicious traffic patterns in CloudWatch
# LastUpdate = successful traffic, NODATA = dropped/rejected
```

### Bastion Host Setup

```hcl
# Deploy bastion host in public subnet
module "bastion_host" {
  source = "terraform-aws-modules/ec2-instance/aws"

  name  = "bastion"
  count = length(module.vpc.public_subnet_ids)

  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = "t3.micro"
  key_name               = "production-key"
  monitoring             = true

  subnet_id              = module.vpc.public_subnet_ids[count.index]
  vpc_security_group_ids = [aws_security_group.bastion.id]

  # Hardening
  metadata_options = {
    http_endpoint               = "enabled"
    http_tokens                 = "required"  # IMDSv2
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }
}

# Strict security group for bastion
resource "aws_security_group" "bastion" {
  name        = "bastion"
  description = "Bastion host security group"
  vpc_id      = module.vpc.vpc_id
}

resource "aws_security_group_rule" "bastion_ssh" {
  security_group_id = aws_security_group.bastion.id
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["203.0.113.0/24"]  # Your office IP
}
```

## Integration with Other Modules

### EKS (Elastic Kubernetes Service)

```hcl
module "vpc" {
  source = "git::https://github.com/company/terraform-modules.git//aws/vpc?ref=v1.0.0"

  name               = "eks-vpc"
  cidr_block         = "10.100.0.0/16"
  availability_zones = ["us-west-2a", "us-west-2b", "us-west-2c"]

  public_subnets  = ["10.100.1.0/24", "10.100.2.0/24", "10.100.3.0/24"]
  private_subnets = ["10.100.11.0/24", "10.100.12.0/24", "10.100.13.0/24"]

  tags = {
    "kubernetes.io/cluster/eks-cluster" = "shared"
    "kubernetes.io/role/elb"            = "1"
    "kubernetes.io/role/internal-elb"   = "1"
  }
}

module "eks" {
  source = "terraform-aws-modules/eks/aws"

  cluster_name    = "eks-cluster"
  cluster_version = "1.30"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids
}

# Addons requiring VPC integration
resource "aws_eks_addon" "vpc_cni" {
  cluster_name  = module.eks.cluster_id
  addon_name    = "vpc-cni"
  addon_version = "v1.15.4-eksbuild.1"

  configuration_values = jsonencode({
    env = {
      AWS_VPC_K8S_CNI_CUSTOM_NETWORK_CFG = "true"
      ENABLE_POD_ENI                       = "true"
    }
  })
}
```

### RDS (Relational Database Service)

```hcl
module "vpc" {
  source = "git::https://github.com/company/terraform-modules.git//aws/vpc?ref=v1.0.0"

  name               = "rds-vpc"
  cidr_block         = "10.0.0.0/16"
  availability_zones = ["us-east-1a", "us-east-1b"]

  database_subnets   = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets    = ["10.0.11.0/24", "10.0.12.0/24"]
}

module "rds_mysql" {
  source = "terraform-aws-modules/rds/aws"

  identifier = "app-database"

  engine               = "mysql"
  engine_version       = "8.0"
  family               = "mysql8.0"
  instance_class       = "db.t3.medium"
  allocated_storage    = 100
  max_allocated_storage = 1000

  # Use database subnets
  db_subnet_group_name = module.vpc.database_subnet_group_name

  # Security from VPC CIDR
  vpc_security_group_ids = [aws_security_group.rds.id]
}

resource "aws_security_group" "rds" {
  name   = "rds-security-group"
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = module.vpc.private_subnets_cidr_blocks
  }
}
```

### Application Load Balancer

```hcl
module "alb" {
  source = "terraform-aws-modules/alb/aws"

  name = "app-alb"
  load_balancer_type = "application"
  internal           = false

  vpc_id          = module.vpc.vpc_id
  subnets         = module.vpc.public_subnet_ids
  security_groups = [module.alb_security_group.security_group_id]

  target_groups = [
    {
      name_prefix      = "app"
      backend_protocol = "HTTP"
      backend_port     = 80
      target_type      = "instance"
      targets          = aws_instance.app.*.id
    }
  ]
}

module "alb_security_group" {
  source = "terraform-aws-modules/security-group/aws"

  name   = "alb-sg"
  vpc_id = module.vpc.vpc_id

  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["http-80-tcp", "https-443-tcp"]

  egress_rules = ["all-all"]
}
```

### EC2 Auto Scaling

```hcl
resource "aws_autoscaling_group" "app" {
  name                = "app-asg"
  vpc_zone_identifier = module.vpc.private_subnet_ids

  min_size         = 2
  max_size         = 10
  desired_capacity = 3

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  target_group_arns = [module.alb.target_group_arns[0]]

  tag {
    key                 = "Environment"
    value               = "production"
    propagate_at_launch = true
  }
}

resource "aws_launch_template" "app" {
  name_prefix   = "app-"
  image_id      = data.aws_ami.amazon_linux_2.id
  instance_type = "t3.medium"

  vpc_security_group_ids = [module.app_sg.security_group_id]

  # No public IPs - private subnet only
  network_interfaces {
    associate_public_ip_address = false
  }
}

module "app_sg" {
  source = "terraform-aws-modules/security-group/aws"

  name   = "app-sg"
  vpc_id = module.vpc.vpc_id

  ingress_rules       = ["https-443-tcp", "http-80-tcp"]
  ingress_cidr_blocks = [module.vpc.vpc_cidr_block]

  egress_rules = ["all-all"]
}
```

## Pricing

### Monthly Cost Estimates (us-east-1)

**VPC (Free Tier):**

- VPC creation: FREE
- VPC endpoints: $7.20/month per AZ per endpoint
- VPC Flow Logs: $0.50/GB (ingestion) + S3/CloudWatch costs

**NAT Gateway (Highest Cost Component):**

- Single NAT Gateway: $32.85/month ($0.045/hour × 730 hours)
- Multi-AZ NAT (3 AZs): $98.55/month
- Data Processing: $0.045/GB ($45/TB)

**Cost Comparison Table:**

| Configuration       | Monthly Cost | Use Case                             |
| ------------------- | ------------ | ------------------------------------ |
| VPC only (no NAT)   | $0           | Isolated workloads, batch processing |
| Single NAT Gateway  | $32.85       | Dev/test, non-critical workloads     |
| Multi-AZ NAT (2 AZ) | $65.70       | Production with 2 AZs                |
| Multi-AZ NAT (3 AZ) | $98.55       | Production with 3 AZs, HA            |
| + VPC Endpoints (2) | $28.80       | Add private S3/DynamoDB access       |
| + Flow Logs (500GB) | $45.00       | Full audit logging                   |

**NAT Gateway Data Processing Example:**

```
Scenario: 500GB/month outbound from private subnet
- NAT Gateway Hourly: $32.85
- Data Processing: 500GB × $0.045/GB = $22.50
- Total: $55.35/month

With VPC Endpoint for S3 (reduced by 200GB):
- Data Processing: 300GB × $0.045 = $13.50
- S3 Endpoint: $7.20
- Total: $51.55/month (Save $3.80 + improved security)
```

**Elastic IP Addresses:**

- First 100: FREE when attached to instance/NAT
- Unattached: $3.60/month per IP
- Remapped >100 times: $3.60 per remap

### Cost Optimization Tips

1. **Use VPC Endpoints**: Reduce NAT data processing costs by routing AWS service traffic through endpoints
2. **Resize subnets**: Avoid over-provisioning subnet sizes to reduce unused IP costs in RDS/Redshift
3. **Single NAT for dev**: Use single NAT Gateway for development/test environments
4. **IPv6 for egress**: Use IPv6 egress-only gateways (free) for outbound traffic
5. **CloudWatch vs S3**: Use CloudWatch for moderate volume, S3 for high-volume flow logs

## Troubleshooting

### Common Issues

**1. Subnet IP Address Exhaustion**

```bash
# Check free IPs in subnets
aws ec2 describe-subnets --subnet-ids subnet-xxx --query "Subnets[*].[SubnetId,AvailableIpAddressCount]"

# Output: [["subnet-xxx", 5]]  # Only 5 IPs left!

# Solution: Add secondary CIDR and new subnets
module "vpc_expand" {
  source = "git::https://github.com/company/terraform-modules.git//aws/vpc?ref=v1.0.0"

  secondary_cidr_blocks = ["10.1.0.0/16"]
  # ... rest of config
}
```

**2. Route Table Conflicts**

```bash
# Check route tables
aws ec2 describe-route-tables --filters Name=vpc-id,Values=vpc-xxx

# Identify overlapping routes
# Cannot have: 0.0.0.0/0 → igw-xxx AND 0.0.0.0/0 → nat-xxx in same table

# Solution: Ensure private route tables use NAT, public use IGW
terraform state show module.vpc.aws_route_table.private[0]
terraform state show module.vpc.aws_route_table.public[0]
```

**3. DNS Resolution Failures**

```bash
# Check DNS settings
aws ec2 describe-vpc-attribute --vpc-id vpc-xxx --attribute enableDnsSupport
aws ec2 describe-vpc-attribute --vpc-id vpc-xxx --attribute enableDnsHostnames

# Expected output: "EnableDnsSupport": {"Value": true}

# Troubleshoot from instance:
sudo yum install -y bind-utils  # or apt-get install dnsutils
dig google.com @169.254.169.253  # VPC resolver

# Common fix: Check DHCP options set
aws ec2 describe-dhcp-options --dhcp-options-ids dopt-xxx
```

**4. NAT Gateway Connectivity Issues**

```bash
# Verify NAT Gateway status
aws ec2 describe-nat-gateways --nat-gateway-ids nat-xxx

# Check for "State": "available"
# Check if NAT is in "Failed" state - usually due to deleted EIP

# Debug from private instance:
ping 8.8.8.8  # Should work if NAT is functioning
curl -v https://amazon.com  # Should work for HTTP/HTTPS

# Check route table for private subnet:
aws ec2 describe-route-tables --filters Name=association.subnet-id,Values=subnet-private-xxx
# Ensure: 0.0.0.0/0 → nat-xxx present
```

**5. VPC Endpoint Connection Issues**

```bash
# Check endpoint status
aws ec2 describe-vpc-endpoints --vpc-endpoint-ids vpce-xxx

# Should show: "State": "available"
# Check security groups allow traffic
aws ec2 describe-security-groups --group-ids sg-xxx

# Test connection from private instance:
aws s3 ls s3://my-bucket/  # Should work with S3 endpoint
```

### Diagnostic Commands

**VPC-Level Diagnostics:**

```bash
# Check VPC overall status
aws ec2 describe-vpcs --vpc-ids vpc-xxx --query "Vpcs[*].State"

# List all resources in VPC
aws ec2 describe-instances --filters Name=vpc-id,Values=vpc-xxx --query "Reservations[*].Instances[*].[InstanceId,SubnetId,State.Name]"
aws ec2 describe-network-interfaces --filters Name=vpc-id,Values=vpc-xxx
```

**Subnet-Level Diagnostics:**

```bash
# Subnet utilization
aws ec2 describe-subnets --filters Name=vpc-id,Values=vpc-xxx --query "Subnets[*].{ID:SubnetId,AZ:AvailabilityZone,CIDR:CidrBlock,Available:AvailableIpAddressCount}"

# Find subnets with < 10 available IPs
aws ec2 describe-subnets --filters Name=vpc-id,Values=vpc-xxx --query "Subnets[?AvailableIpAddressCount<\`10\`].SubnetId"
```

**Networking Diagnostics:**

```bash
# Check security group rules
aws ec2 describe-security-groups --filters Name=vpc-id,Values=vpc-xxx --query "SecurityGroups[*].[GroupName,IpPermissions[0].IpRanges]"

# Check NACL rules
aws ec2 describe-network-acls --filters Name=vpc-id,Values=vpc-xxx --query "NetworkAcls[*].Entries"

# Check route propagation
aws ec2 describe-route-tables --filters Name=vpc-id,Values=vpc-xxx --query "RouteTables[*].{ID:RouteTableId,Routes:Routes,VPC:VpcId}"
```

**Flow Logs Analysis:**

```bash
# For CloudWatch flow logs
group_name=$(aws logs describe-log-groups --log-group-name-prefix "vpc-flow-logs" --query "logGroups[0].logGroupName" --output text)

# Find rejected connections
aws logs filter-log-events --log-group-name "$group_name" \
  --filter-pattern "[version, account_id, interface_id, srcaddr, dstaddr, srcport, dstport, protocol, packets, bytes, start, end, action = REJECT]" \
  --query "events[*].message" --limit 10
```

### Quick Fixes

**Restore NAT Gateway:**

```bash
# If NAT failed, replace it
eip_id=$(aws ec2 allocate-address --domain vpc --query "AllocationId" --output text)
aws ec2 create-nat-gateway --subnet-id subnet-public-xxx --allocation-id "$eip_id"
```

**Fix Routing:**

```bash
# Replace incorrect route
aws ec2 replace-route --route-table-id rtb-xxx \
  --destination-cidr-block "0.0.0.0/0" \
  --nat-gateway-id nat-xxx
```

**Enable DNS:**

```bash
# If DNS is disabled
aws ec2 modify-vpc-attribute --vpc-id vpc-xxx --enable-dns-support
aws ec2 modify-vpc-attribute --vpc-id vpc-xxx --enable-dns-hostnames
```

## References

### AWS Documentation

- [Amazon VPC User Guide](https://docs.aws.amazon.com/vpc/latest/userguide/)
- [VPC Subnet Sizing](https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Subnets.html#VPC_Sizing)
- [NAT Gateway](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-nat-gateway.html)
- [VPC Flow Logs](https://docs.aws.amazon.com/vpc/latest/userguide/flow-logs.html)
- [VPC Endpoints](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-endpoints.html)
- [Pricing](https://aws.amazon.com/vpc/pricing/)

### Terraform Documentation

- [AWS VPC Resource](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc)
- [AWS Subnet Resource](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet)
- [AWS NAT Gateway Resource](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/nat_gateway)

### Related Modules

- [terraform-aws-modules/vpc/aws](https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws)
- [terraform-aws-modules/eks/aws](https://registry.terraform.io/modules/terraform-aws-modules/eks/aws)
- [terraform-aws-modules/rds/aws](https://registry.terraform.io/modules/terraform-aws-modules/rds/aws)
- [terraform-aws-modules/alb/aws](https://registry.terraform.io/modules/terraform-aws-modules/alb/aws)
- [terraform-aws-modules/security-group/aws](https://registry.terraform.io/modules/terraform-aws-modules/security-group/aws)

### Best Practices Guides

- [AWS Well-Architected Framework - Security](https://docs.aws.amazon.com/wellarchitected/latest/security-pillar/welcome.html)
- [AWS VPC CNI Best Practices](https://docs.aws.amazon.com/eks/latest/userguide/cni-best-practices.html)
- [AWS VPC Design Patterns](https://aws.amazon.com/blogs/architecture/vpc-design-best-practices/)

### Community Resources

- [AWS VPC IP Address Manager](https://aws.amazon.com/vpc/ipam/)
- [AWS Reachability Analyzer](https://docs.aws.amazon.com/vpc/latest/reachability/)
- [VPC Flow Log Analysis Tools](https://github.com/awslabs/vpc-flowlog-analysis-tools)
