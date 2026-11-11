terraform {
  required_version = ">= 1.9.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.116.0, < 4.0.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.35.0, < 3.0.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.17.0, < 3.0.0"
    }
  }

  # The resource group and the storage account are supplied at init time:
  # terraform init -backend-config="resource_group_name=<group>" -backend-config="storage_account_name=<account>"
  backend "azurerm" {
    container_name   = "tfstate"
    key              = "${{ values.projectName }}/${{ values.environment }}/kubernetes-platform.tfstate"
    use_oidc         = true
    use_azuread_auth = true
  }
}

provider "azurerm" {
  # null selects the subscription of the credentials Terraform runs with (ARM_SUBSCRIPTION_ID in the pipeline).
  subscription_id = var.subscription_id

  features {}
}

# The platform components are installed with the cluster's own administrator certificate, which exists as soon as
# the cluster does and does not depend on a role assignment in Microsoft Entra ID.
provider "kubernetes" {
  host                   = azurerm_kubernetes_cluster.main.kube_admin_config[0].host
  client_certificate     = base64decode(azurerm_kubernetes_cluster.main.kube_admin_config[0].client_certificate)
  client_key             = base64decode(azurerm_kubernetes_cluster.main.kube_admin_config[0].client_key)
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.main.kube_admin_config[0].cluster_ca_certificate)
}

provider "helm" {
  kubernetes {
    host                   = azurerm_kubernetes_cluster.main.kube_admin_config[0].host
    client_certificate     = base64decode(azurerm_kubernetes_cluster.main.kube_admin_config[0].client_certificate)
    client_key             = base64decode(azurerm_kubernetes_cluster.main.kube_admin_config[0].client_key)
    cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.main.kube_admin_config[0].cluster_ca_certificate)
  }
}
