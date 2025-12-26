# GCP VPC Module

A production-ready Terraform module for creating a Google Cloud VPC with custom subnets and Cloud NAT.

## Features

- Custom mode VPC network
- Multiple subnets with secondary IP ranges (for GKE)
- Cloud NAT for private subnet internet access
- VPC Flow Logs
- Firewall rules with sensible defaults
- IAP SSH access support
- Private Service Access for managed services

## Usage

```hcl
module "vpc" {
  source = "./modules/gcp-vpc"

  name       = "my-app"
  project_id = "my-project-id"

  public_subnets = [
    {
      region = "us-central1"
      cidr   = "10.0.1.0/24"
    },
    {
      region = "us-east1"
      cidr   = "10.0.2.0/24"
    }
  ]

  private_subnets = [
    {
      region = "us-central1"
      cidr   = "10.0.11.0/24"
      secondary_ranges = [
        { name = "pods", cidr = "10.1.0.0/16" },
        { name = "services", cidr = "10.2.0.0/20" }
      ]
    }
  ]

  enable_nat              = true
  enable_iap_ssh          = true
  enable_private_service_access = true
}
```

## Requirements

- Terraform >= 1.0
- Google Provider >= 5.0

## License

Apache 2.0
