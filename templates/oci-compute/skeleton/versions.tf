terraform {
  # The oci state backend was added in Terraform 1.12.
  required_version = ">= 1.12.0"

  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~> 9.12"
    }
  }
}
