terraform {
  backend "azurerm" {
    resource_group_name  = "terraform-state-rg"
    storage_account_name = "tfstate${{ values.name | replace('-', '') }}"
    container_name       = "tfstate"
    key                  = "${{ values.name }}.tfstate"
  }
}
