# ${{ values.name }}

${{ values.description }}

## Overview

This Packer template creates immutable machine images for deployment across cloud providers and virtualization platforms. It supports multi-cloud builds (AWS AMI, Azure Managed Images, GCP Compute Images) with a unified CI/CD pipeline that includes validation, security scanning, and automated image lifecycle management.

Key features:

- Multi-cloud support (AWS, Azure, GCP, VMware)
- Automated security scanning with Trivy and TruffleHog
- CI/CD pipeline with GitHub Actions
- Image versioning based on git commits
- Automated cleanup of old images
- Customizable provisioners for software installation

```d2
direction: down

title: {
  label: Packer Build Process
  near: top-center
  shape: text
  style.font-size: 24
  style.bold: true
}

sources: Source Images {
  style.fill: "#E3F2FD"
  style.stroke: "#1976D2"

  aws: AWS AMI {
    shape: hexagon
    style.fill: "#FF9900"
    style.stroke: "#232F3E"
  }

  azure: Azure Image {
    shape: hexagon
    style.fill: "#0078D4"
    style.stroke: "#002050"
  }

  gcp: GCP Image {
    shape: hexagon
    style.fill: "#4285F4"
    style.stroke: "#1A73E8"
  }
}

packer: Packer Build {
  style.fill: "#E8F5E9"
  style.stroke: "#388E3C"

  init: Initialize {
    label: "packer init"
  }

  validate: Validate {
    label: "packer validate"
  }

  build: Build {
    label: "packer build"
  }

  init -> validate -> build
}

provisioners: Provisioners {
  style.fill: "#FFF3E0"
  style.stroke: "#FF9800"

  shell: Shell Scripts {
    shape: document
  }

  ansible: Ansible Playbooks {
    shape: document
  }

  file: File Uploads {
    shape: document
  }
}

postprocessors: Post-Processors {
  style.fill: "#FCE4EC"
  style.stroke: "#C2185B"

  manifest: Manifest {
    label: "Image IDs"
    shape: cylinder
  }

  compress: Compress {
    label: "Archive"
  }

  checksum: Checksum {
    label: "Verify"
  }
}

outputs: Output Images {
  style.fill: "#E8F5E9"
  style.stroke: "#388E3C"

  ami: AWS AMI {
    shape: hexagon
    style.fill: "#FF9900"
  }

  managed: Azure Managed Image {
    shape: hexagon
    style.fill: "#0078D4"
  }

  compute: GCP Compute Image {
    shape: hexagon
    style.fill: "#4285F4"
  }
}

sources -> packer.init
packer.build -> provisioners
provisioners -> postprocessors
postprocessors -> outputs
```

---

## Configuration Summary

| Setting         | Value                              |
| --------------- | ---------------------------------- |
| Image Name      | `${{ values.name }}`               |
| Cloud Provider  | `${{ values.cloud_provider }}`     |
| Base OS         | `${{ values.base_os }}`            |
| Region          | `${{ values.region }}`             |
| Instance Type   | `${{ values.instance_type }}`      |
| Owner           | `${{ values.owner }}`              |

---

## Template Structure

The Packer template follows HashiCorp's recommended project structure:

```
${{ values.name }}/
├── .github/
│   └── workflows/
│       └── packer.yaml       # CI/CD pipeline for building images
├── docs/
│   └── index.md              # This documentation
├── scripts/                  # Shell provisioner scripts (optional)
│   ├── base.sh               # Base system configuration
│   ├── security.sh           # Security hardening
│   └── cleanup.sh            # Build cleanup
├── ansible/                  # Ansible provisioners (optional)
│   └── playbook.yml
├── image.pkr.hcl             # Main Packer template
├── variables.pkr.hcl         # Variable definitions (optional)
├── catalog-info.yaml         # Backstage catalog entry
├── mkdocs.yml                # Documentation configuration
└── README.md                 # Quick start guide
```

### Template Components

| File                | Purpose                                               |
| ------------------- | ----------------------------------------------------- |
| `image.pkr.hcl`     | Main template with source, build, and provisioner blocks |
| `variables.pkr.hcl` | Centralized variable definitions with defaults        |
| `packer.yaml`       | GitHub Actions workflow for CI/CD automation          |
| `catalog-info.yaml` | Backstage service catalog registration                |

---

## CI/CD Pipeline

This repository includes a comprehensive GitHub Actions pipeline for automated image building:

- **Validation**: Format checking, syntax validation, linting
- **Security Scanning**: Trivy IaC scanner, TruffleHog for secrets detection
- **Multi-Cloud Builds**: Parallel builds for AWS, Azure, and GCP
- **Image Scanning**: Post-build vulnerability scanning
- **Lifecycle Management**: Automated cleanup of old images
- **Notifications**: Build summary and status reporting

### Pipeline Workflow

```d2
direction: right

trigger: Trigger {
  shape: oval
  style.fill: "#E3F2FD"
  style.stroke: "#1976D2"
  label: "Push/PR/\nManual"
}

validate: Validate {
  style.fill: "#E8F5E9"
  style.stroke: "#388E3C"
  label: "Format Check\nInit\nValidate"
}

security: Security {
  style.fill: "#FFCDD2"
  style.stroke: "#D32F2F"
  label: "Trivy Scan\nSecret Detection\nShellcheck"
}

builds: Parallel Builds {
  style.fill: "#E3F2FD"
  style.stroke: "#1976D2"

  aws: AWS AMI {
    style.fill: "#FF9900"
  }

  azure: Azure Image {
    style.fill: "#0078D4"
  }

  gcp: GCP Image {
    style.fill: "#4285F4"
  }
}

scan: Image Scan {
  style.fill: "#FCE4EC"
  style.stroke: "#C2185B"
  label: "Vulnerability\nScanning"
}

cleanup: Cleanup {
  style.fill: "#FFF3E0"
  style.stroke: "#FF9800"
  label: "Remove Old\nImages"
}

notify: Notify {
  shape: oval
  style.fill: "#E8F5E9"
  style.stroke: "#388E3C"
  label: "Build\nSummary"
}

trigger -> validate -> security -> builds
builds -> scan -> cleanup -> notify
```

### Pipeline Triggers

| Trigger           | Actions                                           |
| ----------------- | ------------------------------------------------- |
| Pull Request      | Validate, Security Scan (no build)                |
| Push to main      | Validate, Security Scan, Build all providers      |
| Manual Dispatch   | Select specific provider(s) and image template    |

---

## Prerequisites

### 1. Packer Installation

Install Packer 1.9 or later:

```bash
# macOS
brew install packer

# Ubuntu/Debian
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install packer

# Verify installation
packer version
```

### 2. Cloud Provider Credentials

#### AWS Credentials

```bash
# Option 1: Environment variables
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="${{ values.region }}"

# Option 2: AWS CLI profile
aws configure --profile packer

# Option 3: IAM Instance Profile (recommended for CI/CD)
# Attach role with required permissions to the build instance
```

**Required AWS IAM Permissions:**

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "PackerAMIBuilder",
      "Effect": "Allow",
      "Action": [
        "ec2:AttachVolume",
        "ec2:AuthorizeSecurityGroupIngress",
        "ec2:CopyImage",
        "ec2:CreateImage",
        "ec2:CreateKeypair",
        "ec2:CreateSecurityGroup",
        "ec2:CreateSnapshot",
        "ec2:CreateTags",
        "ec2:CreateVolume",
        "ec2:DeleteKeyPair",
        "ec2:DeleteSecurityGroup",
        "ec2:DeleteSnapshot",
        "ec2:DeleteVolume",
        "ec2:DeregisterImage",
        "ec2:DescribeImageAttribute",
        "ec2:DescribeImages",
        "ec2:DescribeInstances",
        "ec2:DescribeInstanceStatus",
        "ec2:DescribeRegions",
        "ec2:DescribeSecurityGroups",
        "ec2:DescribeSnapshots",
        "ec2:DescribeSubnets",
        "ec2:DescribeTags",
        "ec2:DescribeVolumes",
        "ec2:DetachVolume",
        "ec2:GetPasswordData",
        "ec2:ModifyImageAttribute",
        "ec2:ModifyInstanceAttribute",
        "ec2:ModifySnapshotAttribute",
        "ec2:RegisterImage",
        "ec2:RunInstances",
        "ec2:StopInstances",
        "ec2:TerminateInstances"
      ],
      "Resource": "*"
    }
  ]
}
```

#### Azure Credentials

```bash
# Environment variables for Azure
export ARM_CLIENT_ID="your-client-id"
export ARM_CLIENT_SECRET="your-client-secret"
export ARM_SUBSCRIPTION_ID="your-subscription-id"
export ARM_TENANT_ID="your-tenant-id"
export ARM_RESOURCE_GROUP="your-resource-group"
```

#### GCP Credentials

```bash
# Option 1: Service account key file
export GOOGLE_APPLICATION_CREDENTIALS="/path/to/credentials.json"

# Option 2: Application Default Credentials
gcloud auth application-default login

# Required GCP roles:
# - Compute Instance Admin (v1)
# - Service Account User
# - Storage Admin (for image export)
```

### 3. GitHub Repository Setup

#### Required Secrets

Configure these in **Settings > Secrets and variables > Actions**:

| Secret                   | Description                          | Provider |
| ------------------------ | ------------------------------------ | -------- |
| `AWS_ROLE_ARN`           | IAM role ARN for OIDC authentication | AWS      |
| `AZURE_CREDENTIALS`      | Azure service principal JSON         | Azure    |
| `AZURE_CLIENT_ID`        | Azure client ID                      | Azure    |
| `AZURE_CLIENT_SECRET`    | Azure client secret                  | Azure    |
| `AZURE_SUBSCRIPTION_ID`  | Azure subscription ID                | Azure    |
| `AZURE_TENANT_ID`        | Azure tenant ID                      | Azure    |
| `GCP_CREDENTIALS`        | GCP service account key JSON         | GCP      |
| `GCP_PROJECT_ID`         | GCP project ID                       | GCP      |

#### Required Variables

Configure these in **Settings > Secrets and variables > Actions > Variables**:

| Variable     | Description        | Default     |
| ------------ | ------------------ | ----------- |
| `AWS_REGION` | Default AWS region | `us-west-2` |

#### GitHub Environments

Create environments in **Settings > Environments**:

| Environment | Protection Rules         | Use Case                    |
| ----------- | ------------------------ | --------------------------- |
| `aws`       | None or required reviewers | AWS AMI builds             |
| `azure`     | Required reviewers       | Azure Managed Image builds  |
| `gcp`       | Required reviewers       | GCP Compute Image builds    |

---

## Usage

### Initialize Packer

```bash
# Initialize plugins
packer init image.pkr.hcl

# Or initialize all templates in a directory
packer init .
```

### Validate Template

```bash
# Syntax validation only
packer validate -syntax-only image.pkr.hcl

# Full validation (requires credentials)
packer validate image.pkr.hcl

# Check formatting
packer fmt -check image.pkr.hcl
```

### Build Images

```bash
# Build for all configured sources
packer build image.pkr.hcl

# Build for specific source
packer build -only=amazon-ebs.main image.pkr.hcl
packer build -only=azure-arm.main image.pkr.hcl
packer build -only=googlecompute.main image.pkr.hcl

# Build with custom variables
packer build \
  -var 'image_name=my-custom-image' \
  -var 'version=1.0.0' \
  image.pkr.hcl

# Build with variable file
packer build -var-file=production.pkrvars.hcl image.pkr.hcl
```

### Multi-Cloud Builds

Build images for multiple cloud providers simultaneously:

```bash
# Build for AWS and GCP only
packer build \
  -only='amazon-ebs.*' \
  -only='googlecompute.*' \
  image.pkr.hcl

# Exclude specific builders
packer build -except=azure-arm.main image.pkr.hcl
```

### Running the Pipeline

#### Automatic Triggers

| Trigger      | Actions                                         |
| ------------ | ----------------------------------------------- |
| Pull Request | Validate, Security Scan                         |
| Push to main | Validate, Security Scan, Build (all providers)  |

#### Manual Deployment

1. Navigate to **Actions** tab
2. Select **Packer Image CI/CD** workflow
3. Click **Run workflow**
4. Configure:
   - **image_name**: Template to build (default: `base`)
   - **cloud_provider**: `aws`, `azure`, `gcp`, or `all`
5. Click **Run workflow**

---

## Provisioner Examples

### Shell Provisioner

```hcl
build {
  sources = ["source.amazon-ebs.main"]

  provisioner "shell" {
    inline = [
      "sudo apt-get update -y",
      "sudo apt-get install -y nginx docker.io",
      "sudo systemctl enable nginx docker"
    ]
  }

  provisioner "shell" {
    scripts = [
      "scripts/base.sh",
      "scripts/security.sh",
      "scripts/cleanup.sh"
    ]
    execute_command = "sudo -S sh -c '{{ .Vars }} {{ .Path }}'"
  }
}
```

### File Provisioner

```hcl
provisioner "file" {
  source      = "configs/nginx.conf"
  destination = "/tmp/nginx.conf"
}

provisioner "shell" {
  inline = [
    "sudo mv /tmp/nginx.conf /etc/nginx/nginx.conf",
    "sudo nginx -t"
  ]
}
```

### Ansible Provisioner

```hcl
provisioner "ansible" {
  playbook_file = "ansible/playbook.yml"
  user          = "ubuntu"
  extra_arguments = [
    "-e", "environment=production",
    "-e", "app_version=1.0.0"
  ]
}
```

### PowerShell Provisioner (Windows)

```hcl
provisioner "powershell" {
  inline = [
    "Install-WindowsFeature -Name Web-Server -IncludeManagementTools",
    "Set-Service -Name W3SVC -StartupType Automatic"
  ]
}
```

---

## Image Versioning

### Naming Convention

Images are named using a consistent convention:

```
{image_name}-{timestamp}
```

Example: `${{ values.name }}-20231215T120000Z`

### Version Variables

Pass version information during builds:

```bash
packer build \
  -var "version=$(git rev-parse --short HEAD)" \
  -var "build_number=${GITHUB_RUN_NUMBER:-local}" \
  image.pkr.hcl
```

### Manifest Generation

Generate a manifest file with image IDs:

```hcl
post-processor "manifest" {
  output     = "manifest.json"
  strip_path = true
  custom_data = {
    version      = var.version
    build_number = var.build_number
    build_date   = timestamp()
    git_commit   = var.git_commit
  }
}
```

### Image Tags

Apply consistent tags to built images:

```hcl
source "amazon-ebs" "main" {
  # ... other configuration

  tags = {
    Name          = var.image_name
    Version       = var.version
    BuildNumber   = var.build_number
    BuildDate     = timestamp()
    GitCommit     = var.git_commit
    Environment   = "production"
    ManagedBy     = "packer"
    Owner         = "${{ values.owner }}"
  }
}
```

---

## Troubleshooting

### Debug Mode

Enable verbose logging:

```bash
# Set debug environment variable
PACKER_LOG=1 packer build image.pkr.hcl

# Log to file
PACKER_LOG=1 PACKER_LOG_PATH=packer.log packer build image.pkr.hcl

# Enable on-error debugging (stops on failure for inspection)
packer build -on-error=ask image.pkr.hcl
```

### Common Issues

#### SSH Connection Failures

**Error:** `Timeout waiting for SSH`

```bash
# Increase SSH timeout
packer build -var 'ssh_timeout=30m' image.pkr.hcl

# Check security group rules allow SSH (port 22) from builder
# Verify the SSH username matches the base image
```

#### Authentication Errors

**Error:** `No valid credential sources found`

```bash
# AWS: Verify credentials
aws sts get-caller-identity

# Azure: Verify service principal
az login --service-principal -u $ARM_CLIENT_ID -p $ARM_CLIENT_SECRET --tenant $ARM_TENANT_ID

# GCP: Verify service account
gcloud auth list
```

#### Plugin Issues

**Error:** `Plugin not found`

```bash
# Clear plugin cache and reinstall
rm -rf ~/.packer.d/plugins/
packer init image.pkr.hcl
```

#### Image Build Failures

**Error:** `Error creating AMI: InvalidAMIName`

```bash
# AMI names must be unique - add timestamp
packer build -var 'image_name=myimage-$(date +%Y%m%d%H%M%S)' image.pkr.hcl
```

#### Provisioner Script Failures

**Error:** `Script exited with non-zero exit status`

```bash
# Add error handling to scripts
set -euxo pipefail

# Check script syntax
shellcheck scripts/*.sh

# Test scripts locally in a container
docker run -v ./scripts:/scripts ubuntu:22.04 bash /scripts/base.sh
```

### Pipeline Failures

#### Security Scan Failures

Set soft fail to allow warnings without blocking:

```yaml
- name: Run Trivy IaC Scanner
  uses: aquasecurity/trivy-action@0.28.0
  with:
    scan-type: 'config'
    exit-code: '0'  # Don't fail on findings
    severity: 'CRITICAL'  # Only fail on critical
```

#### Build Timeouts

Increase timeout for large images:

```yaml
- name: Build AMI
  timeout-minutes: 60
  run: packer build image.pkr.hcl
```

---

## Related Templates

| Template                                                          | Description                      |
| ----------------------------------------------------------------- | -------------------------------- |
| [aws-ec2-instance](/docs/default/template/aws-ec2-instance)       | Deploy EC2 instances from AMIs   |
| [aws-launch-template](/docs/default/template/aws-launch-template) | Create launch templates for ASGs |
| [aws-eks](/docs/default/template/aws-eks)                         | Amazon EKS Kubernetes cluster    |
| [azure-vm](/docs/default/template/azure-vm)                       | Azure Virtual Machine deployment |
| [gcp-compute-instance](/docs/default/template/gcp-compute-instance) | GCP Compute Engine instances   |
| [ansible-playbook](/docs/default/template/ansible-playbook)       | Ansible configuration management |

---

## References

- [Packer Documentation](https://developer.hashicorp.com/packer/docs)
- [Packer Plugins Registry](https://developer.hashicorp.com/packer/integrations)
- [AWS AMI Builder](https://developer.hashicorp.com/packer/integrations/hashicorp/amazon)
- [Azure ARM Builder](https://developer.hashicorp.com/packer/integrations/hashicorp/azure)
- [GCP Compute Builder](https://developer.hashicorp.com/packer/integrations/hashicorp/googlecompute)
- [Packer GitHub Actions](https://github.com/hashicorp/setup-packer)
- [Trivy Security Scanner](https://trivy.dev/)
- [Golden Image Best Practices](https://developer.hashicorp.com/packer/tutorials/aws-get-started/aws-get-started-build-image)

---

## Support

- **Owner**: ${{ values.owner }}
- **Repository**: [GitHub](${{ values.repoUrl }})
