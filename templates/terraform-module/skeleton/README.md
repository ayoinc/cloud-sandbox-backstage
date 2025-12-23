# ${{ values.name }}

${{ values.description }}

## Overview

This Terraform module is designed for **${{ values.provider | upper }}** and manages **${{ values.resource_type }}** resources.

## Requirements

| Name | Version |
|------|---------|
| terraform | ${{ values.terraform_version }} |
| ${{ values.provider }} | >= 4.0 |

## Usage

```hcl
module "${{ values.name | replace('terraform-', '') }}" {
  source = "github.com/${{ values.destination.owner }}/${{ values.destination.repo }}"

  # Add your variables here
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| See `variables.tf` for complete list | | | | |

## Outputs

| Name | Description |
|------|-------------|
| See `outputs.tf` for complete list | |

## Examples

See the [examples](./examples) directory for usage examples.

{% if values.include_testing %}
## Testing

This module includes tests using Terratest. To run tests:

```bash
cd test
go test -v -timeout 30m
```
{% endif %}

{% if values.enable_compliance %}
## Compliance

This module includes security and compliance validations:
- tfsec scanning
- checkov policies
- AWS Config rules (if applicable)
{% endif %}

## Contributing

1. Fork this repository
2. Create a feature branch
3. Make your changes
4. Run `terraform fmt` and `terraform validate`
5. Submit a pull request

## License

Apache 2.0 Licensed. See [LICENSE](LICENSE) for full details.
