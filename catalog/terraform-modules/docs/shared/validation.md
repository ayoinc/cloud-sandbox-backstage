# Validation Module

Generic input validation framework for Terraform modules.

## Features

- **Required variable** validation
- **Pattern matching** with regex
- **Range validation** for numbers
- **Enum validation** for allowed values
- **Length validation** for strings
- Common validation patterns included

## Usage

```hcl
module "validation" {
  source = "path/to/shared/validation"

  required_variables = {
    project     = var.project
    environment = var.environment
  }

  patterns = {
    project_name = {
      value   = var.project
      pattern = "^[a-z][a-z0-9-]*$"
      message = "must be lowercase with hyphens"
    }
  }

  ranges = {
    instance_count = {
      value = var.instance_count
      min   = 1
      max   = 100
    }
  }

  enums = {
    environment = {
      value   = var.environment
      allowed = ["dev", "staging", "prod"]
    }
  }

  lengths = {
    storage_account_name = {
      value = var.storage_name
      min   = 3
      max   = 24
    }
  }

  fail_on_error = true  # Fail terraform plan on errors
}
```

## Outputs

| Output | Description |
|--------|-------------|
| `valid` | Boolean - all validations passed |
| `errors` | List of error messages |
| `error_count` | Number of errors |
| `error_summary` | Human-readable summary |
| `resolved_optionals` | Optional variables with defaults applied |
| `validation_report` | Full validation report object |
| `common_patterns` | Reference patterns for validation |

## Common Patterns

The module exports common regex patterns for reference:

```hcl
output "common_patterns" {
  value = {
    # Naming patterns
    lowercase_alphanumeric     = "^[a-z][a-z0-9]*$"
    lowercase_with_hyphens     = "^[a-z][a-z0-9-]*[a-z0-9]$"
    
    # Azure specific
    azure_storage_account      = "^[a-z0-9]{3,24}$"
    azure_key_vault            = "^[a-zA-Z][a-zA-Z0-9-]{1,22}[a-zA-Z0-9]$"
    
    # AWS specific
    aws_s3_bucket              = "^[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]$"
    
    # GCP specific
    gcp_project_id             = "^[a-z][a-z0-9-]{4,28}[a-z0-9]$"
    
    # Network patterns
    ipv4_address               = "^(?:(?:25[0-5]|...)$"
    ipv4_cidr                  = "^(?:(?:25[0-5]|...)$"
    
    # Email and URL
    email                      = "^[a-zA-Z0-9._%+-]+@..."
    url                        = "^https?://..."
  }
}
```

## Optional Variables

Handle optional variables with defaults:

```hcl
module "validation" {
  source = "path/to/shared/validation"

  optional_variables = {
    region = {
      value   = var.region      # May be empty
      default = "eastus"        # Use if empty
    }
    tier = {
      value   = var.tier
      default = "standard"
    }
  }
}

# Access resolved values
locals {
  region = module.validation.resolved_optionals["region"]
  tier   = module.validation.resolved_optionals["tier"]
}
```

## Error Handling

```hcl
module "validation" {
  source = "path/to/shared/validation"

  required_variables = {
    project = ""  # Empty - will fail
  }

  fail_on_error = false  # Don't fail plan, just report
}

# Check results
output "is_valid" {
  value = module.validation.valid
}

output "errors" {
  value = module.validation.errors
}
# Output: ["Required variable 'project' is empty or not set"]
```
