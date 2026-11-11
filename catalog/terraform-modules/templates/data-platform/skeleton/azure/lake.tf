# -----------------------------------------------------------------------------
# Data lake: Azure Data Lake Storage Gen2 with a raw, a processed and a curated
# zone. data_lake_storage_class selects the access tier and the lifecycle rule.
# -----------------------------------------------------------------------------

locals {
  lake_tiering = {
    standard   = { access_tier = "Hot", cool_after_days = 90, archive_after_days = null }
    infrequent = { access_tier = "Cool", cool_after_days = null, archive_after_days = 180 }
    archive    = { access_tier = "Cool", cool_after_days = null, archive_after_days = 30 }
  }[var.data_lake_storage_class]

  lake_account_id = one(azurerm_storage_account.lake[*].id)
}

#trivy:ignore:AVD-AZU-0012 Terraform runs on GitHub-hosted runners without a fixed address and creates the filesystems; set allowed_ip_ranges to deny other networks.
resource "azurerm_storage_account" "lake" {
  count = local.create_lake_account ? 1 : 0

  name                = "dl${local.compact_prefix}${local.unique_suffix}"
  resource_group_name = module.resource_group.name
  location            = var.location

  account_kind   = "StorageV2"
  account_tier   = "Standard"
  access_tier    = local.lake_tiering.access_tier
  is_hns_enabled = true
  # The archive tier is not available with zone-redundant replication.
  account_replication_type = local.is_production ? "GRS" : "LRS"

  min_tls_version                 = "TLS1_2"
  https_traffic_only_enabled      = true
  allow_nested_items_to_be_public = false

  # With access control every request is authorised with Microsoft Entra ID; account keys and SAS tokens are off.
  shared_access_key_enabled       = !var.enable_access_control
  default_to_oauth_authentication = var.enable_access_control

  identity {
    type = "SystemAssigned"
  }

  blob_properties {
    delete_retention_policy {
      days = local.is_production ? 30 : 7
    }

    container_delete_retention_policy {
      days = local.is_production ? 30 : 7
    }
  }

  network_rules {
    default_action = local.restrict_networks ? "Deny" : "Allow"
    bypass         = ["AzureServices"]
    ip_rules       = var.allowed_ip_ranges
  }

  tags = local.common_tags

  # The key is set by azurerm_storage_account_customer_managed_key.lake once the account's identity can read it.
  # Remove prevent_destroy to delete the data lake on purpose.
  lifecycle {
    prevent_destroy = true
    ignore_changes  = [customer_managed_key]
  }
}

resource "azurerm_key_vault_access_policy" "lake" {
  count = local.customer_managed_keys && local.create_lake_account ? 1 : 0

  key_vault_id = azurerm_key_vault.this[0].id
  tenant_id    = azurerm_storage_account.lake[0].identity[0].tenant_id
  object_id    = azurerm_storage_account.lake[0].identity[0].principal_id

  key_permissions = ["Get", "WrapKey", "UnwrapKey"]
}

# Without a key version the account follows the key when it is rotated.
resource "azurerm_storage_account_customer_managed_key" "lake" {
  count = local.customer_managed_keys && local.create_lake_account ? 1 : 0

  storage_account_id = azurerm_storage_account.lake[0].id
  key_vault_id       = azurerm_key_vault.this[0].id
  key_name           = azurerm_key_vault_key.data[0].name

  depends_on = [azurerm_key_vault_access_policy.lake]
}

# Without account keys Terraform itself needs a data role to create filesystems and set their ACLs. The role
# takes about a minute to reach the storage service.
resource "azurerm_role_assignment" "lake_deployer" {
  count = var.enable_access_control && local.create_lake_account ? 1 : 0

  scope                = azurerm_storage_account.lake[0].id
  role_definition_name = "Storage Blob Data Owner"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "time_sleep" "lake_deployer" {
  count = var.enable_access_control && local.create_lake_account ? 1 : 0

  create_duration = "90s"

  depends_on = [azurerm_role_assignment.lake_deployer]
}

locals {
  # Microsoft Entra groups that get ACL entries on a zone when access control is on.
  lake_zone_groups = {
    raw       = { engineers = "rwx" }
    processed = { engineers = "rwx" }
    curated   = { engineers = "rwx", analysts = "r-x" }
  }

  lake_group_object_ids = {
    engineers = var.data_engineer_group_object_id
    analysts  = var.data_analyst_group_object_id
  }

  lake_named_entries = {
    for zone, groups in local.lake_zone_groups : zone => [
      for group, permissions in groups : { id = local.lake_group_object_ids[group], permissions = permissions }
      if var.enable_access_control && local.lake_group_object_ids[group] != null
    ]
  }

  # The ACL of a zone's root directory: the owner entries plus one entry per group, once for the directory itself
  # ("access") and once as the template its children inherit ("default"). Zones without group entries keep the
  # ACL Azure gives a new filesystem.
  lake_acl = {
    for zone, named in local.lake_named_entries : zone => flatten([
      for scope in(length(named) > 0 ? ["access", "default"] : []) : concat(
        [
          { scope = scope, type = "user", id = null, permissions = "rwx" },
          { scope = scope, type = "group", id = null, permissions = "r-x" },
          { scope = scope, type = "mask", id = null, permissions = "rwx" },
          { scope = scope, type = "other", id = null, permissions = "---" },
        ],
        [for entry in named : { scope = scope, type = "group", id = entry.id, permissions = entry.permissions }]
      )
    ])
  }
}

# The three zones, and the filesystem of the Synapse workspace when the warehouse is enabled.
resource "azurerm_storage_data_lake_gen2_filesystem" "this" {
  for_each = toset(local.lake_filesystems)

  name               = each.key
  storage_account_id = azurerm_storage_account.lake[0].id

  dynamic "ace" {
    for_each = lookup(local.lake_acl, each.key, [])

    content {
      scope       = ace.value.scope
      type        = ace.value.type
      id          = ace.value.id
      permissions = ace.value.permissions
    }
  }

  depends_on = [time_sleep.lake_deployer]
}

# Ageing data in the raw and processed zones moves to a cheaper tier; the curated zone stays in the account's tier
# because it is the one that is queried.
resource "azurerm_storage_management_policy" "lake" {
  count = var.enable_data_lake ? 1 : 0

  storage_account_id = azurerm_storage_account.lake[0].id

  rule {
    name    = "tier-ageing-data"
    enabled = true

    filters {
      blob_types   = ["blockBlob"]
      prefix_match = ["raw/", "processed/"]
    }

    actions {
      base_blob {
        tier_to_cool_after_days_since_modification_greater_than    = local.lake_tiering.cool_after_days
        tier_to_archive_after_days_since_modification_greater_than = local.lake_tiering.archive_after_days
      }
    }
  }

  depends_on = [azurerm_storage_data_lake_gen2_filesystem.this]
}

# -----------------------------------------------------------------------------
# Who may read and write the data lake. With access control each managed
# identity gets a role on the zones it works in; without it, on the whole
# account.
# -----------------------------------------------------------------------------

locals {
  lake_principals = {
    synapse = {
      enabled      = local.create_synapse
      principal_id = one(azurerm_synapse_workspace.this[*].identity[0].principal_id)
      role         = "Storage Blob Data Contributor"
      zones        = concat(["synapse"], var.enable_data_lake ? ["curated"] : [])
    }
    data_factory = {
      enabled      = local.create_data_factory && var.enable_data_lake
      principal_id = one(azurerm_data_factory.this[*].identity[0].principal_id)
      role         = "Storage Blob Data Contributor"
      zones        = local.lake_zones
    }
    databricks = {
      enabled      = local.create_databricks && var.enable_data_lake
      principal_id = one(azurerm_databricks_access_connector.this[*].identity[0].principal_id)
      role         = "Storage Blob Data Contributor"
      zones        = local.lake_zones
    }
    # Purview lists the filesystems of the account when it scans, so its read role is on the account.
    purview = {
      enabled      = local.create_purview
      principal_id = one(azurerm_purview_account.this[*].identity[0].principal_id)
      role         = "Storage Blob Data Reader"
      zones        = ["account"]
    }
    machine_learning = {
      enabled      = var.enable_ml_platform && var.enable_data_lake
      principal_id = one(azurerm_machine_learning_workspace.this[*].identity[0].principal_id)
      role         = "Storage Blob Data Reader"
      zones        = ["curated"]
    }
    # With access control the groups are granted through the ACL entries above instead of a role.
    engineers = {
      enabled      = var.data_engineer_group_object_id != null
      principal_id = var.data_engineer_group_object_id
      role         = "Storage Blob Data Contributor"
      zones        = []
    }
    analysts = {
      enabled      = var.data_analyst_group_object_id != null
      principal_id = var.data_analyst_group_object_id
      role         = "Storage Blob Data Reader"
      zones        = []
    }
  }

  lake_grants = flatten([
    for name, principal in local.lake_principals : [
      for target in(var.enable_access_control ? principal.zones : ["account"]) : {
        key          = "${name}-${target}"
        principal_id = principal.principal_id
        role         = principal.role
        scope        = target == "account" ? local.lake_account_id : "${local.lake_account_id}/blobServices/default/containers/${target}"
      }
    ] if principal.enabled && local.create_lake_account
  ])
}

resource "azurerm_role_assignment" "lake" {
  for_each = { for grant in local.lake_grants : grant.key => grant }

  scope                = each.value.scope
  role_definition_name = each.value.role
  principal_id         = each.value.principal_id

  depends_on = [azurerm_storage_data_lake_gen2_filesystem.this]
}
