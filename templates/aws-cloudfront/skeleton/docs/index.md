# ${{ values.name }}

${{ values.description }}

## Overview

This CloudFront distribution provides a production-ready Content Delivery Network (CDN) for the **${{ values.environment }}** environment in **${{ values.region }}**. It delivers content globally through AWS edge locations with:

- Origin Access Control (OAC) for secure S3 origin access
- Automatic content compression for optimal performance
- Custom cache behaviors with configurable TTLs
- HTTPS enforcement with TLS 1.2+ for all connections
- Custom error responses for SPA routing support
- Optional WAF integration for enhanced security
- Access logging for analytics and troubleshooting

```d2
direction: right

title: {
  label: AWS CloudFront Distribution Architecture
  near: top-center
  shape: text
  style.font-size: 24
  style.bold: true
}

users: Global Users {
  icon: https://icons.terrastruct.com/essentials%2F359-users.svg
  shape: cloud
  style.fill: "#E8F5E9"
  style.stroke: "#388E3C"
}

edge: CloudFront Edge Network {
  style.fill: "#E3F2FD"
  style.stroke: "#1976D2"

  locations: Edge Locations {
    style.multiple: true
    style.fill: "#BBDEFB"
    style.stroke: "#1976D2"

    na: North America
    eu: Europe
    asia: Asia Pacific
  }

  cache: Cache Layer {
    style.fill: "#C8E6C9"
    style.stroke: "#388E3C"
  }
}

cloudfront: CloudFront Distribution {
  style.fill: "#FFF3E0"
  style.stroke: "#FF9800"
  icon: https://icons.terrastruct.com/aws%2FNetworking%20&%20Content%20Delivery%2FAmazon-CloudFront.svg

  oac: Origin Access Control {
    style.fill: "#FFCDD2"
    style.stroke: "#D32F2F"
  }

  behaviors: Cache Behaviors {
    style.fill: "#E1F5FE"
    style.stroke: "#0288D1"

    default: Default (/*) {
      style.fill: "#B3E5FC"
    }
  }

  waf: WAF (Optional) {
    style.fill: "#F3E5F5"
    style.stroke: "#7B1FA2"
    shape: hexagon
  }
}

origin: AWS Origin {
  style.fill: "#FCE4EC"
  style.stroke: "#C2185B"

  s3: S3 Bucket {
    icon: https://icons.terrastruct.com/aws%2FStorage%2FAmazon-Simple-Storage-Service-S3.svg
    style.fill: "#F8BBD9"
    style.stroke: "#C2185B"
  }
}

dns: Route 53 {
  icon: https://icons.terrastruct.com/aws%2FNetworking%20&%20Content%20Delivery%2FAmazon-Route-53.svg
  style.fill: "#E8EAF6"
  style.stroke: "#3F51B5"
}

acm: ACM Certificate {
  icon: https://icons.terrastruct.com/aws%2FSecurity%2C%20Identity%2C%20&%20Compliance%2FAWS-Certificate-Manager.svg
  style.fill: "#FFECB3"
  style.stroke: "#FFA000"
}

logs: Access Logs {
  icon: https://icons.terrastruct.com/aws%2FStorage%2FAmazon-Simple-Storage-Service-S3.svg
  shape: cylinder
  style.fill: "#E0E0E0"
  style.stroke: "#616161"
}

# User request flow
users -> dns: 1. DNS Lookup
dns -> edge.locations: 2. Resolve
users -> edge.locations: 3. HTTPS Request
edge.locations -> edge.cache: 4. Check Cache
edge.cache -> cloudfront.behaviors: 5. Cache Miss
cloudfront.waf -> cloudfront.behaviors: Inspect
cloudfront.behaviors -> cloudfront.oac: 6. Authorize
cloudfront.oac -> origin.s3: 7. Fetch Content

# Supporting services
acm -> cloudfront: SSL/TLS Certificate
cloudfront -> logs: Access Logs
```

---

## Configuration Summary

| Setting                  | Value                                          |
| ------------------------ | ---------------------------------------------- |
| Distribution Name        | `${{ values.name }}`                           |
| Environment              | `${{ values.environment }}`                    |
| Origin Region            | `${{ values.region }}`                         |
| Origin Domain            | `${{ values.origin_domain_name }}`             |
| Price Class              | `${{ values.price_class }}`                    |
| Default TTL              | `${{ values.default_ttl }}` seconds            |
| Max TTL                  | `${{ values.max_ttl }}` seconds                |
| Viewer Protocol Policy   | `${{ values.viewer_protocol_policy }}`         |
| Compression Enabled      | `${{ values.enable_compression }}`             |
| IPv6 Enabled             | `${{ values.ipv6_enabled }}`                   |
| Default Root Object      | `${{ values.default_root_object }}`            |

---

## Cache Behavior Configuration

### Default Cache Behavior

The default cache behavior applies to all requests that don't match a specific path pattern:

| Setting              | Value                                      |
| -------------------- | ------------------------------------------ |
| Allowed Methods      | `${{ values.allowed_methods }}`            |
| Cached Methods       | `${{ values.cached_methods }}`             |
| Viewer Protocol      | `${{ values.viewer_protocol_policy }}`     |
| Compress             | `${{ values.enable_compression }}`         |
| Min TTL              | `${{ values.min_ttl }}` seconds            |
| Default TTL          | `${{ values.default_ttl }}` seconds        |
| Max TTL              | `${{ values.max_ttl }}` seconds            |
| Forward Query String | `${{ values.forward_query_string }}`       |
| Forward Cookies      | `${{ values.forward_cookies }}`            |

### Price Classes

| Price Class    | Edge Locations                   | Use Case                    |
| -------------- | -------------------------------- | --------------------------- |
| PriceClass_100 | US, Canada, Europe               | Cost-optimized, US/EU focus |
| PriceClass_200 | + Asia, Middle East, Africa      | Global with cost balance    |
| PriceClass_All | All 400+ edge locations globally | Maximum global performance  |

### Recommended TTL Strategy

| Content Type                 | Recommended TTL              | Reason                          |
| ---------------------------- | ---------------------------- | ------------------------------- |
| HTML files                   | 0-300 seconds (0-5 min)      | Frequently updated              |
| CSS/JS (versioned filenames) | 31536000 seconds (1 year)    | Cache-busted by filename hash   |
| Images/Media                 | 86400-604800 (1 day-1 week)  | Rarely changes                  |
| API responses                | 0-60 seconds                 | Dynamic content                 |
| Fonts                        | 31536000 seconds (1 year)    | Static assets                   |

---

## CI/CD Pipeline

This repository includes a comprehensive GitHub Actions pipeline with:

- **Validation**: Format checking, TFLint, Terraform validation
- **Testing**: Terraform native tests for configuration validation
- **Security Scanning**: tfsec, Checkov, Trivy for vulnerability detection
- **Cost Estimation**: Infracost integration for cost visibility
- **Multi-Environment**: Separate plans for dev, staging, and production
- **Manual Approvals**: Required for apply and destroy operations

### Pipeline Workflow

```d2
direction: right

pr: Pull Request {
  shape: oval
  style.fill: "#E3F2FD"
  style.stroke: "#1976D2"
}

validate: Validate {
  style.fill: "#E8F5E9"
  style.stroke: "#388E3C"
  label: "Format Check\nTFLint\nValidate"
}

test: Test {
  style.fill: "#E1F5FE"
  style.stroke: "#0288D1"
  label: "Terraform Test\nUnit Tests"
}

security: Security {
  style.fill: "#FFCDD2"
  style.stroke: "#D32F2F"
  label: "tfsec\nCheckov\nTrivy"
}

plan: Plan {
  style.fill: "#E3F2FD"
  style.stroke: "#1976D2"
  label: "Generate Plan\nCost Estimate"
}

review: Review {
  shape: diamond
  style.fill: "#FFECB3"
  style.stroke: "#FFA000"
  label: "Manual\nApproval"
}

apply: Apply {
  style.fill: "#E8F5E9"
  style.stroke: "#388E3C"
  label: "Deploy\nDistribution"
}

invalidate: Invalidate {
  style.fill: "#F3E5F5"
  style.stroke: "#7B1FA2"
  label: "Clear Cache\n(Optional)"
}

pr -> validate -> test -> security -> plan -> review -> apply -> invalidate
```

### Pipeline Triggers

| Trigger                  | Actions                                          |
| ------------------------ | ------------------------------------------------ |
| Pull Request to `main`   | Validate, Test, Security Scan, Plan, Cost Est.   |
| Push to `main`           | Validate, Test, Security Scan, Plan (all envs)   |
| Manual `workflow_dispatch` | Plan, Apply, or Destroy (selectable)           |

---

## Prerequisites

### 1. AWS Account Setup

#### Create OIDC Identity Provider

GitHub Actions uses OpenID Connect (OIDC) for secure, keyless authentication with AWS.

```bash
# Create the OIDC provider (one-time setup per AWS account)
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1
```

#### Create IAM Role for GitHub Actions

Create a role with the following trust policy:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:YOUR_ORG/YOUR_REPO:*"
        }
      }
    }
  ]
}
```

#### Required IAM Permissions

Attach a policy with these permissions for CloudFront management:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "CloudFrontManagement",
      "Effect": "Allow",
      "Action": [
        "cloudfront:CreateDistribution",
        "cloudfront:DeleteDistribution",
        "cloudfront:GetDistribution",
        "cloudfront:GetDistributionConfig",
        "cloudfront:UpdateDistribution",
        "cloudfront:ListDistributions",
        "cloudfront:TagResource",
        "cloudfront:UntagResource",
        "cloudfront:ListTagsForResource",
        "cloudfront:CreateInvalidation",
        "cloudfront:GetInvalidation",
        "cloudfront:ListInvalidations",
        "cloudfront:CreateOriginAccessControl",
        "cloudfront:DeleteOriginAccessControl",
        "cloudfront:GetOriginAccessControl",
        "cloudfront:UpdateOriginAccessControl",
        "cloudfront:ListOriginAccessControls"
      ],
      "Resource": "*"
    },
    {
      "Sid": "S3OriginAccess",
      "Effect": "Allow",
      "Action": [
        "s3:GetBucketPolicy",
        "s3:PutBucketPolicy",
        "s3:GetBucketLocation",
        "s3:ListBucket"
      ],
      "Resource": "arn:aws:s3:::YOUR_ORIGIN_BUCKET"
    },
    {
      "Sid": "ACMCertificates",
      "Effect": "Allow",
      "Action": [
        "acm:DescribeCertificate",
        "acm:ListCertificates",
        "acm:GetCertificate"
      ],
      "Resource": "*",
      "Condition": {
        "StringEquals": {
          "aws:RequestedRegion": "us-east-1"
        }
      }
    },
    {
      "Sid": "WAFOptional",
      "Effect": "Allow",
      "Action": [
        "wafv2:GetWebACL",
        "wafv2:GetWebACLForResource",
        "wafv2:AssociateWebACL",
        "wafv2:DisassociateWebACL"
      ],
      "Resource": "*"
    },
    {
      "Sid": "Route53Optional",
      "Effect": "Allow",
      "Action": [
        "route53:ChangeResourceRecordSets",
        "route53:GetHostedZone",
        "route53:ListResourceRecordSets"
      ],
      "Resource": "arn:aws:route53:::hostedzone/*"
    },
    {
      "Sid": "TerraformState",
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::YOUR_STATE_BUCKET",
        "arn:aws:s3:::YOUR_STATE_BUCKET/*"
      ]
    },
    {
      "Sid": "StateLocking",
      "Effect": "Allow",
      "Action": [
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:DeleteItem"
      ],
      "Resource": "arn:aws:dynamodb:*:*:table/terraform-state-lock"
    }
  ]
}
```

### 2. S3 Origin Bucket

Create and configure the S3 bucket that will serve as the origin:

```bash
# Create origin bucket
aws s3 mb s3://${{ values.origin_domain_name }} --region ${{ values.region }}

# Block all public access (CloudFront uses OAC)
aws s3api put-public-access-block \
  --bucket ${{ values.origin_domain_name }} \
  --public-access-block-configuration \
  "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"

# Enable versioning (recommended)
aws s3api put-bucket-versioning \
  --bucket ${{ values.origin_domain_name }} \
  --versioning-configuration Status=Enabled
```

After CloudFront is deployed, update the bucket policy to allow OAC access:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowCloudFrontServicePrincipalReadOnly",
      "Effect": "Allow",
      "Principal": {
        "Service": "cloudfront.amazonaws.com"
      },
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::YOUR_BUCKET_NAME/*",
      "Condition": {
        "StringEquals": {
          "AWS:SourceArn": "arn:aws:cloudfront::ACCOUNT_ID:distribution/DISTRIBUTION_ID"
        }
      }
    }
  ]
}
```

### 3. ACM Certificate (Optional - for Custom Domain)

If using a custom domain, create an ACM certificate in **us-east-1** (required for CloudFront):

```bash
# Request certificate (must be in us-east-1)
aws acm request-certificate \
  --domain-name cdn.example.com \
  --validation-method DNS \
  --region us-east-1

# Validate via DNS (add CNAME records to Route 53)
# After validation, note the certificate ARN for the template
```

### 4. Terraform State Backend

```bash
# Create S3 bucket for state
aws s3 mb s3://your-terraform-state-bucket --region ${{ values.region }}

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket your-terraform-state-bucket \
  --versioning-configuration Status=Enabled

# Enable encryption
aws s3api put-bucket-encryption \
  --bucket your-terraform-state-bucket \
  --server-side-encryption-configuration '{
    "Rules": [{"ApplyServerSideEncryptionByDefault": {"SSEAlgorithm": "AES256"}}]
  }'

# Create DynamoDB table for state locking
aws dynamodb create-table \
  --table-name terraform-state-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST
```

### 5. GitHub Repository Setup

#### Required Secrets

Configure these in **Settings > Secrets and variables > Actions**:

| Secret                | Description                                 | Example                                              |
| --------------------- | ------------------------------------------- | ---------------------------------------------------- |
| `AWS_ROLE_ARN`        | IAM role ARN for OIDC authentication        | `arn:aws:iam::123456789012:role/github-actions-role` |
| `TF_STATE_BUCKET`     | S3 bucket name for Terraform state          | `my-terraform-state-bucket`                          |
| `TF_STATE_LOCK_TABLE` | DynamoDB table for state locking (optional) | `terraform-state-lock`                               |
| `INFRACOST_API_KEY`   | API key for cost estimation (optional)      | `ico-xxxxxxxx`                                       |

#### Repository Variables

Configure these in **Settings > Secrets and variables > Actions > Variables**:

| Variable     | Description        | Default                 |
| ------------ | ------------------ | ----------------------- |
| `AWS_REGION` | Default AWS region | `${{ values.region }}`  |

#### GitHub Environments

Create environments in **Settings > Environments**:

| Environment | Protection Rules                                     | Reviewers                |
| ----------- | ---------------------------------------------------- | ------------------------ |
| `dev`       | None                                                 | -                        |
| `staging`   | Required reviewers (optional)                        | Team leads               |
| `prod`      | Required reviewers, Deployment branches: `main` only | Senior engineers, DevOps |

---

## Usage

### Local Development

```bash
# Clone the repository
git clone <repository-url>
cd ${{ values.name }}

# Initialize Terraform
terraform init

# Format code
terraform fmt -recursive

# Validate configuration
terraform validate

# Plan changes (dev environment)
terraform plan -var-file=environments/dev.tfvars

# Apply changes (requires appropriate AWS credentials)
terraform apply -var-file=environments/dev.tfvars
```

### Manual Deployment via GitHub Actions

1. Navigate to **Actions** tab
2. Select **AWS CloudFront Infrastructure** workflow
3. Click **Run workflow**
4. Configure:
   - **action**: `plan`, `apply`, or `destroy`
   - **environment**: `dev`, `staging`, or `prod`
   - **confirm_destroy**: Type `DESTROY` to confirm (required for destroy)
5. Click **Run workflow**

For `staging` and `prod` environments, you'll need approval from designated reviewers.

### Cache Invalidation

After deploying new content to your origin, invalidate the CloudFront cache:

```bash
# Invalidate all objects
aws cloudfront create-invalidation \
  --distribution-id <DISTRIBUTION_ID> \
  --paths "/*"

# Invalidate specific paths
aws cloudfront create-invalidation \
  --distribution-id <DISTRIBUTION_ID> \
  --paths "/index.html" "/static/*"

# Check invalidation status
aws cloudfront get-invalidation \
  --distribution-id <DISTRIBUTION_ID> \
  --id <INVALIDATION_ID>

# List recent invalidations
aws cloudfront list-invalidations \
  --distribution-id <DISTRIBUTION_ID> \
  --max-items 10
```

### AWS CLI Operations

```bash
# Get distribution details
aws cloudfront get-distribution --id <DISTRIBUTION_ID>

# List all distributions
aws cloudfront list-distributions

# Get distribution configuration
aws cloudfront get-distribution-config --id <DISTRIBUTION_ID>

# Disable distribution (required before deletion)
aws cloudfront get-distribution-config --id <DISTRIBUTION_ID> > config.json
# Edit config.json: set "Enabled": false
aws cloudfront update-distribution \
  --id <DISTRIBUTION_ID> \
  --if-match <ETAG> \
  --distribution-config file://config.json
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

# IPv6 AAAA record
resource "aws_route53_record" "cdn_ipv6" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "cdn"
  type    = "AAAA"

  alias {
    name                   = data.aws_cloudfront_distribution.this.domain_name
    zone_id                = data.aws_cloudfront_distribution.this.hosted_zone_id
    evaluate_target_health = false
  }
}
```

---

## Security Features

### HTTPS Enforcement

| Feature                    | Configuration                               |
| -------------------------- | ------------------------------------------- |
| Viewer Protocol Policy     | `${{ values.viewer_protocol_policy }}`      |
| Minimum TLS Version        | `${{ values.minimum_protocol_version }}`    |
| SSL Support Method         | `${{ values.ssl_support_method }}`          |

All connections use TLS 1.2+ with modern cipher suites.

### Origin Access Control (OAC)

Origin Access Control secures the S3 origin bucket:

- Only CloudFront can access the origin bucket
- Requests are signed using AWS Signature Version 4
- No public access to the S3 bucket required
- Better security than legacy Origin Access Identity (OAI)

### WAF Integration (Optional)

Enable AWS WAF for additional protection:

```hcl
# Example WAF Web ACL
resource "aws_wafv2_web_acl" "cloudfront" {
  provider    = aws.us_east_1  # WAF for CloudFront must be in us-east-1
  name        = "${var.name}-waf"
  description = "WAF for CloudFront distribution"
  scope       = "CLOUDFRONT"

  default_action {
    allow {}
  }

  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name               = "AWSManagedRulesCommonRuleSet"
      sampled_requests_enabled  = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name               = "${var.name}-waf"
    sampled_requests_enabled  = true
  }
}
```

### Geo Restrictions

Configure geographic restrictions if needed:

| Type        | Description                              |
| ----------- | ---------------------------------------- |
| `none`      | No geographic restrictions (default)     |
| `whitelist` | Only allow listed countries              |
| `blacklist` | Block listed countries                   |

### Custom Error Responses

The distribution handles errors gracefully for SPA routing:

| Error Code      | Response                     | Use Case              |
| --------------- | ---------------------------- | --------------------- |
| 403 (Forbidden) | Returns /index.html with 200 | SPA client-side routing |
| 404 (Not Found) | Returns /index.html with 200 | SPA client-side routing |

---

## Outputs

After deployment, these outputs are available:

| Output                     | Description                                |
| -------------------------- | ------------------------------------------ |
| `distribution_id`          | CloudFront distribution ID                 |
| `distribution_arn`         | CloudFront distribution ARN                |
| `domain_name`              | CloudFront domain (*.cloudfront.net)       |
| `hosted_zone_id`           | Route 53 hosted zone ID for alias records  |
| `etag`                     | Current version of distribution config     |
| `status`                   | Distribution status (Deployed/InProgress)  |
| `origin_access_control_id` | Origin Access Control ID                   |
| `price_class`              | Configured price class                     |
| `enabled`                  | Whether distribution is enabled            |
| `custom_domain`            | Custom domain name (if configured)         |
| `viewer_protocol_policy`   | Viewer protocol policy                     |
| `compression_enabled`      | Whether compression is enabled             |

Access outputs via:

```bash
# Get specific output
terraform output distribution_id
terraform output domain_name

# Get all outputs as JSON
terraform output -json

# Get summary
terraform output distribution_info
```

---

## Monitoring

### CloudWatch Metrics

CloudFront publishes the following metrics to CloudWatch:

| Metric            | Description                              | Unit       |
| ----------------- | ---------------------------------------- | ---------- |
| `Requests`        | Total viewer requests                    | Count      |
| `BytesDownloaded` | Bytes downloaded by viewers              | Bytes      |
| `BytesUploaded`   | Bytes uploaded by viewers                | Bytes      |
| `TotalErrorRate`  | Percentage of all errors                 | Percent    |
| `4xxErrorRate`    | Percentage of 4xx client errors          | Percent    |
| `5xxErrorRate`    | Percentage of 5xx origin errors          | Percent    |
| `CacheHitRate`    | Percentage of requests served from cache | Percent    |

### CloudWatch Alarms (Recommended)

```hcl
resource "aws_cloudwatch_metric_alarm" "error_rate" {
  alarm_name          = "${var.name}-high-error-rate"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "5xxErrorRate"
  namespace           = "AWS/CloudFront"
  period              = 300
  statistic           = "Average"
  threshold           = 5
  alarm_description   = "High 5xx error rate on CloudFront distribution"
  
  dimensions = {
    DistributionId = aws_cloudfront_distribution.this.id
    Region         = "Global"
  }
}
```

### Access Logs

When logging is enabled, access logs are stored in S3:

```bash
# List log files
aws s3 ls s3://${{ values.logging_bucket }}/${{ values.name }}/

# Download and analyze logs
aws s3 cp s3://${{ values.logging_bucket }}/${{ values.name }}/ ./logs/ --recursive

# Parse logs (gzip compressed)
zcat logs/*.gz | head -100
```

---

## Cost Estimation

CloudFront pricing is based on data transfer and requests:

### Data Transfer Pricing (per GB)

| Region          | PriceClass_100 | PriceClass_200 | PriceClass_All |
| --------------- | -------------- | -------------- | -------------- |
| US, Canada      | $0.085         | $0.085         | $0.085         |
| Europe          | $0.085         | $0.085         | $0.085         |
| Asia            | N/A            | $0.120         | $0.120         |
| South America   | N/A            | N/A            | $0.170         |
| Australia       | N/A            | $0.170         | $0.170         |

### Request Pricing (per 10,000 requests)

| Request Type | HTTP   | HTTPS  |
| ------------ | ------ | ------ |
| US/Europe    | $0.0075| $0.010 |
| Other regions| $0.0090| $0.012 |

### Estimated Monthly Costs

| Usage Level    | Data Transfer | Requests   | Est. Cost/Month |
| -------------- | ------------- | ---------- | --------------- |
| Low (Dev)      | 10 GB         | 100K       | ~$2-5           |
| Medium         | 100 GB        | 1M         | ~$15-25         |
| High (Prod)    | 1 TB          | 10M        | ~$100-150       |

### Additional Costs

- **Invalidations**: First 1,000 paths/month free, then $0.005/path
- **Lambda@Edge**: Based on requests and duration
- **WAF**: $5/month + $1/million requests + $0.60/million rule evaluations

Get detailed cost estimates with [Infracost](https://www.infracost.io/).

---

## Troubleshooting

### Distribution Not Deploying

**Symptom:** Distribution status stuck at "InProgress"

**Resolution:**
1. CloudFront deployments can take 15-30 minutes
2. Check for configuration errors:
   ```bash
   aws cloudfront get-distribution --id <DISTRIBUTION_ID>
   ```
3. Ensure ACM certificate is validated (if using custom domain)

### 403 Forbidden Errors

**Symptom:** Users receive 403 errors when accessing content

**Resolution:**
1. Verify S3 bucket policy allows CloudFront OAC:
   ```bash
   aws s3api get-bucket-policy --bucket YOUR_BUCKET
   ```
2. Ensure the bucket policy references the correct distribution ARN
3. Check that content exists at the requested path:
   ```bash
   aws s3 ls s3://YOUR_BUCKET/path/to/content
   ```

### 504 Gateway Timeout

**Symptom:** Requests timeout with 504 errors

**Resolution:**
1. Check origin bucket region matches configuration
2. Verify S3 bucket is accessible:
   ```bash
   aws s3 ls s3://YOUR_BUCKET
   ```
3. Review CloudFront origin timeout settings

### Cache Not Invalidating

**Symptom:** Old content served despite invalidation

**Resolution:**
1. Verify invalidation completed:
   ```bash
   aws cloudfront list-invalidations --distribution-id <ID>
   ```
2. Check browser cache (hard refresh: Ctrl+Shift+R)
3. Use versioned filenames for static assets

### ACM Certificate Issues

**Symptom:** Custom domain not working, SSL errors

**Resolution:**
1. Ensure certificate is in **us-east-1** region
2. Verify certificate is validated:
   ```bash
   aws acm describe-certificate \
     --certificate-arn <ARN> \
     --region us-east-1
   ```
3. Check certificate covers the custom domain

### CORS Errors

**Symptom:** Browser blocks requests due to CORS

**Resolution:**
1. Configure S3 bucket CORS:
   ```json
   [
     {
       "AllowedHeaders": ["*"],
       "AllowedMethods": ["GET", "HEAD"],
       "AllowedOrigins": ["*"],
       "ExposeHeaders": []
     }
   ]
   ```
2. Forward `Origin` header to origin in CloudFront

### State Lock Errors

**Symptom:** "Error acquiring the state lock"

**Resolution:**
1. Wait for running pipelines to complete
2. Manually remove stuck lock:
   ```bash
   aws dynamodb delete-item \
     --table-name terraform-state-lock \
     --key '{"LockID":{"S":"your-bucket/path/terraform.tfstate"}}'
   ```

### Authentication Failures

**Symptom:** GitHub Actions cannot authenticate with AWS

**Resolution:**
1. Verify `AWS_ROLE_ARN` secret is correct
2. Check OIDC provider is configured in AWS
3. Ensure trust policy includes repository:
   ```
   repo:YOUR_ORG/YOUR_REPO:*
   ```
4. Verify IAM role has required permissions

---

## Related Templates

| Template                                                  | Description                              |
| --------------------------------------------------------- | ---------------------------------------- |
| [aws-s3-bucket](/docs/default/template/aws-s3-bucket)     | S3 bucket for CloudFront origin          |
| [aws-waf](/docs/default/template/aws-waf)                 | WAF Web ACL for CloudFront protection    |
| [aws-acm](/docs/default/template/aws-acm)                 | ACM certificate for custom domains       |
| [aws-route53](/docs/default/template/aws-route53)         | Route 53 hosted zone and DNS records     |
| [aws-lambda-edge](/docs/default/template/aws-lambda-edge) | Lambda@Edge functions for CloudFront     |
| [aws-vpc](/docs/default/template/aws-vpc)                 | VPC for custom origin (ALB/EC2)          |

---

## References

- [AWS CloudFront Documentation](https://docs.aws.amazon.com/cloudfront/latest/APIReference/Welcome.html)
- [CloudFront Developer Guide](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/Introduction.html)
- [Origin Access Control](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/private-content-restricting-access-to-s3.html)
- [Terraform AWS CloudFront Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_distribution)
- [GitHub Actions OIDC with AWS](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services)
- [CloudFront Pricing](https://aws.amazon.com/cloudfront/pricing/)
- [CloudFront Best Practices](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/best-practices.html)

---

## Owner

This resource is owned by **${{ values.owner }}**.
