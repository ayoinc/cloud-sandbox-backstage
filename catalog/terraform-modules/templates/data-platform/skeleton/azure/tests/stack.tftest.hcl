# Plans the stack against mocked providers, so the tests need no Azure subscription.
# Values not set in a run come from terraform.tfvars.

mock_provider "azurerm" {
  mock_data "azurerm_client_config" {
    defaults = {
      tenant_id       = "11111111-1111-1111-1111-111111111111"
      subscription_id = "22222222-2222-2222-2222-222222222222"
      client_id       = "33333333-3333-3333-3333-333333333333"
      object_id       = "44444444-4444-4444-4444-444444444444"
    }
  }
}

mock_provider "random" {}

mock_provider "time" {}

run "configured_values" {
  command = plan

  assert {
    condition     = length(azurerm_storage_account.lake) == (var.enable_data_lake || var.enable_data_warehouse ? 1 : 0)
    error_message = "The Data Lake Storage account exists exactly when the data lake or the warehouse is enabled."
  }

  assert {
    condition     = length(azurerm_purview_account.this) == (var.enable_data_catalog ? 1 : 0)
    error_message = "A Purview account exists exactly when the data catalog is enabled."
  }

  assert {
    condition     = length(azurerm_synapse_sql_pool.warehouse) == (var.enable_data_warehouse ? 1 : 0)
    error_message = "A dedicated SQL pool exists exactly when the warehouse is enabled."
  }

  assert {
    condition     = length(azurerm_data_factory.this) == (var.enable_orchestration || (var.enable_etl_pipelines && var.etl_engine == "native") ? 1 : 0)
    error_message = "A data factory exists exactly for native ETL or orchestration."
  }

  assert {
    condition     = length(azurerm_databricks_workspace.this) == (var.enable_etl_pipelines && var.etl_engine == "spark" ? 1 : 0)
    error_message = "A Databricks workspace exists exactly when the ETL engine is spark."
  }

  assert {
    condition     = length(azurerm_eventhub.events) == (var.enable_streaming ? 1 : 0)
    error_message = "An event hub exists exactly when streaming is enabled."
  }

  assert {
    condition     = length(azurerm_machine_learning_workspace.this) == (var.enable_ml_platform ? 1 : 0)
    error_message = "A Machine Learning workspace exists exactly when the ML platform is enabled."
  }
}

run "everything_enabled_in_production" {
  command = plan

  variables {
    environment                      = "production"
    enable_data_lake                 = true
    data_lake_storage_class          = "archive"
    enable_data_catalog              = true
    enable_data_warehouse            = true
    warehouse_size                   = "large"
    enable_etl_pipelines             = true
    etl_engine                       = "spark"
    enable_orchestration             = true
    enable_streaming                 = true
    streaming_retention_hours        = 168
    enable_bi_tools                  = true
    enable_ml_platform               = true
    enable_encryption                = true
    enable_data_lineage              = true
    enable_access_control            = true
    data_engineer_group_object_id    = "55555555-5555-5555-5555-555555555555"
    data_analyst_group_object_id     = "66666666-6666-6666-6666-666666666666"
    power_bi_capacity_administrators = ["bi-admin@example.com"]
  }

  assert {
    condition     = azurerm_storage_account.lake[0].access_tier == "Cool" && azurerm_storage_account.lake[0].account_replication_type == "GRS"
    error_message = "The archive class stores the lake cool, and production replicates it to a second region."
  }

  assert {
    condition     = azurerm_storage_management_policy.lake[0].rule[0].actions[0].base_blob[0].tier_to_archive_after_days_since_modification_greater_than == 30
    error_message = "The archive class moves raw and processed data to the archive tier after 30 days."
  }

  assert {
    condition     = sort(keys(azurerm_storage_data_lake_gen2_filesystem.this)) == tolist(["curated", "processed", "raw", "synapse"])
    error_message = "The lake has the three zones and the filesystem of the Synapse workspace."
  }

  assert {
    condition     = azurerm_synapse_sql_pool.warehouse[0].sku_name == "DW1000c" && azurerm_synapse_sql_pool.warehouse[0].geo_backup_policy_enabled
    error_message = "A large warehouse is a DW1000c pool, geo-backed up in production."
  }

  assert {
    condition     = length(azurerm_key_vault_key.data) == 1 && length(azurerm_storage_account_customer_managed_key.lake) == 1 && length(azurerm_storage_account_customer_managed_key.ml) == 1 && length(azurerm_synapse_workspace_key.this) == 1 && length(azurerm_databricks_workspace_root_dbfs_customer_managed_key.this) == 1
    error_message = "Encryption puts the customer-managed key on both storage accounts, the Synapse workspace and the Databricks root storage."
  }

  assert {
    condition     = length(azurerm_synapse_workspace.this[0].customer_managed_key) == 1 && azurerm_databricks_workspace.this[0].customer_managed_key_enabled
    error_message = "The Synapse and Databricks workspaces are created ready for the customer-managed key."
  }

  assert {
    condition     = azurerm_databricks_workspace.this[0].sku == "premium" && length(azurerm_databricks_access_connector.this) == 1
    error_message = "The spark engine is a premium Databricks workspace with an access connector."
  }

  assert {
    condition     = length(azurerm_data_factory.this) == 1 && length(azurerm_data_factory_pipeline.spark) == 1 && length(azurerm_data_factory_pipeline.ingest) == 0 && azurerm_data_factory_trigger_schedule.daily[0].pipeline_name == "run_spark_etl"
    error_message = "With orchestration the data factory runs the Databricks notebook on the schedule."
  }

  assert {
    condition     = local.lineage_enabled && output.data_lineage_enabled
    error_message = "Lineage is reported when the catalog exists."
  }

  assert {
    condition     = azurerm_eventhub.events[0].message_retention == 7 && azurerm_eventhub_namespace.this[0].auto_inflate_enabled
    error_message = "168 hours are 7 days of retention, and the production namespace scales its throughput units."
  }

  assert {
    condition     = !azurerm_storage_account.lake[0].shared_access_key_enabled && azurerm_synapse_workspace.this[0].azuread_authentication_only && !azurerm_eventhub_namespace.this[0].local_authentication_enabled
    error_message = "Access control turns off account keys, SQL logins and shared access keys."
  }

  assert {
    condition     = sort(keys(azurerm_role_assignment.lake)) == tolist(["data_factory-curated", "data_factory-processed", "data_factory-raw", "databricks-curated", "databricks-processed", "databricks-raw", "machine_learning-curated", "purview-account", "synapse-curated", "synapse-synapse"])
    error_message = "Access control grants each managed identity a role on its zones only, and the groups none."
  }

  assert {
    condition     = length(azurerm_storage_data_lake_gen2_filesystem.this["raw"].ace) == 10 && length(azurerm_storage_data_lake_gen2_filesystem.this["curated"].ace) == 12 && length(local.lake_acl["curated"]) == 12
    error_message = "Engineers get ACL entries on every zone and analysts on the curated zone, as access and default entries."
  }

  assert {
    condition     = sort(keys(azurerm_role_assignment.streaming)) == tolist(["databricks", "engineers"])
    error_message = "Databricks and the engineers get Event Hubs data roles."
  }

  assert {
    condition     = length(azurerm_synapse_firewall_rule.azure_services) == 1 && length(azurerm_powerbi_embedded.this) == 1
    error_message = "BI opens the SQL endpoint to Azure services and creates the capacity when administrators are named."
  }

  assert {
    condition     = length(azurerm_machine_learning_workspace.this) == 1 && length(module.app_insights) == 1 && length(module.log_analytics) == 1 && length(azurerm_storage_account.ml) == 1
    error_message = "The ML platform is a workspace with storage, Application Insights and Log Analytics."
  }
}

run "data_lake_only" {
  command = plan

  variables {
    environment             = "staging"
    enable_data_lake        = true
    data_lake_storage_class = "infrequent"
    enable_data_catalog     = false
    enable_data_warehouse   = false
    enable_etl_pipelines    = false
    enable_orchestration    = false
    enable_streaming        = false
    enable_bi_tools         = false
    enable_ml_platform      = false
    enable_encryption       = false
    enable_data_lineage     = false
    enable_access_control   = false
  }

  assert {
    condition     = sort(keys(azurerm_storage_data_lake_gen2_filesystem.this)) == tolist(["curated", "processed", "raw"])
    error_message = "The data lake has a raw, a processed and a curated zone."
  }

  assert {
    condition     = azurerm_storage_account.lake[0].is_hns_enabled && azurerm_storage_account.lake[0].access_tier == "Cool" && azurerm_storage_account.lake[0].account_replication_type == "LRS"
    error_message = "The infrequent class stores the lake in the cool tier."
  }

  assert {
    condition     = azurerm_storage_management_policy.lake[0].rule[0].actions[0].base_blob[0].tier_to_archive_after_days_since_modification_greater_than == 180
    error_message = "The infrequent class archives raw and processed data after 180 days."
  }

  assert {
    condition     = length(azurerm_key_vault.this) == 0 && length(azurerm_key_vault_key.data) == 0 && length(azurerm_storage_account_customer_managed_key.lake) == 0
    error_message = "Without encryption the lake uses Microsoft-managed keys and no Key Vault is needed."
  }

  assert {
    condition     = azurerm_storage_account.lake[0].shared_access_key_enabled && length(azurerm_role_assignment.lake_deployer) == 0 && length(azurerm_role_assignment.lake) == 0
    error_message = "Without access control the account keys stay enabled and nothing else needs a role."
  }

  assert {
    condition     = length(azurerm_synapse_workspace.this) + length(azurerm_purview_account.this) + length(azurerm_data_factory.this) + length(azurerm_databricks_workspace.this) + length(azurerm_eventhub_namespace.this) + length(azurerm_machine_learning_workspace.this) == 0
    error_message = "Disabled features create nothing."
  }
}

run "nothing_enabled" {
  command = plan

  variables {
    enable_data_lake      = false
    enable_data_catalog   = false
    enable_data_warehouse = false
    enable_etl_pipelines  = false
    enable_orchestration  = false
    enable_streaming      = false
    enable_bi_tools       = true
    enable_ml_platform    = false
    enable_encryption     = true
    enable_data_lineage   = true
    enable_access_control = true
  }

  assert {
    condition     = length(azurerm_storage_account.lake) == 0 && length(azurerm_storage_data_lake_gen2_filesystem.this) == 0 && length(azurerm_storage_management_policy.lake) == 0
    error_message = "No storage is created when neither the data lake nor the warehouse is enabled."
  }

  assert {
    condition     = length(azurerm_key_vault.this) == 0 && length(azurerm_key_vault_key.data) == 0
    error_message = "Encryption creates no key while there is nothing to encrypt."
  }

  assert {
    condition     = !output.data_lineage_enabled && length(azurerm_synapse_firewall_rule.azure_services) == 0 && length(azurerm_role_assignment.lake) == 0
    error_message = "Lineage, BI and access control have nothing to act on."
  }
}

run "standard_class_and_small_warehouse" {
  command = plan

  variables {
    environment             = "dev"
    enable_data_lake        = true
    data_lake_storage_class = "standard"
    enable_data_warehouse   = true
    warehouse_size          = "small"
  }

  assert {
    condition     = azurerm_storage_account.lake[0].access_tier == "Hot" && azurerm_storage_management_policy.lake[0].rule[0].actions[0].base_blob[0].tier_to_cool_after_days_since_modification_greater_than == 90
    error_message = "The standard class keeps the lake hot and cools raw and processed data after 90 days."
  }

  assert {
    condition     = azurerm_synapse_sql_pool.warehouse[0].sku_name == "DW100c" && azurerm_synapse_sql_pool.warehouse[0].storage_account_type == "LRS" && !azurerm_synapse_sql_pool.warehouse[0].geo_backup_policy_enabled
    error_message = "A small warehouse is a DW100c pool with local backups outside production."
  }

  assert {
    condition     = azurerm_synapse_sql_pool.warehouse[0].data_encrypted
    error_message = "The SQL pool is always encrypted at rest."
  }
}

run "warehouse_without_data_lake" {
  command = plan

  variables {
    enable_data_lake      = false
    enable_data_catalog   = false
    enable_data_warehouse = true
    warehouse_size        = "medium"
    enable_etl_pipelines  = false
    enable_orchestration  = false
    enable_bi_tools       = true
    enable_ml_platform    = false
    enable_encryption     = false
    enable_access_control = false
  }

  assert {
    condition     = length(azurerm_storage_account.lake) == 1 && keys(azurerm_storage_data_lake_gen2_filesystem.this) == ["synapse"] && length(azurerm_storage_management_policy.lake) == 0
    error_message = "The warehouse brings the storage account Synapse requires, without the zones."
  }

  assert {
    condition     = azurerm_synapse_sql_pool.warehouse[0].sku_name == "DW500c"
    error_message = "A medium warehouse is a DW500c pool."
  }

  assert {
    condition     = length(azurerm_synapse_workspace.this[0].customer_managed_key) == 0 && length(azurerm_synapse_workspace_key.this) == 0 && length(azurerm_key_vault_key.data) == 0
    error_message = "Without encryption the workspace uses Microsoft-managed keys."
  }

  assert {
    condition     = length(azurerm_key_vault_secret.sql_admin_password) == 1 && !azurerm_synapse_workspace.this[0].azuread_authentication_only
    error_message = "Without access control SQL logins work, and the generated administrator password is in the Key Vault."
  }

  assert {
    condition     = keys(azurerm_role_assignment.lake) == ["synapse-account"]
    error_message = "Without access control the workspace gets its role on the whole storage account."
  }

  assert {
    condition     = length(azurerm_synapse_firewall_rule.azure_services) == 1 && length(azurerm_powerbi_embedded.this) == 0
    error_message = "BI opens the SQL endpoint to the Power BI service; no capacity is created without administrators."
  }
}

run "bi_disabled" {
  command = plan

  variables {
    enable_data_warehouse            = true
    enable_bi_tools                  = false
    power_bi_capacity_administrators = ["bi-admin@example.com"]
  }

  assert {
    condition     = length(azurerm_synapse_firewall_rule.azure_services) == 0 && length(azurerm_powerbi_embedded.this) == 0
    error_message = "Without BI the SQL endpoint stays closed to Azure services and no capacity is created."
  }
}

run "native_etl_on_a_schedule" {
  command = plan

  variables {
    enable_data_lake     = true
    enable_etl_pipelines = true
    etl_engine           = "native"
    enable_orchestration = true
  }

  assert {
    condition     = length(azurerm_data_factory.this) == 1 && length(azurerm_databricks_workspace.this) == 0
    error_message = "The native engine is a data factory without Databricks."
  }

  assert {
    condition     = length(azurerm_data_factory_pipeline.ingest) == 1 && length(azurerm_data_factory_dataset_delimited_text.raw) == 1 && length(azurerm_data_factory_dataset_parquet.processed) == 1
    error_message = "The native ETL copies the raw zone to Parquet in the processed zone."
  }

  assert {
    condition     = azurerm_data_factory_trigger_schedule.daily[0].pipeline_name == "ingest_raw_to_processed" && !azurerm_data_factory_trigger_schedule.daily[0].activated
    error_message = "Orchestration schedules the ingest pipeline; the trigger is created stopped."
  }

  assert {
    condition     = !azurerm_data_factory.this[0].public_network_enabled
    error_message = "The data factory has no public endpoint."
  }
}

run "native_etl_without_orchestration" {
  command = plan

  variables {
    enable_data_lake     = true
    enable_etl_pipelines = true
    etl_engine           = "native"
    enable_orchestration = false
  }

  assert {
    condition     = length(azurerm_data_factory_pipeline.ingest) == 1 && length(azurerm_data_factory_trigger_schedule.daily) == 0
    error_message = "Without orchestration the ingest pipeline has no schedule."
  }
}

run "spark_etl_without_orchestration" {
  command = plan

  variables {
    enable_etl_pipelines = true
    etl_engine           = "spark"
    enable_orchestration = false
    enable_encryption    = false
  }

  assert {
    condition     = length(azurerm_databricks_workspace.this) == 1 && length(azurerm_data_factory.this) == 0 && length(azurerm_data_factory_pipeline.spark) == 0
    error_message = "The spark engine alone is a Databricks workspace without a data factory."
  }

  assert {
    condition     = !azurerm_databricks_workspace.this[0].customer_managed_key_enabled && length(azurerm_databricks_workspace_root_dbfs_customer_managed_key.this) == 0
    error_message = "Without encryption the Databricks root storage uses Microsoft-managed keys."
  }
}

run "orchestration_without_etl" {
  command = plan

  variables {
    enable_etl_pipelines = false
    enable_orchestration = true
  }

  assert {
    condition     = length(azurerm_data_factory.this) == 1 && length(azurerm_data_factory_pipeline.ingest) + length(azurerm_data_factory_pipeline.spark) + length(azurerm_data_factory_trigger_schedule.daily) == 0
    error_message = "Orchestration without an ETL engine creates the data factory with nothing scheduled yet."
  }
}

run "lineage_without_catalog" {
  command = plan

  variables {
    enable_data_catalog   = false
    enable_data_lineage   = true
    enable_data_warehouse = true
    enable_orchestration  = true
  }

  assert {
    condition     = length(azurerm_purview_account.this) == 0 && azurerm_data_factory.this[0].purview_id == null && azurerm_synapse_workspace.this[0].purview_id == null && !output.data_lineage_enabled
    error_message = "Without a catalog there is nowhere to report lineage to."
  }
}

run "catalog_without_lineage" {
  command = plan

  variables {
    enable_data_catalog   = true
    enable_data_lineage   = false
    enable_data_lake      = true
    enable_data_warehouse = true
    enable_orchestration  = true
    enable_access_control = true
  }

  assert {
    condition     = length(azurerm_purview_account.this) == 1 && azurerm_data_factory.this[0].purview_id == null && azurerm_synapse_workspace.this[0].purview_id == null
    error_message = "With lineage disabled the catalog exists but Data Factory and Synapse are not connected to it."
  }

  assert {
    condition     = contains(keys(azurerm_role_assignment.lake), "purview-account")
    error_message = "The catalog can read the data lake to scan it."
  }
}

run "streaming_one_day" {
  command = plan

  variables {
    enable_streaming          = true
    streaming_retention_hours = 24
    enable_access_control     = false
  }

  assert {
    condition     = azurerm_eventhub_namespace.this[0].sku == "Standard" && azurerm_eventhub.events[0].message_retention == 1 && length(azurerm_eventhub_consumer_group.etl) == 1
    error_message = "24 hours are 1 day of retention on a Standard namespace."
  }

  assert {
    condition     = azurerm_eventhub_namespace.this[0].local_authentication_enabled
    error_message = "Without access control shared access keys stay enabled."
  }
}

run "streaming_rounds_up_to_whole_days" {
  command = plan

  variables {
    enable_streaming          = true
    streaming_retention_hours = 49
  }

  assert {
    condition     = azurerm_eventhub.events[0].message_retention == 3 && output.streaming_retention_days == 3
    error_message = "49 hours are rounded up to 3 days."
  }
}

run "streaming_stays_within_the_standard_tier" {
  command = plan

  variables {
    enable_streaming          = true
    streaming_retention_hours = 720
  }

  assert {
    condition     = azurerm_eventhub.events[0].message_retention == 7
    error_message = "Retention is limited to the 7 days of Event Hubs Standard."
  }
}

run "groups_without_access_control" {
  command = plan

  variables {
    enable_data_lake              = true
    enable_data_warehouse         = false
    enable_data_catalog           = false
    enable_etl_pipelines          = false
    enable_orchestration          = false
    enable_ml_platform            = false
    enable_access_control         = false
    data_engineer_group_object_id = "55555555-5555-5555-5555-555555555555"
    data_analyst_group_object_id  = "66666666-6666-6666-6666-666666666666"
  }

  assert {
    condition     = sort(keys(azurerm_role_assignment.lake)) == tolist(["analysts-account", "engineers-account"])
    error_message = "Without access control the groups get account-wide roles."
  }

  assert {
    condition     = length(local.lake_acl["raw"]) == 0 && length(local.lake_acl["curated"]) == 0
    error_message = "Without access control no ACL entries are set."
  }
}

run "restricted_networks" {
  command = plan

  variables {
    enable_data_warehouse = true
    enable_ml_platform    = true
    allowed_ip_ranges     = ["203.0.113.0/24", "198.51.100.8/30"]
  }

  assert {
    condition     = azurerm_storage_account.lake[0].network_rules[0].default_action == "Deny" && azurerm_storage_account.ml[0].network_rules[0].default_action == "Deny" && azurerm_key_vault.this[0].network_acls[0].default_action == "Deny"
    error_message = "With allowed_ip_ranges the storage accounts and the Key Vault deny other networks."
  }

  assert {
    condition     = azurerm_synapse_firewall_rule.allowed["203.0.113.0/24"].start_ip_address == "203.0.113.0" && azurerm_synapse_firewall_rule.allowed["203.0.113.0/24"].end_ip_address == "203.0.113.255" && length(azurerm_synapse_firewall_rule.allowed) == 2
    error_message = "Each allowed range becomes a Synapse firewall rule."
  }
}
