# E-Commerce Platform Infrastructure
# Full Terraform stack for e-commerce

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    {{ .provider }} = {
      source  = "hashicorp/{{ .provider }}"
      version = "~> 5.0"
    }
  }

  # Use Terraform Cloud for state management
  cloud {
    organization = "{{ .projectName }}-org"
    workspaces {
      name = "{{ .projectName }}-{{ .environment }}"
    }
  }
}

# Generate consistent naming
module "naming" {
  source = "../../../shared-modules/naming"

  provider      = "{{ .provider }}"
  project       = var.project_name
  environment   = var.environment
  component     = "ecommerce"
  resource_type = "main"
  region        = var.region
  instance      = "001"
}

# Generate standardized tags
module "tagging" {
  source = "../../../shared-modules/tagging"

  project     = var.project_name
  environment = var.environment
  team        = var.business_unit
  cost_center = var.business_unit
  component_type = "application"
  application_id = "app-001"
  auto_shutdown  = var.environment == "dev" ? "0 19 * * 1-5" : ""
}

# Resource Group / Project / VPC
{{ if eq .provider "azure" }}
module "resource_group" {
  source = "../../azure/resources/resource-group"
  
  name     = module.naming.name
  location = var.region
  tags     = module.tagging.tags
}
{{ else if eq .provider "aws" }}
module "vpc" {
  source = "../../aws/resources/networking/vpc"

  name                = module.naming.name
  cidr_block          = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags                = module.tagging.tags
}
{{ else if eq .provider "gcp" }}
module "vpc" {
  source = "../../gcp/resources/networking/vpc"

  name          = module.naming.name
  project_id    = var.project_id
  auto_create_subnetworks = false
  tags          = module.tagging.tags
}
{{ end }}

# Storage - for product images, assets
{{ if .enableStorage }}
module "storage" {
  source = "../../{{ .provider }}/resources/storage"
  
  name                = "${module.naming.short_name}-storage"
  {{ if eq .provider "azure" }}
  resource_group_name = module.resource_group.name
  location            = var.region
  {{ end }}
  {{ if eq .provider "aws" }}
  region              = var.region
  {{ end }}
  {{ if eq .provider "gcp" }}
  project_id          = var.project_id
  {{ end }}
  
  tags = module.tagging.tags
}
{{ end }}

# Database - for products, orders, users
{{ if .enableDatabase }}
module "database" {
  source = "../../{{ .provider }}/resources/database"
  
  name                = "${module.naming.short_name}-db"
  {{ if eq .provider "azure" }}
  resource_group_name = module.resource_group.name
  location            = var.region
  {{ end }}
  {{ if eq .provider "aws" }}
  region              = var.region
  {{ end }}
  {{ if eq .provider "gcp" }}
  project_id          = var.project_id
  {{ end }}
  
  database_type = "postgresql"
  version       = var.environment == "prod" ? "14" : "13"
  
  tags = module.tagging.tags
}
{{ end }}

# Cache - Redis for session and performance
{{ if .enableCache }}
module "cache" {
  source = "../../{{ .provider }}/resources/database"
  
  name                = "${module.naming.short_name}-cache"
  {{ if eq .provider "azure" }}
  resource_group_name = module.resource_group.name
  location            = var.region
  {{ end }}
  {{ if eq .provider "aws" }}
  region              = var.region
  {{ end }}
  {{ if eq .provider "gcp" }}
  project_id          = var.project_id
  {{ end }}
  
  database_type = "redis"
  {{ if eq .environment "prod" }}
  sku = "Premium"
  {{ else }}
  sku = "Basic"
  {{ end }}
  
  tags = module.tagging.tags
}
{{ end }}

# CDN - for static assets
{{ if .enableCDN }}
module "cdn" {
  source = "../../{{ .provider }}/resources/networking/cdn"
  
  name = "${module.naming.short_name}-cdn"
  
  {{ if eq .provider "azure" }}
  resource_group_name = module.resource_group.name
  location            = var.region
  {{ end }}
  {{ if eq .provider "aws" }}
  region              = var.region
  {{ end }}
  {{ if eq .provider "gcp" }}
  project_id          = var.project_id
  {{ end }}
  
  origin = module.storage.primary_endpoint
  
  tags = module.tagging.tags
}
{{ end }}

# Application Hosting
{{ if .enableContainerApps }}
module "container_app" {
  source = "../../{{ .provider }}/resources/containers"
  
  name                = module.naming.name
  
  {{ if eq .provider "azure" }}
  resource_group_name = module.resource_group.name
  location            = var.region
  {{ end }}
  {{ if eq .provider "aws" }}
  region              = var.region
  {{ end }}
  {{ if eq .provider "gcp" }}
  project_id          = var.project_id
  {{ end }}
  
  environment = var.environment
  
  {{ if eq .environment "prod" }}
  replicas = 3
  cpu      = "2"
  memory   = "4Gi"
  {{ else }}
  replicas = 1
  cpu      = "1"
  memory   = "2Gi"
  {{ end }}
  
  ingress_enabled = true
  
  env_vars = {
    NODE_ENV              = var.environment
    DATABASE_URL          = module.database.connection_string
    CACHE_URL            = module.cache.connection_string
    STORAGE_URL          = module.storage.primary_endpoint
    API_BASE_PATH        = "/api/v1"
  }
  
  tags = module.tagging.tags
}
{{ end }}

# Monitoring
{{ if .enableMonitoring }}
module "monitoring" {
  source = "../../{{ .provider }}/resources/monitoring"
  
  name = "${module.naming.short_name}-monitoring"
  
  {{ if eq .provider "azure" }}
  resource_group_name = module.resource_group.name
  location            = var.region
  {{ end }}
  {{ if eq .provider "aws" }}
  region              = var.region
  {{ end }}
  {{ if eq .provider "gcp" }}
  project_id          = var.project_id
  {{ end }}
  
  retention_days = var.environment == "prod" ? 90 : 30
  
  tags = module.tagging.tags
}
{{ end }}

# API Management
{{ if .enableAPIManagement }}
module "api_gateway" {
  source = "../../{{ .provider }}/resources/integration"
  
  name                = "${module.naming.short_name}-api"
  
  {{ if eq .provider "azure" }}
  resource_group_name = module.resource_group.name
  location            = var.region
  {{ end }}
  {{ if eq .provider "aws" }}
  region              = var.region
  {{ end }}
  {{ if eq .provider "gcp" }}
  project_id          = var.project_id
  {{ end }}
  
  backend_url = module.container_app.url
  
  tags = module.tagging.tags
}
{{ end }}