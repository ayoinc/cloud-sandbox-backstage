# Terraform Module Template

This template creates a reusable Terraform module following HashiCorp best practices.

## Features

- **Multi-cloud support** - AWS, Azure, and GCP examples
- **Testing framework** - Terratest integration
- **Documentation** - Auto-generated docs with terraform-docs
- **CI/CD** - GitHub Actions for validation and testing
- **Compliance** - Pre-configured security scanning

## Getting Started

1. Create a new repository using this template
2. Define your module resources in `main.tf`
3. Configure variables in `variables.tf`
4. Add outputs in `outputs.tf`
5. Write tests in the `test/` directory

## Project Structure

```
├── main.tf           # Main module resources
├── variables.tf      # Input variables
├── outputs.tf        # Output values
├── versions.tf       # Provider version constraints
├── examples/         # Usage examples
│   └── basic/
├── test/             # Terratest tests
└── docs/             # Additional documentation
```

## Usage

```hcl
module "example" {
  source  = "github.com/org/module-name"
  version = "1.0.0"

  # Module inputs
  name = "my-resource"
  tags = {
    Environment = "production"
  }
}
```

## Testing

```bash
# Run tests
cd test/
go test -v -timeout 30m
```

## Support

Contact the Platform Team for assistance.
