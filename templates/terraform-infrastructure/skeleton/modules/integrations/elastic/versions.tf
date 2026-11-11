terraform {
  required_version = ">= 1.10"

  required_providers {
    ec = {
      source  = "elastic/ec"
      version = "~> 0.14"
    }
  }
}
