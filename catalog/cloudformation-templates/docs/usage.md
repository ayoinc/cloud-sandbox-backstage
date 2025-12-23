# CloudFormation Templates Usage Guide

## Deployment Workflows

### Manual Deployment

```bash
# 1. Validate templates
aws cloudformation validate-template \
  --template-body file://templates/networking/vpc.yaml

# 2. Create parameter file
cat > parameters/production/vpc.json << 'EOF'
[
  {
    "ParameterKey": "Environment",
    "ParameterValue": "production"
  },
  {
    "ParameterKey": "VpcCIDR",
    "ParameterValue": "10.0.0.0/16"
  },
  {
    "ParameterKey": "EnableNatGateway",
    "ParameterValue": "true"
  }
]
EOF

# 3. Deploy with change set (recommended)
aws cloudformation create-change-set \
  --stack-name production-vpc \
  --template-body file://templates/networking/vpc.yaml \
  --parameters file://parameters/production/vpc.json \
  --capabilities CAPABILITY_IAM \
  --change-set-name deploy-$(date +%Y%m%d-%H%M%S)

# 4. Review change set
aws cloudformation describe-change-set \
  --stack-name production-vpc \
  --change-set-name deploy-20240115-120000

# 5. Execute change set
aws cloudformation execute-change-set \
  --stack-name production-vpc \
  --change-set-name deploy-20240115-120000

# 6. Monitor progress
aws cloudformation describe-stack-events \
  --stack-name production-vpc \
  --query 'StackEvents[*].[Timestamp,ResourceStatus,ResourceType,LogicalResourceId]' \
  --output table
```

### CI/CD Pipeline Integration

#### GitHub Actions

```yaml
# .github/workflows/cloudformation.yml
name: CloudFormation Deploy

on:
  push:
    branches: [main]
    paths:
      - 'templates/**'
      - 'parameters/**'
  pull_request:
    branches: [main]
    paths:
      - 'templates/**'

env:
  AWS_REGION: us-west-2

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ${{ env.AWS_REGION }}
      
      - name: Install cfn-lint
        run: pip install cfn-lint
      
      - name: Lint templates
        run: cfn-lint templates/**/*.yaml
      
      - name: Validate templates
        run: |
          for template in templates/**/*.yaml; do
            echo "Validating $template"
            aws cloudformation validate-template --template-body file://$template
          done

  security-scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Run cfn-nag
        uses: stelligent/cfn_nag@master
        with:
          input_path: templates
          extra_args: --fail-on-warnings

  deploy-staging:
    needs: [validate, security-scan]
    if: github.event_name == 'push'
    runs-on: ubuntu-latest
    environment: staging
    steps:
      - uses: actions/checkout@v4
      
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ${{ env.AWS_REGION }}
      
      - name: Deploy VPC stack
        run: |
          aws cloudformation deploy \
            --stack-name staging-vpc \
            --template-file templates/networking/vpc.yaml \
            --parameter-overrides file://parameters/staging/vpc.json \
            --capabilities CAPABILITY_IAM \
            --no-fail-on-empty-changeset
      
      - name: Deploy ECS stack
        run: |
          aws cloudformation deploy \
            --stack-name staging-ecs \
            --template-file templates/compute/ecs-cluster.yaml \
            --parameter-overrides \
              Environment=staging \
              VpcStackName=staging-vpc \
            --capabilities CAPABILITY_IAM \
            --no-fail-on-empty-changeset

  deploy-production:
    needs: deploy-staging
    runs-on: ubuntu-latest
    environment: production
    steps:
      - uses: actions/checkout@v4
      
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::123456789012:role/CloudFormationDeployRole
          aws-region: ${{ env.AWS_REGION }}
      
      - name: Create change set
        id: changeset
        run: |
          CHANGESET_NAME="deploy-${{ github.sha }}"
          aws cloudformation create-change-set \
            --stack-name production-vpc \
            --template-body file://templates/networking/vpc.yaml \
            --parameters file://parameters/production/vpc.json \
            --capabilities CAPABILITY_IAM \
            --change-set-name $CHANGESET_NAME
          
          echo "changeset_name=$CHANGESET_NAME" >> $GITHUB_OUTPUT
          
          # Wait for change set creation
          aws cloudformation wait change-set-create-complete \
            --stack-name production-vpc \
            --change-set-name $CHANGESET_NAME
      
      - name: Review change set
        run: |
          aws cloudformation describe-change-set \
            --stack-name production-vpc \
            --change-set-name ${{ steps.changeset.outputs.changeset_name }} \
            --query 'Changes[*].ResourceChange.{Action:Action,Resource:LogicalResourceId,Type:ResourceType}'
      
      - name: Execute change set
        run: |
          aws cloudformation execute-change-set \
            --stack-name production-vpc \
            --change-set-name ${{ steps.changeset.outputs.changeset_name }}
          
          aws cloudformation wait stack-update-complete \
            --stack-name production-vpc
```

### AWS CodePipeline

```yaml
# codepipeline/pipeline.yaml
AWSTemplateFormatVersion: '2010-09-09'
Description: CI/CD Pipeline for CloudFormation deployments

Resources:
  Pipeline:
    Type: AWS::CodePipeline::Pipeline
    Properties:
      Name: infrastructure-pipeline
      RoleArn: !GetAtt PipelineRole.Arn
      ArtifactStore:
        Type: S3
        Location: !Ref ArtifactBucket
      Stages:
        - Name: Source
          Actions:
            - Name: SourceAction
              ActionTypeId:
                Category: Source
                Owner: AWS
                Provider: CodeStarSourceConnection
                Version: '1'
              Configuration:
                ConnectionArn: !Ref GitHubConnection
                FullRepositoryId: company/cloudformation-templates
                BranchName: main
              OutputArtifacts:
                - Name: SourceOutput

        - Name: Validate
          Actions:
            - Name: CFNLint
              ActionTypeId:
                Category: Build
                Owner: AWS
                Provider: CodeBuild
                Version: '1'
              Configuration:
                ProjectName: !Ref ValidateProject
              InputArtifacts:
                - Name: SourceOutput

        - Name: DeployStaging
          Actions:
            - Name: CreateChangeSet
              ActionTypeId:
                Category: Deploy
                Owner: AWS
                Provider: CloudFormation
                Version: '1'
              Configuration:
                ActionMode: CHANGE_SET_REPLACE
                StackName: staging-infrastructure
                ChangeSetName: staging-changeset
                TemplatePath: SourceOutput::templates/master-stack.yaml
                TemplateConfiguration: SourceOutput::parameters/staging/config.json
                Capabilities: CAPABILITY_IAM,CAPABILITY_NAMED_IAM
                RoleArn: !GetAtt CloudFormationRole.Arn
              InputArtifacts:
                - Name: SourceOutput
              RunOrder: 1

            - Name: ExecuteChangeSet
              ActionTypeId:
                Category: Deploy
                Owner: AWS
                Provider: CloudFormation
                Version: '1'
              Configuration:
                ActionMode: CHANGE_SET_EXECUTE
                StackName: staging-infrastructure
                ChangeSetName: staging-changeset
              RunOrder: 2

        - Name: ApproveProduction
          Actions:
            - Name: ManualApproval
              ActionTypeId:
                Category: Approval
                Owner: AWS
                Provider: Manual
                Version: '1'
              Configuration:
                CustomData: Review staging deployment before production

        - Name: DeployProduction
          Actions:
            - Name: CreateChangeSet
              ActionTypeId:
                Category: Deploy
                Owner: AWS
                Provider: CloudFormation
                Version: '1'
              Configuration:
                ActionMode: CHANGE_SET_REPLACE
                StackName: production-infrastructure
                ChangeSetName: production-changeset
                TemplatePath: SourceOutput::templates/master-stack.yaml
                TemplateConfiguration: SourceOutput::parameters/production/config.json
                Capabilities: CAPABILITY_IAM,CAPABILITY_NAMED_IAM
                RoleArn: !GetAtt CloudFormationRole.Arn
              InputArtifacts:
                - Name: SourceOutput
              RunOrder: 1

            - Name: ExecuteChangeSet
              ActionTypeId:
                Category: Deploy
                Owner: AWS
                Provider: CloudFormation
                Version: '1'
              Configuration:
                ActionMode: CHANGE_SET_EXECUTE
                StackName: production-infrastructure
                ChangeSetName: production-changeset
              RunOrder: 2
```

## Testing Templates

### TaskCat Testing

```yaml
# .taskcat.yml
project:
  name: cloudformation-templates
  regions:
    - us-west-2
    - us-east-1

tests:
  vpc-test:
    template: templates/networking/vpc.yaml
    parameters:
      Environment: test
      VpcCIDR: 10.99.0.0/16
      EnableNatGateway: 'false'
  
  ecs-test:
    template: templates/compute/ecs-cluster.yaml
    parameters:
      Environment: test
      VpcStackName: vpc-test
    depends_on:
      - vpc-test
```

```bash
# Install TaskCat
pip install taskcat

# Run tests
taskcat test run

# Cleanup test stacks
taskcat test clean
```

### cfn-lint Validation

```bash
# Install cfn-lint
pip install cfn-lint

# Lint single template
cfn-lint templates/networking/vpc.yaml

# Lint all templates
cfn-lint templates/**/*.yaml

# With custom rules
cfn-lint -a rules/ templates/**/*.yaml

# Output as JSON
cfn-lint -f json templates/**/*.yaml
```

### Security Scanning with cfn-nag

```bash
# Install cfn-nag
gem install cfn-nag

# Scan single template
cfn_nag_scan --input-path templates/networking/vpc.yaml

# Scan directory
cfn_nag_scan --input-path templates/

# Generate report
cfn_nag_scan --input-path templates/ --output-format json > cfn-nag-report.json

# Fail on warnings
cfn_nag_scan --input-path templates/ --fail-on-warnings
```

## Drift Detection

```bash
# Start drift detection
aws cloudformation detect-stack-drift --stack-name production-vpc

# Check detection status
aws cloudformation describe-stack-drift-detection-status \
  --stack-drift-detection-id <detection-id>

# Get drift details
aws cloudformation describe-stack-resource-drifts \
  --stack-name production-vpc \
  --stack-resource-drift-status-filters MODIFIED DELETED

# Remediate drift (update stack to match template)
aws cloudformation update-stack \
  --stack-name production-vpc \
  --use-previous-template \
  --parameters file://parameters/production/vpc.json \
  --capabilities CAPABILITY_IAM
```

## Stack Operations

### Import Existing Resources

```bash
# Create import template with existing resources
cat > import-template.yaml << 'EOF'
Resources:
  ExistingBucket:
    Type: AWS::S3::Bucket
    DeletionPolicy: Retain
    Properties:
      BucketName: my-existing-bucket
EOF

# Create change set for import
aws cloudformation create-change-set \
  --stack-name imported-resources \
  --change-set-name import-bucket \
  --change-set-type IMPORT \
  --resources-to-import '[{"ResourceType":"AWS::S3::Bucket","LogicalResourceId":"ExistingBucket","ResourceIdentifier":{"BucketName":"my-existing-bucket"}}]' \
  --template-body file://import-template.yaml

# Execute import
aws cloudformation execute-change-set \
  --stack-name imported-resources \
  --change-set-name import-bucket
```

### Stack Deletion with Retained Resources

```bash
# Update stack with DeletionPolicy: Retain
aws cloudformation update-stack \
  --stack-name my-stack \
  --template-body file://template-with-retain.yaml

# Delete stack (retained resources will remain)
aws cloudformation delete-stack --stack-name my-stack

# Force delete stuck stack
aws cloudformation delete-stack \
  --stack-name my-stack \
  --retain-resources LogicalResourceId1 LogicalResourceId2
```

## StackSets Operations

### Create StackSet

```bash
# Create StackSet
aws cloudformation create-stack-set \
  --stack-set-name security-baseline \
  --template-body file://templates/stacksets/security-baseline.yaml \
  --capabilities CAPABILITY_IAM \
  --permission-model SERVICE_MANAGED \
  --auto-deployment Enabled=true,RetainStacksOnAccountRemoval=false

# Deploy to organizational units
aws cloudformation create-stack-instances \
  --stack-set-name security-baseline \
  --deployment-targets OrganizationalUnitIds=ou-xxxx-xxxxxxxx \
  --regions us-west-2 us-east-1 eu-west-1

# Check operation status
aws cloudformation describe-stack-set-operation \
  --stack-set-name security-baseline \
  --operation-id <operation-id>
```

### Update StackSet

```bash
# Update all instances
aws cloudformation update-stack-set \
  --stack-set-name security-baseline \
  --template-body file://templates/stacksets/security-baseline.yaml \
  --capabilities CAPABILITY_IAM \
  --operation-preferences MaxConcurrentPercentage=25,FailureTolerancePercentage=10

# Update specific accounts
aws cloudformation update-stack-instances \
  --stack-set-name security-baseline \
  --accounts 111111111111 222222222222 \
  --regions us-west-2
```

## Troubleshooting

| Issue | Cause | Solution |
|-------|-------|----------|
| CREATE_FAILED | Resource creation error | Check stack events for specific error message |
| UPDATE_ROLLBACK_FAILED | Rollback cannot complete | Use continue-update-rollback with skip resources |
| DELETE_FAILED | Resource has dependencies | Delete dependent resources first or use retain |
| ROLLBACK_IN_PROGRESS | Update failed | Wait for rollback, check events for cause |
| Circular dependency | Resources reference each other | Use DependsOn or refactor template |
| Template validation error | Invalid YAML/JSON | Use cfn-lint to validate syntax |
| Insufficient permissions | Missing IAM permissions | Add required permissions to execution role |
| Resource limit exceeded | Account limits | Request limit increase or use different region |

### Debug Commands

```bash
# View detailed stack events
aws cloudformation describe-stack-events \
  --stack-name my-stack \
  --query 'StackEvents[?ResourceStatus==`CREATE_FAILED` || ResourceStatus==`UPDATE_FAILED`]'

# Get stack failure reason
aws cloudformation describe-stacks \
  --stack-name my-stack \
  --query 'Stacks[0].StackStatusReason'

# Continue update rollback with skip
aws cloudformation continue-update-rollback \
  --stack-name my-stack \
  --resources-to-skip LogicalResourceId1

# Get template from stack
aws cloudformation get-template \
  --stack-name my-stack \
  --template-stage Original

# Compare templates
diff <(aws cloudformation get-template --stack-name my-stack --query TemplateBody --output text) template.yaml
```

## Best Practices

### Template Organization

1. **Use nested stacks** - Break large templates into manageable components
2. **Export outputs** - Enable cross-stack references
3. **Use mappings** - Region-specific values, AMI IDs
4. **Parameterize** - Make templates reusable across environments
5. **Add descriptions** - Document parameters and resources

### Security

1. **Least privilege** - Minimal IAM permissions for CloudFormation role
2. **Enable encryption** - KMS for all data at rest
3. **Use Secrets Manager** - Never hardcode credentials
4. **Enable logging** - CloudTrail, VPC Flow Logs
5. **Security scanning** - cfn-nag, Checkov in CI/CD

### Operations

1. **Use change sets** - Review changes before applying
2. **Enable termination protection** - Prevent accidental deletion
3. **Set deletion policies** - Retain or snapshot critical resources
4. **Tag resources** - Cost allocation, ownership tracking
5. **Monitor drift** - Regular drift detection

### Cost Optimization

1. **Use cost allocation tags** - Track spending by stack
2. **Conditional resources** - Different configs per environment
3. **Auto-scaling** - Right-size based on demand
4. **Spot instances** - Where appropriate (non-prod)
5. **Reserved capacity** - For predictable workloads
