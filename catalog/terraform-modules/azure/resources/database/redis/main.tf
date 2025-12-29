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
    project     = var.project_name
    environment = var.environment
    managed_by  = "terraform"
  }
  tags = merge(local.default_tags, var.tags)
}

resource "azurerm_redis_cache" "this" {
  name                          = var.redis_name
  location                      = var.location
  resource_group_name           = var.resource_group_name
  capacity                      = var.capacity
  family                        = var.family
  sku_name                      = var.sku_name
  enable_non_ssl_port           = var.enable_non_ssl_port
  minimum_tls_version           = var.minimum_tls_version
  public_network_access_enabled = var.subnet_id != null ? false : true
  shard_count                   = var.sku_name == "Premium" ? var.shard_count : null
  replicas_per_master           = var.sku_name == "Premium" ? var.replicas_per_master : null
  zones                         = var.zones
  private_static_ip_address     = var.private_static_ip_address
  subnet_id                     = var.subnet_id

  dynamic "redis_configuration" {
    for_each = var.redis_configuration != null ? [var.redis_configuration] : []
    content {
      maxmemory_policy                = redis_configuration.value.maxmemory_policy
      aof_backup_enabled              = var.sku_name == "Premium" ? redis_configuration.value.aof_backup_enabled : null
      aof_storage_connection_string_0 = var.sku_name == "Premium" ? redis_configuration.value.aof_storage_connection_string_0 : null
      aof_storage_connection_string_1 = var.sku_name == "Premium" ? redis_configuration.value.aof_storage_connection_string_1 : null
      rdb_backup_enabled              = var.sku_name == "Premium" ? redis_configuration.value.rdb_backup_enabled : null
      rdb_backup_frequency            = var.sku_name == "Premium" && redis_configuration.value.rdb_backup_enabled ? redis_configuration.value.rdb_backup_frequency : null
      rdb_backup_max_snapshot_count   = var.sku_name == "Premium" && redis_configuration.value.rdb_backup_enabled ? redis_configuration.value.rdb_backup_max_snapshot_count : null
      rdb_storage_connection_string   = var.sku_name == "Premium" && redis_configuration.value.rdb_backup_enabled ? redis_configuration.value.rdb_storage_connection_string : null
      maxmemory_reserved              = redis_configuration.value.maxmemory_reserved
      maxmemory_delta                 = redis_configuration.value.maxmemory_delta
      maxfragmentationmemory_reserved = redis_configuration.value.maxfragmentationmemory_reserved
      notify_keyspace_events          = redis_configuration.value.notify_keyspace_events
    }
  }

  tags = local.tags
}

resource "azurerm_redis_firewall_rule" "this" {
  for_each = { for rule in var.firewall_rules : rule.name => rule }

  name                = each.value.name
  redis_cache_name    = azurerm_redis_cache.this.name
  resource_group_name = var.resource_group_name
  start_ip            = each.value.start_ip
  end_ip              = each.value.end_ip
}

resource "azurerm_private_endpoint" "this" {
  count = var.private_endpoint_subnet_id != null ? 1 : 0

  name                = "${var.redis_name}-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "${var.redis_name}-psc"
    private_connection_resource_id = azurerm_redis_cache.this.id
    is_manual_connection           = false
    subresource_names              = ["redisCache"]
  }

  dynamic "private_dns_zone_group" {
    for_each = var.private_dns_zone_id != null ? [1] : []
    content {
      name                 = "default"
      private_dns_zone_ids = [var.private_dns_zone_id]
    }
  }

  tags = local.tags
}
