# =============================================================================
# Azure Container Apps Module
# =============================================================================
# Creates a container app and everything it needs to run:
# - Resource group
# - Log Analytics workspace
# - Container Apps environment (workload profiles, Consumption)
# - User-assigned managed identity, with optional registry and Key Vault access
# - Container app with HTTPS ingress, health probes and HTTP autoscaling
# =============================================================================

locals {
  resource_group_name = "rg-${var.name}-${var.environment}"

  # Container app names allow at most 32 characters.
  container_app_name = "ca-${var.name}-${var.environment}"

  common_tags = merge(
    var.tags,
    {
      Project     = var.name
      Environment = var.environment
      ManagedBy   = "terraform"
    },
    var.owner != "" ? { Owner = var.owner } : {},
    var.description != "" ? { Description = substr(var.description, 0, 256) } : {},
  )
  # Secret names allow only lowercase letters, digits and hyphens.
  secrets = { for variable, secret_id in var.secret_environment_variables : variable => {
    name      = replace(lower(variable), "_", "-")
    secret_id = secret_id
  } }
}

# =============================================================================
# Resource Group
# =============================================================================
resource "azurerm_resource_group" "main" {
  name     = local.resource_group_name
  location = var.location
  tags     = local.common_tags
}

# =============================================================================
# Log Analytics Workspace
# =============================================================================
resource "azurerm_log_analytics_workspace" "main" {
  name                = "law-${var.name}-${var.environment}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "PerGB2018"
  retention_in_days   = var.log_retention_days
  tags                = local.common_tags
}

# =============================================================================
# Container Apps Environment
# =============================================================================
resource "azurerm_container_app_environment" "main" {
  name                = "cae-${var.name}-${var.environment}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  logs_destination           = "log-analytics"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  infrastructure_subnet_id       = var.infrastructure_subnet_id
  internal_load_balancer_enabled = var.infrastructure_subnet_id == null ? null : var.internal_load_balancer_enabled
  zone_redundancy_enabled        = var.infrastructure_subnet_id == null ? null : var.zone_redundancy_enabled

  workload_profile {
    name                  = "Consumption"
    workload_profile_type = "Consumption"
  }

  tags = local.common_tags
}

# =============================================================================
# Managed Identity
# =============================================================================
# The app pulls its image, reads its secrets and calls other Azure services
# as this identity. No credential is stored in the app.
resource "azurerm_user_assigned_identity" "app" {
  name                = "id-${var.name}-${var.environment}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  tags                = local.common_tags
}

resource "azurerm_role_assignment" "acr_pull" {
  count = var.container_registry == null ? 0 : 1

  scope                = var.container_registry.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.app.principal_id
  principal_type       = "ServicePrincipal"
}

resource "azurerm_role_assignment" "key_vault_secrets_user" {
  count = var.key_vault_id == null ? 0 : 1

  scope                = var.key_vault_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.app.principal_id
  principal_type       = "ServicePrincipal"
}

# =============================================================================
# Container App
# =============================================================================
resource "azurerm_container_app" "main" {
  name                         = local.container_app_name
  resource_group_name          = azurerm_resource_group.main.name
  container_app_environment_id = azurerm_container_app_environment.main.id
  workload_profile_name        = "Consumption"

  # One active revision: a new one replaces the old one once it is healthy.
  revision_mode = "Single"

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.app.id]
  }

  dynamic "registry" {
    for_each = var.container_registry == null ? [] : [var.container_registry]

    content {
      server   = registry.value.login_server
      identity = azurerm_user_assigned_identity.app.id
    }
  }

  dynamic "secret" {
    for_each = local.secrets

    content {
      name                = secret.value.name
      key_vault_secret_id = secret.value.secret_id
      identity            = azurerm_user_assigned_identity.app.id
    }
  }

  template {
    min_replicas = var.min_replicas
    max_replicas = var.max_replicas

    container {
      name   = var.name
      image  = var.container_image
      cpu    = var.container_cpu
      memory = var.container_memory

      # Lets the Azure SDKs pick the user-assigned identity.
      env {
        name  = "AZURE_CLIENT_ID"
        value = azurerm_user_assigned_identity.app.client_id
      }

      dynamic "env" {
        for_each = var.environment_variables

        content {
          name  = env.key
          value = env.value
        }
      }

      dynamic "env" {
        for_each = local.secrets

        content {
          name        = env.key
          secret_name = env.value.name
        }
      }

      liveness_probe {
        transport = "HTTP"
        port      = var.target_port
        path      = var.health_probe_path
      }

      readiness_probe {
        transport = "HTTP"
        port      = var.target_port
        path      = var.health_probe_path
      }
    }

    http_scale_rule {
      name                = "http"
      concurrent_requests = tostring(var.concurrent_requests_per_replica)
    }
  }

  ingress {
    external_enabled           = var.external_ingress_enabled
    target_port                = var.target_port
    transport                  = "auto"
    allow_insecure_connections = false

    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }

  tags = local.common_tags

  # The identity must hold its roles before the first revision starts.
  depends_on = [
    azurerm_role_assignment.acr_pull,
    azurerm_role_assignment.key_vault_secrets_user,
  ]

  lifecycle {
    precondition {
      condition     = length(local.container_app_name) <= 32
      error_message = "The container app name ${local.container_app_name} must have at most 32 characters: shorten the name."
    }
  }
}
