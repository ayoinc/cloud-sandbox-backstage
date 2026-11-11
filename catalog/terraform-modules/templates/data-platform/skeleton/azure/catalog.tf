# -----------------------------------------------------------------------------
# Data catalog: Microsoft Purview. Its managed identity reads the data lake
# (lake.tf) so that the lake can be registered and scanned in the Purview portal.
# -----------------------------------------------------------------------------

resource "azurerm_purview_account" "this" {
  count = local.create_purview ? 1 : 0

  name                = "pview-${local.name_prefix}-${local.unique_suffix}"
  resource_group_name = module.resource_group.name
  location            = var.location

  identity {
    type = "SystemAssigned"
  }

  tags = local.common_tags
}
