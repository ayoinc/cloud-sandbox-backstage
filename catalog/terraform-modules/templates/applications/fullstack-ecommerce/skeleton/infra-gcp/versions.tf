terraform {
  required_version = ">= 1.9.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 8.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }

  # State is kept in a local file until you configure a backend, for example:
  #
  # backend "gcs" {
  #   bucket = "<state bucket>"
  #   prefix = "${{ values.projectName }}"
  # }
}

provider "google" {
  project = var.project_id
  region  = var.region
}
