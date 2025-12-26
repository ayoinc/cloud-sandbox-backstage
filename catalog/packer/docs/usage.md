# Usage Guide

## Getting Started

### Prerequisites

| Requirement | Version | Installation                    |
| ----------- | ------- | ------------------------------- |
| Packer      | 1.10+   | `brew install packer`           |
| AWS CLI     | 2.x     | `brew install awscli`           |
| Azure CLI   | 2.x     | `brew install azure-cli`        |
| gcloud CLI  | Latest  | `brew install google-cloud-sdk` |
| Ansible     | 2.15+   | `pip install ansible`           |

### Installation

```bash
# Install Packer
brew install packer

# Or download directly
curl -fsSL https://releases.hashicorp.com/packer/1.10.0/packer_1.10.0_darwin_amd64.zip -o packer.zip
unzip packer.zip
sudo mv packer /usr/local/bin/

# Verify installation
packer version
# Packer v1.10.0

# Initialize plugins
cd packer/templates/aws
packer init .

# Validate template
packer validate .
```

### Cloud Authentication

```bash
# AWS
export AWS_ACCESS_KEY_ID="AKIA..."
export AWS_SECRET_ACCESS_KEY="..."
export AWS_DEFAULT_REGION="us-west-2"
# Or use AWS SSO
aws sso login --profile company-dev

# Azure
az login
az account set --subscription "subscription-id"
# Or use service principal
export ARM_CLIENT_ID="..."
export ARM_CLIENT_SECRET="..."
export ARM_SUBSCRIPTION_ID="..."
export ARM_TENANT_ID="..."

# GCP
gcloud auth application-default login
export GOOGLE_PROJECT="my-project"
# Or use service account
export GOOGLE_APPLICATION_CREDENTIALS="/path/to/key.json"
```

## Examples

### Basic AWS AMI Build

```hcl
# aws-simple.pkr.hcl
packer {
  required_plugins {
    amazon = {
      version = ">= 1.3.0"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

variable "version" {
  type    = string
  default = "1.0.0"
}

data "amazon-ami" "ubuntu" {
  filters = {
    name                = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"
    root-device-type    = "ebs"
    virtualization-type = "hvm"
  }
  most_recent = true
  owners      = ["099720109477"]
}

source "amazon-ebs" "ubuntu" {
  ami_name      = "my-app-${var.version}-{{timestamp}}"
  instance_type = "t3.medium"
  region        = "us-west-2"
  source_ami    = data.amazon-ami.ubuntu.id
  ssh_username  = "ubuntu"

  tags = {
    Name        = "my-app-${var.version}"
    Environment = "production"
    ManagedBy   = "packer"
  }
}

build {
  sources = ["source.amazon-ebs.ubuntu"]

  provisioner "shell" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y nginx",
      "sudo systemctl enable nginx"
    ]
  }
}
```

```bash
# Build the AMI
packer build aws-simple.pkr.hcl

# Build with custom version
packer build -var "version=2.0.0" aws-simple.pkr.hcl
```

### Multi-Cloud Build

```hcl
# multi-cloud.pkr.hcl
packer {
  required_plugins {
    amazon = {
      version = ">= 1.3.0"
      source  = "github.com/hashicorp/amazon"
    }
    azure = {
      version = ">= 2.0.0"
      source  = "github.com/hashicorp/azure"
    }
    googlecompute = {
      version = ">= 1.1.0"
      source  = "github.com/hashicorp/googlecompute"
    }
  }
}

variable "version" {
  type    = string
  default = "1.0.0"
}

# AWS Source
source "amazon-ebs" "ubuntu" {
  ami_name      = "company-app-${var.version}-{{timestamp}}"
  instance_type = "t3.medium"
  region        = "us-west-2"
  source_ami_filter {
    filters = {
      name                = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"
      virtualization-type = "hvm"
    }
    owners      = ["099720109477"]
    most_recent = true
  }
  ssh_username = "ubuntu"
}

# Azure Source
source "azure-arm" "ubuntu" {
  use_azure_cli_auth = true
  os_type            = "Linux"
  image_publisher    = "Canonical"
  image_offer        = "0001-com-ubuntu-server-jammy"
  image_sku          = "22_04-lts-gen2"
  location           = "westus2"
  vm_size            = "Standard_D2s_v3"

  managed_image_name                = "company-app-${var.version}"
  managed_image_resource_group_name = "packer-images-rg"
}

# GCP Source
source "googlecompute" "ubuntu" {
  project_id          = "my-project"
  source_image_family = "ubuntu-2204-lts"
  zone                = "us-central1-a"
  machine_type        = "e2-medium"
  image_name          = "company-app-${replace(var.version, ".", "-")}"
  image_family        = "company-app"
  ssh_username        = "ubuntu"
}

build {
  sources = [
    "source.amazon-ebs.ubuntu",
    "source.azure-arm.ubuntu",
    "source.googlecompute.ubuntu"
  ]

  provisioner "shell" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get upgrade -y"
    ]
  }

  provisioner "shell" {
    script = "scripts/install-app.sh"
  }

  post-processor "manifest" {
    output = "manifest.json"
  }
}
```

```bash
# Build all platforms
packer build multi-cloud.pkr.hcl

# Build specific platform
packer build -only="amazon-ebs.ubuntu" multi-cloud.pkr.hcl
packer build -only="azure-arm.ubuntu" multi-cloud.pkr.hcl
packer build -only="googlecompute.ubuntu" multi-cloud.pkr.hcl

# Build multiple (exclude one)
packer build -except="azure-arm.ubuntu" multi-cloud.pkr.hcl
```

### Variables File Usage

```hcl
# variables.pkrvars.hcl
version     = "2.0.0"
environment = "prod"
aws_region  = "us-east-1"
instance_type = "t3.large"

tags = {
  Team      = "platform"
  CostCenter = "engineering"
  ManagedBy  = "packer"
}
```

```bash
# Use variables file
packer build -var-file="variables.pkrvars.hcl" .

# Override specific variable
packer build -var-file="variables.pkrvars.hcl" -var "version=2.1.0" .

# Use environment variables
export PKR_VAR_version="2.1.0"
export PKR_VAR_environment="staging"
packer build .
```

### Ansible Provisioning

```hcl
# with-ansible.pkr.hcl
build {
  sources = ["source.amazon-ebs.ubuntu"]

  provisioner "ansible" {
    playbook_file = "ansible/playbook.yml"
    user          = "ubuntu"
    use_proxy     = false

    extra_arguments = [
      "--extra-vars", "environment=${var.environment}",
      "--extra-vars", "app_version=${var.version}",
      "-vv"
    ]

    ansible_env_vars = [
      "ANSIBLE_HOST_KEY_CHECKING=False",
      "ANSIBLE_SSH_ARGS='-o ForwardAgent=yes -o ControlMaster=auto -o ControlPersist=60s'"
    ]

    # Use Ansible vault for secrets
    # ansible_vault_password_file = "vault-password.txt"
  }
}
```

```yaml
# ansible/playbook.yml
---
- name: Configure application server
  hosts: all
  become: true

  vars:
    app_version: "{{ lookup('env', 'APP_VERSION') | default('latest') }}"

  roles:
    - role: common
    - role: security
    - role: docker
    - role: monitoring

  tasks:
    - name: Deploy application
      ansible.builtin.include_role:
        name: app
      vars:
        version: '{{ app_version }}'
```

## CI/CD Integration

### GitHub Actions

```yaml
# .github/workflows/packer-build.yaml
name: Build Machine Images

on:
  push:
    branches: [main]
    paths:
      - 'packer/**'
  pull_request:
    branches: [main]
    paths:
      - 'packer/**'
  workflow_dispatch:
    inputs:
      version:
        description: 'Image version'
        required: true
        default: '1.0.0'
      environment:
        description: 'Target environment'
        required: true
        default: 'dev'
        type: choice
        options:
          - dev
          - staging
          - prod

env:
  PACKER_VERSION: '1.10.0'

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Packer
        uses: hashicorp/setup-packer@main
        with:
          version: ${{ env.PACKER_VERSION }}

      - name: Initialize Packer
        run: packer init packer/templates/aws

      - name: Validate Template
        run: packer validate packer/templates/aws

      - name: Format Check
        run: packer fmt -check -recursive packer/

  build-dev:
    needs: validate
    if: github.ref == 'refs/heads/main' || github.event_name == 'workflow_dispatch'
    runs-on: ubuntu-latest
    environment: development

    steps:
      - uses: actions/checkout@v4

      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: us-west-2

      - name: Setup Packer
        uses: hashicorp/setup-packer@main
        with:
          version: ${{ env.PACKER_VERSION }}

      - name: Initialize Packer
        run: packer init packer/templates/aws

      - name: Build AMI
        run: |
          packer build \
            -var "version=${{ github.event.inputs.version || '1.0.0' }}" \
            -var "environment=${{ github.event.inputs.environment || 'dev' }}" \
            packer/templates/aws

      - name: Upload Manifest
        uses: actions/upload-artifact@v4
        with:
          name: packer-manifest
          path: manifest.json

  build-prod:
    needs: build-dev
    if: github.event.inputs.environment == 'prod'
    runs-on: ubuntu-latest
    environment: production

    steps:
      - uses: actions/checkout@v4

      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID_PROD }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY_PROD }}
          aws-region: us-east-1

      - name: Setup Packer
        uses: hashicorp/setup-packer@main
        with:
          version: ${{ env.PACKER_VERSION }}

      - name: Build Production AMI
        run: |
          packer build \
            -var "version=${{ github.event.inputs.version }}" \
            -var "environment=prod" \
            -var-file="packer/variables/prod.pkrvars.hcl" \
            packer/templates/aws
```

### GitLab CI

```yaml
# .gitlab-ci.yml
stages:
  - validate
  - build-dev
  - build-prod

variables:
  PACKER_VERSION: '1.10.0'

.packer-setup:
  before_script:
    - wget -q https://releases.hashicorp.com/packer/${PACKER_VERSION}/packer_${PACKER_VERSION}_linux_amd64.zip
    - unzip -q packer_${PACKER_VERSION}_linux_amd64.zip
    - mv packer /usr/local/bin/
    - packer init packer/templates/aws

validate:
  stage: validate
  extends: .packer-setup
  script:
    - packer validate packer/templates/aws
    - packer fmt -check -recursive packer/
  only:
    changes:
      - packer/**

build-dev:
  stage: build-dev
  extends: .packer-setup
  script:
    - packer build -var "version=${CI_COMMIT_SHORT_SHA}" -var "environment=dev" packer/templates/aws
  artifacts:
    paths:
      - manifest.json
  only:
    - main
  environment:
    name: development

build-prod:
  stage: build-prod
  extends: .packer-setup
  script:
    - packer build -var "version=${CI_COMMIT_TAG}" -var "environment=prod" packer/templates/aws
  only:
    - tags
  environment:
    name: production
  when: manual
```

## Advanced Topics

### Parallel Builds with Limits

```bash
# Limit parallel builds
packer build -parallel-builds=2 multi-cloud.pkr.hcl

# Force sequential builds
packer build -parallel-builds=1 multi-cloud.pkr.hcl
```

### Debug Mode

```bash
# Enable debug output
PACKER_LOG=1 packer build .

# Log to file
PACKER_LOG=1 PACKER_LOG_PATH=packer.log packer build .

# Step-by-step debug
packer build -debug .
```

### Using Data Sources

```hcl
# Query AWS for VPC and subnet
data "amazon-ami" "ubuntu" {
  filters = {
    name = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"
  }
  most_recent = true
  owners      = ["099720109477"]
}

data "amazon-secretsmanager" "api_key" {
  name = "packer/api-key"
}

locals {
  api_key = jsondecode(data.amazon-secretsmanager.api_key.secret_string)["key"]
}

source "amazon-ebs" "ubuntu" {
  source_ami = data.amazon-ami.ubuntu.id
  # ...
}

build {
  sources = ["source.amazon-ebs.ubuntu"]

  provisioner "shell" {
    environment_vars = [
      "API_KEY=${local.api_key}"
    ]
    inline = ["echo 'API key configured'"]
  }
}
```

### Post-Processors Chain

```hcl
build {
  sources = ["source.amazon-ebs.ubuntu"]

  # First post-processor: generate manifest
  post-processor "manifest" {
    output     = "manifest.json"
    strip_path = true
  }

  # Second post-processor: generate checksum
  post-processor "checksum" {
    checksum_types = ["sha256"]
    output         = "checksums.txt"
  }

  # Post-processor sequence (runs in order)
  post-processors {
    post-processor "shell-local" {
      inline = ["echo 'AMI ID: {{.ArtifactId}}'"]
    }

    post-processor "shell-local" {
      inline = ["./scripts/notify-slack.sh {{.ArtifactId}}"]
    }
  }
}
```

## Troubleshooting

| Issue                      | Cause                    | Solution                          |
| -------------------------- | ------------------------ | --------------------------------- |
| `Plugin not found`         | Plugins not initialized  | Run `packer init .`               |
| `403 Access Denied`        | Insufficient permissions | Check IAM/RBAC permissions        |
| `SSH connection failed`    | Security group blocking  | Allow SSH from builder IP         |
| `Timeout waiting for SSH`  | Instance not ready       | Increase `ssh_timeout`            |
| `AMI already exists`       | Name collision           | Use `{{timestamp}}` in name       |
| `Instance failed to start` | Capacity issues          | Try different AZ or instance type |
| `Provisioner failed`       | Script error             | Check script locally first        |
| `VPC not found`            | Invalid VPC ID           | Verify VPC exists in region       |

### Debug Commands

```bash
# Validate template
packer validate .

# Format check
packer fmt -check -diff .

# Show template structure
packer inspect .

# Debug build (stops at each step)
packer build -debug .

# On-error behavior
packer build -on-error=ask .     # Prompt
packer build -on-error=abort .   # Stop immediately
packer build -on-error=cleanup . # Cleanup resources
packer build -on-error=run-cleanup-provisioner . # Run cleanup

# Force build (overwrite existing)
packer build -force .
```

## Best Practices

### Template Organization

- [ ] Use HCL2 format (not legacy JSON)
- [ ] Separate variables into pkrvars.hcl files
- [ ] Use data sources for dynamic values
- [ ] Keep provisioner scripts in separate files
- [ ] Use meaningful naming conventions

### Security

- [ ] Never hardcode credentials
- [ ] Use IAM roles/managed identities
- [ ] Encrypt AMIs with KMS
- [ ] Remove SSH keys after build
- [ ] Clear command history
- [ ] Run security hardening scripts

### CI/CD

- [ ] Validate templates in CI
- [ ] Use version tags for builds
- [ ] Store manifests as artifacts
- [ ] Implement approval gates for prod
- [ ] Clean up old images periodically

### Performance

- [ ] Use fast instance types for building
- [ ] Leverage build caching where possible
- [ ] Run parallel builds when independent
- [ ] Use regional base images

## CLI Reference

| Command                         | Description            |
| ------------------------------- | ---------------------- |
| `packer init`                   | Initialize plugins     |
| `packer validate`               | Validate template      |
| `packer fmt`                    | Format HCL files       |
| `packer inspect`                | Show template info     |
| `packer build`                  | Build images           |
| `packer build -only`            | Build specific sources |
| `packer build -except`          | Exclude sources        |
| `packer build -var`             | Set variable           |
| `packer build -var-file`        | Use variables file     |
| `packer build -parallel-builds` | Limit parallelism      |
| `packer build -debug`           | Step-by-step debug     |
| `packer build -force`           | Force overwrite        |
| `packer build -on-error`        | Error handling         |
| `packer plugins`                | Manage plugins         |

## Related Resources

- [Packer Documentation](https://developer.hashicorp.com/packer/docs)
- [Packer Plugins Registry](https://developer.hashicorp.com/packer/plugins)
- [HCL2 Templates](https://developer.hashicorp.com/packer/docs/templates/hcl_templates)
- [Packer Examples](https://github.com/hashicorp/packer/tree/main/examples)
- [AWS AMI Builder](https://developer.hashicorp.com/packer/plugins/builders/amazon)
- [Azure Image Builder](https://developer.hashicorp.com/packer/plugins/builders/azure)
