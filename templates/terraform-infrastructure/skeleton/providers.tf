# Provider Configurations for ${{ values.name }} Infrastructure

{% if values.cloud_provider == 'aws' or values.cloud_provider == 'multi-cloud' %}
provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = local.common_tags
  }
}
{% endif %}

{% if values.cloud_provider == 'azure' or values.cloud_provider == 'multi-cloud' %}
provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}
{% endif %}

{% if values.cloud_provider == 'gcp' or values.cloud_provider == 'multi-cloud' %}
provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
}
{% endif %}

{% if values.enable_kubernetes %}
# Kubernetes provider configuration (configured after cluster creation)
provider "kubernetes" {
  {% if values.cloud_provider == 'aws' %}
  host                   = module.aws_infrastructure[0].eks_cluster_endpoint
  cluster_ca_certificate = base64decode(module.aws_infrastructure[0].eks_cluster_ca_certificate)
  token                  = data.aws_eks_cluster_auth.cluster[0].token
  {% elif values.cloud_provider == 'azure' %}
  host                   = module.azure_infrastructure[0].kube_config.0.host
  client_certificate     = base64decode(module.azure_infrastructure[0].kube_config.0.client_certificate)
  client_key             = base64decode(module.azure_infrastructure[0].kube_config.0.client_key)
  cluster_ca_certificate = base64decode(module.azure_infrastructure[0].kube_config.0.cluster_ca_certificate)
  {% elif values.cloud_provider == 'gcp' %}
  host                   = "https://${module.gcp_infrastructure[0].endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(module.gcp_infrastructure[0].ca_certificate)
  {% endif %}
}

provider "helm" {
  kubernetes {
    {% if values.cloud_provider == 'aws' %}
    host                   = module.aws_infrastructure[0].eks_cluster_endpoint
    cluster_ca_certificate = base64decode(module.aws_infrastructure[0].eks_cluster_ca_certificate)
    token                  = data.aws_eks_cluster_auth.cluster[0].token
    {% elif values.cloud_provider == 'azure' %}
    host                   = module.azure_infrastructure[0].kube_config.0.host
    client_certificate     = base64decode(module.azure_infrastructure[0].kube_config.0.client_certificate)
    client_key             = base64decode(module.azure_infrastructure[0].kube_config.0.client_key)
    cluster_ca_certificate = base64decode(module.azure_infrastructure[0].kube_config.0.cluster_ca_certificate)
    {% elif values.cloud_provider == 'gcp' %}
    host                   = "https://${module.gcp_infrastructure[0].endpoint}"
    token                  = data.google_client_config.default.access_token
    cluster_ca_certificate = base64decode(module.gcp_infrastructure[0].ca_certificate)
    {% endif %}
  }
}
{% endif %}
