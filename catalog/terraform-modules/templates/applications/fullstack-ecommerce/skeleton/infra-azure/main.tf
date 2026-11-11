locals {
  name = "${var.project_name}-${var.environment}"

  tags = {
    project       = var.project_name
    environment   = var.environment
    business-unit = var.business_unit
    managed-by    = "terraform"
  }

  max_replicas = var.enable_autoscaling ? var.max_replicas : var.min_replicas
}

resource "azurerm_resource_group" "main" {
  name     = "rg-${local.name}"
  location = var.region
  tags     = local.tags
}

# ---------------------------------------------------------------------------
# Database
# ---------------------------------------------------------------------------

resource "random_password" "database" {
  length  = 32
  special = false
}

resource "azurerm_postgresql_flexible_server" "main" {
  name                          = "psql-${local.name}"
  resource_group_name           = azurerm_resource_group.main.name
  location                      = azurerm_resource_group.main.location
  version                       = "16"
  sku_name                      = var.database_sku
  storage_mb                    = 32768
  administrator_login           = "store"
  administrator_password        = random_password.database.result
  backup_retention_days         = var.environment == "prod" ? 30 : 7
  public_network_access_enabled = true
  tags                          = local.tags

  lifecycle {
    # Azure picks the availability zone; do not move the server when it is reported back.
    ignore_changes = [zone]
  }
}

resource "azurerm_postgresql_flexible_server_database" "store" {
  name      = "store"
  server_id = azurerm_postgresql_flexible_server.main.id
  charset   = "UTF8"
  collation = "en_US.utf8"
}

# The container apps reach the database over its public endpoint. This rule
# admits traffic that originates inside Azure, and nothing else.
resource "azurerm_postgresql_flexible_server_firewall_rule" "azure_services" {
  name             = "allow-azure-services"
  server_id        = azurerm_postgresql_flexible_server.main.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

# ---------------------------------------------------------------------------
# Cache
# ---------------------------------------------------------------------------

resource "azurerm_redis_cache" "main" {
  count = var.enable_cache ? 1 : 0

  name                = "redis-${local.name}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku_name            = var.environment == "prod" ? "Standard" : "Basic"
  family              = "C"
  capacity            = var.environment == "prod" ? 1 : 0
  minimum_tls_version = "1.2"
  tags                = local.tags
}

# ---------------------------------------------------------------------------
# Containers
# ---------------------------------------------------------------------------

resource "azurerm_log_analytics_workspace" "main" {
  name                = "log-${local.name}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = local.tags
}

resource "azurerm_container_app_environment" "main" {
  name                       = "cae-${local.name}"
  resource_group_name        = azurerm_resource_group.main.name
  location                   = azurerm_resource_group.main.location
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
  tags                       = local.tags
}

resource "random_password" "admin_token" {
  length  = 40
  special = false
}

resource "azurerm_container_app" "backend" {
  name                         = "backend"
  resource_group_name          = azurerm_resource_group.main.name
  container_app_environment_id = azurerm_container_app_environment.main.id
  revision_mode                = "Single"
  tags                         = local.tags

  secret {
    name  = "database-url"
    value = "postgres://store:${random_password.database.result}@${azurerm_postgresql_flexible_server.main.fqdn}:5432/${azurerm_postgresql_flexible_server_database.store.name}?sslmode=verify-full"
  }

  secret {
    name  = "admin-token"
    value = random_password.admin_token.result
  }

  dynamic "secret" {
    for_each = azurerm_redis_cache.main
    content {
      name  = "redis-url"
      value = "rediss://:${secret.value.primary_access_key}@${secret.value.hostname}:${secret.value.ssl_port}"
    }
  }

  template {
    min_replicas = var.min_replicas
    max_replicas = local.max_replicas

    container {
      name   = "backend"
      image  = var.backend_image
      cpu    = 0.5
      memory = "1Gi"

      env {
        name        = "DATABASE_URL"
        secret_name = "database-url"
      }

      env {
        name        = "ADMIN_TOKEN"
        secret_name = "admin-token"
      }

      dynamic "env" {
        for_each = azurerm_redis_cache.main
        content {
          name        = "REDIS_URL"
          secret_name = "redis-url"
        }
      }

      liveness_probe {
        transport = "HTTP"
        port      = 8080
        path      = "/healthz"
      }

      readiness_probe {
        transport = "HTTP"
        port      = 8080
        path      = "/readyz"
      }
    }

    dynamic "http_scale_rule" {
      for_each = var.enable_autoscaling ? [1] : []
      content {
        name                = "http"
        concurrent_requests = "50"
      }
    }
  }

  # Only the storefront calls the API, from inside the environment.
  ingress {
    external_enabled = false
    target_port      = 8080

    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }
}

resource "azurerm_container_app" "frontend" {
  name                         = "frontend"
  resource_group_name          = azurerm_resource_group.main.name
  container_app_environment_id = azurerm_container_app_environment.main.id
  revision_mode                = "Single"
  tags                         = local.tags

  template {
    min_replicas = var.min_replicas
    max_replicas = local.max_replicas

    container {
      name   = "frontend"
      image  = var.frontend_image
      cpu    = 0.25
      memory = "0.5Gi"

      env {
        name  = "BACKEND_URL"
        value = "https://${azurerm_container_app.backend.ingress[0].fqdn}"
      }

      liveness_probe {
        transport = "HTTP"
        port      = 8080
        path      = "/"
      }
    }

    dynamic "http_scale_rule" {
      for_each = var.enable_autoscaling ? [1] : []
      content {
        name                = "http"
        concurrent_requests = "100"
      }
    }
  }

  ingress {
    external_enabled = true
    target_port      = 8080

    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }
}

# ---------------------------------------------------------------------------
# Content delivery network
# ---------------------------------------------------------------------------

resource "azurerm_cdn_frontdoor_profile" "main" {
  count = var.enable_cdn ? 1 : 0

  name                = "afd-${local.name}"
  resource_group_name = azurerm_resource_group.main.name
  sku_name            = "Standard_AzureFrontDoor"
  tags                = local.tags
}

resource "azurerm_cdn_frontdoor_endpoint" "main" {
  count = var.enable_cdn ? 1 : 0

  name                     = local.name
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.main[0].id
  tags                     = local.tags
}

resource "azurerm_cdn_frontdoor_origin_group" "frontend" {
  count = var.enable_cdn ? 1 : 0

  name                     = "frontend"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.main[0].id

  load_balancing {}

  health_probe {
    protocol            = "Https"
    path                = "/"
    request_type        = "HEAD"
    interval_in_seconds = 60
  }
}

resource "azurerm_cdn_frontdoor_origin" "frontend" {
  count = var.enable_cdn ? 1 : 0

  name                           = "frontend"
  cdn_frontdoor_origin_group_id  = azurerm_cdn_frontdoor_origin_group.frontend[0].id
  enabled                        = true
  host_name                      = azurerm_container_app.frontend.ingress[0].fqdn
  origin_host_header             = azurerm_container_app.frontend.ingress[0].fqdn
  certificate_name_check_enabled = true
}

resource "azurerm_cdn_frontdoor_route" "frontend" {
  count = var.enable_cdn ? 1 : 0

  name                          = "frontend"
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.main[0].id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.frontend[0].id
  cdn_frontdoor_origin_ids      = [azurerm_cdn_frontdoor_origin.frontend[0].id]
  supported_protocols           = ["Http", "Https"]
  patterns_to_match             = ["/*"]
  forwarding_protocol           = "HttpsOnly"
  https_redirect_enabled        = true

  # Responses are cached as the storefront's Cache-Control headers allow:
  # hashed assets for a year, pages and API answers not at all.
  cache {
    query_string_caching_behavior = "UseQueryString"
    compression_enabled           = true
    content_types_to_compress     = ["text/html", "text/css", "application/javascript", "application/json", "image/svg+xml"]
  }
}
