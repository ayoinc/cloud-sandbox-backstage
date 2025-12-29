# Terraform native tests for Azure Key Vault module

variables {
  project_name        = "testproject"
  environment         = "test"
  resource_group_name = "test-rg"
  location            = "eastus"
  tenant_id           = "00000000-0000-0000-0000-000000000000"

  enable_soft_delete         = true
  soft_delete_retention_days = 7
  enable_purge_protection    = false

  tags = {
    Test = "true"
  }
}

run "key_vault_creation" {
  command = plan

  assert {
    condition     = azurerm_key_vault.main.sku_name == "standard"
    error_message = "Key Vault should use standard SKU by default"
  }

  assert {
    condition     = azurerm_key_vault.main.soft_delete_retention_days == 7
    error_message = "Soft delete retention should be 7 days"
  }
}

run "security_settings" {
  command = plan

  assert {
    condition     = azurerm_key_vault.main.enabled_for_disk_encryption == true
    error_message = "Disk encryption should be enabled"
  }
}
