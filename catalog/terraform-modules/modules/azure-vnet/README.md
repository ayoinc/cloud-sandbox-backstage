# Azure Virtual Network Module

A production-ready Terraform module for creating an Azure Virtual Network with public and private subnets.

## Features

- Multiple subnets with configurable CIDR blocks
- Network Security Groups with sensible defaults
- NAT Gateway for private subnet internet access
- Azure Bastion support for secure VM access
- Service endpoints for Azure services
- Private endpoint support
- Diagnostic settings integration

## Usage

```hcl
module "vnet" {
  source = "./modules/azure-vnet"

  name        = "my-app"
  environment = "prod"
  location    = "eastus"

  address_space   = ["10.0.0.0/16"]
  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets = ["10.0.11.0/24", "10.0.12.0/24"]

  enable_nat_gateway = true
  enable_bastion     = true

  tags = {
    Project = "my-project"
    Team    = "platform"
  }
}
```

## Requirements

- Terraform >= 1.0
- AzureRM Provider >= 3.0

## License

Apache 2.0
