terraform {
  required_version = ">= 1.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0"
    }
  }
}

locals {
  default_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }

  eventhubs_map       = { for eh in var.eventhubs : eh.name => eh }
  consumer_groups_map = { for cg in var.consumer_groups : "${cg.eventhub_name}-${cg.name}" => cg }
  auth_rules_map      = { for ar in var.authorization_rules : ar.name => ar }
}

resource "azurerm_eventhub_namespace" "this" {
  name                     = var.namespace_name
  location                 = var.location
  resource_group_name      = var.resource_group_name
  sku                      = var.sku
  capacity                 = var.capacity
  auto_inflate_enabled     = var.auto_inflate_enabled
  maximum_throughput_units = var.auto_inflate_enabled ? var.maximum_throughput_units : null
  zone_redundant           = var.zone_redundant

  identity {
    type = "SystemAssigned"
  }

  network_rulesets {
    default_action                 = "Allow"
    trusted_service_access_enabled = true
  }

  tags = merge(local.default_tags, var.tags)
}

resource "azurerm_eventhub" "this" {
  for_each = local.eventhubs_map

  name                = each.value.name
  namespace_name      = azurerm_eventhub_namespace.this.name
  resource_group_name = var.resource_group_name
  partition_count     = each.value.partition_count
  message_retention   = each.value.message_retention

  dynamic "capture_description" {
    for_each = each.value.capture_enabled ? [1] : []

    content {
      enabled             = true
      encoding            = "Avro"
      interval_in_seconds = 300
      size_limit_in_bytes = 314572800
      skip_empty_archives = true

      destination {
        name                = "EventHubArchive.AzureBlockBlob"
        archive_name_format = "{Namespace}/{EventHub}/{PartitionId}/{Year}/{Month}/{Day}/{Hour}/{Minute}/{Second}"
        blob_container_name = each.value.capture_container_name
        storage_account_id  = each.value.capture_storage_account_id
      }
    }
  }
}

resource "azurerm_eventhub_consumer_group" "this" {
  for_each = local.consumer_groups_map

  name                = each.value.name
  namespace_name      = azurerm_eventhub_namespace.this.name
  eventhub_name       = azurerm_eventhub.this[each.value.eventhub_name].name
  resource_group_name = var.resource_group_name
}

resource "azurerm_eventhub_authorization_rule" "this" {
  for_each = local.auth_rules_map

  name                = each.value.name
  namespace_name      = azurerm_eventhub_namespace.this.name
  eventhub_name       = azurerm_eventhub.this[keys(local.eventhubs_map)[0]].name
  resource_group_name = var.resource_group_name
  listen              = each.value.listen
  send                = each.value.send
  manage              = each.value.manage
}

resource "azurerm_eventhub_namespace_authorization_rule" "this" {
  for_each = local.auth_rules_map

  name                = "${each.value.name}-namespace"
  namespace_name      = azurerm_eventhub_namespace.this.name
  resource_group_name = var.resource_group_name
  listen              = each.value.listen
  send                = each.value.send
  manage              = each.value.manage
}
