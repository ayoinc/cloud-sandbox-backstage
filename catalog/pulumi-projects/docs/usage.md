# Usage Guide

## Getting Started

### Prerequisites

| Requirement | Version | Installation |
|-------------|---------|--------------|
| Node.js | 18+ | `brew install node` |
| Pulumi CLI | 3.100+ | `brew install pulumi` |
| AWS CLI | 2.x | `brew install awscli` |
| Docker | 24+ | Docker Desktop |

### Installation

```bash
# Install Pulumi CLI
curl -fsSL https://get.pulumi.com | sh

# Verify installation
pulumi version
# v3.100.0

# Login to Pulumi Service (or self-hosted backend)
pulumi login

# Configure AWS credentials
aws configure
# Or use environment variables
export AWS_ACCESS_KEY_ID="AKIA..."
export AWS_SECRET_ACCESS_KEY="..."
export AWS_REGION="us-west-2"
```

### Project Initialization

```bash
# Create new project from template
pulumi new aws-typescript --name myproject --stack dev

# Or create from scratch
mkdir myproject && cd myproject
pulumi new aws-typescript

# Project structure
myproject/
├── Pulumi.yaml           # Project definition
├── Pulumi.dev.yaml       # Dev stack config
├── package.json          # Node.js dependencies
├── tsconfig.json         # TypeScript config
├── index.ts              # Main entrypoint
└── components/           # Reusable components
    ├── vpc.ts
    ├── eks.ts
    └── rds.ts
```

## Examples

### Basic Infrastructure

```typescript
// index.ts - Complete AWS infrastructure
import * as pulumi from "@pulumi/pulumi";
import * as aws from "@pulumi/aws";

const config = new pulumi.Config();
const environment = config.require("environment");

// VPC
const vpc = new aws.ec2.Vpc("main-vpc", {
    cidrBlock: "10.0.0.0/16",
    enableDnsHostnames: true,
    enableDnsSupport: true,
    tags: {
        Name: `${environment}-vpc`,
        Environment: environment,
    },
});

// Internet Gateway
const igw = new aws.ec2.InternetGateway("main-igw", {
    vpcId: vpc.id,
    tags: { Name: `${environment}-igw` },
});

// Public Subnets
const azs = ["us-west-2a", "us-west-2b", "us-west-2c"];
const publicSubnets = azs.map((az, index) => 
    new aws.ec2.Subnet(`public-subnet-${index}`, {
        vpcId: vpc.id,
        cidrBlock: `10.0.${index}.0/24`,
        availabilityZone: az,
        mapPublicIpOnLaunch: true,
        tags: {
            Name: `${environment}-public-${az}`,
            "kubernetes.io/role/elb": "1",
        },
    })
);

// Private Subnets
const privateSubnets = azs.map((az, index) => 
    new aws.ec2.Subnet(`private-subnet-${index}`, {
        vpcId: vpc.id,
        cidrBlock: `10.0.${index + 10}.0/24`,
        availabilityZone: az,
        tags: {
            Name: `${environment}-private-${az}`,
            "kubernetes.io/role/internal-elb": "1",
        },
    })
);

// NAT Gateway
const eip = new aws.ec2.Eip("nat-eip", { domain: "vpc" });
const natGateway = new aws.ec2.NatGateway("nat-gateway", {
    subnetId: publicSubnets[0].id,
    allocationId: eip.id,
    tags: { Name: `${environment}-nat` },
});

// Route Tables
const publicRouteTable = new aws.ec2.RouteTable("public-rt", {
    vpcId: vpc.id,
    routes: [{
        cidrBlock: "0.0.0.0/0",
        gatewayId: igw.id,
    }],
    tags: { Name: `${environment}-public-rt` },
});

const privateRouteTable = new aws.ec2.RouteTable("private-rt", {
    vpcId: vpc.id,
    routes: [{
        cidrBlock: "0.0.0.0/0",
        natGatewayId: natGateway.id,
    }],
    tags: { Name: `${environment}-private-rt` },
});

// Route Table Associations
publicSubnets.forEach((subnet, index) => 
    new aws.ec2.RouteTableAssociation(`public-rta-${index}`, {
        subnetId: subnet.id,
        routeTableId: publicRouteTable.id,
    })
);

privateSubnets.forEach((subnet, index) => 
    new aws.ec2.RouteTableAssociation(`private-rta-${index}`, {
        subnetId: subnet.id,
        routeTableId: privateRouteTable.id,
    })
);

// Exports
export const vpcId = vpc.id;
export const publicSubnetIds = publicSubnets.map(s => s.id);
export const privateSubnetIds = privateSubnets.map(s => s.id);
```

### EKS Cluster with Node Groups

```typescript
// eks-cluster.ts
import * as pulumi from "@pulumi/pulumi";
import * as aws from "@pulumi/aws";
import * as eks from "@pulumi/eks";

const config = new pulumi.Config();

// Import VPC from network stack
const networkStack = new pulumi.StackReference(config.require("networkStack"));
const vpcId = networkStack.getOutput("vpcId");
const privateSubnetIds = networkStack.getOutput("privateSubnetIds");

// EKS Cluster
const cluster = new eks.Cluster("eks-cluster", {
    vpcId: vpcId,
    subnetIds: privateSubnetIds,
    instanceType: "t3.medium",
    desiredCapacity: 3,
    minSize: 2,
    maxSize: 5,
    version: "1.29",
    nodeAssociatePublicIpAddress: false,
    enabledClusterLogTypes: [
        "api",
        "audit", 
        "authenticator",
        "controllerManager",
        "scheduler",
    ],
    createOidcProvider: true,
    tags: {
        Environment: config.require("environment"),
    },
});

// Managed Node Group for workloads
const workloadNodeGroup = new eks.ManagedNodeGroup("workload-nodes", {
    cluster: cluster,
    nodeGroupName: "workload-nodes",
    instanceTypes: ["t3.large"],
    scalingConfig: {
        desiredSize: 3,
        minSize: 2,
        maxSize: 10,
    },
    labels: {
        "workload-type": "general",
    },
    taints: [],
});

// Spot Node Group for batch workloads
const spotNodeGroup = new eks.ManagedNodeGroup("spot-nodes", {
    cluster: cluster,
    nodeGroupName: "spot-nodes",
    instanceTypes: ["t3.large", "t3.xlarge", "m5.large"],
    capacityType: "SPOT",
    scalingConfig: {
        desiredSize: 2,
        minSize: 0,
        maxSize: 20,
    },
    labels: {
        "workload-type": "batch",
        "node-lifecycle": "spot",
    },
    taints: [{
        key: "workload-type",
        value: "batch",
        effect: "NO_SCHEDULE",
    }],
});

export const kubeconfig = cluster.kubeconfig;
export const clusterName = cluster.eksCluster.name;
export const clusterEndpoint = cluster.eksCluster.endpoint;
export const oidcProviderArn = cluster.core.oidcProvider?.arn;
```

### Kubernetes Resources

```typescript
// k8s-resources.ts
import * as pulumi from "@pulumi/pulumi";
import * as k8s from "@pulumi/kubernetes";

const config = new pulumi.Config();

// Import kubeconfig from EKS stack
const eksStack = new pulumi.StackReference(config.require("eksStack"));
const kubeconfig = eksStack.getOutput("kubeconfig");

// Create K8s provider
const k8sProvider = new k8s.Provider("k8s-provider", {
    kubeconfig: kubeconfig,
});

// Namespace
const namespace = new k8s.core.v1.Namespace("app-namespace", {
    metadata: { name: "myapp" },
}, { provider: k8sProvider });

// ConfigMap
const configMap = new k8s.core.v1.ConfigMap("app-config", {
    metadata: {
        name: "app-config",
        namespace: namespace.metadata.name,
    },
    data: {
        "config.yaml": `
server:
  port: 8080
  host: 0.0.0.0
logging:
  level: info
  format: json
`,
    },
}, { provider: k8sProvider });

// Secret
const secret = new k8s.core.v1.Secret("app-secrets", {
    metadata: {
        name: "app-secrets",
        namespace: namespace.metadata.name,
    },
    stringData: {
        "database-url": config.requireSecret("databaseUrl"),
        "api-key": config.requireSecret("apiKey"),
    },
}, { provider: k8sProvider });

// Deployment
const deployment = new k8s.apps.v1.Deployment("app-deployment", {
    metadata: {
        name: "myapp",
        namespace: namespace.metadata.name,
    },
    spec: {
        replicas: 3,
        selector: {
            matchLabels: { app: "myapp" },
        },
        template: {
            metadata: {
                labels: { app: "myapp" },
            },
            spec: {
                containers: [{
                    name: "myapp",
                    image: "myregistry/myapp:v1.0.0",
                    ports: [{ containerPort: 8080 }],
                    envFrom: [
                        { configMapRef: { name: configMap.metadata.name } },
                        { secretRef: { name: secret.metadata.name } },
                    ],
                    resources: {
                        requests: { cpu: "100m", memory: "128Mi" },
                        limits: { cpu: "500m", memory: "512Mi" },
                    },
                    livenessProbe: {
                        httpGet: { path: "/health", port: 8080 },
                        initialDelaySeconds: 30,
                        periodSeconds: 10,
                    },
                    readinessProbe: {
                        httpGet: { path: "/ready", port: 8080 },
                        initialDelaySeconds: 5,
                        periodSeconds: 5,
                    },
                }],
            },
        },
    },
}, { provider: k8sProvider });

// Service
const service = new k8s.core.v1.Service("app-service", {
    metadata: {
        name: "myapp",
        namespace: namespace.metadata.name,
    },
    spec: {
        type: "ClusterIP",
        selector: { app: "myapp" },
        ports: [{
            port: 80,
            targetPort: 8080,
        }],
    },
}, { provider: k8sProvider });

// Ingress
const ingress = new k8s.networking.v1.Ingress("app-ingress", {
    metadata: {
        name: "myapp",
        namespace: namespace.metadata.name,
        annotations: {
            "kubernetes.io/ingress.class": "nginx",
            "cert-manager.io/cluster-issuer": "letsencrypt-prod",
        },
    },
    spec: {
        tls: [{
            hosts: ["myapp.example.com"],
            secretName: "myapp-tls",
        }],
        rules: [{
            host: "myapp.example.com",
            http: {
                paths: [{
                    path: "/",
                    pathType: "Prefix",
                    backend: {
                        service: {
                            name: service.metadata.name,
                            port: { number: 80 },
                        },
                    },
                }],
            },
        }],
    },
}, { provider: k8sProvider });

export const appUrl = pulumi.interpolate`https://myapp.example.com`;
```

### Multi-Environment Deployment

```typescript
// multi-env/index.ts
import * as pulumi from "@pulumi/pulumi";
import * as aws from "@pulumi/aws";

const stack = pulumi.getStack();
const config = new pulumi.Config();

// Environment-specific configuration
const envConfig: Record<string, {
    instanceType: string;
    minSize: number;
    maxSize: number;
    multiAz: boolean;
    enableDeletionProtection: boolean;
}> = {
    dev: {
        instanceType: "t3.small",
        minSize: 1,
        maxSize: 2,
        multiAz: false,
        enableDeletionProtection: false,
    },
    staging: {
        instanceType: "t3.medium",
        minSize: 2,
        maxSize: 4,
        multiAz: true,
        enableDeletionProtection: false,
    },
    prod: {
        instanceType: "t3.large",
        minSize: 3,
        maxSize: 10,
        multiAz: true,
        enableDeletionProtection: true,
    },
};

const settings = envConfig[stack] || envConfig.dev;

// Apply environment-specific resources
const asg = new aws.autoscaling.Group("app-asg", {
    minSize: settings.minSize,
    maxSize: settings.maxSize,
    desiredCapacity: settings.minSize,
    launchTemplate: {
        id: launchTemplate.id,
        version: "$Latest",
    },
    vpcZoneIdentifiers: privateSubnetIds,
    tags: [{
        key: "Environment",
        value: stack,
        propagateAtLaunch: true,
    }],
});

const rds = new aws.rds.Instance("app-db", {
    instanceClass: `db.${settings.instanceType}`,
    multiAz: settings.multiAz,
    deletionProtection: settings.enableDeletionProtection,
    // ... other config
});
```

## CI/CD Integration

### GitHub Actions

```yaml
# .github/workflows/pulumi.yaml
name: Pulumi Infrastructure

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

env:
  PULUMI_ACCESS_TOKEN: ${{ secrets.PULUMI_ACCESS_TOKEN }}
  AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
  AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
  AWS_REGION: us-west-2

jobs:
  preview:
    name: Preview
    runs-on: ubuntu-latest
    if: github.event_name == 'pull_request'
    steps:
      - uses: actions/checkout@v4
      
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
      
      - name: Install dependencies
        run: npm ci
      
      - uses: pulumi/actions@v5
        with:
          command: preview
          stack-name: org/myproject/dev
          comment-on-pr: true
          github-token: ${{ secrets.GITHUB_TOKEN }}

  deploy-dev:
    name: Deploy to Dev
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    steps:
      - uses: actions/checkout@v4
      
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
      
      - name: Install dependencies
        run: npm ci
      
      - uses: pulumi/actions@v5
        with:
          command: up
          stack-name: org/myproject/dev

  deploy-prod:
    name: Deploy to Prod
    runs-on: ubuntu-latest
    needs: deploy-dev
    if: github.ref == 'refs/heads/main'
    environment: production
    steps:
      - uses: actions/checkout@v4
      
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
      
      - name: Install dependencies
        run: npm ci
      
      - uses: pulumi/actions@v5
        with:
          command: up
          stack-name: org/myproject/prod
```

### GitLab CI

```yaml
# .gitlab-ci.yml
image: node:20

stages:
  - preview
  - deploy-dev
  - deploy-staging
  - deploy-prod

variables:
  PULUMI_ACCESS_TOKEN: ${PULUMI_ACCESS_TOKEN}
  AWS_ACCESS_KEY_ID: ${AWS_ACCESS_KEY_ID}
  AWS_SECRET_ACCESS_KEY: ${AWS_SECRET_ACCESS_KEY}
  AWS_REGION: us-west-2

.pulumi-template: &pulumi-template
  before_script:
    - curl -fsSL https://get.pulumi.com | sh
    - export PATH=$PATH:$HOME/.pulumi/bin
    - npm ci

preview:
  <<: *pulumi-template
  stage: preview
  script:
    - pulumi preview --stack dev --non-interactive
  only:
    - merge_requests

deploy-dev:
  <<: *pulumi-template
  stage: deploy-dev
  script:
    - pulumi up --stack dev --yes --non-interactive
  only:
    - main

deploy-staging:
  <<: *pulumi-template
  stage: deploy-staging
  script:
    - pulumi up --stack staging --yes --non-interactive
  only:
    - main
  when: manual

deploy-prod:
  <<: *pulumi-template
  stage: deploy-prod
  script:
    - pulumi up --stack prod --yes --non-interactive
  only:
    - main
  when: manual
  environment:
    name: production
```

## Testing

### Unit Testing

```typescript
// __tests__/vpc.test.ts
import * as pulumi from "@pulumi/pulumi";
import "jest";

// Mock Pulumi runtime
pulumi.runtime.setMocks({
    newResource: (args: pulumi.runtime.MockResourceArgs) => {
        return {
            id: `${args.name}-id`,
            state: {
                ...args.inputs,
                arn: `arn:aws:${args.type}:us-west-2:123456789:${args.name}`,
            },
        };
    },
    call: (args: pulumi.runtime.MockCallArgs) => {
        return args.inputs;
    },
});

describe("VPC Component", () => {
    let infra: typeof import("../index");

    beforeAll(async () => {
        infra = await import("../index");
    });

    test("VPC has correct CIDR block", async () => {
        const cidr = await new Promise<string>((resolve) => 
            infra.vpcCidr.apply(resolve)
        );
        expect(cidr).toBe("10.0.0.0/16");
    });

    test("Creates correct number of subnets", async () => {
        const publicSubnets = await new Promise<string[]>((resolve) =>
            pulumi.all(infra.publicSubnetIds).apply(resolve)
        );
        expect(publicSubnets.length).toBe(3);
    });

    test("VPC has DNS support enabled", async () => {
        const dnsEnabled = await new Promise<boolean>((resolve) =>
            infra.vpcDnsSupport.apply(resolve)
        );
        expect(dnsEnabled).toBe(true);
    });
});
```

### Integration Testing

```typescript
// __tests__/integration/eks.test.ts
import * as automation from "@pulumi/pulumi/automation";
import * as k8s from "@kubernetes/client-node";
import { describe, test, expect, beforeAll, afterAll } from "@jest/globals";

describe("EKS Cluster Integration", () => {
    let stack: automation.Stack;
    let kubeconfig: string;

    beforeAll(async () => {
        // Create ephemeral stack for testing
        stack = await automation.LocalWorkspace.createOrSelectStack({
            stackName: `test-${Date.now()}`,
            workDir: "./",
        });

        await stack.setConfig("aws:region", { value: "us-west-2" });
        await stack.setConfig("myproject:environment", { value: "test" });

        // Deploy infrastructure
        const result = await stack.up({ onOutput: console.log });
        kubeconfig = result.outputs.kubeconfig.value;
    }, 600000); // 10 minute timeout

    afterAll(async () => {
        // Cleanup
        await stack.destroy({ onOutput: console.log });
        await stack.workspace.removeStack(stack.name);
    }, 300000);

    test("Cluster is accessible", async () => {
        const kc = new k8s.KubeConfig();
        kc.loadFromString(kubeconfig);

        const k8sApi = kc.makeApiClient(k8s.CoreV1Api);
        const nodes = await k8sApi.listNode();

        expect(nodes.body.items.length).toBeGreaterThan(0);
    });

    test("Cluster has correct node count", async () => {
        const kc = new k8s.KubeConfig();
        kc.loadFromString(kubeconfig);

        const k8sApi = kc.makeApiClient(k8s.CoreV1Api);
        const nodes = await k8sApi.listNode();

        expect(nodes.body.items.length).toBeGreaterThanOrEqual(2);
    });
});
```

### Policy Testing

```typescript
// policy/__tests__/security.test.ts
import * as policy from "@pulumi/policy";
import { PolicyTestHelpers } from "@pulumi/policy/test";

describe("Security Policies", () => {
    const helper = new PolicyTestHelpers();

    test("S3 buckets without encryption fail", async () => {
        const result = await helper.validateResource(
            "s3-encryption-required",
            {
                type: "aws:s3/bucket:Bucket",
                props: {
                    bucket: "my-bucket",
                    // Missing serverSideEncryptionConfiguration
                },
            }
        );
        expect(result.violations.length).toBe(1);
        expect(result.violations[0].message).toContain("encryption");
    });

    test("S3 buckets with encryption pass", async () => {
        const result = await helper.validateResource(
            "s3-encryption-required",
            {
                type: "aws:s3/bucket:Bucket",
                props: {
                    bucket: "my-bucket",
                    serverSideEncryptionConfiguration: {
                        rule: {
                            applyServerSideEncryptionByDefault: {
                                sseAlgorithm: "AES256",
                            },
                        },
                    },
                },
            }
        );
        expect(result.violations.length).toBe(0);
    });
});
```

## Import Existing Resources

### Import Command

```bash
# Import existing AWS resources
pulumi import aws:ec2/vpc:Vpc main-vpc vpc-1234567890abcdef0

# Import with custom name
pulumi import aws:s3/bucket:Bucket my-bucket my-existing-bucket-name

# Import multiple resources from file
pulumi import -f imports.json
```

### Import File Format

```json
{
    "resources": [
        {
            "type": "aws:ec2/vpc:Vpc",
            "name": "main-vpc",
            "id": "vpc-1234567890abcdef0"
        },
        {
            "type": "aws:ec2/subnet:Subnet",
            "name": "public-subnet-1",
            "id": "subnet-1234567890abcdef0"
        },
        {
            "type": "aws:rds/instance:Instance",
            "name": "main-db",
            "id": "my-database-instance"
        }
    ]
}
```

### Bulk Import Script

```typescript
// scripts/import-resources.ts
import * as automation from "@pulumi/pulumi/automation";
import * as aws from "aws-sdk";

async function importExistingResources() {
    const ec2 = new aws.EC2({ region: "us-west-2" });
    
    // Get existing VPCs
    const vpcs = await ec2.describeVpcs().promise();
    
    const stack = await automation.LocalWorkspace.selectStack({
        stackName: "dev",
        workDir: "./",
    });
    
    for (const vpc of vpcs.Vpcs || []) {
        const name = vpc.Tags?.find(t => t.Key === "Name")?.Value || vpc.VpcId;
        
        try {
            await stack.import({
                resources: [{
                    type: "aws:ec2/vpc:Vpc",
                    name: name!.replace(/[^a-zA-Z0-9-]/g, "-"),
                    id: vpc.VpcId!,
                }],
            });
            console.log(`Imported VPC: ${vpc.VpcId}`);
        } catch (err) {
            console.error(`Failed to import ${vpc.VpcId}:`, err);
        }
    }
}

importExistingResources();
```

## Troubleshooting

| Issue | Cause | Solution |
|-------|-------|----------|
| `error: no Pulumi.yaml found` | Not in project directory | Run `pulumi new` or `cd` to project root |
| `error: stack 'x' not found` | Stack doesn't exist | Run `pulumi stack init <name>` |
| `error: resource already exists` | Resource created outside Pulumi | Use `pulumi import` to adopt resource |
| `error: update failed` | Deployment conflict | Check `pulumi stack export` for state issues |
| `error: A]WS credentials not found` | Missing credentials | Run `aws configure` or set env vars |
| `preview failed: resource plugin not found` | Missing provider | Run `npm install @pulumi/<provider>` |
| `error: secrets provider not configured` | Missing secrets backend | Set `pulumi:secrets:provider` in config |
| `error: state file locked` | Concurrent operation | Wait or run `pulumi cancel` |
| `checksum mismatch` | Corrupted state | Export state, fix, reimport |
| `timeout waiting for resource` | Slow resource creation | Increase timeout in resource options |

### Debug Mode

```bash
# Enable verbose logging
pulumi up --debug

# Log to file
pulumi up --debug --logflow --logtostderr 2>&1 | tee pulumi.log

# Trace specific resource
PULUMI_DEBUG_COMMANDS=true pulumi up

# Show detailed diffs
pulumi preview --diff
```

### State Management

```bash
# Export state
pulumi stack export --file state.json

# Import state
pulumi stack import --file state.json

# Refresh state from cloud
pulumi refresh

# Force unlock state
pulumi cancel

# Delete resource from state (doesn't delete actual resource)
pulumi state delete 'urn:pulumi:dev::myproject::aws:s3/bucket:Bucket::my-bucket'
```

## Best Practices

### Code Organization

```
infrastructure/
├── Pulumi.yaml
├── Pulumi.dev.yaml
├── Pulumi.staging.yaml
├── Pulumi.prod.yaml
├── package.json
├── tsconfig.json
├── index.ts                 # Main entrypoint
├── config/
│   ├── index.ts             # Configuration loading
│   └── environments.ts      # Environment-specific settings
├── components/
│   ├── index.ts             # Component exports
│   ├── vpc.ts               # VPC component
│   ├── eks.ts               # EKS component
│   ├── rds.ts               # RDS component
│   └── monitoring.ts        # Monitoring component
├── stacks/
│   ├── network.ts           # Network resources
│   ├── compute.ts           # Compute resources
│   └── database.ts          # Database resources
├── policies/
│   ├── package.json
│   ├── index.ts
│   └── rules/
│       ├── security.ts
│       └── cost.ts
└── __tests__/
    ├── unit/
    └── integration/
```

### Security Checklist

- [ ] Never commit secrets to version control
- [ ] Use `pulumi config set --secret` for sensitive values
- [ ] Enable encryption for all storage resources
- [ ] Use least-privilege IAM roles
- [ ] Enable VPC flow logs
- [ ] Use private subnets for databases
- [ ] Enable deletion protection for production resources
- [ ] Use CrossGuard policies to enforce security standards
- [ ] Regularly rotate secrets and credentials
- [ ] Enable CloudTrail for audit logging

### Performance Tips

```typescript
// Use explicit dependencies to parallelize
const bucket1 = new aws.s3.Bucket("bucket1");
const bucket2 = new aws.s3.Bucket("bucket2");
// These create in parallel

// Group related resources with ComponentResource
class MyComponent extends pulumi.ComponentResource {
    constructor(name: string, opts?: pulumi.ComponentResourceOptions) {
        super("custom:MyComponent", name, {}, opts);
        // All child resources deploy together
    }
}

// Use transformations for cross-cutting concerns
pulumi.runtime.registerStackTransformation((args) => {
    // Apply tags to all resources at once
    return { props: args.props, opts: args.opts };
});
```

### Resource Naming Conventions

```typescript
const config = new pulumi.Config();
const environment = config.require("environment");
const project = pulumi.getProject();

// Consistent naming pattern
function resourceName(type: string, name: string): string {
    return `${project}-${environment}-${type}-${name}`;
}

// Usage
const vpc = new aws.ec2.Vpc(resourceName("vpc", "main"), {
    tags: {
        Name: resourceName("vpc", "main"),
        Environment: environment,
        Project: project,
        ManagedBy: "pulumi",
    },
});
```

## CLI Reference

| Command | Description |
|---------|-------------|
| `pulumi new <template>` | Create new project from template |
| `pulumi stack init <name>` | Create new stack |
| `pulumi stack select <name>` | Switch to stack |
| `pulumi config set <key> <value>` | Set configuration |
| `pulumi config set --secret <key> <value>` | Set secret configuration |
| `pulumi preview` | Preview changes |
| `pulumi up` | Deploy changes |
| `pulumi refresh` | Sync state with cloud |
| `pulumi destroy` | Destroy all resources |
| `pulumi stack export` | Export stack state |
| `pulumi stack import` | Import stack state |
| `pulumi import <type> <name> <id>` | Import existing resource |
| `pulumi logs` | View resource logs |
| `pulumi watch` | Watch for changes and auto-deploy |

## Related Resources

- [Pulumi Documentation](https://www.pulumi.com/docs/)
- [Pulumi Registry](https://www.pulumi.com/registry/)
- [Pulumi Examples](https://github.com/pulumi/examples)
- [Pulumi Blog](https://www.pulumi.com/blog/)
- [Pulumi Community Slack](https://slack.pulumi.com/)
