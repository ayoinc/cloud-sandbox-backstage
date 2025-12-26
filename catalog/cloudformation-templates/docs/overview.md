# CloudFormation Templates Overview

## Template Patterns

### VPC Template

```yaml
# templates/networking/vpc.yaml
AWSTemplateFormatVersion: '2010-09-09'
Description: Production VPC with public and private subnets across 3 AZs

Parameters:
  Environment:
    Type: String
    AllowedValues: [development, staging, production]

  VpcCIDR:
    Type: String
    Default: 10.0.0.0/16

  EnableNatGateway:
    Type: String
    AllowedValues: [true, false]
    Default: true

  SingleNatGateway:
    Type: String
    AllowedValues: [true, false]
    Default: false
    Description: Use single NAT Gateway (cost savings for non-prod)

Conditions:
  CreateNatGateway: !Equals [!Ref EnableNatGateway, true]
  UseSingleNat: !Equals [!Ref SingleNatGateway, true]
  CreateMultipleNats: !And
    - !Condition CreateNatGateway
    - !Not [!Condition UseSingleNat]

Resources:
  VPC:
    Type: AWS::EC2::VPC
    Properties:
      CidrBlock: !Ref VpcCIDR
      EnableDnsSupport: true
      EnableDnsHostnames: true
      Tags:
        - Key: Name
          Value: !Sub ${Environment}-vpc
        - Key: Environment
          Value: !Ref Environment

  InternetGateway:
    Type: AWS::EC2::InternetGateway
    Properties:
      Tags:
        - Key: Name
          Value: !Sub ${Environment}-igw

  InternetGatewayAttachment:
    Type: AWS::EC2::VPCGatewayAttachment
    Properties:
      VpcId: !Ref VPC
      InternetGatewayId: !Ref InternetGateway

  # Public Subnets
  PublicSubnet1:
    Type: AWS::EC2::Subnet
    Properties:
      VpcId: !Ref VPC
      AvailabilityZone: !Select [0, !GetAZs '']
      CidrBlock: !Select [0, !Cidr [!Ref VpcCIDR, 6, 8]]
      MapPublicIpOnLaunch: true
      Tags:
        - Key: Name
          Value: !Sub ${Environment}-public-subnet-1
        - Key: kubernetes.io/role/elb
          Value: '1'

  PublicSubnet2:
    Type: AWS::EC2::Subnet
    Properties:
      VpcId: !Ref VPC
      AvailabilityZone: !Select [1, !GetAZs '']
      CidrBlock: !Select [1, !Cidr [!Ref VpcCIDR, 6, 8]]
      MapPublicIpOnLaunch: true
      Tags:
        - Key: Name
          Value: !Sub ${Environment}-public-subnet-2
        - Key: kubernetes.io/role/elb
          Value: '1'

  PublicSubnet3:
    Type: AWS::EC2::Subnet
    Properties:
      VpcId: !Ref VPC
      AvailabilityZone: !Select [2, !GetAZs '']
      CidrBlock: !Select [2, !Cidr [!Ref VpcCIDR, 6, 8]]
      MapPublicIpOnLaunch: true
      Tags:
        - Key: Name
          Value: !Sub ${Environment}-public-subnet-3
        - Key: kubernetes.io/role/elb
          Value: '1'

  # Private Subnets
  PrivateSubnet1:
    Type: AWS::EC2::Subnet
    Properties:
      VpcId: !Ref VPC
      AvailabilityZone: !Select [0, !GetAZs '']
      CidrBlock: !Select [3, !Cidr [!Ref VpcCIDR, 6, 8]]
      Tags:
        - Key: Name
          Value: !Sub ${Environment}-private-subnet-1
        - Key: kubernetes.io/role/internal-elb
          Value: '1'

  PrivateSubnet2:
    Type: AWS::EC2::Subnet
    Properties:
      VpcId: !Ref VPC
      AvailabilityZone: !Select [1, !GetAZs '']
      CidrBlock: !Select [4, !Cidr [!Ref VpcCIDR, 6, 8]]
      Tags:
        - Key: Name
          Value: !Sub ${Environment}-private-subnet-2
        - Key: kubernetes.io/role/internal-elb
          Value: '1'

  PrivateSubnet3:
    Type: AWS::EC2::Subnet
    Properties:
      VpcId: !Ref VPC
      AvailabilityZone: !Select [2, !GetAZs '']
      CidrBlock: !Select [5, !Cidr [!Ref VpcCIDR, 6, 8]]
      Tags:
        - Key: Name
          Value: !Sub ${Environment}-private-subnet-3
        - Key: kubernetes.io/role/internal-elb
          Value: '1'

  # NAT Gateways
  NatGateway1EIP:
    Type: AWS::EC2::EIP
    Condition: CreateNatGateway
    DependsOn: InternetGatewayAttachment
    Properties:
      Domain: vpc

  NatGateway1:
    Type: AWS::EC2::NatGateway
    Condition: CreateNatGateway
    Properties:
      AllocationId: !GetAtt NatGateway1EIP.AllocationId
      SubnetId: !Ref PublicSubnet1
      Tags:
        - Key: Name
          Value: !Sub ${Environment}-nat-1

  # Route Tables
  PublicRouteTable:
    Type: AWS::EC2::RouteTable
    Properties:
      VpcId: !Ref VPC
      Tags:
        - Key: Name
          Value: !Sub ${Environment}-public-rt

  DefaultPublicRoute:
    Type: AWS::EC2::Route
    DependsOn: InternetGatewayAttachment
    Properties:
      RouteTableId: !Ref PublicRouteTable
      DestinationCidrBlock: 0.0.0.0/0
      GatewayId: !Ref InternetGateway

  PublicSubnet1RouteTableAssociation:
    Type: AWS::EC2::SubnetRouteTableAssociation
    Properties:
      SubnetId: !Ref PublicSubnet1
      RouteTableId: !Ref PublicRouteTable

  PrivateRouteTable1:
    Type: AWS::EC2::RouteTable
    Properties:
      VpcId: !Ref VPC
      Tags:
        - Key: Name
          Value: !Sub ${Environment}-private-rt-1

  DefaultPrivateRoute1:
    Type: AWS::EC2::Route
    Condition: CreateNatGateway
    Properties:
      RouteTableId: !Ref PrivateRouteTable1
      DestinationCidrBlock: 0.0.0.0/0
      NatGatewayId: !Ref NatGateway1

  # VPC Flow Logs
  FlowLogsLogGroup:
    Type: AWS::Logs::LogGroup
    Properties:
      LogGroupName: !Sub /aws/vpc/${Environment}-flow-logs
      RetentionInDays: 30

  FlowLogsRole:
    Type: AWS::IAM::Role
    Properties:
      AssumeRolePolicyDocument:
        Version: '2012-10-17'
        Statement:
          - Effect: Allow
            Principal:
              Service: vpc-flow-logs.amazonaws.com
            Action: sts:AssumeRole
      Policies:
        - PolicyName: FlowLogsPolicy
          PolicyDocument:
            Version: '2012-10-17'
            Statement:
              - Effect: Allow
                Action:
                  - logs:CreateLogStream
                  - logs:PutLogEvents
                  - logs:DescribeLogGroups
                  - logs:DescribeLogStreams
                Resource: !GetAtt FlowLogsLogGroup.Arn

  VPCFlowLog:
    Type: AWS::EC2::FlowLog
    Properties:
      DeliverLogsPermissionArn: !GetAtt FlowLogsRole.Arn
      LogGroupName: !Ref FlowLogsLogGroup
      ResourceId: !Ref VPC
      ResourceType: VPC
      TrafficType: ALL

Outputs:
  VpcId:
    Description: VPC ID
    Value: !Ref VPC
    Export:
      Name: !Sub ${AWS::StackName}-VpcId

  PublicSubnets:
    Description: List of public subnet IDs
    Value:
      !Join [',', [!Ref PublicSubnet1, !Ref PublicSubnet2, !Ref PublicSubnet3]]
    Export:
      Name: !Sub ${AWS::StackName}-PublicSubnets

  PrivateSubnets:
    Description: List of private subnet IDs
    Value:
      !Join [
        ',',
        [!Ref PrivateSubnet1, !Ref PrivateSubnet2, !Ref PrivateSubnet3],
      ]
    Export:
      Name: !Sub ${AWS::StackName}-PrivateSubnets
```

### ECS Cluster Template

```yaml
# templates/compute/ecs-cluster.yaml
AWSTemplateFormatVersion: '2010-09-09'
Description: ECS Fargate Cluster with Application Load Balancer

Parameters:
  Environment:
    Type: String
  VpcStackName:
    Type: String
    Description: Name of VPC stack for cross-stack references

Resources:
  ECSCluster:
    Type: AWS::ECS::Cluster
    Properties:
      ClusterName: !Sub ${Environment}-cluster
      ClusterSettings:
        - Name: containerInsights
          Value: enabled
      CapacityProviders:
        - FARGATE
        - FARGATE_SPOT
      DefaultCapacityProviderStrategy:
        - CapacityProvider: FARGATE
          Weight: 1
          Base: 1
        - CapacityProvider: FARGATE_SPOT
          Weight: 4

  # Application Load Balancer
  ALBSecurityGroup:
    Type: AWS::EC2::SecurityGroup
    Properties:
      GroupDescription: ALB Security Group
      VpcId:
        Fn::ImportValue: !Sub ${VpcStackName}-VpcId
      SecurityGroupIngress:
        - IpProtocol: tcp
          FromPort: 80
          ToPort: 80
          CidrIp: 0.0.0.0/0
        - IpProtocol: tcp
          FromPort: 443
          ToPort: 443
          CidrIp: 0.0.0.0/0

  ApplicationLoadBalancer:
    Type: AWS::ElasticLoadBalancingV2::LoadBalancer
    Properties:
      Name: !Sub ${Environment}-alb
      Type: application
      Scheme: internet-facing
      SecurityGroups:
        - !Ref ALBSecurityGroup
      Subnets: !Split
        - ','
        - Fn::ImportValue: !Sub ${VpcStackName}-PublicSubnets
      LoadBalancerAttributes:
        - Key: idle_timeout.timeout_seconds
          Value: '60'
        - Key: routing.http2.enabled
          Value: 'true'
        - Key: access_logs.s3.enabled
          Value: 'true'
        - Key: access_logs.s3.bucket
          Value: !Ref ALBLogsBucket

  ALBLogsBucket:
    Type: AWS::S3::Bucket
    Properties:
      BucketName: !Sub ${Environment}-alb-logs-${AWS::AccountId}
      BucketEncryption:
        ServerSideEncryptionConfiguration:
          - ServerSideEncryptionByDefault:
              SSEAlgorithm: AES256
      PublicAccessBlockConfiguration:
        BlockPublicAcls: true
        BlockPublicPolicy: true
        IgnorePublicAcls: true
        RestrictPublicBuckets: true
      LifecycleConfiguration:
        Rules:
          - Id: DeleteOldLogs
            Status: Enabled
            ExpirationInDays: 90

  # ECS Task Execution Role
  ECSTaskExecutionRole:
    Type: AWS::IAM::Role
    Properties:
      RoleName: !Sub ${Environment}-ecs-execution-role
      AssumeRolePolicyDocument:
        Version: '2012-10-17'
        Statement:
          - Effect: Allow
            Principal:
              Service: ecs-tasks.amazonaws.com
            Action: sts:AssumeRole
      ManagedPolicyArns:
        - arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy
      Policies:
        - PolicyName: SecretsAccess
          PolicyDocument:
            Version: '2012-10-17'
            Statement:
              - Effect: Allow
                Action:
                  - secretsmanager:GetSecretValue
                  - ssm:GetParameters
                Resource: '*'

  # ECS Service Security Group
  ECSServiceSecurityGroup:
    Type: AWS::EC2::SecurityGroup
    Properties:
      GroupDescription: ECS Service Security Group
      VpcId:
        Fn::ImportValue: !Sub ${VpcStackName}-VpcId
      SecurityGroupIngress:
        - IpProtocol: tcp
          FromPort: 8080
          ToPort: 8080
          SourceSecurityGroupId: !Ref ALBSecurityGroup

Outputs:
  ClusterName:
    Value: !Ref ECSCluster
    Export:
      Name: !Sub ${AWS::StackName}-ClusterName

  ClusterArn:
    Value: !GetAtt ECSCluster.Arn
    Export:
      Name: !Sub ${AWS::StackName}-ClusterArn

  ALBArn:
    Value: !Ref ApplicationLoadBalancer
    Export:
      Name: !Sub ${AWS::StackName}-ALBArn

  ALBDNSName:
    Value: !GetAtt ApplicationLoadBalancer.DNSName
    Export:
      Name: !Sub ${AWS::StackName}-ALBDNSName
```

### RDS Aurora Template

```yaml
# templates/database/rds-aurora.yaml
AWSTemplateFormatVersion: '2010-09-09'
Description: Aurora PostgreSQL Cluster with Multi-AZ

Parameters:
  Environment:
    Type: String
  VpcStackName:
    Type: String
  DatabaseName:
    Type: String
    Default: appdb
  MasterUsername:
    Type: String
    Default: admin
    NoEcho: true
  InstanceClass:
    Type: String
    Default: db.r6g.large
    AllowedValues:
      - db.r6g.large
      - db.r6g.xlarge
      - db.r6g.2xlarge

Resources:
  DBSubnetGroup:
    Type: AWS::RDS::DBSubnetGroup
    Properties:
      DBSubnetGroupDescription: Subnet group for Aurora cluster
      SubnetIds: !Split
        - ','
        - Fn::ImportValue: !Sub ${VpcStackName}-PrivateSubnets

  DBSecurityGroup:
    Type: AWS::EC2::SecurityGroup
    Properties:
      GroupDescription: Aurora cluster security group
      VpcId:
        Fn::ImportValue: !Sub ${VpcStackName}-VpcId
      SecurityGroupIngress:
        - IpProtocol: tcp
          FromPort: 5432
          ToPort: 5432
          CidrIp: 10.0.0.0/8

  DBSecret:
    Type: AWS::SecretsManager::Secret
    Properties:
      Name: !Sub ${Environment}/aurora/master
      GenerateSecretString:
        SecretStringTemplate: !Sub '{"username": "${MasterUsername}"}'
        GenerateStringKey: password
        PasswordLength: 32
        ExcludeCharacters: '"@/\'

  DBClusterParameterGroup:
    Type: AWS::RDS::DBClusterParameterGroup
    Properties:
      Description: Aurora PostgreSQL cluster parameters
      Family: aurora-postgresql15
      Parameters:
        shared_preload_libraries: pg_stat_statements,auto_explain
        log_statement: ddl
        log_min_duration_statement: 1000

  AuroraCluster:
    Type: AWS::RDS::DBCluster
    DeletionPolicy: Snapshot
    UpdateReplacePolicy: Snapshot
    Properties:
      DBClusterIdentifier: !Sub ${Environment}-aurora-cluster
      Engine: aurora-postgresql
      EngineVersion: '15.4'
      DatabaseName: !Ref DatabaseName
      MasterUsername: !Sub '{{resolve:secretsmanager:${DBSecret}:SecretString:username}}'
      MasterUserPassword: !Sub '{{resolve:secretsmanager:${DBSecret}:SecretString:password}}'
      DBSubnetGroupName: !Ref DBSubnetGroup
      VpcSecurityGroupIds:
        - !Ref DBSecurityGroup
      DBClusterParameterGroupName: !Ref DBClusterParameterGroup
      BackupRetentionPeriod: 7
      PreferredBackupWindow: 03:00-04:00
      PreferredMaintenanceWindow: sun:04:00-sun:05:00
      StorageEncrypted: true
      DeletionProtection: true
      EnableCloudwatchLogsExports:
        - postgresql
      Tags:
        - Key: Environment
          Value: !Ref Environment

  AuroraInstance1:
    Type: AWS::RDS::DBInstance
    Properties:
      DBInstanceIdentifier: !Sub ${Environment}-aurora-instance-1
      DBClusterIdentifier: !Ref AuroraCluster
      DBInstanceClass: !Ref InstanceClass
      Engine: aurora-postgresql
      PubliclyAccessible: false
      EnablePerformanceInsights: true
      PerformanceInsightsRetentionPeriod: 7
      MonitoringInterval: 60
      MonitoringRoleArn: !GetAtt RDSMonitoringRole.Arn

  AuroraInstance2:
    Type: AWS::RDS::DBInstance
    Properties:
      DBInstanceIdentifier: !Sub ${Environment}-aurora-instance-2
      DBClusterIdentifier: !Ref AuroraCluster
      DBInstanceClass: !Ref InstanceClass
      Engine: aurora-postgresql
      PubliclyAccessible: false
      EnablePerformanceInsights: true
      PerformanceInsightsRetentionPeriod: 7
      MonitoringInterval: 60
      MonitoringRoleArn: !GetAtt RDSMonitoringRole.Arn

  RDSMonitoringRole:
    Type: AWS::IAM::Role
    Properties:
      AssumeRolePolicyDocument:
        Version: '2012-10-17'
        Statement:
          - Effect: Allow
            Principal:
              Service: monitoring.rds.amazonaws.com
            Action: sts:AssumeRole
      ManagedPolicyArns:
        - arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole

  # Attach secret to cluster
  SecretTargetAttachment:
    Type: AWS::SecretsManager::SecretTargetAttachment
    Properties:
      SecretId: !Ref DBSecret
      TargetId: !Ref AuroraCluster
      TargetType: AWS::RDS::DBCluster

Outputs:
  ClusterEndpoint:
    Value: !GetAtt AuroraCluster.Endpoint.Address
    Export:
      Name: !Sub ${AWS::StackName}-ClusterEndpoint

  ReaderEndpoint:
    Value: !GetAtt AuroraCluster.ReadEndpoint.Address
    Export:
      Name: !Sub ${AWS::StackName}-ReaderEndpoint

  SecretArn:
    Value: !Ref DBSecret
    Export:
      Name: !Sub ${AWS::StackName}-SecretArn
```

## Nested Stacks

### Master Stack Pattern

```yaml
# templates/master-stack.yaml
AWSTemplateFormatVersion: '2010-09-09'
Description: Master stack orchestrating all infrastructure components

Parameters:
  Environment:
    Type: String
    AllowedValues: [development, staging, production]
  TemplateBucket:
    Type: String
    Description: S3 bucket containing nested templates

Resources:
  NetworkStack:
    Type: AWS::CloudFormation::Stack
    Properties:
      TemplateURL: !Sub https://${TemplateBucket}.s3.amazonaws.com/templates/networking/vpc.yaml
      Parameters:
        Environment: !Ref Environment
        VpcCIDR: 10.0.0.0/16
        EnableNatGateway: true
      Tags:
        - Key: Environment
          Value: !Ref Environment

  SecurityStack:
    Type: AWS::CloudFormation::Stack
    DependsOn: NetworkStack
    Properties:
      TemplateURL: !Sub https://${TemplateBucket}.s3.amazonaws.com/templates/security/security-groups.yaml
      Parameters:
        Environment: !Ref Environment
        VpcId: !GetAtt NetworkStack.Outputs.VpcId

  DatabaseStack:
    Type: AWS::CloudFormation::Stack
    DependsOn: SecurityStack
    Properties:
      TemplateURL: !Sub https://${TemplateBucket}.s3.amazonaws.com/templates/database/rds-aurora.yaml
      Parameters:
        Environment: !Ref Environment
        VpcStackName: !GetAtt NetworkStack.Outputs.StackName

  ComputeStack:
    Type: AWS::CloudFormation::Stack
    DependsOn: [SecurityStack, DatabaseStack]
    Properties:
      TemplateURL: !Sub https://${TemplateBucket}.s3.amazonaws.com/templates/compute/ecs-cluster.yaml
      Parameters:
        Environment: !Ref Environment
        VpcStackName: !GetAtt NetworkStack.Outputs.StackName

Outputs:
  VpcId:
    Value: !GetAtt NetworkStack.Outputs.VpcId
  ClusterArn:
    Value: !GetAtt ComputeStack.Outputs.ClusterArn
  DatabaseEndpoint:
    Value: !GetAtt DatabaseStack.Outputs.ClusterEndpoint
```

## Custom Resources

### Lambda-Backed Custom Resource

```yaml
# templates/custom-resources/route53-certificate-validation.yaml
Resources:
  CertificateValidationFunction:
    Type: AWS::Lambda::Function
    Properties:
      FunctionName: !Sub ${AWS::StackName}-cert-validation
      Runtime: python3.11
      Handler: index.handler
      Timeout: 300
      Role: !GetAtt LambdaExecutionRole.Arn
      Code:
        ZipFile: |
          import boto3
          import cfnresponse
          import time

          def handler(event, context):
              try:
                  if event['RequestType'] == 'Delete':
                      cfnresponse.send(event, context, cfnresponse.SUCCESS, {})
                      return

                  acm = boto3.client('acm')
                  route53 = boto3.client('route53')
                  
                  cert_arn = event['ResourceProperties']['CertificateArn']
                  hosted_zone_id = event['ResourceProperties']['HostedZoneId']
                  
                  # Wait for certificate to be issued with DNS validation records
                  for _ in range(30):
                      cert = acm.describe_certificate(CertificateArn=cert_arn)
                      if cert['Certificate']['DomainValidationOptions'][0].get('ResourceRecord'):
                          break
                      time.sleep(10)
                  
                  # Create Route53 validation records
                  for dvo in cert['Certificate']['DomainValidationOptions']:
                      rr = dvo['ResourceRecord']
                      route53.change_resource_record_sets(
                          HostedZoneId=hosted_zone_id,
                          ChangeBatch={
                              'Changes': [{
                                  'Action': 'UPSERT',
                                  'ResourceRecordSet': {
                                      'Name': rr['Name'],
                                      'Type': rr['Type'],
                                      'TTL': 300,
                                      'ResourceRecords': [{'Value': rr['Value']}]
                                  }
                              }]
                          }
                      )
                  
                  cfnresponse.send(event, context, cfnresponse.SUCCESS, {'CertificateArn': cert_arn})
              except Exception as e:
                  cfnresponse.send(event, context, cfnresponse.FAILED, {'Error': str(e)})

  CertificateValidation:
    Type: Custom::CertificateValidation
    Properties:
      ServiceToken: !GetAtt CertificateValidationFunction.Arn
      CertificateArn: !Ref Certificate
      HostedZoneId: !Ref HostedZoneId
```

## StackSets for Multi-Account

```yaml
# templates/stacksets/security-baseline.yaml
AWSTemplateFormatVersion: '2010-09-09'
Description: Security baseline for all accounts

Resources:
  # Enable AWS Config
  ConfigRecorder:
    Type: AWS::Config::ConfigurationRecorder
    Properties:
      Name: default
      RoleARN: !GetAtt ConfigRole.Arn
      RecordingGroup:
        AllSupported: true
        IncludeGlobalResourceTypes: true

  # Enable GuardDuty
  GuardDutyDetector:
    Type: AWS::GuardDuty::Detector
    Properties:
      Enable: true
      FindingPublishingFrequency: FIFTEEN_MINUTES

  # CloudTrail
  CloudTrail:
    Type: AWS::CloudTrail::Trail
    Properties:
      TrailName: security-audit-trail
      S3BucketName: !Ref AuditLogsBucket
      IsMultiRegionTrail: true
      EnableLogFileValidation: true
      IncludeGlobalServiceEvents: true

  # S3 Block Public Access
  AccountPublicAccessBlock:
    Type: AWS::S3::AccountPublicAccessBlock
    Properties:
      BlockPublicAcls: true
      BlockPublicPolicy: true
      IgnorePublicAcls: true
      RestrictPublicBuckets: true
```

## Security Best Practices

### IAM Least Privilege

```yaml
# templates/security/iam-roles.yaml
Resources:
  ApplicationRole:
    Type: AWS::IAM::Role
    Properties:
      RoleName: !Sub ${Environment}-application-role
      AssumeRolePolicyDocument:
        Version: '2012-10-17'
        Statement:
          - Effect: Allow
            Principal:
              Service: ecs-tasks.amazonaws.com
            Action: sts:AssumeRole
      Policies:
        - PolicyName: MinimalS3Access
          PolicyDocument:
            Version: '2012-10-17'
            Statement:
              - Effect: Allow
                Action:
                  - s3:GetObject
                  - s3:PutObject
                Resource: !Sub arn:aws:s3:::${ApplicationBucket}/*
              - Effect: Allow
                Action:
                  - s3:ListBucket
                Resource: !Sub arn:aws:s3:::${ApplicationBucket}
        - PolicyName: SecretsAccess
          PolicyDocument:
            Version: '2012-10-17'
            Statement:
              - Effect: Allow
                Action:
                  - secretsmanager:GetSecretValue
                Resource: !Sub arn:aws:secretsmanager:${AWS::Region}:${AWS::AccountId}:secret:${Environment}/*
                Condition:
                  StringEquals:
                    secretsmanager:ResourceTag/Environment: !Ref Environment
```

### Encryption Configuration

```yaml
# templates/security/kms.yaml
Resources:
  MasterKey:
    Type: AWS::KMS::Key
    Properties:
      Description: Master encryption key for all services
      EnableKeyRotation: true
      KeyPolicy:
        Version: '2012-10-17'
        Statement:
          - Sid: Enable IAM User Permissions
            Effect: Allow
            Principal:
              AWS: !Sub arn:aws:iam::${AWS::AccountId}:root
            Action: kms:*
            Resource: '*'
          - Sid: Allow services to use key
            Effect: Allow
            Principal:
              Service:
                - s3.amazonaws.com
                - rds.amazonaws.com
                - secretsmanager.amazonaws.com
            Action:
              - kms:Encrypt
              - kms:Decrypt
              - kms:GenerateDataKey*
            Resource: '*'
      Tags:
        - Key: Environment
          Value: !Ref Environment

  KeyAlias:
    Type: AWS::KMS::Alias
    Properties:
      AliasName: !Sub alias/${Environment}-master-key
      TargetKeyId: !Ref MasterKey
```
