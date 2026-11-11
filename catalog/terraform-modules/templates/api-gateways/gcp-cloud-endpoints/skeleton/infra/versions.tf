terraform {
  required_version = ">= 1.9.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 8.11.0"
    }
  }

  # The deploy workflow passes the bucket and the prefix with -backend-config.
  backend "gcs" {}
}
