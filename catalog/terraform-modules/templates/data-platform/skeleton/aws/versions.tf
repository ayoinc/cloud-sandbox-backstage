terraform {
  required_version = ">= 1.9.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0.0, < 7.0.0"
    }
  }

  # The bucket is supplied at init time: terraform init -backend-config="bucket=<state bucket>"
  backend "s3" {
    key          = "${{ values.projectName }}/${{ values.environment }}/data-platform.tfstate"
    region       = "${{ values.awsRegion }}"
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
