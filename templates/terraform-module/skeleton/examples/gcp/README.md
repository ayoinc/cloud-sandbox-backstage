# GCP Example

This example demonstrates a complete GCP deployment using the terraform module.

## Prerequisites

- Terraform >= 1.5
- Google Cloud SDK configured with appropriate credentials
- A GCP project with permissions to create resources
- Required APIs enabled (Compute, Storage, KMS, etc.)

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

- VPC Network with subnets
- Cloud NAT for private subnet egress
- Managed Instance Group with autoscaler
- Cloud Storage bucket
- Cloud Monitoring workspace
- KMS key ring and crypto key
- Firewall rules
