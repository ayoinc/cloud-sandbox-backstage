# ${{ values.name }}

${{ values.description }}

## Overview

This CloudFront distribution is managed by Terraform and provides a global CDN for content delivery in the **${{ values.environment }}** environment.

## Architecture

```d2
direction: right

users: Users {
  icon: https://icons.terrastruct.com/essentials%2F359-users.svg
}

cloudfront: CloudFront {
  icon: https://icons.terrastruct.com/aws%2FNetworking%20&%20Content%20Delivery%2FAmazon-CloudFront.svg

  edge_locations: Edge Locations {
    style.multiple: true
  }

  oac: Origin Access Control
}

s3: S3 Origin {
  icon: https://icons.terrastruct.com/aws%2FStorage%2FAmazon-Simple-Storage-Service-S3.svg
  bucket: Origin Bucket
}

route53: Route 53 {
  icon: https://icons.terrastruct.com/aws%2FNetworking%20&%20Content%20Delivery%2FAmazon-Route-53.svg
}

acm: ACM Certificate {
  icon: https://icons.terrastruct.com/aws%2FSecurity%2C%20Identity%2C%20&%20Compliance%2FAWS-Certificate-Manager.svg
}

users -> route53: DNS lookup
route53 -> cloudfront: Resolve to CloudFront
users -> cloudfront: HTTPS request
cloudfront.edge_locations -> cloudfront.oac: Authorize
cloudfront.oac -> s3.bucket: Fetch origin content
acm -> cloudfront: SSL/TLS
```

## Configuration

| Setting         | Value                                |
| --------------- | ------------------------------------ |
| Region          | ${{ values.region }} (origin)        |
| Environment     | ${{ values.environment }}            |
| Origin Domain   | ${{ values.origin_domain_name }}     |
| Price Class     | ${{ values.price_class }}            |
| Default TTL     | ${{ values.default_ttl }} seconds    |
| Viewer Protocol | ${{ values.viewer_protocol_policy }} |
| Compression     | ${{ values.enable_compression }}     |

## Price Classes

| Price Class    | Edge Locations               |
| -------------- | ---------------------------- |
| PriceClass_100 | US, Canada, Europe           |
| PriceClass_200 | + Asia, Middle East, Africa  |
| PriceClass_All | All edge locations worldwide |

## Usage

### AWS CLI

```bash
# Get distribution info
aws cloudfront get-distribution --id <DISTRIBUTION_ID>

# List all distributions
aws cloudfront list-distributions

# Create cache invalidation
aws cloudfront create-invalidation \
  --distribution-id <DISTRIBUTION_ID> \
  --paths "/*"

# Check invalidation status
aws cloudfront get-invalidation \
  --distribution-id <DISTRIBUTION_ID> \
  --id <INVALIDATION_ID>
```

### Terraform Reference

To reference this distribution in other Terraform configurations:

```hcl
data "aws_cloudfront_distribution" "this" {
  id = "<DISTRIBUTION_ID>"
}

# Use in Route 53 alias record
resource "aws_route53_record" "cdn" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "cdn"
  type    = "A"

  alias {
    name                   = data.aws_cloudfront_distribution.this.domain_name
    zone_id                = data.aws_cloudfront_distribution.this.hosted_zone_id
    evaluate_target_health = false
  }
}
```

## Security

- Origin Access Control (OAC) secures the S3 origin
- HTTPS enforced via viewer protocol policy: ${{ values.viewer_protocol_policy }}
- TLS 1.2+ required for all connections
- Custom domain uses ACM certificate (if configured)

## Caching Strategy

| Content Type       | Recommended TTL           |
| ------------------ | ------------------------- |
| HTML files         | 0-300 seconds             |
| CSS/JS (versioned) | 31536000 seconds (1 year) |
| Images             | 86400-604800 seconds      |
| API responses      | 0-60 seconds              |

## Custom Error Pages

The distribution is configured to handle errors gracefully:

| Error Code      | Response                     |
| --------------- | ---------------------------- |
| 403 (Forbidden) | Returns /index.html with 200 |
| 404 (Not Found) | Returns /index.html with 200 |

This enables SPA (Single Page Application) routing.

## Monitoring

### CloudWatch Metrics

- `Requests` - Total number of viewer requests
- `BytesDownloaded` - Total bytes downloaded by viewers
- `4xxErrorRate` - Percentage of 4xx errors
- `5xxErrorRate` - Percentage of 5xx errors
- `TotalErrorRate` - Total error rate

### Real-time Logs (Optional)

Configure real-time logs to Kinesis Data Streams for detailed analysis.

## Owner

This resource is owned by **${{ values.owner }}**.
