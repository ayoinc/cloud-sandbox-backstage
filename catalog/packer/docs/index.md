# Packer Image Builder

HashiCorp Packer for building identical machine images across multiple cloud providers and platforms.

## Quick Start

```bash
# Install Packer
brew install packer

# Initialize plugins
packer init .

# Validate template
packer validate .

# Build image
packer build .

# Build specific target
packer build -only="amazon-ebs.ubuntu" .

# Build with variables
packer build -var "version=1.0.0" -var "environment=prod" .
```

## Features

| Feature | Description | Status |
|---------|-------------|--------|
| Multi-Cloud | AWS, Azure, GCP, VMware support | Active |
| HCL2 Templates | Modern HashiCorp Configuration Language | Active |
| Parallel Builds | Build for multiple platforms simultaneously | Active |
| Provisioners | Shell, Ansible, Chef, Puppet integration | Active |
| Post-Processors | Compress, upload, manifest generation | Active |
| Variables | Environment, file, and CLI variables | Active |
| Data Sources | Dynamic data from external sources | Active |
| CI/CD Integration | GitHub Actions, GitLab CI templates | Active |

## Architecture

```
+------------------------------------------------------------------+
|                    PACKER BUILD PIPELINE                          |
+------------------------------------------------------------------+
|                                                                   |
|  +-------------------+    +-------------------+                   |
|  |   HCL2 Template   |    |   Variables       |                   |
|  |   *.pkr.hcl       |--->|   *.pkrvars.hcl   |                   |
|  |                   |    |   Environment     |                   |
|  +-------------------+    +-------------------+                   |
|                                  |                                |
|                                  v                                |
|  +-------------------+    +-------------------+                   |
|  |   Source Block    |    |   Builder         |                   |
|  |   Base Image      |--->|   amazon-ebs      |                   |
|  |   ISO/AMI/etc     |    |   azure-arm       |                   |
|  +-------------------+    +-------------------+                   |
|                                  |                                |
|                                  v                                |
|  +-------------------+    +-------------------+                   |
|  |   Provisioners    |    |   Post-Processors |                   |
|  |   Shell/Ansible   |--->|   Manifest        |                   |
|  |   File/Scripts    |    |   Compress        |                   |
|  +-------------------+    +-------------------+                   |
|                                  |                                |
|                                  v                                |
|  +--------------------------------------------------+            |
|  |              OUTPUT ARTIFACTS                     |            |
|  |  +------------+  +------------+  +------------+  |            |
|  |  | AWS AMI    |  | Azure Img  |  | GCP Image  |  |            |
|  |  | us-east-1  |  | West US 2  |  | us-central |  |            |
|  |  +------------+  +------------+  +------------+  |            |
|  +--------------------------------------------------+            |
|                                                                   |
+------------------------------------------------------------------+
```

## Available Templates

| Template | Cloud | Description | Base OS |
|----------|-------|-------------|---------|
| `aws-ubuntu` | AWS | Ubuntu 22.04 LTS | Ubuntu |
| `aws-amazon-linux` | AWS | Amazon Linux 2023 | AL2023 |
| `azure-ubuntu` | Azure | Ubuntu 22.04 LTS | Ubuntu |
| `gcp-ubuntu` | GCP | Ubuntu 22.04 LTS | Ubuntu |
| `vmware-ubuntu` | VMware | Ubuntu 22.04 LTS | Ubuntu |
| `docker-base` | Docker | Container base image | Alpine |

## Template Structure

```
packer/
├── templates/
│   ├── aws/
│   │   ├── ubuntu.pkr.hcl
│   │   ├── amazon-linux.pkr.hcl
│   │   └── variables.pkr.hcl
│   ├── azure/
│   │   ├── ubuntu.pkr.hcl
│   │   └── variables.pkr.hcl
│   └── gcp/
│       ├── ubuntu.pkr.hcl
│       └── variables.pkr.hcl
├── scripts/
│   ├── common/
│   │   ├── base.sh
│   │   ├── security.sh
│   │   └── cleanup.sh
│   └── app/
│       ├── docker.sh
│       └── monitoring.sh
├── ansible/
│   ├── playbook.yml
│   └── roles/
├── variables/
│   ├── dev.pkrvars.hcl
│   ├── staging.pkrvars.hcl
│   └── prod.pkrvars.hcl
└── plugins.pkr.hcl
```

## Packer Commands Reference

| Command | Description |
|---------|-------------|
| `packer init` | Initialize plugins |
| `packer validate` | Validate template syntax |
| `packer fmt` | Format HCL files |
| `packer inspect` | Show template components |
| `packer build` | Build images |
| `packer build -only` | Build specific sources |
| `packer build -except` | Exclude specific sources |
| `packer build -parallel-builds=N` | Limit parallel builds |

## Related Documentation

- [Overview](overview.md) - Template development, provisioners, and best practices
- [Usage](usage.md) - Building images and CI/CD integration
