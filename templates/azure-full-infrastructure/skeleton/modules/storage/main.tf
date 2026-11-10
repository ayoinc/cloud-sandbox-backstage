# =============================================================================
# Storage Module
# =============================================================================
# General-purpose v2 storage account with blob versioning and soft delete.
# With the hierarchical namespace enabled it is a Data Lake Storage Gen2 account.
# =============================================================================

locals {
  # Storage account names consist of lowercase letters and digits only.
  storage_account_name = lower(replace("st${var.name}${var.environment}", "-", ""))
}

#trivy:ignore:AZU-0012 The account accepts requests from any network by default so the pipeline can manage it; every request still needs a key or an Azure role. Set restrict_network_access to change it
resource "azurerm_storage_account" "main" {
  #checkov:skip=CKV_AZURE_35:The account accepts requests from any network by default so the pipeline can manage it; set restrict_network_access to change it
  #checkov:skip=CKV_AZURE_59:The account keeps its public endpoint so the pipeline can manage it; anonymous blob access is switched off
  #checkov:skip=CKV2_AZURE_33:Workloads reach the account through the Microsoft.Storage service endpoint of their subnet
  #checkov:skip=CKV2_AZURE_40:Terraform configures the blob and queue services with the account key
  #checkov:skip=CKV2_AZURE_1:Data is encrypted with platform-managed keys; a customer-managed key needs a Key Vault key and an identity
  #checkov:skip=CKV_AZURE_206:Replication follows the high availability and disaster recovery settings: LRS, ZRS, GRS or GZRS
  name                     = local.storage_account_name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_kind             = "StorageV2"
  account_tier             = "Standard"
  account_replication_type = var.replication_type
  is_hns_enabled           = var.enable_hierarchical_namespace

  # Encrypted transport only, no anonymous blob access, and a second layer of
  # encryption at rest
  min_tls_version                   = "TLS1_2"
  https_traffic_only_enabled        = true
  allow_nested_items_to_be_public   = false
  infrastructure_encryption_enabled = true

  # The portal and SDKs default to Entra ID sign-in. Account keys stay enabled
  # because Terraform configures the blob and queue services with them; SAS
  # tokens valid for longer than a day are flagged.
  default_to_oauth_authentication = true
  shared_access_key_enabled       = true
  local_user_enabled              = false

  sas_policy {
    expiration_period = "01.00:00:00"
    expiration_action = "Log"
  }

  blob_properties {
    # Versioning is not available together with a hierarchical namespace
    versioning_enabled = !var.enable_hierarchical_namespace

    delete_retention_policy {
      days = var.soft_delete_retention_days
    }

    container_delete_retention_policy {
      days = var.soft_delete_retention_days
    }
  }

  # Request logging for the queue service
  queue_properties {
    logging {
      delete                = true
      read                  = true
      write                 = true
      version               = "1.0"
      retention_policy_days = 7
    }
  }

  network_rules {
    default_action             = var.restrict_network_access ? "Deny" : "Allow"
    bypass                     = ["AzureServices"]
    virtual_network_subnet_ids = var.allowed_subnet_ids
    ip_rules                   = var.allowed_ip_ranges
  }

  tags = var.tags
}
