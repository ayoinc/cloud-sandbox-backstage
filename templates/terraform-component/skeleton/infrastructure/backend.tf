# Environment Isolation & Workspace Configuration
# This file configures Terraform workspaces for environment isolation

terraform {
  required_version = ">= 1.6"

  required_providers {
    {{ provider }} = {
      source  = "{{ provider_source }}"
      version = "{{ provider_version }}"
    }
  }

{{- if eq .backendType "remote" }}
  # Terraform Cloud/Enterprise Backend
  cloud {
    organization = "{{ .backend_organization }}"

    workspaces {
      name = "{{ .componentType }}-{{ .provider }}-{{ .environment }}-{{ .name }}"
    }
  }
{{- else if eq .backendType "s3" }}
  # AWS S3 Backend with state locking
  backend "s3" {
    bucket         = "{{ .backend_bucket }}"
{{- if eq .stateFileStructure "hierarchical" }}
    key            = "terraform/{{ .componentType }}/{{ .provider }}/{{ .environment }}/{{ .name }}/terraform.tfstate"
{{- else }}
    key            = "terraform/{{ .componentType }}-{{ .provider }}-{{ .environment }}-{{ .name }}.tfstate"
{{- end }}
    region         = "{{ .region }}"
    encrypt        = true
{{- if .enableStateLocking }}
    dynamodb_table = "terraform-state-lock"
{{- end }}
  }
{{- else if eq .backendType "azure" }}
  # Azure Storage Backend with state locking
  backend "azurerm" {
    resource_group_name  = "{{ .backend_resource_group }}"
    storage_account_name = "{{ .backend_storage_account }}"
    container_name       = "tfstate"
{{- if eq .stateFileStructure "hierarchical" }}
    key                  = "terraform/{{ .componentType }}/{{ .provider }}/{{ .environment }}/{{ .name }}.tfstate"
{{- else }}
    key                  = "terraform/{{ .componentType }}-{{ .provider }}-{{ .environment }}-{{ .name }}.tfstate"
{{- end }}
  }
{{- else if eq .backendType "gcs" }}
  # GCP Cloud Storage Backend
  backend "gcs" {
    bucket = "{{ .backend_bucket }}"
{{- if eq .stateFileStructure "hierarchical" }}
    prefix = "terraform/{{ .componentType }}/{{ .provider }}/{{ .environment }}/{{ .name }}"
{{- else }}
    prefix = "terraform/{{ .componentType }}-{{ .provider }}-{{ .environment }}-{{ .name }}"
{{- end }}
  }
{{- end }}
}

# Configure default provider
provider "{{ provider }}" {
{{- if eq .provider "aws" }}
  region = var.region
  default_tags {
    tags = local.required_tags
  }
{{- else if eq .provider "azure" }}
  features {}
{{- else if eq .provider "gcp" }}
  project = var.project_id
  region  = var.region
{{- end }}
}

{{- if eq .provider "azure" }}
# Azure provider alias for resource group
provider "azurerm" {
  alias           = "rg"
  features {}
  subscription_id = var.subscription_id
}
{{- end }}

{{- if .secondaryRegion }}
# Secondary provider for DR
provider "{{ provider }}" {
  alias = "secondary"
{{- if eq .provider "aws" }}
  region = var.secondary_region
{{- else if eq .provider "azure" }}
  features {}
{{- else if eq .provider "gcp" }}
  project = var.project_id
  region  = var.secondary_region
{{- end }}
}
{{- end }}
