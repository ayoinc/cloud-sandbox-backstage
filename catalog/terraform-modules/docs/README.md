# Terraform Modules Documentation

This directory contains comprehensive Terraform modules for Azure, AWS, and GCP infrastructure.

## Directory Structure

```
.
├── README.md                    # This file
├── catalog-info.yaml           # Backstage catalog entry
├── shared/                     # Shared modules (naming, tagging, validation)
│   ├── naming/                # Multi-provider naming conventions
│   ├── tagging/               # Standardized tagging
│   └── validation/            # Input validation
├── azure/                     # Azure modules
│   ├── resources/             # Azure resource modules
│   └── templates/             # Azure templates
├── aws/                      # AWS modules
│   ├── resources/            # AWS resource modules
│   └── templates/            # AWS templates
└── gcp/                     # GCP modules
    ├── resources/           # GCP resource modules
    └── templates/           # GCP templates
```

## Shared Modules

### Naming Module

- Multi-provider support (Azure CAF, AWS, GCP)
- Layer-based naming (platform/application/data/network/security/monitoring)
- Industry-standard conventions

### Tagging Module

- Environment isolation
- Cost allocation
- Compliance tagging
- Auto-shutdown for dev/stg

### Validation Module

- Input validation framework
- Schema validation
- Custom validation rules

## Available Templates

### Full Infrastructure Templates

- **azure-full-infrastructure**: Complete Azure stack with all modules
- **aws-full-infrastructure**: Complete AWS stack with all modules
- **gcp-full-infrastructure**: Complete GCP stack with all modules

### Single Resource Templates

- Available for each individual resource
- Modulular and composable

## Usage

See individual template README files for usage instructions:

- `/backstage/catalog/terraform-modules/templates/README.md`

## Testing

All tests use native `terraform test` with `mock_provider`:

```bash
# Run all tests
cd shared/tests/
terraform init -backend=false
terraform test -verbose
```

## Documentation Links

- [Master Architecture](/docs/MASTER-ARCHITECTURE.md)
- [Agent Coordination](/docs/AGENT-COORDINATION.md)
- [Implementation Summary](/backstage/catalog/terraform-modules/IMPLEMENTATION-COMPLETE.md)

## Support

For questions or issues, please see:

- [Troubleshooting Guide](/docs/TROUBLESHOOTING.md)
- [Best Practices](/docs/BEST-PRACTICES.md)

## Contributing

Please see [CONTRIBUTING.md](/CONTRIBUTING.md) for contribution guidelines.
