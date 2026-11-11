terraform {
  required_version = ">= 1.9.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.80.0, < 7.0.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = ">= 4.0.0, < 5.0.0"
    }
  }

  # The bucket is supplied at init time: terraform init -backend-config="bucket=<state bucket>"
  backend "s3" {
    key          = "${{ values.projectName }}/${{ values.environment }}/three-tier.tfstate"
    region       = "${{ values.region }}"
    encrypt      = true
    use_lockfile = true
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = local.common_tags
  }
}
