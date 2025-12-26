# ${{ values.name }}

${{ values.description }}

## Overview

This S3 bucket is managed by Terraform and provides secure object storage for the **${{ values.environment }}** environment.

## Configuration

| Setting         | Value                          |
| --------------- | ------------------------------ |
| Region          | ${{ values.region }}           |
| Environment     | ${{ values.environment }}      |
| Versioning      | ${{ values.versioning }}       |
| Encryption      | ${{ values.encryption }}       |
| Lifecycle Rules | ${{ values.lifecycleEnabled }} |

## Usage

### AWS CLI

```bash
# List objects
aws s3 ls s3://myorg-${{ values.name }}-${{ values.environment }}/

# Upload a file
aws s3 cp myfile.txt s3://myorg-${{ values.name }}-${{ values.environment }}/

# Download a file
aws s3 cp s3://myorg-${{ values.name }}-${{ values.environment }}/myfile.txt ./

# Sync a directory
aws s3 sync ./local-dir s3://myorg-${{ values.name }}-${{ values.environment }}/remote-dir/
```

### Terraform Reference

To reference this bucket in other Terraform configurations:

```hcl
data "aws_s3_bucket" "this" {
  bucket = "myorg-${{ values.name }}-${{ values.environment }}"
}
```

## Security

- Public access is blocked by default
- Server-side encryption is enabled (${{ values.encryption }})
- Versioning is ${{ values.versioning | ternary("enabled for object recovery", "disabled") }}

## Owner

This resource is owned by **${{ values.owner }}**.
