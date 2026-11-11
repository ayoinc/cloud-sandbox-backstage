# account_id = null links the account the newrelic provider is configured for.
resource "newrelic_cloud_azure_link_account" "this" {
  account_id      = var.newrelic_account_id
  name            = var.name_prefix
  application_id  = azuread_application.newrelic.client_id
  client_secret   = azuread_application_password.newrelic.value
  subscription_id = data.azurerm_subscription.current.subscription_id
  tenant_id       = data.azurerm_subscription.current.tenant_id

  depends_on = [time_sleep.identity_propagation]
}

# The services this stack can create.
resource "newrelic_cloud_azure_integrations" "this" {
  account_id        = var.newrelic_account_id
  linked_account_id = newrelic_cloud_azure_link_account.this.id

  # Network
  virtual_networks {}

  # Load balancing and CDN
  load_balancer {}
  app_gateway {}
  front_door {}

  # Kubernetes: AKS clusters and the scale sets of their node pools
  containers {}
  vms {}

  # Managed databases
  postgresql {}
  postgresql_flexible {}
  mysql {}
  mysql_flexible {}
  cosmos_db {}
  redis_cache {}

  # Object storage and secrets
  storage {}
  key_vault {}
}
