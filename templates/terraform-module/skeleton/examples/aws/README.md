# AWS Example

This example demonstrates a complete AWS deployment using the terraform module.

## Prerequisites

- Terraform >= 1.5
- AWS CLI configured with appropriate credentials
- An AWS account with permissions to create resources

## Usage

1. Copy the example tfvars:

   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

2. Update the values in `terraform.tfvars`

3. Initialize and apply:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

## What This Example Creates

- VPC with public and private subnets
- NAT Gateway for private subnet egress
- Auto Scaling Group with launch template
- Application Load Balancer
- S3 bucket for storage
- CloudWatch log group and alarms
- KMS key for encryption
- Security groups with minimal required rules
