# Azure Storage Module - Variables

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region for resources"
  type        = string
}

variable "storage_accounts" {
  description = "Map of Storage Accounts to create"
  type = map(object({
    account_tier                      = optional(string, "Standard")
    account_replication_type          = optional(string, "LRS")
    account_kind                      = optional(string, "StorageV2")
    access_tier                       = optional(string, "Hot")
    https_traffic_only_enabled        = optional(bool, true)
    min_tls_version                   = optional(string, "TLS1_2")
    allow_nested_items_to_be_public   = optional(bool, false)
    shared_access_key_enabled         = optional(bool, true)
    public_network_access_enabled     = optional(bool, true)
    default_to_oauth_authentication   = optional(bool, false)
    is_hns_enabled                    = optional(bool, false)
    nfsv3_enabled                     = optional(bool, false)
    large_file_share_enabled          = optional(bool, false)
    infrastructure_encryption_enabled = optional(bool, false)
    sftp_enabled                      = optional(bool, false)
    identity = optional(object({
      type         = string
      identity_ids = optional(list(string))
    }))
    blob_properties = optional(object({
      versioning_enabled       = optional(bool, false)
      change_feed_enabled      = optional(bool, false)
      last_access_time_enabled = optional(bool, false)
      default_service_version  = optional(string)
      delete_retention_policy = optional(object({
        days                     = optional(number, 7)
        permanent_delete_enabled = optional(bool, false)
      }))
      container_delete_retention_policy = optional(object({
        days = optional(number, 7)
      }))
      cors_rules = optional(list(object({
        allowed_headers    = list(string)
        allowed_methods    = list(string)
        allowed_origins    = list(string)
        exposed_headers    = list(string)
        max_age_in_seconds = number
      })))
    }))
    network_rules = optional(object({
      default_action             = string
      bypass                     = optional(set(string), ["AzureServices"])
      ip_rules                   = optional(list(string), [])
      virtual_network_subnet_ids = optional(list(string), [])
      private_link_access = optional(list(object({
        endpoint_resource_id = string
        endpoint_tenant_id   = optional(string)
      })))
    }))
    static_website = optional(object({
      index_document     = optional(string)
      error_404_document = optional(string)
    }))
  }))
  default = {}
}

variable "storage_containers" {
  description = "Map of Storage Containers to create"
  type = map(object({
    storage_account_key   = string
    container_access_type = optional(string, "private")
  }))
  default = {}
}

variable "storage_shares" {
  description = "Map of Storage File Shares to create"
  type = map(object({
    storage_account_key = string
    quota               = optional(number, 50)
    access_tier         = optional(string, "TransactionOptimized")
    enabled_protocol    = optional(string, "SMB")
  }))
  default = {}
}

variable "storage_queues" {
  description = "Map of Storage Queues to create"
  type = map(object({
    storage_account_key = string
  }))
  default = {}
}

variable "storage_tables" {
  description = "Map of Storage Tables to create"
  type = map(object({
    storage_account_key = string
  }))
  default = {}
}

variable "storage_management_policies" {
  description = "Map of Storage Management Policies"
  type = map(object({
    storage_account_key = string
    rules = list(object({
      name    = string
      enabled = optional(bool, true)
      filters = object({
        prefix_match = optional(list(string))
        blob_types   = list(string)
      })
      actions = object({
        base_blob = optional(object({
          tier_to_cool_after_days    = optional(number)
          tier_to_archive_after_days = optional(number)
          delete_after_days          = optional(number)
        }))
        snapshot = optional(object({
          delete_after_days = optional(number)
        }))
        version = optional(object({
          delete_after_days = optional(number)
        }))
      })
    }))
  }))
  default = {}
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "private_endpoints" {
  type = map(object({
    location                      = string
    resource_group_name           = string
    subnet_id                     = string
    storage_account_id            = optional(string)
    storage_account_key           = optional(string)
    subresource_names             = list(string)
    is_manual_connection          = optional(bool, false)
    request_message               = optional(string)
    custom_network_interface_name = optional(string)
    private_dns_zone_ids          = optional(list(string))
    ip_configurations = optional(list(object({
      name               = string
      private_ip_address = string
      subresource_name   = string
      member_name        = optional(string)
    })))
  }))
  default = {}
}

variable "customer_managed_keys" {
  type = map(object({
    storage_account_id        = optional(string)
    storage_account_key       = optional(string)
    key_vault_id              = string
    key_name                  = string
    key_version               = optional(string)
    user_assigned_identity_id = optional(string)
  }))
  default = {}
}

variable "blob_inventory_policies" {
  type = map(object({
    storage_account_id  = optional(string)
    storage_account_key = optional(string)
    rules = list(object({
      name                   = string
      storage_container_name = string
      format                 = string
      schedule               = string
      scope                  = string
      schema_fields          = list(string)
      filter = object({
        blob_types            = list(string)
        include_blob_versions = optional(bool, false)
        include_deleted       = optional(bool, false)
        include_snapshots     = optional(bool, false)
        prefix_match          = optional(list(string))
        exclude_prefixes      = optional(list(string))
      })
    }))
  }))
  default = {}
}

variable "local_users" {
  type = map(object({
    storage_account_id   = optional(string)
    storage_account_key  = optional(string)
    home_directory       = optional(string)
    ssh_key_enabled      = optional(bool, true)
    ssh_password_enabled = optional(bool, false)
    permission_scopes = list(object({
      resource_name = string
      service       = string
      permissions = object({
        create = optional(bool, false)
        delete = optional(bool, false)
        list   = optional(bool, false)
        read   = optional(bool, false)
        write  = optional(bool, false)
      })
    }))
    ssh_authorized_keys = optional(list(object({
      key         = string
      description = optional(string)
    })))
  }))
  default = {}
}

variable "data_lake_filesystems" {
  type = map(object({
    storage_account_id  = optional(string)
    storage_account_key = optional(string)
    owner               = optional(string)
    group               = optional(string)
    ace_entries = optional(list(object({
      scope       = optional(string, "access")
      type        = string
      id          = optional(string)
      permissions = string
    })))
    properties = optional(map(string))
  }))
  default = {}
}
