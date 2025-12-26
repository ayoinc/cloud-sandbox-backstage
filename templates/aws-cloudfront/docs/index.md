# AWS CloudFront Distribution

This template provisions an Amazon CloudFront distribution with Origin Access Control (OAC), configurable caching behaviors, and optional custom domain support. The infrastructure is defined using Terraform with a modular architecture designed for production workloads.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                        CloudFront Distribution                   │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │  Edge Locations (Global)                                  │  │
│  │  • Automatic geographic routing                           │  │
│  │  • SSL/TLS termination                                    │  │
│  │  • Compression (Gzip/Brotli)                              │  │
│  └───────────────────────────────────────────────────────────┘  │
│                              │                                   │
│                              ▼                                   │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │  Origin Access Control (OAC)                              │  │
│  │  • SigV4 request signing                                  │  │
│  │  • Secure origin authentication                           │  │
│  └───────────────────────────────────────────────────────────┘  │
│                              │                                   │
└──────────────────────────────┼───────────────────────────────────┘
                               ▼
                    ┌─────────────────────┐
                    │    S3 Origin        │
                    │  (Private Bucket)   │
                    └─────────────────────┘
```

## Features

### Core Capabilities

| Feature                   | Description                                                                                    |
| ------------------------- | ---------------------------------------------------------------------------------------------- |
| **Origin Access Control** | Modern OAC implementation with SigV4 signing for secure S3 origin access                       |
| **Cache Behaviors**       | Configurable TTL settings (min/default/max), query string forwarding, header forwarding        |
| **Compression**           | Automatic Gzip and Brotli compression for supported content types                              |
| **Price Classes**         | Cost optimization via edge location selection (PriceClass_100, PriceClass_200, PriceClass_All) |
| **IPv6 Support**          | Dual-stack support enabled by default                                                          |

### Security Features

| Feature               | Description                                                           |
| --------------------- | --------------------------------------------------------------------- |
| **HTTPS Enforcement** | Viewer protocol policies: redirect-to-https, https-only, or allow-all |
| **TLS 1.2+**          | Minimum protocol version TLSv1.2_2021 for custom domains              |
| **WAF Integration**   | Optional AWS WAF web ACL attachment via `web_acl_id`                  |
| **Geo Restrictions**  | Whitelist or blacklist countries for content access                   |

### Advanced Features

| Feature                | Description                                       |
| ---------------------- | ------------------------------------------------- |
| **Custom Domains**     | CNAME aliases with ACM certificate support        |
| **Edge Functions**     | CloudFront Functions and Lambda@Edge associations |
| **Custom Error Pages** | Configurable error response codes and cache TTLs  |
| **Access Logging**     | Optional S3 bucket logging with cookie inclusion  |

## Prerequisites

- **AWS Account** with appropriate IAM permissions
- **Terraform** >= 1.0
- **S3 Bucket** configured as origin (with bucket policy allowing CloudFront OAC)
- **ACM Certificate** in us-east-1 (if using custom domain)

## Quick Start

### 1. Initialize and Plan

```bash
# Initialize Terraform with backend configuration
terraform init

# Review changes for development environment
terraform plan -var-file=environments/dev.tfvars
```

### 2. Apply Infrastructure

```bash
# Deploy to development
terraform apply -var-file=environments/dev.tfvars

# Deploy to production
terraform apply -var-file=environments/prod.tfvars
```

### 3. Configure S3 Bucket Policy

After deployment, update your S3 bucket policy to allow CloudFront OAC access:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowCloudFrontServicePrincipal",
      "Effect": "Allow",
      "Principal": {
        "Service": "cloudfront.amazonaws.com"
      },
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::your-bucket-name/*",
      "Condition": {
        "StringEquals": {
          "AWS:SourceArn": "arn:aws:cloudfront::ACCOUNT_ID:distribution/DISTRIBUTION_ID"
        }
      }
    }
  ]
}
```

## Configuration Reference

### Required Variables

| Variable             | Type   | Description                                                                |
| -------------------- | ------ | -------------------------------------------------------------------------- |
| `name`               | string | Name identifier for the distribution                                       |
| `origin_domain_name` | string | S3 bucket regional domain name (e.g., `bucket.s3.us-east-1.amazonaws.com`) |

### Cache Behavior Variables

| Variable                 | Type   | Default           | Description                             |
| ------------------------ | ------ | ----------------- | --------------------------------------- |
| `default_ttl`            | number | 86400             | Default cache TTL in seconds (24 hours) |
| `min_ttl`                | number | 0                 | Minimum cache TTL                       |
| `max_ttl`                | number | 31536000          | Maximum cache TTL (1 year)              |
| `viewer_protocol_policy` | string | redirect-to-https | Protocol enforcement policy             |
| `enable_compression`     | bool   | true              | Enable automatic compression            |
| `forward_query_string`   | bool   | false             | Forward query strings to origin         |

### Custom Domain Variables

| Variable                   | Type   | Default      | Description                                |
| -------------------------- | ------ | ------------ | ------------------------------------------ |
| `custom_domain`            | string | ""           | Custom domain name (CNAME)                 |
| `acm_certificate_arn`      | string | ""           | ACM certificate ARN (must be in us-east-1) |
| `minimum_protocol_version` | string | TLSv1.2_2021 | Minimum TLS version                        |

## Outputs

| Output             | Description                               |
| ------------------ | ----------------------------------------- |
| `distribution_id`  | CloudFront distribution ID                |
| `distribution_arn` | Distribution ARN for IAM policies         |
| `domain_name`      | CloudFront domain (\*.cloudfront.net)     |
| `hosted_zone_id`   | Route 53 hosted zone ID for alias records |

## CI/CD Integration

This template includes a GitHub Actions workflow (`.github/workflows/terraform.yaml`) that:

1. **On Pull Request**: Runs `terraform fmt`, `terraform validate`, and `terraform plan`
2. **On Merge to Main**: Applies infrastructure changes automatically
3. **Environment Promotion**: Uses environment-specific tfvars files

## Testing

The template includes Terraform test files in the `tests/` directory:

```bash
# Run Terraform tests
terraform test
```

## Cost Considerations

| Price Class    | Edge Locations              | Use Case                         |
| -------------- | --------------------------- | -------------------------------- |
| PriceClass_100 | US, Canada, Europe          | Cost-optimized, regional traffic |
| PriceClass_200 | + Asia, Middle East, Africa | Broader coverage                 |
| PriceClass_All | All edge locations          | Global audience                  |

## Troubleshooting

### Distribution Not Serving Content

1. Verify S3 bucket policy includes CloudFront OAC principal
2. Check origin domain name format (use regional endpoint, not legacy)
3. Confirm default root object is set correctly

### SSL Certificate Errors

1. ACM certificate must be in us-east-1 region
2. Certificate must be issued and validated
3. Custom domain must match certificate SAN

### Cache Invalidation

```bash
# Invalidate all cached content
aws cloudfront create-invalidation \
    --distribution-id DISTRIBUTION_ID \
    --paths "/*"
```

## Related Resources

- [AWS CloudFront Documentation](https://docs.aws.amazon.com/cloudfront/)
- [Origin Access Control Guide](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/private-content-restricting-access-to-s3.html)
- [Price Class Reference](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/PriceClass.html)
