# =============================================================================
# Resource Group Module
# =============================================================================
# A resource group, optionally protected by a delete lock.
# =============================================================================

resource "azurerm_resource_group" "main" {
  name     = var.name
  location = var.location
  tags     = var.tags
}

resource "azurerm_management_lock" "delete" {
  count = var.enable_delete_lock ? 1 : 0

  name       = "${var.name}-delete-lock"
  scope      = azurerm_resource_group.main.id
  lock_level = "CanNotDelete"
  notes      = "Remove this lock before destroying the resource group."
}
