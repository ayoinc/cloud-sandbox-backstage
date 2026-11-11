mock_provider "azurerm" {}
mock_provider "random" {}

variables {
  project_name        = "demo-platform-services"
  environment         = "dev"
  location            = "eastus2"
  resource_group_name = "demo-dev-rg"
}

run "defaults" {
  command = plan

  assert {
    condition     = azurerm_storage_account.main.https_traffic_only_enabled && azurerm_storage_account.main.min_tls_version == "TLS1_2"
    error_message = "The account must accept only TLS 1.2 HTTPS traffic."
  }

  assert {
    condition     = azurerm_storage_account.main.allow_nested_items_to_be_public == false
    error_message = "Anonymous blob access must be disabled."
  }

  assert {
    condition     = azurerm_storage_account.main.infrastructure_encryption_enabled
    error_message = "Infrastructure encryption must be on by default."
  }

  assert {
    condition     = azurerm_storage_account.main.network_rules[0].default_action == "Deny"
    error_message = "The account firewall must deny by default."
  }

  assert {
    condition     = azurerm_storage_account.main.blob_properties[0].versioning_enabled
    error_message = "Blob versioning must be on by default."
  }

  assert {
    condition     = sort(keys(azurerm_storage_container.main)) == tolist(["data"]) && azurerm_storage_container.main["data"].container_access_type == "private"
    error_message = "A single private container named data is expected."
  }

  assert {
    condition     = azurerm_storage_management_policy.main[0].rule[0].actions[0].base_blob[0].tier_to_archive_after_days_since_modification_greater_than == 90
    error_message = "The default lifecycle rule archives blobs after 90 days."
  }

  assert {
    condition     = length(azurerm_storage_share.main) == 0 && length(azurerm_monitor_diagnostic_setting.storage) == 0
    error_message = "File share and diagnostics are off by default."
  }
}

run "file_share_diagnostics_and_network_rules" {
  command = plan

  variables {
    enable_file_share          = true
    file_share_quota_gb        = 200
    file_share_access_tier     = "Cool"
    allowed_ip_ranges          = ["203.0.113.0/24"]
    allowed_subnet_ids         = ["/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/private"]
    log_analytics_workspace_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.OperationalInsights/workspaces/law"
  }

  assert {
    condition     = azurerm_storage_share.main[0].name == "demo-platform-services-dev-share" && azurerm_storage_share.main[0].quota == 200 && azurerm_storage_share.main[0].access_tier == "Cool"
    error_message = "The file share must use the requested quota and tier."
  }

  assert {
    condition     = azurerm_storage_account.main.network_rules[0].ip_rules == toset(["203.0.113.0/24"]) && length(azurerm_storage_account.main.network_rules[0].virtual_network_subnet_ids) == 1
    error_message = "Network rules must carry the allow-lists."
  }

  assert {
    condition     = length(azurerm_monitor_diagnostic_setting.storage[0].enabled_log) == 3
    error_message = "Read, write and delete logs must be sent to Log Analytics."
  }
}

run "no_containers_or_lifecycle_rules" {
  command = plan

  variables {
    container_names   = []
    lifecycle_rules   = []
    enable_versioning = false
  }

  assert {
    condition     = length(azurerm_storage_container.main) == 0 && length(azurerm_storage_management_policy.main) == 0
    error_message = "No containers or policy are expected for empty inputs."
  }
}

run "premium_file_storage" {
  command = plan

  variables {
    account_kind           = "FileStorage"
    account_tier           = "Premium"
    replication_type       = "ZRS"
    container_names        = []
    lifecycle_rules        = []
    enable_file_share      = true
    file_share_quota_gb    = 100
    file_share_access_tier = "Premium"
  }

  assert {
    condition     = azurerm_storage_account.main.account_kind == "FileStorage" && azurerm_storage_share.main[0].access_tier == "Premium"
    error_message = "A premium file share must be planned on a FileStorage account."
  }
}

run "rejects_archive_with_zone_redundancy" {
  command = plan

  variables {
    replication_type = "ZRS"
  }

  expect_failures = [azurerm_storage_management_policy.main]
}

run "rejects_premium_with_geo_replication" {
  command = plan

  variables {
    account_kind     = "BlockBlobStorage"
    account_tier     = "Premium"
    replication_type = "GRS"
    lifecycle_rules  = []
  }

  expect_failures = [azurerm_storage_account.main]
}

run "rejects_invalid_container_name" {
  command = plan

  variables {
    container_names = ["Data_Bucket"]
  }

  expect_failures = [var.container_names]
}
