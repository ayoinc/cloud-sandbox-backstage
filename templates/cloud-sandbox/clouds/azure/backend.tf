# Remote state in Azure Blob Storage. The storage account, container and key
# are passed to `terraform init` with -backend-config; see README.md.
terraform {
  backend "azurerm" {}
}
