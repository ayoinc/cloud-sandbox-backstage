locals {
  prefix = "${var.name}-${var.environment}"

  tags = {
    stack       = var.name
    environment = var.environment
    owner       = var.owner
    managed-by  = "opentofu"
  }
}
{%- if values.cloud == 'aws' %}

data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

data "aws_availability_zones" "available" {
  state = "available"
}
{%- elif values.cloud == 'azure' %}

data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "main" {
  name     = "rg-${local.prefix}"
  location = var.region
  tags     = local.tags
}

# The `enabled` meta-argument creates the lock only where it is asked for,
# without turning the resource into a list the way `count` does.
resource "azurerm_management_lock" "main" {
  name       = "do-not-delete"
  scope      = azurerm_resource_group.main.id
  lock_level = "CanNotDelete"
  notes      = "Managed by the ${var.name} stack. Set lock_resource_group to false and apply before deleting."

  lifecycle {
    enabled = var.lock_resource_group
  }
}
{%- else %}

data "google_storage_project_service_account" "current" {}
{%- endif %}
