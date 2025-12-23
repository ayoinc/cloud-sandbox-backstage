# Azure Storage Module
# Reusable module for creating Azure Storage Accounts and related resources

terraform {
  required_version = ">= 1.5"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.0"
    }
  }
}

# Storage Account
resource "azurerm_storage_account" "this" {
  for_each = var.storage_accounts

  name                              = each.key
  resource_group_name               = var.resource_group_name
  location                          = var.location
  account_tier                      = each.value.account_tier
  account_replication_type          = each.value.account_replication_type
  account_kind                      = each.value.account_kind
  access_tier                       = each.value.access_tier
  https_traffic_only_enabled        = each.value.https_traffic_only_enabled
  min_tls_version                   = each.value.min_tls_version
  allow_nested_items_to_be_public   = each.value.allow_nested_items_to_be_public
  shared_access_key_enabled         = each.value.shared_access_key_enabled
  public_network_access_enabled     = each.value.public_network_access_enabled
  default_to_oauth_authentication   = each.value.default_to_oauth_authentication
  is_hns_enabled                    = each.value.is_hns_enabled
  nfsv3_enabled                     = each.value.nfsv3_enabled
  large_file_share_enabled          = each.value.large_file_share_enabled
  infrastructure_encryption_enabled = each.value.infrastructure_encryption_enabled
  sftp_enabled                      = each.value.sftp_enabled

  dynamic "identity" {
    for_each = each.value.identity != null ? [each.value.identity] : []
    content {
      type         = identity.value.type
      identity_ids = identity.value.identity_ids
    }
  }

  dynamic "blob_properties" {
    for_each = each.value.blob_properties != null ? [each.value.blob_properties] : []
    content {
      versioning_enabled       = blob_properties.value.versioning_enabled
      change_feed_enabled      = blob_properties.value.change_feed_enabled
      last_access_time_enabled = blob_properties.value.last_access_time_enabled
      default_service_version  = blob_properties.value.default_service_version

      dynamic "delete_retention_policy" {
        for_each = blob_properties.value.delete_retention_policy != null ? [blob_properties.value.delete_retention_policy] : []
        content {
          days                     = delete_retention_policy.value.days
          permanent_delete_enabled = delete_retention_policy.value.permanent_delete_enabled
        }
      }

      dynamic "container_delete_retention_policy" {
        for_each = blob_properties.value.container_delete_retention_policy != null ? [blob_properties.value.container_delete_retention_policy] : []
        content {
          days = container_delete_retention_policy.value.days
        }
      }

      dynamic "cors_rule" {
        for_each = blob_properties.value.cors_rules != null ? blob_properties.value.cors_rules : []
        content {
          allowed_headers    = cors_rule.value.allowed_headers
          allowed_methods    = cors_rule.value.allowed_methods
          allowed_origins    = cors_rule.value.allowed_origins
          exposed_headers    = cors_rule.value.exposed_headers
          max_age_in_seconds = cors_rule.value.max_age_in_seconds
        }
      }
    }
  }

  dynamic "network_rules" {
    for_each = each.value.network_rules != null ? [each.value.network_rules] : []
    content {
      default_action             = network_rules.value.default_action
      bypass                     = network_rules.value.bypass
      ip_rules                   = network_rules.value.ip_rules
      virtual_network_subnet_ids = network_rules.value.virtual_network_subnet_ids

      dynamic "private_link_access" {
        for_each = network_rules.value.private_link_access != null ? network_rules.value.private_link_access : []
        content {
          endpoint_resource_id = private_link_access.value.endpoint_resource_id
          endpoint_tenant_id   = private_link_access.value.endpoint_tenant_id
        }
      }
    }
  }

  dynamic "static_website" {
    for_each = each.value.static_website != null ? [each.value.static_website] : []
    content {
      index_document     = static_website.value.index_document
      error_404_document = static_website.value.error_404_document
    }
  }

  tags = var.tags
}

# Storage Container
resource "azurerm_storage_container" "this" {
  for_each = var.storage_containers

  name                  = each.key
  storage_account_id    = azurerm_storage_account.this[each.value.storage_account_key].id
  container_access_type = each.value.container_access_type
}

# Storage Share (File Share)
resource "azurerm_storage_share" "this" {
  for_each = var.storage_shares

  name               = each.key
  storage_account_id = azurerm_storage_account.this[each.value.storage_account_key].id
  quota              = each.value.quota
  access_tier        = each.value.access_tier
  enabled_protocol   = each.value.enabled_protocol
}

# Storage Queue
resource "azurerm_storage_queue" "this" {
  for_each = var.storage_queues

  name                 = each.key
  storage_account_name = azurerm_storage_account.this[each.value.storage_account_key].name
}

# Storage Table
resource "azurerm_storage_table" "this" {
  for_each = var.storage_tables

  name                 = each.key
  storage_account_name = azurerm_storage_account.this[each.value.storage_account_key].name
}

# Storage Management Policy
resource "azurerm_storage_management_policy" "this" {
  for_each = var.storage_management_policies

  storage_account_id = azurerm_storage_account.this[each.value.storage_account_key].id

  dynamic "rule" {
    for_each = each.value.rules
    content {
      name    = rule.value.name
      enabled = rule.value.enabled

      filters {
        prefix_match = rule.value.filters.prefix_match
        blob_types   = rule.value.filters.blob_types
      }

      actions {
        dynamic "base_blob" {
          for_each = rule.value.actions.base_blob != null ? [rule.value.actions.base_blob] : []
          content {
            tier_to_cool_after_days_since_modification_greater_than    = base_blob.value.tier_to_cool_after_days
            tier_to_archive_after_days_since_modification_greater_than = base_blob.value.tier_to_archive_after_days
            delete_after_days_since_modification_greater_than          = base_blob.value.delete_after_days
          }
        }

        dynamic "snapshot" {
          for_each = rule.value.actions.snapshot != null ? [rule.value.actions.snapshot] : []
          content {
            delete_after_days_since_creation_greater_than = snapshot.value.delete_after_days
          }
        }

        dynamic "version" {
          for_each = rule.value.actions.version != null ? [rule.value.actions.version] : []
          content {
            delete_after_days_since_creation = version.value.delete_after_days
          }
        }
      }
    }
  }
}

# Private Endpoints for Storage Accounts
resource "azurerm_private_endpoint" "this" {
  for_each = var.private_endpoints

  name                          = each.key
  location                      = each.value.location
  resource_group_name           = each.value.resource_group_name
  subnet_id                     = each.value.subnet_id
  custom_network_interface_name = each.value.custom_network_interface_name

  private_service_connection {
    name                           = "${each.key}-connection"
    private_connection_resource_id = each.value.storage_account_id != null ? each.value.storage_account_id : azurerm_storage_account.this[each.value.storage_account_key].id
    subresource_names              = each.value.subresource_names
    is_manual_connection           = each.value.is_manual_connection
    request_message                = each.value.request_message
  }

  dynamic "private_dns_zone_group" {
    for_each = each.value.private_dns_zone_ids != null ? [1] : []
    content {
      name                 = "${each.key}-dns-zone-group"
      private_dns_zone_ids = each.value.private_dns_zone_ids
    }
  }

  dynamic "ip_configuration" {
    for_each = each.value.ip_configurations != null ? each.value.ip_configurations : []
    content {
      name               = ip_configuration.value.name
      private_ip_address = ip_configuration.value.private_ip_address
      subresource_name   = ip_configuration.value.subresource_name
      member_name        = ip_configuration.value.member_name
    }
  }

  tags = var.tags
}

# Storage Account Customer Managed Key
resource "azurerm_storage_account_customer_managed_key" "this" {
  for_each = var.customer_managed_keys

  storage_account_id        = each.value.storage_account_id != null ? each.value.storage_account_id : azurerm_storage_account.this[each.value.storage_account_key].id
  key_vault_id              = each.value.key_vault_id
  key_name                  = each.value.key_name
  key_version               = each.value.key_version
  user_assigned_identity_id = each.value.user_assigned_identity_id
}

# Storage Blob Inventory Policy
resource "azurerm_storage_blob_inventory_policy" "this" {
  for_each = var.blob_inventory_policies

  storage_account_id = each.value.storage_account_id != null ? each.value.storage_account_id : azurerm_storage_account.this[each.value.storage_account_key].id

  dynamic "rules" {
    for_each = each.value.rules
    content {
      name                   = rules.value.name
      storage_container_name = rules.value.storage_container_name
      format                 = rules.value.format
      schedule               = rules.value.schedule
      scope                  = rules.value.scope
      schema_fields          = rules.value.schema_fields

      filter {
        blob_types            = rules.value.filter.blob_types
        include_blob_versions = rules.value.filter.include_blob_versions
        include_deleted       = rules.value.filter.include_deleted
        include_snapshots     = rules.value.filter.include_snapshots
        prefix_match          = rules.value.filter.prefix_match
        exclude_prefixes      = rules.value.filter.exclude_prefixes
      }
    }
  }
}

# Storage Account Local User (for SFTP)
resource "azurerm_storage_account_local_user" "this" {
  for_each = var.local_users

  name                 = each.key
  storage_account_id   = each.value.storage_account_id != null ? each.value.storage_account_id : azurerm_storage_account.this[each.value.storage_account_key].id
  home_directory       = each.value.home_directory
  ssh_key_enabled      = each.value.ssh_key_enabled
  ssh_password_enabled = each.value.ssh_password_enabled

  dynamic "permission_scope" {
    for_each = each.value.permission_scopes
    content {
      resource_name = permission_scope.value.resource_name
      service       = permission_scope.value.service

      permissions {
        create = permission_scope.value.permissions.create
        delete = permission_scope.value.permissions.delete
        list   = permission_scope.value.permissions.list
        read   = permission_scope.value.permissions.read
        write  = permission_scope.value.permissions.write
      }
    }
  }

  dynamic "ssh_authorized_key" {
    for_each = each.value.ssh_authorized_keys != null ? each.value.ssh_authorized_keys : []
    content {
      key         = ssh_authorized_key.value.key
      description = ssh_authorized_key.value.description
    }
  }
}

# Storage Data Lake Gen2 Filesystem
resource "azurerm_storage_data_lake_gen2_filesystem" "this" {
  for_each = var.data_lake_filesystems

  name               = each.key
  storage_account_id = each.value.storage_account_id != null ? each.value.storage_account_id : azurerm_storage_account.this[each.value.storage_account_key].id
  owner              = each.value.owner
  group              = each.value.group

  dynamic "ace" {
    for_each = each.value.ace_entries != null ? each.value.ace_entries : []
    content {
      scope       = ace.value.scope
      type        = ace.value.type
      id          = ace.value.id
      permissions = ace.value.permissions
    }
  }

  properties = each.value.properties
}
