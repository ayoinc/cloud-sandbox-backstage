# AWS S3 Bucket Template

This template creates an Amazon S3 bucket with security best practices and optional features.

## Features

- **Versioning** - Object version control
- **Encryption** - Server-side encryption (SSE-S3 or SSE-KMS)
- **Lifecycle rules** - Automatic transitions and expiration
- **Access logging** - Request logging to another bucket
- **Bucket policies** - Fine-grained access control
- **CORS** - Cross-origin resource sharing

## Prerequisites

- AWS Account
- Terraform >= 1.5
- Appropriate IAM permissions

## Quick Start

```bash
terraform init
terraform plan
terraform apply
```

## Configuration

| Variable | Description | Default |
|----------|-------------|---------|
| `bucket_name` | Bucket name | - |
| `versioning` | Enable versioning | `true` |
| `encryption` | Encryption type | `AES256` |
| `public_access_block` | Block public access | `true` |

## Use Cases

- **Static website hosting**
- **Data lake storage**
- **Backup and archive**
- **Application assets**

## Outputs

- `bucket_id` - Bucket name
- `bucket_arn` - Bucket ARN
- `bucket_domain_name` - Bucket domain name

## Support

Contact the Platform Team for assistance.
