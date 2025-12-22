# ${{ values.name }} Infrastructure
# Terraform configuration for ${{ values.description }}

terraform {
  required_version = "${{ values.terraform_version }}"
  
  required_providers {
    {% if values.cloud_provider === 'aws' or values.cloud_provider === 'multi-cloud' %}
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    {% endif %}
    {% if values.cloud_provider === 'azure' or values.cloud_provider === 'multi-cloud' %}
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    {% endif %}
    {% if values.cloud_provider === 'gcp' or values.cloud_provider === 'multi-cloud' %}
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    {% endif %}
    {% if values.enable_kubernetes %}
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.20"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.10"
    }
    {% endif %}
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }

  # Backend configuration - update with your backend details
  backend "s3" {
    bucket = "terraform-state-${{ values.name }}"
    key    = "${{ values.name }}/terraform.tfstate"
    region = "us-west-2"
    encrypt = true
    dynamodb_table = "terraform-locks-${{ values.name }}"
  }
}

# Provider configurations
{% if values.cloud_provider === 'aws' or values.cloud_provider === 'multi-cloud' %}
provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = local.common_tags
  }
}
{% endif %}

{% if values.cloud_provider === 'azure' or values.cloud_provider === 'multi-cloud' %}
provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}
{% endif %}

{% if values.cloud_provider === 'gcp' or values.cloud_provider === 'multi-cloud' %}
provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
}
{% endif %}

{% if values.enable_kubernetes %}
# Kubernetes provider configuration (configured after cluster creation)
provider "kubernetes" {
  {% if values.cloud_provider === 'aws' %}
  host                   = module.eks[0].cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks[0].cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.cluster[0].token
  {% elif values.cloud_provider === 'azure' %}
  host                   = module.aks[0].kube_config.0.host
  client_certificate     = base64decode(module.aks[0].kube_config.0.client_certificate)
  client_key             = base64decode(module.aks[0].kube_config.0.client_key)
  cluster_ca_certificate = base64decode(module.aks[0].kube_config.0.cluster_ca_certificate)
  {% elif values.cloud_provider === 'gcp' %}
  host                   = "https://${module.gke[0].endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(module.gke[0].ca_certificate)
  {% endif %}
}

provider "helm" {
  kubernetes {
    {% if values.cloud_provider === 'aws' %}
    host                   = module.eks[0].cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks[0].cluster_certificate_authority_data)
    token                  = data.aws_eks_cluster_auth.cluster[0].token
    {% elif values.cloud_provider === 'azure' %}
    host                   = module.aks[0].kube_config.0.host
    client_certificate     = base64decode(module.aks[0].kube_config.0.client_certificate)
    client_key             = base64decode(module.aks[0].kube_config.0.client_key)
    cluster_ca_certificate = base64decode(module.aks[0].kube_config.0.cluster_ca_certificate)
    {% elif values.cloud_provider === 'gcp' %}
    host                   = "https://${module.gke[0].endpoint}"
    token                  = data.google_client_config.default.access_token
    cluster_ca_certificate = base64decode(module.gke[0].ca_certificate)
    {% endif %}
  }
}
{% endif %}

# Local values for common configurations
locals {
  name_prefix = "${{ values.name }}"
  
  common_tags = {
    Project               = "${{ values.name }}"
    Environment          = var.environment
    Owner                = "${{ values.owner }}"
    Infrastructure-Type  = "${{ values.infrastructure_type }}"
    Terraform           = "true"
    Created-By          = "backstage-devops-platform"
    {% if values.compliance_framework !== 'none' %}
    Compliance          = "${{ values.compliance_framework }}"
    {% endif %}
  }

  {% for env in values.environments %}
  {{ env }}_config = {
    environment = "{{ env }}"
    {% if values.enable_kubernetes %}
    node_count = {{ env == 'production' ? 'var.max_nodes' : 'var.min_nodes' }}
    {% endif %}
    {% if values.enable_database %}
    db_instance_class = {{ env == 'production' ? '"db.r5.large"' : '"db.t3.medium"' }}
    {% endif %}
  }
  {% endfor %}
}

# Data sources
{% if values.cloud_provider === 'aws' or values.cloud_provider === 'multi-cloud' %}
data "aws_availability_zones" "available" {
  count = var.cloud_provider == "aws" || var.cloud_provider == "multi-cloud" ? 1 : 0
  state = "available"
}

data "aws_caller_identity" "current" {
  count = var.cloud_provider == "aws" || var.cloud_provider == "multi-cloud" ? 1 : 0
}

{% if values.enable_kubernetes %}
data "aws_eks_cluster_auth" "cluster" {
  count = var.enable_kubernetes && var.cloud_provider == "aws" ? 1 : 0
  name  = module.eks[0].cluster_name
}
{% endif %}
{% endif %}

{% if values.cloud_provider === 'gcp' or values.cloud_provider === 'multi-cloud' %}
data "google_client_config" "default" {
  count = var.cloud_provider == "gcp" || var.cloud_provider == "multi-cloud" ? 1 : 0
}
{% endif %}

# Random password for databases and secrets
resource "random_password" "database_password" {
  count   = var.enable_database ? 1 : 0
  length  = 16
  special = true
}

resource "random_id" "suffix" {
  byte_length = 4
}

# Infrastructure modules based on cloud provider
{% if values.cloud_provider === 'aws' or values.cloud_provider === 'multi-cloud' %}
module "aws_infrastructure" {
  count  = var.cloud_provider == "aws" || var.cloud_provider == "multi-cloud" ? 1 : 0
  source = "./modules/aws"

  name_prefix          = local.name_prefix
  environment         = var.environment
  common_tags         = local.common_tags
  
  # Networking
  enable_networking   = var.enable_networking
  vpc_cidr           = var.vpc_cidr
  availability_zones = data.aws_availability_zones.available[0].names
  
  # Kubernetes
  enable_kubernetes       = var.enable_kubernetes
  kubernetes_version     = var.kubernetes_version
  node_instance_type     = var.node_instance_type
  enable_autoscaling     = var.enable_autoscaling
  min_nodes             = var.min_nodes
  max_nodes             = var.max_nodes
  
  # Database
  enable_database       = var.enable_database
  database_password    = var.enable_database ? random_password.database_password[0].result : ""
  
  # Storage
  enable_storage        = var.enable_storage
  enable_cdn           = var.enable_cdn
  
  # Security
  enable_kms                    = var.enable_kms
  enable_secrets_manager        = var.enable_secrets_manager
  enable_security_group_rules   = var.enable_security_group_rules
  enable_waf                   = var.enable_waf
  
  # Monitoring
  enable_monitoring    = var.enable_monitoring
  enable_alerting     = var.enable_alerting
  log_retention_days  = var.log_retention_days
  
  # Compliance
  compliance_framework = var.compliance_framework
  enable_backup       = var.enable_backup
}
{% endif %}

{% if values.cloud_provider === 'azure' or values.cloud_provider === 'multi-cloud' %}
module "azure_infrastructure" {
  count  = var.cloud_provider == "azure" || var.cloud_provider == "multi-cloud" ? 1 : 0
  source = "./modules/azure"

  name_prefix     = local.name_prefix
  environment    = var.environment
  common_tags    = local.common_tags
  location       = var.azure_location
  
  # Networking
  enable_networking = var.enable_networking
  vnet_cidr        = var.vnet_cidr
  
  # Kubernetes
  enable_kubernetes      = var.enable_kubernetes
  kubernetes_version    = var.kubernetes_version
  node_instance_type    = var.node_instance_type
  enable_autoscaling    = var.enable_autoscaling
  min_nodes            = var.min_nodes
  max_nodes            = var.max_nodes
  
  # Database
  enable_database      = var.enable_database
  database_password   = var.enable_database ? random_password.database_password[0].result : ""
  
  # Storage
  enable_storage       = var.enable_storage
  enable_cdn          = var.enable_cdn
  
  # Security
  enable_key_vault             = var.enable_secrets_manager
  enable_security_group_rules  = var.enable_security_group_rules
  
  # Monitoring
  enable_monitoring   = var.enable_monitoring
  enable_alerting    = var.enable_alerting
  log_retention_days = var.log_retention_days
}
{% endif %}

{% if values.cloud_provider === 'gcp' or values.cloud_provider === 'multi-cloud' %}
module "gcp_infrastructure" {
  count  = var.cloud_provider == "gcp" || var.cloud_provider == "multi-cloud" ? 1 : 0
  source = "./modules/gcp"

  name_prefix    = local.name_prefix
  project_id     = var.gcp_project_id
  region         = var.gcp_region
  environment   = var.environment
  common_labels = local.common_tags
  
  # Networking
  enable_networking = var.enable_networking
  vpc_cidr         = var.vpc_cidr
  
  # Kubernetes
  enable_kubernetes     = var.enable_kubernetes
  kubernetes_version   = var.kubernetes_version
  node_instance_type   = var.node_instance_type
  enable_autoscaling   = var.enable_autoscaling
  min_nodes           = var.min_nodes
  max_nodes           = var.max_nodes
  
  # Database
  enable_database     = var.enable_database
  database_password  = var.enable_database ? random_password.database_password[0].result : ""
  
  # Storage
  enable_storage      = var.enable_storage
  enable_cdn         = var.enable_cdn
  
  # Security
  enable_kms                  = var.enable_kms
  enable_secret_manager       = var.enable_secrets_manager
  enable_security_rules       = var.enable_security_group_rules
  
  # Monitoring
  enable_monitoring  = var.enable_monitoring
  enable_alerting   = var.enable_alerting
  log_retention_days = var.log_retention_days
}
{% endif %}

{% if values.enable_monitoring and values.monitoring_solution === 'prometheus-grafana' %}
# Monitoring stack deployment
module "monitoring" {
  source = "./modules/monitoring"
  
  cluster_name     = var.enable_kubernetes ? (
    {% if values.cloud_provider === 'aws' %}
    var.cloud_provider == "aws" ? module.eks[0].cluster_name :
    {% endif %}
    {% if values.cloud_provider === 'azure' %}
    var.cloud_provider == "azure" ? module.aks[0].cluster_name :
    {% endif %}
    {% if values.cloud_provider === 'gcp' %}
    var.cloud_provider == "gcp" ? module.gke[0].cluster_name :
    {% endif %}
    ""
  ) : ""
  
  namespace       = "monitoring"
  enable_grafana  = true
  enable_alertmanager = var.enable_alerting
  
  common_tags = local.common_tags
  
  depends_on = [
    {% if values.cloud_provider === 'aws' %}
    module.eks,
    {% endif %}
    {% if values.cloud_provider === 'azure' %}
    module.aks,
    {% endif %}
    {% if values.cloud_provider === 'gcp' %}
    module.gke,
    {% endif %}
  ]
}
{% endif %}
