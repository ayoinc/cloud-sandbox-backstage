# Azure Example

This example demonstrates a complete Azure deployment using the terraform module.

## Prerequisites

- Terraform >= 1.5
- Azure CLI configured with appropriate credentials
- An Azure subscription with permissions to create resources

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

- Resource Group
- Virtual Network with subnets
- NAT Gateway for private subnet egress
- Virtual Machine Scale Set
- Storage Account
- Log Analytics Workspace
- Key Vault for secrets
- Network Security Groups
