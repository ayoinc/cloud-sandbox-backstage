# Usage Guide

## Deployment Patterns

### Full Stack Deployment

```bash
# Clone repository
git clone https://github.com/example/multi-cloud-management.git
cd multi-cloud-management

# Set up credentials
cat > ~/.multi-cloud/credentials.env << 'EOF'
# AWS
export AWS_ACCESS_KEY_ID="AKIAIOSFODNN7EXAMPLE"
export AWS_SECRET_ACCESS_KEY="wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
export AWS_DEFAULT_REGION="us-east-1"

# Azure
export ARM_CLIENT_ID="00000000-0000-0000-0000-000000000000"
export ARM_CLIENT_SECRET="client-secret"
export ARM_SUBSCRIPTION_ID="00000000-0000-0000-0000-000000000000"
export ARM_TENANT_ID="00000000-0000-0000-0000-000000000000"

# GCP
export GOOGLE_APPLICATION_CREDENTIALS="/path/to/service-account.json"
export GOOGLE_PROJECT="my-gcp-project"
EOF

source ~/.multi-cloud/credentials.env

# Initialize Terraform
cd terraform/environments/prod
terraform init \
  -backend-config="bucket=tfstate-bucket" \
  -backend-config="key=multi-cloud/prod/terraform.tfstate" \
  -backend-config="region=us-east-1"

# Plan deployment
terraform plan \
  -var-file=prod.tfvars \
  -out=tfplan

# Apply with approval
terraform apply tfplan
```

### Environment-Specific Configuration

```hcl
# terraform/environments/prod/prod.tfvars

# Global settings
environment = "production"
project     = "multi-cloud-platform"

# AWS Configuration
aws_config = {
  region = "us-east-1"
  
  vpc = {
    cidr               = "10.0.0.0/16"
    availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]
    private_subnets    = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
    public_subnets     = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
  }
  
  eks = {
    cluster_version = "1.29"
    node_groups = {
      general = {
        desired_size   = 3
        min_size       = 2
        max_size       = 10
        instance_types = ["m6i.large"]
      }
      compute = {
        desired_size   = 2
        min_size       = 1
        max_size       = 20
        instance_types = ["c6i.2xlarge"]
      }
    }
  }
  
  rds = {
    engine_version    = "15.4"
    instance_class    = "db.r6g.large"
    allocated_storage = 100
    multi_az          = true
  }
}

# Azure Configuration
azure_config = {
  location = "eastus"
  
  vnet = {
    address_space   = ["10.1.0.0/16"]
    private_subnets = ["10.1.1.0/24", "10.1.2.0/24", "10.1.3.0/24"]
  }
  
  aks = {
    kubernetes_version = "1.29"
    node_pools = {
      system = {
        node_count = 3
        vm_size    = "Standard_D4s_v3"
      }
      user = {
        node_count    = 2
        vm_size       = "Standard_D8s_v3"
        auto_scaling  = true
        min_count     = 2
        max_count     = 20
      }
    }
  }
  
  postgres = {
    sku_name   = "GP_Standard_D4s_v3"
    version    = "15"
    storage_mb = 102400
    ha_mode    = "ZoneRedundant"
  }
}

# GCP Configuration
gcp_config = {
  region = "us-east1"
  
  vpc = {
    subnet_cidr = "10.2.0.0/16"
  }
  
  gke = {
    release_channel = "REGULAR"
    node_pools = {
      default = {
        node_count   = 3
        machine_type = "e2-standard-4"
      }
      preemptible = {
        node_count   = 2
        machine_type = "e2-standard-8"
        preemptible  = true
      }
    }
  }
  
  cloudsql = {
    database_version = "POSTGRES_15"
    tier             = "db-custom-4-16384"
    ha_type          = "REGIONAL"
  }
}

# Cross-cloud networking
cross_cloud_vpn = {
  enabled = true
  
  aws_azure = {
    enabled = true
    tunnels = 2
  }
  
  azure_gcp = {
    enabled = true
    tunnels = 2
  }
  
  aws_gcp = {
    enabled = true
    tunnels = 2
  }
}

# Common tags/labels
common_tags = {
  Environment = "production"
  Project     = "multi-cloud-platform"
  ManagedBy   = "terraform"
  Owner       = "platform-team"
  CostCenter  = "INFRA-001"
}
```

## Pulumi Alternative

### Multi-Cloud with TypeScript

```typescript
// pulumi/index.ts
import * as pulumi from "@pulumi/pulumi";
import * as aws from "@pulumi/aws";
import * as azure from "@pulumi/azure-native";
import * as gcp from "@pulumi/gcp";

const config = new pulumi.Config();
const environment = config.require("environment");

// AWS VPC and EKS
const awsVpc = new aws.ec2.Vpc("main-vpc", {
    cidrBlock: "10.0.0.0/16",
    enableDnsHostnames: true,
    enableDnsSupport: true,
    tags: {
        Name: `${environment}-vpc`,
        Environment: environment,
    },
});

const eksCluster = new aws.eks.Cluster("eks-cluster", {
    name: `${environment}-eks`,
    roleArn: eksRole.arn,
    version: "1.29",
    vpcConfig: {
        subnetIds: privateSubnets.map(s => s.id),
        endpointPrivateAccess: true,
        endpointPublicAccess: true,
    },
    tags: {
        Environment: environment,
    },
});

// Azure VNet and AKS
const resourceGroup = new azure.resources.ResourceGroup("rg", {
    resourceGroupName: `${environment}-rg`,
    location: "eastus",
});

const azureVnet = new azure.network.VirtualNetwork("vnet", {
    resourceGroupName: resourceGroup.name,
    location: resourceGroup.location,
    virtualNetworkName: `${environment}-vnet`,
    addressSpace: {
        addressPrefixes: ["10.1.0.0/16"],
    },
});

const aksCluster = new azure.containerservice.ManagedCluster("aks", {
    resourceGroupName: resourceGroup.name,
    location: resourceGroup.location,
    resourceName: `${environment}-aks`,
    kubernetesVersion: "1.29",
    dnsPrefix: `${environment}-aks`,
    agentPoolProfiles: [{
        name: "default",
        count: 3,
        vmSize: "Standard_D4s_v3",
        mode: "System",
        vnetSubnetId: aksSubnet.id,
    }],
    identity: {
        type: "SystemAssigned",
    },
    networkProfile: {
        networkPlugin: "azure",
        networkPolicy: "calico",
    },
});

// GCP VPC and GKE
const gcpNetwork = new gcp.compute.Network("vpc", {
    name: `${environment}-vpc`,
    autoCreateSubnetworks: false,
});

const gcpSubnet = new gcp.compute.Subnetwork("subnet", {
    name: `${environment}-subnet`,
    ipCidrRange: "10.2.0.0/16",
    region: "us-east1",
    network: gcpNetwork.id,
    secondaryIpRanges: [
        { rangeName: "pods", ipCidrRange: "10.3.0.0/16" },
        { rangeName: "services", ipCidrRange: "10.4.0.0/20" },
    ],
});

const gkeCluster = new gcp.container.Cluster("gke", {
    name: `${environment}-gke`,
    location: "us-east1",
    network: gcpNetwork.name,
    subnetwork: gcpSubnet.name,
    removeDefaultNodePool: true,
    initialNodeCount: 1,
    releaseChannel: { channel: "REGULAR" },
    ipAllocationPolicy: {
        clusterSecondaryRangeName: "pods",
        servicesSecondaryRangeName: "services",
    },
    workloadIdentityConfig: {
        workloadPool: `${gcp.config.project}.svc.id.goog`,
    },
});

// Export cluster endpoints
export const awsEksEndpoint = eksCluster.endpoint;
export const azureAksEndpoint = aksCluster.fqdn;
export const gcpGkeEndpoint = gkeCluster.endpoint;
```

## Crossplane Compositions

### Multi-Cloud Database Composition

```yaml
# crossplane/compositions/database-composition.yaml
apiVersion: apiextensions.crossplane.io/v1
kind: Composition
metadata:
  name: xdatabase-multicloud
  labels:
    provider: multicloud
    crossplane.io/xrd: xdatabases.platform.example.com
spec:
  compositeTypeRef:
    apiVersion: platform.example.com/v1alpha1
    kind: XDatabase
  
  patchSets:
    - name: common-fields
      patches:
        - type: FromCompositeFieldPath
          fromFieldPath: spec.parameters.region
          toFieldPath: spec.forProvider.region
        - type: FromCompositeFieldPath
          fromFieldPath: metadata.labels
          toFieldPath: metadata.labels

  resources:
    # AWS RDS (when cloud=aws)
    - name: aws-rds
      base:
        apiVersion: rds.aws.crossplane.io/v1beta1
        kind: Instance
        spec:
          forProvider:
            engine: postgres
            engineVersion: "15"
            instanceClass: db.t3.medium
            allocatedStorage: 20
            skipFinalSnapshotBeforeDeletion: true
            publiclyAccessible: false
          providerConfigRef:
            name: aws-provider
      patches:
        - type: FromCompositeFieldPath
          fromFieldPath: spec.parameters.size
          toFieldPath: spec.forProvider.instanceClass
          transforms:
            - type: map
              map:
                small: db.t3.small
                medium: db.t3.medium
                large: db.r6g.large
        - type: FromCompositeFieldPath
          fromFieldPath: spec.parameters.storageGB
          toFieldPath: spec.forProvider.allocatedStorage
        - type: ToCompositeFieldPath
          fromFieldPath: status.atProvider.endpoint
          toFieldPath: status.endpoint

    # Azure PostgreSQL (when cloud=azure)
    - name: azure-postgres
      base:
        apiVersion: dbforpostgresql.azure.crossplane.io/v1beta1
        kind: FlexibleServer
        spec:
          forProvider:
            version: "15"
            skuName: GP_Standard_D2s_v3
            storageSizeGb: 32
            publicNetworkAccess: Disabled
          providerConfigRef:
            name: azure-provider
      patches:
        - type: FromCompositeFieldPath
          fromFieldPath: spec.parameters.size
          toFieldPath: spec.forProvider.skuName
          transforms:
            - type: map
              map:
                small: B_Standard_B1ms
                medium: GP_Standard_D2s_v3
                large: GP_Standard_D4s_v3

    # GCP Cloud SQL (when cloud=gcp)
    - name: gcp-cloudsql
      base:
        apiVersion: sql.gcp.crossplane.io/v1beta1
        kind: DatabaseInstance
        spec:
          forProvider:
            databaseVersion: POSTGRES_15
            region: us-east1
            settings:
              tier: db-custom-2-8192
              ipConfiguration:
                ipv4Enabled: false
                privateNetwork: projects/my-project/global/networks/default
          providerConfigRef:
            name: gcp-provider
      patches:
        - type: FromCompositeFieldPath
          fromFieldPath: spec.parameters.size
          toFieldPath: spec.forProvider.settings.tier
          transforms:
            - type: map
              map:
                small: db-custom-1-4096
                medium: db-custom-2-8192
                large: db-custom-4-16384

---
# XRD Definition
apiVersion: apiextensions.crossplane.io/v1
kind: CompositeResourceDefinition
metadata:
  name: xdatabases.platform.example.com
spec:
  group: platform.example.com
  names:
    kind: XDatabase
    plural: xdatabases
  claimNames:
    kind: Database
    plural: databases
  versions:
    - name: v1alpha1
      served: true
      referenceable: true
      schema:
        openAPIV3Schema:
          type: object
          properties:
            spec:
              type: object
              properties:
                parameters:
                  type: object
                  properties:
                    cloud:
                      type: string
                      enum: [aws, azure, gcp]
                    size:
                      type: string
                      enum: [small, medium, large]
                      default: medium
                    storageGB:
                      type: integer
                      default: 20
                    region:
                      type: string
                  required:
                    - cloud
                    - region
            status:
              type: object
              properties:
                endpoint:
                  type: string
                connectionSecret:
                  type: string
```

### Using the Composition

```yaml
# Request a database on AWS
apiVersion: platform.example.com/v1alpha1
kind: Database
metadata:
  name: my-app-database
  namespace: default
spec:
  parameters:
    cloud: aws
    region: us-east-1
    size: medium
    storageGB: 50
  writeConnectionSecretToRef:
    name: my-app-db-credentials
```

## CI/CD Integration

### GitHub Actions Workflow

```yaml
# .github/workflows/multi-cloud-deploy.yaml
name: Multi-Cloud Deploy

on:
  push:
    branches: [main]
    paths:
      - 'terraform/**'
  pull_request:
    branches: [main]
    paths:
      - 'terraform/**'

env:
  TF_VERSION: '1.7.0'
  TF_CLOUD_ORGANIZATION: 'my-org'

jobs:
  plan:
    name: Terraform Plan
    runs-on: ubuntu-latest
    strategy:
      matrix:
        environment: [dev, staging, prod]
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: ${{ env.TF_VERSION }}
          cli_config_credentials_token: ${{ secrets.TF_API_TOKEN }}
      
      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: us-east-1
      
      - name: Configure Azure Credentials
        uses: azure/login@v1
        with:
          creds: ${{ secrets.AZURE_CREDENTIALS }}
      
      - name: Configure GCP Credentials
        uses: google-github-actions/auth@v2
        with:
          credentials_json: ${{ secrets.GCP_SA_KEY }}
      
      - name: Terraform Init
        working-directory: terraform/environments/${{ matrix.environment }}
        run: terraform init
      
      - name: Terraform Plan
        working-directory: terraform/environments/${{ matrix.environment }}
        run: |
          terraform plan \
            -var-file=${{ matrix.environment }}.tfvars \
            -out=tfplan \
            -no-color
        continue-on-error: true
      
      - name: OPA Policy Check
        uses: open-policy-agent/opa-github-action@main
        with:
          input: terraform/environments/${{ matrix.environment }}/tfplan.json
          policy: policies/opa/

  apply:
    name: Terraform Apply
    needs: plan
    if: github.ref == 'refs/heads/main' && github.event_name == 'push'
    runs-on: ubuntu-latest
    environment: 
      name: ${{ matrix.environment }}
    strategy:
      max-parallel: 1
      matrix:
        environment: [dev, staging, prod]
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: ${{ env.TF_VERSION }}
          cli_config_credentials_token: ${{ secrets.TF_API_TOKEN }}
      
      # Configure all cloud credentials...
      
      - name: Terraform Apply
        working-directory: terraform/environments/${{ matrix.environment }}
        run: terraform apply -auto-approve tfplan
```

## Troubleshooting

### Common Issues

| Issue | Cause | Solution |
|-------|-------|----------|
| Cross-cloud VPN down | BGP session failed | Check VPN gateway logs, verify BGP ASN configuration |
| Terraform state lock | Concurrent runs | Use `terraform force-unlock <LOCK_ID>` |
| Provider auth failure | Expired credentials | Refresh credentials, check token expiry |
| Resource quota exceeded | Cloud limits | Request quota increase or use different region |
| DNS propagation slow | TTL settings | Lower TTL, check DNS health checks |
| Cost anomaly detected | Unexpected usage | Review CloudWatch/Monitor/Ops metrics |

### Diagnostic Commands

```bash
# Check Terraform state
terraform state list
terraform state show aws_vpc.main

# Validate configuration
terraform validate
terraform fmt -check -recursive

# Check provider versions
terraform providers

# Debug mode
TF_LOG=DEBUG terraform plan 2>&1 | tee debug.log

# Cross-cloud connectivity test
# From AWS to Azure
aws ec2 describe-vpn-connections --query 'VpnConnections[*].[VpnConnectionId,State]'

# From Azure to GCP
az network vpn-connection show --name azure-gcp-vpn --resource-group vpn-rg

# GCP VPN status
gcloud compute vpn-tunnels describe aws-tunnel --region us-east1 --format='value(status)'
```

### Cost Optimization

```bash
# Generate cost report
python scripts/cost-report.py > /tmp/cost-report.json

# Find unused resources
# AWS
aws ec2 describe-volumes --filters Name=status,Values=available

# Azure
az resource list --query "[?tags.LastAccessed < '2024-01-01']"

# GCP
gcloud compute disks list --filter="status=READY AND -users:*"

# Rightsizing recommendations
# AWS
aws ce get-rightsizing-recommendation --service EC2

# Azure
az advisor recommendation list --filter "Category eq 'Cost'"

# GCP
gcloud recommender recommendations list --recommender=google.compute.instance.MachineTypeRecommender
```

## Best Practices

### Security Checklist

- [ ] Use workload identity federation instead of long-lived credentials
- [ ] Enable encryption at rest for all data stores
- [ ] Implement network policies and private endpoints
- [ ] Use OPA/Sentinel for policy enforcement
- [ ] Enable audit logging on all clouds
- [ ] Rotate secrets regularly via Vault
- [ ] Implement least-privilege IAM
- [ ] Use private DNS for cross-cloud resolution
- [ ] Enable DDoS protection on all endpoints
- [ ] Regular security scanning with Cloud Security Posture Management

### Operational Checklist

- [ ] Unified monitoring with Prometheus federation
- [ ] Centralized logging with Loki or Elasticsearch
- [ ] Distributed tracing with Jaeger or Tempo
- [ ] Automated backup and disaster recovery
- [ ] Regular cost reviews and optimization
- [ ] Infrastructure drift detection
- [ ] Automated compliance reporting
- [ ] Runbook documentation for all services
- [ ] Chaos engineering testing
- [ ] Regular DR drills

### GitOps Workflow

```bash
# Install Atlantis for PR-based Terraform
helm repo add runatlantis https://runatlantis.github.io/helm-charts
helm install atlantis runatlantis/atlantis \
  --namespace atlantis \
  --set atlantis.repo-config='/etc/atlantis/repos.yaml' \
  --set-file atlantis.repoConfig=atlantis-repos.yaml
```

```yaml
# atlantis-repos.yaml
repos:
  - id: github.com/org/multi-cloud-management
    workflow: multicloud
    apply_requirements: [approved, mergeable]
    allowed_overrides: [workflow]

workflows:
  multicloud:
    plan:
      steps:
        - init
        - plan:
            extra_args: ["-var-file", "prod.tfvars"]
        - run: conftest test $PLANFILE -p policies/opa
    apply:
      steps:
        - apply
```

## Related Documentation

- [Index](index.md) - Quick start and features overview
- [Overview](overview.md) - Architecture and configuration details
