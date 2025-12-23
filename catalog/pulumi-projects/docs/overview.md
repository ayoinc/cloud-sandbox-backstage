# Overview

## Architecture

Pulumi Infrastructure Projects provides a modern infrastructure as code platform using real programming languages. Unlike domain-specific languages, Pulumi leverages TypeScript, Python, Go, and C# to define cloud resources with full IDE support, testing capabilities, and code reuse.

```
+------------------------------------------------------------------+
|                      PULUMI ARCHITECTURE                          |
+------------------------------------------------------------------+
|                                                                   |
|  +-------------------+    +-------------------+                   |
|  |   Pulumi CLI      |    |   Pulumi Service  |                   |
|  |   pulumi up       |--->|   (State Backend) |                   |
|  |   pulumi preview  |    |   app.pulumi.com  |                   |
|  +-------------------+    +-------------------+                   |
|           |                        |                              |
|           v                        v                              |
|  +-------------------+    +-------------------+                   |
|  |   Language Host   |    |   State Storage   |                   |
|  |   Node.js/Python  |    |   S3/Azure/GCS    |                   |
|  |   Go/.NET         |    |   Local/Pulumi    |                   |
|  +-------------------+    +-------------------+                   |
|           |                                                       |
|           v                                                       |
|  +-------------------+    +-------------------+                   |
|  |   Pulumi Engine   |--->|   Cloud Providers |                   |
|  |   Resource Graph  |    |   AWS/Azure/GCP   |                   |
|  |   Diff/Deploy     |    |   K8s/Docker      |                   |
|  +-------------------+    +-------------------+                   |
|                                                                   |
+------------------------------------------------------------------+
```

## Core Components

### Resource Providers

Pulumi supports 100+ cloud providers through native and bridged providers:

| Provider | Package | Version | Description |
|----------|---------|---------|-------------|
| AWS | `@pulumi/aws` | 6.x | Amazon Web Services resources |
| Azure | `@pulumi/azure-native` | 2.x | Azure Resource Manager native |
| GCP | `@pulumi/gcp` | 7.x | Google Cloud Platform |
| Kubernetes | `@pulumi/kubernetes` | 4.x | Kubernetes resources |
| Docker | `@pulumi/docker` | 4.x | Docker containers/images |
| CloudFlare | `@pulumi/cloudflare` | 5.x | CloudFlare DNS/Workers |
| Datadog | `@pulumi/datadog` | 4.x | Datadog monitoring |

### Component Resources

Component resources are reusable abstractions that encapsulate multiple resources:

```typescript
// components/vpc.ts
import * as pulumi from "@pulumi/pulumi";
import * as aws from "@pulumi/aws";

export interface VpcArgs {
    cidrBlock: string;
    availabilityZones: string[];
    enableNatGateway?: boolean;
    tags?: Record<string, string>;
}

export class Vpc extends pulumi.ComponentResource {
    public readonly vpcId: pulumi.Output<string>;
    public readonly publicSubnetIds: pulumi.Output<string>[];
    public readonly privateSubnetIds: pulumi.Output<string>[];
    public readonly natGatewayIds: pulumi.Output<string>[];

    constructor(name: string, args: VpcArgs, opts?: pulumi.ComponentResourceOptions) {
        super("custom:network:Vpc", name, {}, opts);

        const vpc = new aws.ec2.Vpc(`${name}-vpc`, {
            cidrBlock: args.cidrBlock,
            enableDnsHostnames: true,
            enableDnsSupport: true,
            tags: { ...args.tags, Name: `${name}-vpc` },
        }, { parent: this });

        this.vpcId = vpc.id;

        const igw = new aws.ec2.InternetGateway(`${name}-igw`, {
            vpcId: vpc.id,
            tags: { ...args.tags, Name: `${name}-igw` },
        }, { parent: this });

        this.publicSubnetIds = [];
        this.privateSubnetIds = [];
        this.natGatewayIds = [];

        args.availabilityZones.forEach((az, index) => {
            const publicSubnet = new aws.ec2.Subnet(`${name}-public-${index}`, {
                vpcId: vpc.id,
                cidrBlock: `10.0.${index * 2}.0/24`,
                availabilityZone: az,
                mapPublicIpOnLaunch: true,
                tags: { ...args.tags, Name: `${name}-public-${az}` },
            }, { parent: this });

            this.publicSubnetIds.push(publicSubnet.id);

            const privateSubnet = new aws.ec2.Subnet(`${name}-private-${index}`, {
                vpcId: vpc.id,
                cidrBlock: `10.0.${index * 2 + 1}.0/24`,
                availabilityZone: az,
                tags: { ...args.tags, Name: `${name}-private-${az}` },
            }, { parent: this });

            this.privateSubnetIds.push(privateSubnet.id);

            if (args.enableNatGateway) {
                const eip = new aws.ec2.Eip(`${name}-eip-${index}`, {
                    domain: "vpc",
                    tags: { ...args.tags, Name: `${name}-eip-${az}` },
                }, { parent: this });

                const nat = new aws.ec2.NatGateway(`${name}-nat-${index}`, {
                    subnetId: publicSubnet.id,
                    allocationId: eip.id,
                    tags: { ...args.tags, Name: `${name}-nat-${az}` },
                }, { parent: this });

                this.natGatewayIds.push(nat.id);
            }
        });

        this.registerOutputs({
            vpcId: this.vpcId,
            publicSubnetIds: this.publicSubnetIds,
            privateSubnetIds: this.privateSubnetIds,
        });
    }
}
```

### EKS Cluster Component

```typescript
// components/eks-cluster.ts
import * as pulumi from "@pulumi/pulumi";
import * as aws from "@pulumi/aws";
import * as eks from "@pulumi/eks";

export interface EksClusterArgs {
    vpcId: pulumi.Input<string>;
    subnetIds: pulumi.Input<string>[];
    instanceType?: string;
    desiredCapacity?: number;
    minSize?: number;
    maxSize?: number;
    version?: string;
}

export class EksCluster extends pulumi.ComponentResource {
    public readonly clusterName: pulumi.Output<string>;
    public readonly kubeconfig: pulumi.Output<string>;
    public readonly oidcProviderArn: pulumi.Output<string>;
    public readonly oidcProviderUrl: pulumi.Output<string>;

    constructor(name: string, args: EksClusterArgs, opts?: pulumi.ComponentResourceOptions) {
        super("custom:container:EksCluster", name, {}, opts);

        const cluster = new eks.Cluster(`${name}-cluster`, {
            vpcId: args.vpcId,
            subnetIds: args.subnetIds,
            instanceType: args.instanceType || "t3.medium",
            desiredCapacity: args.desiredCapacity || 2,
            minSize: args.minSize || 1,
            maxSize: args.maxSize || 4,
            version: args.version || "1.29",
            enabledClusterLogTypes: [
                "api",
                "audit",
                "authenticator",
                "controllerManager",
                "scheduler",
            ],
            createOidcProvider: true,
        }, { parent: this });

        this.clusterName = cluster.eksCluster.name;
        this.kubeconfig = cluster.kubeconfigJson;
        this.oidcProviderArn = cluster.core.oidcProvider!.arn;
        this.oidcProviderUrl = cluster.core.oidcProvider!.url;

        this.registerOutputs({
            clusterName: this.clusterName,
            kubeconfig: this.kubeconfig,
        });
    }
}
```

### RDS Database Component

```typescript
// components/rds-database.ts
import * as pulumi from "@pulumi/pulumi";
import * as aws from "@pulumi/aws";
import * as random from "@pulumi/random";

export interface RdsDatabaseArgs {
    vpcId: pulumi.Input<string>;
    subnetIds: pulumi.Input<string>[];
    engine: "postgres" | "mysql" | "mariadb";
    engineVersion: string;
    instanceClass?: string;
    allocatedStorage?: number;
    multiAz?: boolean;
    allowedSecurityGroups?: pulumi.Input<string>[];
}

export class RdsDatabase extends pulumi.ComponentResource {
    public readonly endpoint: pulumi.Output<string>;
    public readonly port: pulumi.Output<number>;
    public readonly username: pulumi.Output<string>;
    public readonly password: pulumi.Output<string>;
    public readonly databaseName: pulumi.Output<string>;

    constructor(name: string, args: RdsDatabaseArgs, opts?: pulumi.ComponentResourceOptions) {
        super("custom:database:RdsDatabase", name, {}, opts);

        const password = new random.RandomPassword(`${name}-password`, {
            length: 32,
            special: true,
            overrideSpecial: "!#$%&*()-_=+[]{}<>:?",
        }, { parent: this });

        const subnetGroup = new aws.rds.SubnetGroup(`${name}-subnet-group`, {
            subnetIds: args.subnetIds,
            tags: { Name: `${name}-subnet-group` },
        }, { parent: this });

        const securityGroup = new aws.ec2.SecurityGroup(`${name}-sg`, {
            vpcId: args.vpcId,
            description: `Security group for ${name} RDS instance`,
            ingress: [{
                protocol: "tcp",
                fromPort: args.engine === "postgres" ? 5432 : 3306,
                toPort: args.engine === "postgres" ? 5432 : 3306,
                securityGroups: args.allowedSecurityGroups || [],
            }],
            egress: [{
                protocol: "-1",
                fromPort: 0,
                toPort: 0,
                cidrBlocks: ["0.0.0.0/0"],
            }],
            tags: { Name: `${name}-sg` },
        }, { parent: this });

        const instance = new aws.rds.Instance(`${name}-instance`, {
            identifier: name,
            engine: args.engine,
            engineVersion: args.engineVersion,
            instanceClass: args.instanceClass || "db.t3.micro",
            allocatedStorage: args.allocatedStorage || 20,
            storageType: "gp3",
            storageEncrypted: true,
            dbName: name.replace(/-/g, "_"),
            username: "admin",
            password: password.result,
            dbSubnetGroupName: subnetGroup.name,
            vpcSecurityGroupIds: [securityGroup.id],
            multiAz: args.multiAz || false,
            backupRetentionPeriod: 7,
            backupWindow: "03:00-04:00",
            maintenanceWindow: "Mon:04:00-Mon:05:00",
            deletionProtection: true,
            skipFinalSnapshot: false,
            finalSnapshotIdentifier: `${name}-final-snapshot`,
            tags: { Name: name },
        }, { parent: this });

        this.endpoint = instance.endpoint;
        this.port = instance.port;
        this.username = instance.username;
        this.password = password.result;
        this.databaseName = instance.dbName;

        this.registerOutputs({
            endpoint: this.endpoint,
            port: this.port,
        });
    }
}
```

## Configuration Management

### Stack Configuration

Pulumi uses stack-specific configuration files:

```yaml
# Pulumi.dev.yaml
config:
  aws:region: us-west-2
  myproject:environment: dev
  myproject:instanceType: t3.small
  myproject:minNodes: 1
  myproject:maxNodes: 3

# Pulumi.prod.yaml
config:
  aws:region: us-east-1
  myproject:environment: prod
  myproject:instanceType: t3.large
  myproject:minNodes: 3
  myproject:maxNodes: 10
```

### Accessing Configuration

```typescript
// index.ts
import * as pulumi from "@pulumi/pulumi";

const config = new pulumi.Config();

// Required configuration
const environment = config.require("environment");

// Optional with defaults
const instanceType = config.get("instanceType") || "t3.medium";
const minNodes = config.getNumber("minNodes") || 2;

// Nested configuration objects
interface DatabaseConfig {
    engine: string;
    version: string;
    instanceClass: string;
}

const dbConfig = config.requireObject<DatabaseConfig>("database");
```

### Environment-Specific Settings

```typescript
// config/index.ts
import * as pulumi from "@pulumi/pulumi";

const stack = pulumi.getStack();

export const settings = {
    dev: {
        instanceType: "t3.small",
        replicas: 1,
        enableMonitoring: false,
        domain: "dev.example.com",
    },
    staging: {
        instanceType: "t3.medium",
        replicas: 2,
        enableMonitoring: true,
        domain: "staging.example.com",
    },
    prod: {
        instanceType: "t3.large",
        replicas: 3,
        enableMonitoring: true,
        domain: "example.com",
    },
}[stack] || {
    instanceType: "t3.micro",
    replicas: 1,
    enableMonitoring: false,
    domain: "localhost",
};
```

## Stack References

Share outputs between stacks:

```typescript
// infrastructure/index.ts (network stack)
import * as pulumi from "@pulumi/pulumi";
import { Vpc } from "./components/vpc";

const vpc = new Vpc("main", {
    cidrBlock: "10.0.0.0/16",
    availabilityZones: ["us-west-2a", "us-west-2b", "us-west-2c"],
    enableNatGateway: true,
});

export const vpcId = vpc.vpcId;
export const publicSubnetIds = vpc.publicSubnetIds;
export const privateSubnetIds = vpc.privateSubnetIds;
```

```typescript
// applications/index.ts (app stack)
import * as pulumi from "@pulumi/pulumi";
import * as aws from "@pulumi/aws";

const config = new pulumi.Config();
const networkStackRef = new pulumi.StackReference(
    config.require("networkStackName")  // e.g., "org/network/prod"
);

const vpcId = networkStackRef.getOutput("vpcId");
const privateSubnetIds = networkStackRef.getOutput("privateSubnetIds");

// Use outputs from network stack
const alb = new aws.lb.LoadBalancer("app-alb", {
    internal: false,
    loadBalancerType: "application",
    subnets: privateSubnetIds,
});
```

## Policy as Code (CrossGuard)

### Policy Pack Structure

```
policy/
├── package.json
├── tsconfig.json
├── index.ts
└── policies/
    ├── cost.ts
    ├── security.ts
    └── compliance.ts
```

### Security Policies

```typescript
// policy/policies/security.ts
import * as policy from "@pulumi/policy";
import * as aws from "@pulumi/aws";

export const securityPolicies: policy.PolicyPack = new policy.PolicyPack("security", {
    policies: [
        {
            name: "s3-no-public-read",
            description: "S3 buckets must not have public read access",
            enforcementLevel: "mandatory",
            validateResource: policy.validateResourceOfType(aws.s3.Bucket, (bucket, args, reportViolation) => {
                if (bucket.acl === "public-read" || bucket.acl === "public-read-write") {
                    reportViolation("S3 bucket must not have public read access");
                }
            }),
        },
        {
            name: "ec2-no-public-ip",
            description: "EC2 instances must not have public IPs in production",
            enforcementLevel: "advisory",
            validateResource: policy.validateResourceOfType(aws.ec2.Instance, (instance, args, reportViolation) => {
                if (args.getStack().endsWith("prod") && instance.associatePublicIpAddress) {
                    reportViolation("Production EC2 instances should not have public IPs");
                }
            }),
        },
        {
            name: "rds-encryption-required",
            description: "RDS instances must have encryption enabled",
            enforcementLevel: "mandatory",
            validateResource: policy.validateResourceOfType(aws.rds.Instance, (instance, args, reportViolation) => {
                if (!instance.storageEncrypted) {
                    reportViolation("RDS instances must have storage encryption enabled");
                }
            }),
        },
        {
            name: "ebs-encryption-required",
            description: "EBS volumes must be encrypted",
            enforcementLevel: "mandatory",
            validateResource: policy.validateResourceOfType(aws.ebs.Volume, (volume, args, reportViolation) => {
                if (!volume.encrypted) {
                    reportViolation("EBS volumes must be encrypted");
                }
            }),
        },
    ],
});
```

### Cost Policies

```typescript
// policy/policies/cost.ts
import * as policy from "@pulumi/policy";
import * as aws from "@pulumi/aws";

const ALLOWED_INSTANCE_TYPES = ["t3.micro", "t3.small", "t3.medium", "t3.large"];
const MAX_RDS_STORAGE_GB = 100;

export const costPolicies: policy.PolicyPack = new policy.PolicyPack("cost", {
    policies: [
        {
            name: "ec2-instance-type-allowed",
            description: "EC2 instances must use approved instance types",
            enforcementLevel: "mandatory",
            validateResource: policy.validateResourceOfType(aws.ec2.Instance, (instance, args, reportViolation) => {
                if (!ALLOWED_INSTANCE_TYPES.includes(instance.instanceType)) {
                    reportViolation(
                        `Instance type ${instance.instanceType} is not allowed. ` +
                        `Use one of: ${ALLOWED_INSTANCE_TYPES.join(", ")}`
                    );
                }
            }),
        },
        {
            name: "rds-max-storage",
            description: "RDS storage must not exceed maximum allowed",
            enforcementLevel: "advisory",
            validateResource: policy.validateResourceOfType(aws.rds.Instance, (instance, args, reportViolation) => {
                if (instance.allocatedStorage > MAX_RDS_STORAGE_GB) {
                    reportViolation(
                        `RDS storage ${instance.allocatedStorage}GB exceeds maximum ${MAX_RDS_STORAGE_GB}GB`
                    );
                }
            }),
        },
        {
            name: "require-cost-tags",
            description: "All resources must have cost allocation tags",
            enforcementLevel: "mandatory",
            validateStack: (args, reportViolation) => {
                for (const resource of args.resources) {
                    const tags = (resource.props as any).tags;
                    if (tags && (!tags.CostCenter || !tags.Project)) {
                        reportViolation(
                            `Resource ${resource.name} is missing required cost tags (CostCenter, Project)`
                        );
                    }
                }
            },
        },
    ],
});
```

### Running Policies

```bash
# Run with local policy pack
pulumi preview --policy-pack ./policy

# Run with published policy pack
pulumi preview --policy-pack org/security-policies/1.0.0

# Multiple policy packs
pulumi up --policy-pack ./cost-policies --policy-pack ./security-policies
```

## Automation API

Programmatically manage Pulumi stacks:

```typescript
// automation/deploy.ts
import * as automation from "@pulumi/pulumi/automation";
import * as path from "path";

async function deploy(stackName: string, environment: string) {
    const projectDir = path.join(__dirname, "..", "infrastructure");
    
    // Create or select stack
    const stack = await automation.LocalWorkspace.createOrSelectStack({
        stackName,
        workDir: projectDir,
    });

    console.log(`Deploying stack: ${stackName}`);

    // Set configuration
    await stack.setAllConfig({
        "aws:region": { value: "us-west-2" },
        "myproject:environment": { value: environment },
    });

    // Preview changes
    const previewResult = await stack.preview({ onOutput: console.log });
    console.log(`Preview: ${previewResult.changeSummary}`);

    // Deploy
    const upResult = await stack.up({ onOutput: console.log });
    console.log(`Deployment complete: ${upResult.summary.result}`);

    // Get outputs
    const outputs = await stack.outputs();
    console.log("Outputs:", outputs);

    return outputs;
}

// Destroy stack
async function destroy(stackName: string) {
    const projectDir = path.join(__dirname, "..", "infrastructure");
    
    const stack = await automation.LocalWorkspace.selectStack({
        stackName,
        workDir: projectDir,
    });

    console.log(`Destroying stack: ${stackName}`);
    const result = await stack.destroy({ onOutput: console.log });
    console.log(`Destroy complete: ${result.summary.result}`);

    // Remove stack
    await stack.workspace.removeStack(stackName);
}

// Export for CLI or programmatic use
export { deploy, destroy };
```

## State Management

### Backend Options

```bash
# Pulumi Service (default)
pulumi login

# AWS S3
pulumi login s3://my-pulumi-state-bucket

# Azure Blob Storage
pulumi login azblob://my-container

# Google Cloud Storage
pulumi login gs://my-bucket

# Local filesystem
pulumi login file://~/.pulumi-state
```

### S3 Backend Configuration

```typescript
// backend.ts
import * as aws from "@pulumi/aws";
import * as pulumi from "@pulumi/pulumi";

// Create S3 bucket for state
const stateBucket = new aws.s3.Bucket("pulumi-state", {
    bucket: "company-pulumi-state",
    versioning: {
        enabled: true,
    },
    serverSideEncryptionConfiguration: {
        rule: {
            applyServerSideEncryptionByDefault: {
                sseAlgorithm: "aws:kms",
            },
        },
    },
    lifecycleRules: [{
        enabled: true,
        noncurrentVersionExpiration: {
            days: 90,
        },
    }],
});

// Block public access
new aws.s3.BucketPublicAccessBlock("state-public-access-block", {
    bucket: stateBucket.id,
    blockPublicAcls: true,
    blockPublicPolicy: true,
    ignorePublicAcls: true,
    restrictPublicBuckets: true,
});

// DynamoDB for locking (optional but recommended)
const lockTable = new aws.dynamodb.Table("pulumi-locks", {
    name: "pulumi-locks",
    billingMode: "PAY_PER_REQUEST",
    hashKey: "LockID",
    attributes: [{
        name: "LockID",
        type: "S",
    }],
});

export const stateBackendUrl = pulumi.interpolate`s3://${stateBucket.bucket}`;
```

## Secrets Management

### Built-in Secrets

```bash
# Set secret via CLI
pulumi config set --secret dbPassword "super-secret-password"

# Set secret in code
pulumi config set --secret apiKey "sk-live-..."
```

### External Secrets Providers

```yaml
# Pulumi.yaml
name: myproject
runtime: nodejs
backend:
  url: s3://my-state-bucket
config:
  # Use AWS Secrets Manager
  pulumi:secrets:provider: awskms://alias/pulumi-secrets
  
  # Or use HashiCorp Vault
  # pulumi:secrets:provider: hashivault://transit/keys/pulumi
```

### Accessing Secrets in Code

```typescript
import * as pulumi from "@pulumi/pulumi";
import * as aws from "@pulumi/aws";

const config = new pulumi.Config();

// Get secret (automatically decrypted)
const dbPassword = config.requireSecret("dbPassword");

// Use in resources
const secret = new aws.secretsmanager.Secret("db-password", {
    name: "myapp/database/password",
});

new aws.secretsmanager.SecretVersion("db-password-version", {
    secretId: secret.id,
    secretString: dbPassword,
});
```

## Monitoring and Observability

### Stack Outputs for Monitoring

```typescript
// Export monitoring endpoints
export const prometheusEndpoint = pulumi.interpolate`http://${prometheus.serviceIp}:9090`;
export const grafanaEndpoint = pulumi.interpolate`http://${grafana.serviceIp}:3000`;
export const alertmanagerEndpoint = pulumi.interpolate`http://${alertmanager.serviceIp}:9093`;

// Export resource identifiers for tagging
export const resourceTags = {
    Environment: config.require("environment"),
    Project: pulumi.getProject(),
    Stack: pulumi.getStack(),
    ManagedBy: "pulumi",
};
```

### Audit Logging

```bash
# View stack history
pulumi stack history

# Export history as JSON
pulumi stack history --json > history.json

# View specific update
pulumi stack history --show-secrets --full
```

## Resource Transformations

Apply transformations across all resources:

```typescript
// transformations.ts
import * as pulumi from "@pulumi/pulumi";

// Add tags to all taggable resources
pulumi.runtime.registerStackTransformation((args) => {
    if (args.props.tags !== undefined) {
        args.props.tags = {
            ...args.props.tags,
            Environment: pulumi.getStack(),
            Project: pulumi.getProject(),
            ManagedBy: "pulumi",
            CreatedAt: new Date().toISOString(),
        };
    }
    return { props: args.props, opts: args.opts };
});

// Ensure all S3 buckets have versioning
pulumi.runtime.registerStackTransformation((args) => {
    if (args.type === "aws:s3/bucket:Bucket") {
        args.props.versioning = args.props.versioning || { enabled: true };
    }
    return { props: args.props, opts: args.opts };
});
```

## Related Resources

- [Pulumi Registry](https://www.pulumi.com/registry/) - Provider documentation
- [Pulumi Examples](https://github.com/pulumi/examples) - Reference implementations
- [Pulumi Templates](https://www.pulumi.com/templates/) - Starter templates
- [CrossGuard Policies](https://www.pulumi.com/docs/using-pulumi/crossguard/) - Policy as code
