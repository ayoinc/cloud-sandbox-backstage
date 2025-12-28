# Azure Security

## Key Vault Module

Creates Azure Key Vault with RBAC authorization, secrets, and private endpoints.

### Usage

```hcl
module "keyvault" {
  source = "path/to/azure/resources/security/key-vault"

  resource_group_name = "rg-myapp-prod"
  location            = "eastus"
  project             = "myapp"
  environment         = "prod"
  tenant_id           = data.azurerm_client_config.current.tenant_id
  
  sku_name                  = "standard"
  enable_rbac_authorization = true
  
  # Security Settings
  enabled_for_deployment          = false
  enabled_for_disk_encryption     = true
  enabled_for_template_deployment = false
  soft_delete_retention_days      = 90
  purge_protection_enabled        = true
  
  # Network Access
  public_network_access_enabled = false
  network_acls = {
    bypass         = "AzureServices"
    default_action = "Deny"
    ip_rules       = ["203.0.113.0/24"]
  }
  
  # Private Endpoint
  enable_private_endpoint    = true
  private_endpoint_subnet_id = module.vnet.subnet_ids["private-endpoints"]
  
  # Initial Secrets
  secrets = {
    db-connection-string = {
      value        = "Server=..."
      content_type = "text/plain"
    }
    api-key = {
      value        = "secret-api-key"
      content_type = "application/json"
    }
  }
  
  tags = module.tags.azure_tags
}
```

### Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `tenant_id` | string | required | Azure AD tenant ID |
| `sku_name` | string | "standard" | standard or premium |
| `enable_rbac_authorization` | bool | true | Use RBAC |
| `soft_delete_retention_days` | number | 90 | Soft delete retention |
| `purge_protection_enabled` | bool | true | Prevent purge |
| `secrets` | map(object) | {} | Initial secrets |
| `access_policies` | list(object) | [] | Access policies (if not RBAC) |

### Outputs

| Output | Description |
|--------|-------------|
| `key_vault_id` | Key Vault ID |
| `key_vault_name` | Key Vault name |
| `key_vault_uri` | Key Vault URI |
| `secret_ids` | Map of secret IDs |

### RBAC Roles

With RBAC enabled, assign these roles:

| Role | Description |
|------|-------------|
| Key Vault Administrator | Full access |
| Key Vault Secrets User | Read secrets |
| Key Vault Secrets Officer | Manage secrets |
| Key Vault Certificates Officer | Manage certificates |
| Key Vault Crypto Officer | Manage keys |

```hcl
resource "azurerm_role_assignment" "secrets_user" {
  scope                = module.keyvault.key_vault_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.app.principal_id
}
```

### Access Policy Mode

If not using RBAC:

```hcl
module "keyvault" {
  # ...
  enable_rbac_authorization = false
  
  access_policies = [
    {
      object_id          = data.azurerm_client_config.current.object_id
      secret_permissions = ["Get", "List", "Set", "Delete"]
      key_permissions    = ["Get", "List"]
    }
  ]
}
```
