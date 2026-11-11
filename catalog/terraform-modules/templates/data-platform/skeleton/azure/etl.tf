# -----------------------------------------------------------------------------
# Processing. etl_engine "native" builds the ETL in Azure Data Factory, "spark"
# creates an Azure Databricks workspace. enable_orchestration adds a Data
# Factory schedule that runs whichever of the two is enabled.
# -----------------------------------------------------------------------------

locals {
  # The native ETL copies between zones, so it needs them.
  create_ingest_pipeline = local.etl_native && var.enable_data_lake
  # Data Factory runs the Databricks notebook only as the orchestrator.
  create_spark_pipeline = local.etl_spark && var.enable_orchestration
  create_schedule       = var.enable_orchestration && (local.create_ingest_pipeline || local.create_spark_pipeline)
}

resource "azurerm_data_factory" "this" {
  count = local.create_data_factory ? 1 : 0

  name                = "adf-${local.name_prefix}-${local.unique_suffix}"
  resource_group_name = module.resource_group.name
  location            = var.location

  # Only self-hosted integration runtimes use the public endpoint, and there are none.
  public_network_enabled = false

  # Copy and data flow activities report lineage to the catalog.
  purview_id = local.lineage_enabled ? azurerm_purview_account.this[0].id : null

  identity {
    type = "SystemAssigned"
  }

  tags = local.common_tags
}

# --- Native ETL: raw delimited text to processed Parquet -----------------------

resource "azurerm_data_factory_linked_service_data_lake_storage_gen2" "lake" {
  count = local.create_data_factory && var.enable_data_lake ? 1 : 0

  name                 = "data_lake"
  data_factory_id      = azurerm_data_factory.this[0].id
  url                  = azurerm_storage_account.lake[0].primary_dfs_endpoint
  use_managed_identity = true
}

resource "azurerm_data_factory_dataset_delimited_text" "raw" {
  count = local.create_ingest_pipeline ? 1 : 0

  name                = "raw_delimited_text"
  data_factory_id     = azurerm_data_factory.this[0].id
  linked_service_name = azurerm_data_factory_linked_service_data_lake_storage_gen2.lake[0].name

  column_delimiter    = ","
  row_delimiter       = "\n"
  encoding            = "UTF-8"
  quote_character     = "\""
  escape_character    = "\\"
  first_row_as_header = true

  azure_blob_fs_location {
    file_system = azurerm_storage_data_lake_gen2_filesystem.this["raw"].name
  }
}

resource "azurerm_data_factory_dataset_parquet" "processed" {
  count = local.create_ingest_pipeline ? 1 : 0

  name                = "processed_parquet"
  data_factory_id     = azurerm_data_factory.this[0].id
  linked_service_name = azurerm_data_factory_linked_service_data_lake_storage_gen2.lake[0].name

  compression_codec = "snappy"

  azure_blob_fs_location {
    file_system = azurerm_storage_data_lake_gen2_filesystem.this["processed"].name
  }
}

resource "azurerm_data_factory_pipeline" "ingest" {
  count = local.create_ingest_pipeline ? 1 : 0

  name            = "ingest_raw_to_processed"
  data_factory_id = azurerm_data_factory.this[0].id
  description     = "Copies the CSV files of the raw zone to Parquet files in the processed zone, keeping the folder structure."

  activities_json = jsonencode([
    {
      name = "CopyRawToProcessed"
      type = "Copy"
      inputs = [
        { referenceName = azurerm_data_factory_dataset_delimited_text.raw[0].name, type = "DatasetReference" },
      ]
      outputs = [
        { referenceName = azurerm_data_factory_dataset_parquet.processed[0].name, type = "DatasetReference" },
      ]
      typeProperties = {
        source = {
          type           = "DelimitedTextSource"
          storeSettings  = { type = "AzureBlobFSReadSettings", recursive = true, wildcardFileName = "*.csv" }
          formatSettings = { type = "DelimitedTextReadSettings" }
        }
        sink = {
          type           = "ParquetSink"
          storeSettings  = { type = "AzureBlobFSWriteSettings" }
          formatSettings = { type = "ParquetWriteSettings" }
        }
      }
    },
  ])
}

# --- Spark ETL: Azure Databricks ------------------------------------------------

resource "azurerm_databricks_workspace" "this" {
  count = local.create_databricks ? 1 : 0

  name                        = "dbw-${local.name_prefix}"
  resource_group_name         = module.resource_group.name
  location                    = var.location
  managed_resource_group_name = "rg-${local.name_prefix}-databricks"

  # Premium is the tier with customer-managed keys, Unity Catalog and access control.
  sku = "premium"

  # Prepares the workspace's root storage for the key set in azurerm_databricks_workspace_root_dbfs_customer_managed_key.
  customer_managed_key_enabled = var.enable_encryption

  tags = local.common_tags

  # Remove prevent_destroy to delete the workspace with its notebooks and root storage on purpose.
  lifecycle {
    prevent_destroy = true
  }
}

# The identity Databricks uses to reach the data lake: register it as a storage credential in Unity Catalog.
resource "azurerm_databricks_access_connector" "this" {
  count = local.create_databricks ? 1 : 0

  name                = "dbac-${local.name_prefix}"
  resource_group_name = module.resource_group.name
  location            = var.location

  identity {
    type = "SystemAssigned"
  }

  tags = local.common_tags
}

resource "azurerm_key_vault_access_policy" "databricks" {
  count = local.create_databricks && local.customer_managed_keys ? 1 : 0

  key_vault_id = azurerm_key_vault.this[0].id
  tenant_id    = azurerm_databricks_workspace.this[0].storage_account_identity[0].tenant_id
  object_id    = azurerm_databricks_workspace.this[0].storage_account_identity[0].principal_id

  key_permissions = ["Get", "WrapKey", "UnwrapKey"]
}

resource "azurerm_databricks_workspace_root_dbfs_customer_managed_key" "this" {
  count = local.create_databricks && local.customer_managed_keys ? 1 : 0

  workspace_id     = azurerm_databricks_workspace.this[0].id
  key_vault_key_id = azurerm_key_vault_key.data[0].id

  depends_on = [azurerm_key_vault_access_policy.databricks]
}

# --- Orchestration: Data Factory runs the Databricks notebook ------------------

# Data Factory signs in to the workspace with its managed identity, which needs the Contributor role there.
resource "azurerm_role_assignment" "data_factory_databricks" {
  count = local.create_spark_pipeline ? 1 : 0

  scope                = azurerm_databricks_workspace.this[0].id
  role_definition_name = "Contributor"
  principal_id         = azurerm_data_factory.this[0].identity[0].principal_id
}

resource "azurerm_data_factory_linked_service_azure_databricks" "this" {
  count = local.create_spark_pipeline ? 1 : 0

  name                       = "databricks"
  data_factory_id            = azurerm_data_factory.this[0].id
  adb_domain                 = "https://${azurerm_databricks_workspace.this[0].workspace_url}"
  msi_work_space_resource_id = azurerm_databricks_workspace.this[0].id

  # Each run starts a job cluster and removes it afterwards.
  new_cluster_config {
    node_type             = var.databricks_node_type
    cluster_version       = var.databricks_spark_version
    min_number_of_workers = 1
    max_number_of_workers = var.databricks_max_workers
  }

  depends_on = [azurerm_role_assignment.data_factory_databricks]
}

resource "azurerm_data_factory_pipeline" "spark" {
  count = local.create_spark_pipeline ? 1 : 0

  name            = "run_spark_etl"
  data_factory_id = azurerm_data_factory.this[0].id
  description     = "Runs the Databricks notebook ${var.databricks_notebook_path} on a job cluster."

  activities_json = jsonencode([
    {
      name              = "RunNotebook"
      type              = "DatabricksNotebook"
      linkedServiceName = { referenceName = azurerm_data_factory_linked_service_azure_databricks.this[0].name, type = "LinkedServiceReference" }
      typeProperties = {
        notebookPath = var.databricks_notebook_path
        # The notebook reads the zones as abfss://<zone>@<data_lake_host>/ when the data lake exists.
        baseParameters = { for name, value in { data_lake_host = one(azurerm_storage_account.lake[*].primary_dfs_host) } : name => value if var.enable_data_lake }
      }
    },
  ])
}

resource "azurerm_data_factory_trigger_schedule" "daily" {
  count = local.create_schedule ? 1 : 0

  name            = "daily"
  data_factory_id = azurerm_data_factory.this[0].id
  pipeline_name   = local.create_spark_pipeline ? azurerm_data_factory_pipeline.spark[0].name : azurerm_data_factory_pipeline.ingest[0].name

  frequency = "Day"
  interval  = 1
  time_zone = "UTC"

  schedule {
    hours   = [var.orchestration_hour_utc]
    minutes = [0]
  }

  activated = var.orchestration_trigger_activated
}
