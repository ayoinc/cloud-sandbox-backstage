# -----------------------------------------------------------------------------
# Container registry
# -----------------------------------------------------------------------------

variable "registry_sku" {
  description = "SKU of the container registry: Basic, Standard or Premium."
  type        = string
  default     = "Basic"

  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.registry_sku)
    error_message = "registry_sku must be Basic, Standard or Premium."
  }
}

resource "azurerm_container_registry" "this" {
  name                = module.naming.global_compact["cr"]
  resource_group_name = local.resource_group_name
  location            = var.region
  sku                 = var.registry_sku

  # Images are pulled and pushed with Entra ID identities only.
  admin_enabled = false

  tags = module.tagging.tags
}

output "container_registry_url" {
  description = "Login server of the container registry."
  value       = azurerm_container_registry.this.login_server
}
