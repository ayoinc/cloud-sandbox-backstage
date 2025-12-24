# AWS CloudFormation Templates

Production-ready AWS CloudFormation templates for automated infrastructure deployment with nested stacks, cross-stack references, and security best practices.

## Quick Start

### Prerequisites

```bash
# Install AWS CLI v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Configure AWS credentials
aws configure
# AWS Access Key ID: YOUR_ACCESS_KEY
# AWS Secret Access Key: YOUR_SECRET_KEY
# Default region name: us-west-2
# Default output format: json

# Verify configuration
aws sts get-caller-identity
```

### Deploy Your First Stack

```bash
# Clone the templates repository
git clone https://github.com/company/cloudformation-templates.git
cd cloudformation-templates

# Validate template
aws cloudformation validate-template \
  --template-body file://templates/vpc/vpc.yaml

# Create stack
aws cloudformation create-stack \
  --stack-name production-vpc \
  --template-body file://templates/vpc/vpc.yaml \
  --parameters file://parameters/production/vpc.json \
  --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM \
  --tags Key=Environment,Value=production Key=ManagedBy,Value=cloudformation

# Wait for completion
aws cloudformation wait stack-create-complete --stack-name production-vpc

# View outputs
aws cloudformation describe-stacks \
  --stack-name production-vpc \
  --query 'Stacks[0].Outputs'
```

## Features

| Feature                    | Description                  | Benefit                        |
| -------------------------- | ---------------------------- | ------------------------------ |
| **Nested Stacks**          | Modular, reusable components | DRY principle, maintainability |
| **Cross-Stack References** | Export/Import values         | Loose coupling, independence   |
| **Drift Detection**        | Detect manual changes        | Configuration compliance       |
| **Change Sets**            | Preview changes before apply | Safe deployments               |
| **StackSets**              | Multi-account/region deploy  | Enterprise scale               |
| **Custom Resources**       | Lambda-backed resources      | Extend capabilities            |
| **Macros**                 | Template transformations     | Code generation                |
| **Guard Rails**            | IAM boundaries, SCPs         | Security compliance            |

## Architecture Overview

```d2
direction: right

library: CloudFormation Template Library {
  style.fill: "#e3f2fd"

  networking: networking/ {
    style.fill: "#e8f5e9"
    vpc: vpc.yaml
    sg: security-groups.yaml
    tgw: transit-gateway.yaml
    vpn: vpn.yaml
  }

  compute: compute/ {
    style.fill: "#fff3e0"
    ec2: ec2-asg.yaml
    ecs: ecs-cluster.yaml
    eks: eks-cluster.yaml
    lambda: lambda.yaml
  }

  database: database/ {
    style.fill: "#fce4ec"
    aurora: rds-aurora.yaml
    dynamo: dynamodb.yaml
    cache: elasticache.yaml
    docdb: documentdb.yaml
  }

  storage: storage/ {
    style.fill: "#f3e5f5"
    s3: s3.yaml
    efs: efs.yaml
    fsx: fsx.yaml
  }

  security: security/ {
    style.fill: "#ffebee"
    iam: iam-roles.yaml
    kms: kms.yaml
    waf: waf.yaml
    guardduty: guardduty.yaml
  }

  observability: observability/ {
    style.fill: "#e0f7fa"
    cw: cloudwatch.yaml
    xray: x-ray.yaml
    config: config.yaml
  }
}
```

## Template Structure

```yaml
# Standard CloudFormation template structure
AWSTemplateFormatVersion: '2010-09-09'
Description: >
  Template description with version info
  Version: 1.0.0
  Author: Platform Team

Metadata:
  AWS::CloudFormation::Interface:
    ParameterGroups:
      - Label:
          default: Network Configuration
        Parameters:
          - VpcCIDR
          - AvailabilityZones
    ParameterLabels:
      VpcCIDR:
        default: VPC CIDR Block

Parameters:
  Environment:
    Type: String
    AllowedValues: [development, staging, production]
    Default: development

  VpcCIDR:
    Type: String
    Default: 10.0.0.0/16
    AllowedPattern: ^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])(\/([0-9]|[1-2][0-9]|3[0-2]))$

Mappings:
  RegionMap:
    us-west-2:
      AMI: ami-0123456789abcdef0
    us-east-1:
      AMI: ami-0fedcba9876543210

Conditions:
  IsProduction: !Equals [!Ref Environment, production]
  CreateNatGateway:
    !Or [
      !Equals [!Ref Environment, staging],
      !Equals [!Ref Environment, production],
    ]

Resources:
  # Resource definitions...

Outputs:
  VpcId:
    Description: VPC ID
    Value: !Ref VPC
    Export:
      Name: !Sub ${AWS::StackName}-VpcId
```

## CLI Commands

```bash
# Validate template
aws cloudformation validate-template --template-body file://template.yaml

# Create stack
aws cloudformation create-stack \
  --stack-name my-stack \
  --template-body file://template.yaml \
  --parameters ParameterKey=Env,ParameterValue=prod

# Update stack with change set (recommended)
aws cloudformation create-change-set \
  --stack-name my-stack \
  --change-set-name my-changes \
  --template-body file://template.yaml

aws cloudformation describe-change-set \
  --stack-name my-stack \
  --change-set-name my-changes

aws cloudformation execute-change-set \
  --stack-name my-stack \
  --change-set-name my-changes

# Delete stack
aws cloudformation delete-stack --stack-name my-stack

# List stacks
aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE UPDATE_COMPLETE

# Describe stack events
aws cloudformation describe-stack-events --stack-name my-stack

# Detect drift
aws cloudformation detect-stack-drift --stack-name my-stack
aws cloudformation describe-stack-drift-detection-status \
  --stack-drift-detection-id <detection-id>
```

## Related Documentation

- [Overview](overview.md) - Deep dive into template patterns and best practices
- [Usage](usage.md) - Deployment examples, CI/CD integration, and troubleshooting
