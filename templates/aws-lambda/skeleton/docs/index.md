# ${{ values.name }}

AWS Lambda function for **${{ values.environment }}** environment.

## Configuration

| Setting | Value |
|---------|-------|
| Region | ${{ values.aws_region }} |
| Runtime | ${{ values.runtime }} |
| Memory | ${{ values.memory_size }} MB |
| Timeout | ${{ values.timeout }} seconds |

## Usage

```bash
terraform init
terraform plan
terraform apply
```

## Invoking the Function

```bash
aws lambda invoke \
  --function-name ${{ values.name }} \
  --payload '{}' \
  response.json
```
