terraform {
  required_version = ">= 1.10"

  required_providers {
    datadog = {
      source  = "DataDog/datadog"
      version = "~> 4.0"
    }
    google = {
      source  = "hashicorp/google"
      version = "~> 8.0"
    }
  }
}
