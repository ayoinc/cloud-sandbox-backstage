# Shared Modules

The shared modules provide cross-provider functionality that works with Azure, AWS, and GCP.

## Available Modules

| Module                      | Description                                   |
| --------------------------- | --------------------------------------------- |
| [Naming](naming.md)         | Industry-standard resource naming conventions |
| [Tagging](tagging.md)       | Standardized tagging and labeling             |
| [Validation](validation.md) | Input validation framework                    |

## Architecture

```
shared/
├── naming/
│   ├── main.tf        # Naming logic for all providers
│   ├── variables.tf   # Input variables
│   ├── outputs.tf     # Output values
│   └── versions.tf    # Version constraints
├── tagging/
│   ├── main.tf        # Tagging logic
│   └── versions.tf
├── validation/
│   ├── main.tf        # Validation framework
│   └── versions.tf
└── tests/
    └── unit.tftest.hcl  # Native terraform tests
```

## Usage Pattern

All provider-specific modules should use these shared modules:

```hcl
# In your Azure/AWS/GCP module
module "naming" {
  source = "../../../shared/naming"

  provider      = "azure"  # or "aws", "gcp"
  project       = var.project
  environment   = var.environment
  resource_type = "storage_account"
  region        = var.location
}

module "tags" {
  source = "../../../shared/tagging"

  project     = var.project
  environment = var.environment
  owner       = var.owner
}

# Use in resources
resource "azurerm_storage_account" "main" {
  name = module.naming.name_no_hyphens
  tags = module.tags.azure_tags
  # ...
}
```
