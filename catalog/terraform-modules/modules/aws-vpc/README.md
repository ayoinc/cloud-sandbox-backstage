# AWS VPC Module

A production-ready Terraform module for creating a VPC with public and private subnets across multiple availability zones.

## Features

- Multi-AZ deployment with configurable number of AZs
- Public subnets with Internet Gateway
- Private subnets with NAT Gateway(s)
- Optional VPC Flow Logs to CloudWatch
- Optional VPC Endpoints for S3 and DynamoDB
- Kubernetes/EKS-ready tagging support
- Customizable Network ACLs
- Secure default security group (no ingress/egress)

## Usage

```hcl
module "vpc" {
  source = "./modules/aws-vpc"

  name        = "my-app"
  environment = "prod"
  vpc_cidr    = "10.0.0.0/16"
  az_count    = 3

  enable_nat_gateway = true
  single_nat_gateway = false  # One NAT per AZ for HA

  enable_flow_logs = true
  enable_s3_endpoint = true

  # For EKS clusters
  enable_kubernetes_tags = true
  cluster_name           = "my-eks-cluster"

  tags = {
    Project = "my-project"
    Team    = "platform"
  }
}
```

## Cost Optimization

For development environments, you can reduce costs by:

```hcl
module "vpc" {
  source = "./modules/aws-vpc"

  name               = "dev-app"
  environment        = "dev"
  az_count           = 2
  single_nat_gateway = true   # Single NAT for all AZs
  enable_flow_logs   = false  # Disable flow logs

  tags = {
    Environment = "dev"
  }
}
```

## Inputs

| Name                   | Description                   | Type   | Default       | Required |
| ---------------------- | ----------------------------- | ------ | ------------- | -------- |
| name                   | Name prefix for all resources | string | -             | yes      |
| environment            | Environment name              | string | "dev"         | no       |
| vpc_cidr               | CIDR block for the VPC        | string | "10.0.0.0/16" | no       |
| az_count               | Number of availability zones  | number | 3             | no       |
| enable_nat_gateway     | Enable NAT Gateway            | bool   | true          | no       |
| single_nat_gateway     | Use single NAT Gateway        | bool   | false         | no       |
| enable_flow_logs       | Enable VPC Flow Logs          | bool   | true          | no       |
| enable_s3_endpoint     | Enable S3 VPC endpoint        | bool   | true          | no       |
| enable_kubernetes_tags | Enable K8s tags               | bool   | false         | no       |

## Outputs

| Name                   | Description                    |
| ---------------------- | ------------------------------ |
| vpc_id                 | ID of the VPC                  |
| public_subnet_ids      | List of public subnet IDs      |
| private_subnet_ids     | List of private subnet IDs     |
| nat_gateway_public_ips | List of NAT Gateway public IPs |

## Requirements

- Terraform >= 1.0
- AWS Provider >= 5.0

## License

Apache 2.0
