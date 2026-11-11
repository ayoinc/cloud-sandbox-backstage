output "resource_group_name" {
  description = "Resource group that holds the data platform"
  value       = module.resource_group.name
}

output "data_lake_storage_account_name" {
  description = "Data Lake Storage Gen2 account, when the data lake or the warehouse is enabled"
  value       = one(azurerm_storage_account.lake[*].name)
}

output "data_lake_dfs_endpoint" {
  description = "Endpoint of the data lake for abfss:// and Power BI connections"
  value       = one(azurerm_storage_account.lake[*].primary_dfs_endpoint)
}

output "data_lake_filesystems" {
  description = "Filesystems of the data lake: the zones, and the one of the Synapse workspace"
  value       = sort(keys(azurerm_storage_data_lake_gen2_filesystem.this))
}

output "key_vault_name" {
  description = "Key Vault with the encryption key and the SQL administrator password"
  value       = one(azurerm_key_vault.this[*].name)
}

output "encryption_key_id" {
  description = "Customer-managed key that encrypts the stores, when encryption is enabled"
  value       = one(azurerm_key_vault_key.data[*].versionless_id)
}

output "data_catalog_account_name" {
  description = "Microsoft Purview account, when the data catalog is enabled"
  value       = one(azurerm_purview_account.this[*].name)
}

output "data_catalog_endpoint" {
  description = "Catalog endpoint of the Purview account"
  value       = one(azurerm_purview_account.this[*].catalog_endpoint)
}

output "data_lineage_enabled" {
  description = "Whether Data Factory and Synapse report lineage to the Purview account"
  value       = local.lineage_enabled && (local.create_data_factory || local.create_synapse)
}

output "synapse_workspace_name" {
  description = "Synapse workspace, when the warehouse is enabled"
  value       = one(azurerm_synapse_workspace.this[*].name)
}

output "warehouse_sql_endpoint" {
  description = "Dedicated SQL endpoint of the warehouse. Power BI and SQL clients connect to it."
  value       = try(azurerm_synapse_workspace.this[0].connectivity_endpoints["sql"], null)
}

output "warehouse_sql_pool_name" {
  description = "Dedicated SQL pool, which is also the database name"
  value       = one(azurerm_synapse_sql_pool.warehouse[*].name)
}

output "warehouse_sql_admin_password_secret" {
  description = "Key Vault secret with the password of the SQL administrator"
  value       = one(azurerm_key_vault_secret.sql_admin_password[*].name)
}

output "data_factory_name" {
  description = "Data Factory, for native ETL or orchestration"
  value       = one(azurerm_data_factory.this[*].name)
}

output "etl_pipeline_name" {
  description = "Data Factory pipeline that runs the ETL"
  value       = local.create_spark_pipeline ? azurerm_data_factory_pipeline.spark[0].name : one(azurerm_data_factory_pipeline.ingest[*].name)
}

output "databricks_workspace_url" {
  description = "URL of the Databricks workspace, when the ETL engine is spark"
  value       = try("https://${azurerm_databricks_workspace.this[0].workspace_url}", null)
}

output "databricks_access_connector_id" {
  description = "Access connector to register as a Unity Catalog storage credential for the data lake"
  value       = one(azurerm_databricks_access_connector.this[*].id)
}

output "eventhub_namespace_name" {
  description = "Event Hubs namespace, when streaming is enabled"
  value       = one(azurerm_eventhub_namespace.this[*].name)
}

output "eventhub_name" {
  description = "Event hub that receives the stream"
  value       = one(azurerm_eventhub.events[*].name)
}

output "streaming_retention_days" {
  description = "Days the event hub keeps events, derived from streaming_retention_hours"
  value       = var.enable_streaming ? local.streaming_retention_days : null
}

output "power_bi_capacity_name" {
  description = "Power BI Embedded capacity, when BI is enabled and administrators are named"
  value       = one(azurerm_powerbi_embedded.this[*].name)
}

output "machine_learning_workspace_name" {
  description = "Azure Machine Learning workspace, when the ML platform is enabled"
  value       = one(azurerm_machine_learning_workspace.this[*].name)
}
