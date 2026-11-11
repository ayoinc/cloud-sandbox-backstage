# -----------------------------------------------------------------------------
# Streaming: Event Hubs namespace with one event hub.
# -----------------------------------------------------------------------------

locals {
  # Event Hubs Standard keeps events for 1 to 7 whole days.
  streaming_retention_days = min(7, max(1, ceil(var.streaming_retention_hours / 24)))

  streaming_principals = {
    # Spark jobs read the stream with the identity of the Databricks access connector.
    databricks = {
      enabled      = local.create_databricks
      principal_id = one(azurerm_databricks_access_connector.this[*].identity[0].principal_id)
      role         = "Azure Event Hubs Data Receiver"
    }
    engineers = {
      enabled      = var.data_engineer_group_object_id != null
      principal_id = var.data_engineer_group_object_id
      role         = "Azure Event Hubs Data Owner"
    }
  }
}

resource "azurerm_eventhub_namespace" "this" {
  count = var.enable_streaming ? 1 : 0

  name                = "evhns-${local.name_prefix}-${local.unique_suffix}"
  resource_group_name = module.resource_group.name
  location            = var.location

  sku                      = "Standard"
  capacity                 = 1
  auto_inflate_enabled     = local.is_production
  maximum_throughput_units = local.is_production ? 10 : null
  minimum_tls_version      = "1.2"

  # With access control shared access keys are refused and clients sign in with Microsoft Entra ID.
  local_authentication_enabled = !var.enable_access_control

  tags = local.common_tags

  # Remove prevent_destroy to delete the namespace and the events it holds on purpose.
  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_eventhub" "events" {
  count = var.enable_streaming ? 1 : 0

  name                = "events"
  namespace_name      = azurerm_eventhub_namespace.this[0].name
  resource_group_name = module.resource_group.name
  partition_count     = var.streaming_partition_count
  message_retention   = local.streaming_retention_days

  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_eventhub_consumer_group" "etl" {
  count = var.enable_streaming ? 1 : 0

  name                = "etl"
  namespace_name      = azurerm_eventhub_namespace.this[0].name
  eventhub_name       = azurerm_eventhub.events[0].name
  resource_group_name = module.resource_group.name
}

resource "azurerm_role_assignment" "streaming" {
  for_each = { for name, principal in local.streaming_principals : name => principal if principal.enabled && var.enable_streaming }

  scope                = azurerm_eventhub_namespace.this[0].id
  role_definition_name = each.value.role
  principal_id         = each.value.principal_id
}
