# Pulumi Infrastructure Projects

Modern Infrastructure as Code using real programming languages (TypeScript, Python, Go, C#) for cloud resource provisioning across AWS, Azure, GCP, and Kubernetes.

## Quick Start

### Prerequisites

```bash
# Install Pulumi CLI
curl -fsSL https://get.pulumi.com | sh

# Or via package managers
brew install pulumi  # macOS
choco install pulumi  # Windows
snap install pulumi --classic  # Linux

# Verify installation
pulumi version
# v3.100.0

# Login to Pulumi Cloud (or use local backend)
pulumi login

# Or use local file backend
pulumi login --local
```

### Create Your First Project

```bash
# Create new project with TypeScript
mkdir my-infrastructure && cd my-infrastructure
pulumi new aws-typescript

# Or with Python
pulumi new aws-python

# Or with Go
pulumi new aws-go

# Preview changes
pulumi preview

# Deploy infrastructure
pulumi up

# View outputs
pulumi stack output

# Destroy when done
pulumi destroy
```

## Features

| Feature | Description | Benefit |
|---------|-------------|---------|
| **Real Languages** | TypeScript, Python, Go, C#, Java, YAML | IDE support, testing, abstractions |
| **Multi-Cloud** | AWS, Azure, GCP, Kubernetes, 100+ providers | Single workflow for all clouds |
| **State Management** | Pulumi Cloud, S3, Azure Blob, GCS | Collaboration, locking, history |
| **Policy as Code** | CrossGuard policies | Compliance enforcement |
| **Secrets Management** | Automatic encryption | Secure by default |
| **Component Resources** | Reusable abstractions | DRY infrastructure |
| **Stack References** | Cross-stack dependencies | Modular architecture |
| **Automation API** | Embed Pulumi in apps | Custom workflows |
| **Import** | Import existing resources | Migration path |
| **Refresh** | Sync state with reality | Drift detection |

## Architecture Overview

```
+------------------------------------------------------------------+
|                    Pulumi Project Structure                       |
+------------------------------------------------------------------+
|                                                                   |
|  pulumi-infrastructure/                                           |
|  ├── Pulumi.yaml              # Project definition                |
|  ├── Pulumi.dev.yaml          # Dev stack config                  |
|  ├── Pulumi.staging.yaml      # Staging stack config              |
|  ├── Pulumi.production.yaml   # Production stack config           |
|  │                                                                |
|  ├── index.ts                 # Main program (TypeScript)         |
|  ├── package.json             # Node.js dependencies              |
|  ├── tsconfig.json            # TypeScript config                 |
|  │                                                                |
|  ├── components/              # Reusable components               |
|  │   ├── vpc.ts               # VPC component                     |
|  │   ├── eks-cluster.ts       # EKS cluster component             |
|  │   ├── rds-database.ts      # RDS component                     |
|  │   └── index.ts             # Component exports                 |
|  │                                                                |
|  ├── config/                  # Configuration helpers             |
|  │   ├── networking.ts        # Network config                    |
|  │   └── sizing.ts            # Instance sizing                   |
|  │                                                                |
|  └── policies/                # CrossGuard policies               |
|      ├── security.ts          # Security policies                 |
|      └── cost.ts              # Cost policies                     |
|                                                                   |
+------------------------------------------------------------------+
           |
           v
+------------------------------------------------------------------+
|                    Pulumi Execution Flow                          |
+------------------------------------------------------------------+
|                                                                   |
|  1. pulumi up                                                     |
|     └── Parse Pulumi.yaml                                         |
|         └── Load stack config (Pulumi.{stack}.yaml)               |
|             └── Execute program (index.ts)                        |
|                 └── Build resource graph                          |
|                     └── Compare with state                        |
|                         └── Generate plan                         |
|                             └── Apply changes                     |
|                                 └── Update state                  |
|                                                                   |
+------------------------------------------------------------------+
```

## Supported Languages

| Language | Template | Package Manager |
|----------|----------|-----------------|
| TypeScript | `aws-typescript` | npm/yarn |
| JavaScript | `aws-javascript` | npm/yarn |
| Python | `aws-python` | pip/poetry |
| Go | `aws-go` | go modules |
| C# | `aws-csharp` | NuGet |
| Java | `aws-java` | Maven/Gradle |
| YAML | `aws-yaml` | N/A |

## Project Structure

```
my-pulumi-project/
├── Pulumi.yaml                 # Project metadata
├── Pulumi.dev.yaml             # Dev environment config
├── Pulumi.staging.yaml         # Staging environment config
├── Pulumi.production.yaml      # Production environment config
├── index.ts                    # Main entry point
├── package.json                # Dependencies
├── tsconfig.json               # TypeScript config
├── components/                 # Reusable components
│   ├── networking/
│   │   ├── vpc.ts
│   │   └── security-groups.ts
│   ├── compute/
│   │   ├── eks.ts
│   │   └── ec2.ts
│   └── database/
│       ├── rds.ts
│       └── dynamodb.ts
└── __tests__/                  # Unit tests
    └── infrastructure.test.ts
```

## CLI Commands

```bash
# Project management
pulumi new <template>           # Create new project
pulumi stack init <name>        # Create new stack
pulumi stack select <name>      # Switch stacks
pulumi stack ls                 # List stacks

# Deployment
pulumi preview                  # Preview changes
pulumi up                       # Deploy changes
pulumi up --yes                 # Deploy without confirmation
pulumi refresh                  # Sync state with cloud
pulumi destroy                  # Tear down resources

# Configuration
pulumi config set <key> <value>           # Set config value
pulumi config set --secret <key> <value>  # Set secret
pulumi config get <key>                   # Get config value

# State management
pulumi stack export > state.json   # Export state
pulumi stack import < state.json   # Import state
pulumi state delete <urn>          # Remove resource from state

# Outputs
pulumi stack output                # Show all outputs
pulumi stack output <name>         # Show specific output
pulumi stack output --json         # JSON format
```

## Related Documentation

- [Overview](overview.md) - Deep dive into components, patterns, and configuration
- [Usage](usage.md) - Deployment examples, testing, and troubleshooting
