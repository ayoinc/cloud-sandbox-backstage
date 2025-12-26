# AWS Lambda Function

This template provisions an AWS Lambda function with a comprehensive set of production-ready features including IAM roles, CloudWatch logging, optional VPC connectivity, dead letter queues, X-Ray tracing, and CloudWatch alarms. The infrastructure uses Terraform with a modular architecture supporting multiple runtimes and deployment patterns.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              AWS Lambda                                      │
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────────┐│
│  │                         Lambda Function                                  ││
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────────────────┐ ││
│  │  │   Handler   │  │   Runtime   │  │      Environment Variables      │ ││
│  │  │ main.handler│  │ python3.12  │  │  ENVIRONMENT=dev                │ ││
│  │  └─────────────┘  └─────────────┘  └─────────────────────────────────┘ ││
│  │                                                                          ││
│  │  ┌──────────────────────────────────────────────────────────────────┐  ││
│  │  │ Resources: Memory (128-10240 MB) | Timeout (1-900s) | Storage    │  ││
│  │  └──────────────────────────────────────────────────────────────────┘  ││
│  └─────────────────────────────────────────────────────────────────────────┘│
│                                    │                                         │
│         ┌──────────────────────────┼──────────────────────────────────┐     │
│         │                          │                                  │     │
│         ▼                          ▼                                  ▼     │
│  ┌─────────────┐           ┌─────────────┐                   ┌─────────────┐│
│  │  IAM Role   │           │ CloudWatch  │                   │   X-Ray     ││
│  │  & Policies │           │    Logs     │                   │  Tracing    ││
│  └─────────────┘           └─────────────┘                   └─────────────┘│
│                                                                              │
│  ┌──────────────────────────────────────────────────────────────────────┐  │
│  │                    Optional Components                                │  │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌───────────────────────┐│  │
│  │  │   VPC    │  │   DLQ    │  │  Alias   │  │    Function URL       ││  │
│  │  │  Config  │  │ (SQS/SNS)│  │  (live)  │  │  (HTTPS endpoint)     ││  │
│  │  └──────────┘  └──────────┘  └──────────┘  └───────────────────────┘│  │
│  └──────────────────────────────────────────────────────────────────────┘  │
│                                                                              │
│  ┌──────────────────────────────────────────────────────────────────────┐  │
│  │                    CloudWatch Alarms                                  │  │
│  │  • Error Rate  • Duration  • Throttles                               │  │
│  └──────────────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Features

### Supported Runtimes

| Runtime | Version    | Use Case                           |
| ------- | ---------- | ---------------------------------- |
| Python  | 3.12, 3.11 | Data processing, automation, APIs  |
| Node.js | 20.x, 18.x | Web backends, real-time processing |
| Go      | 1.x        | High-performance workloads         |
| Java    | 21, 17     | Enterprise applications            |

### Core Capabilities

| Feature                   | Description                                                      |
| ------------------------- | ---------------------------------------------------------------- |
| **Automatic Packaging**   | Source code in `src/` is automatically zipped during deployment  |
| **IAM Role**              | Least-privilege execution role with configurable custom policies |
| **CloudWatch Logs**       | Automatic log group creation with configurable retention         |
| **Environment Variables** | Inject configuration at runtime                                  |
| **Layers**                | Support for Lambda layers (dependencies, shared code)            |

### Advanced Features

| Feature                  | Description                                                |
| ------------------------ | ---------------------------------------------------------- |
| **VPC Integration**      | Deploy Lambda in VPC subnets with security groups          |
| **Dead Letter Queue**    | Route failed invocations to SQS or SNS                     |
| **X-Ray Tracing**        | Distributed tracing for debugging and performance analysis |
| **Function URL**         | HTTPS endpoint without API Gateway                         |
| **Versioning & Aliases** | Immutable versions with traffic-shifting aliases           |
| **Reserved Concurrency** | Limit concurrent executions                                |

### Monitoring & Alerting

| Alarm          | Metric    | Default Threshold |
| -------------- | --------- | ----------------- |
| Error Alarm    | Errors    | > 0 in 5 minutes  |
| Duration Alarm | Duration  | Configurable (ms) |
| Throttle Alarm | Throttles | > 0 in 5 minutes  |

## Prerequisites

- **AWS Account** with appropriate IAM permissions
- **Terraform** >= 1.0
- **Source Code** in the `src/` directory

### Required IAM Permissions

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "lambda:CreateFunction",
        "lambda:UpdateFunctionCode",
        "lambda:UpdateFunctionConfiguration",
        "lambda:CreateAlias",
        "lambda:CreateFunctionUrlConfig",
        "iam:CreateRole",
        "iam:AttachRolePolicy",
        "logs:CreateLogGroup",
        "cloudwatch:PutMetricAlarm"
      ],
      "Resource": "*"
    }
  ]
}
```

## Quick Start

### 1. Add Your Code

Place your Lambda function code in the `src/` directory:

```python
# src/main.py
import json

def handler(event, context):
    """Lambda function entry point."""
    return {
        'statusCode': 200,
        'body': json.dumps({
            'message': 'Hello from Lambda!',
            'event': event
        })
    }
```

### 2. Configure Environment

Edit `environments/dev.tfvars`:

```hcl
name        = "my-function"
environment = "dev"
runtime     = "python3.12"
handler     = "main.handler"
memory_size = 256
timeout     = 30
```

### 3. Deploy

```bash
# Initialize Terraform
terraform init

# Plan changes
terraform plan -var-file=environments/dev.tfvars

# Apply
terraform apply -var-file=environments/dev.tfvars
```

## Configuration Reference

### Required Variables

| Variable      | Type   | Description                                   |
| ------------- | ------ | --------------------------------------------- |
| `name`        | string | Function name identifier                      |
| `environment` | string | Environment (dev, staging, prod)              |
| `runtime`     | string | Lambda runtime (python3.12, nodejs20.x, etc.) |
| `handler`     | string | Function handler (file.function)              |

### Resource Configuration

| Variable                         | Type   | Default    | Description                        |
| -------------------------------- | ------ | ---------- | ---------------------------------- |
| `memory_size`                    | number | 256        | Memory allocation (128-10240 MB)   |
| `timeout`                        | number | 30         | Execution timeout (1-900 seconds)  |
| `reserved_concurrent_executions` | number | null       | Max concurrent executions          |
| `ephemeral_storage_size`         | number | 512        | /tmp storage (512-10240 MB)        |
| `architectures`                  | list   | ["x86_64"] | CPU architecture (x86_64 or arm64) |

### VPC Configuration

| Variable                 | Type | Default | Description                   |
| ------------------------ | ---- | ------- | ----------------------------- |
| `vpc_subnet_ids`         | list | null    | Subnet IDs for VPC deployment |
| `vpc_security_group_ids` | list | null    | Security group IDs            |

### Monitoring Configuration

| Variable                | Type   | Default | Description                           |
| ----------------------- | ------ | ------- | ------------------------------------- |
| `log_retention_days`    | number | 14      | CloudWatch log retention              |
| `tracing_mode`          | string | null    | X-Ray tracing (Active or PassThrough) |
| `create_error_alarm`    | bool   | false   | Create error rate alarm               |
| `create_duration_alarm` | bool   | false   | Create duration alarm                 |

### Function URL Configuration

| Variable                 | Type   | Default | Description                           |
| ------------------------ | ------ | ------- | ------------------------------------- |
| `create_function_url`    | bool   | false   | Create HTTPS endpoint                 |
| `function_url_auth_type` | string | AWS_IAM | Authentication type (AWS_IAM or NONE) |

## Outputs

| Output           | Description                     |
| ---------------- | ------------------------------- |
| `function_name`  | Lambda function name            |
| `function_arn`   | Lambda function ARN             |
| `invoke_arn`     | ARN for API Gateway integration |
| `function_url`   | HTTPS endpoint (if enabled)     |
| `role_arn`       | IAM execution role ARN          |
| `log_group_name` | CloudWatch log group name       |

## Deployment Patterns

### Blue/Green with Aliases

Enable versioning and aliases for safe deployments:

```hcl
publish_version = true
create_alias    = true
alias_routing_config = {
    "2" = 0.1  # 10% traffic to version 2
}
```

### VPC-Connected Lambda

Deploy Lambda inside your VPC for database access:

```hcl
vpc_subnet_ids         = ["subnet-abc123", "subnet-def456"]
vpc_security_group_ids = ["sg-123456"]
```

### With Dead Letter Queue

Route failed invocations to SQS:

```hcl
dead_letter_target_arn = "arn:aws:sqs:us-east-1:123456789:my-dlq"
```

## Cost Optimization

| Factor                      | Optimization                                                |
| --------------------------- | ----------------------------------------------------------- |
| **Memory**                  | Right-size based on actual usage (check CloudWatch metrics) |
| **Architecture**            | Use arm64 for ~20% cost savings                             |
| **Provisioned Concurrency** | Avoid unless low latency is critical                        |
| **Duration**                | Optimize code to reduce execution time                      |

### Pricing Components

- **Requests**: $0.20 per 1M requests
- **Duration**: $0.0000166667 per GB-second
- **Provisioned Concurrency**: Additional charge when enabled

## CI/CD Integration

The included GitHub Actions workflow:

1. **On Pull Request**: Validates Terraform and runs plan
2. **On Merge**: Applies changes to target environment
3. **Code Packaging**: Automatically creates deployment ZIP

## Testing

### Local Testing

```bash
# Python with SAM CLI
sam local invoke -e events/test.json

# Or use pytest
pytest tests/
```

### Terraform Tests

```bash
terraform test
```

## Troubleshooting

### Function Timeout

1. Check CloudWatch Logs for execution time
2. Increase `timeout` value
3. Optimize code or increase memory (more memory = more CPU)

### VPC Cold Starts

1. Use Provisioned Concurrency for latency-sensitive functions
2. Ensure NAT Gateway exists for internet access
3. Check security group allows required outbound traffic

### Permission Denied Errors

1. Review IAM role policies in CloudWatch Logs
2. Add required permissions via `custom_iam_policy`
3. Verify resource-based policies on target services

### Package Size Exceeded

1. Use Lambda Layers for dependencies
2. Exclude unnecessary files from `src/`
3. Consider container image deployment for large packages

## Related Resources

- [AWS Lambda Documentation](https://docs.aws.amazon.com/lambda/)
- [Lambda Quotas](https://docs.aws.amazon.com/lambda/latest/dg/gettingstarted-limits.html)
- [Lambda Best Practices](https://docs.aws.amazon.com/lambda/latest/dg/best-practices.html)
- [X-Ray Tracing](https://docs.aws.amazon.com/lambda/latest/dg/services-xray.html)
