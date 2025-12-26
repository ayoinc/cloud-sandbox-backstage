# ${{ values.name }}

${{ values.description }}

## Overview

This Packer template creates machine images for deployment across cloud providers and virtualization platforms.

## Prerequisites

- Packer 1.9 or later
- Cloud provider credentials (AWS, Azure, GCP, or VMware)
- Network access to download packages during build

## Quick Start

### Initialize Packer

```bash
packer init image.pkr.hcl
```

### Validate Template

```bash
packer validate image.pkr.hcl
```

### Build Image

```bash
# Build for all targets
packer build image.pkr.hcl

# Build for specific target
packer build -only=amazon-ebs.ubuntu image.pkr.hcl

# Build with variables
packer build -var 'aws_region=us-west-2' image.pkr.hcl
```

## Project Structure

```
.
├── .github/              # GitHub Actions workflows
│   └── workflows/
├── catalog-info.yaml     # Backstage catalog entry
├── docs/                 # Documentation
├── image.pkr.hcl         # Main Packer template
└── README.md
```

## Configuration

### Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `aws_region` | AWS region for AMI build | `us-east-1` |
| `instance_type` | EC2 instance type for builder | `t3.micro` |
| `source_ami_filter` | AMI filter for base image | Ubuntu 22.04 |

### Environment Variables

Set credentials via environment variables:

```bash
# AWS
export AWS_ACCESS_KEY_ID="your-key"
export AWS_SECRET_ACCESS_KEY="your-secret"

# Azure
export ARM_CLIENT_ID="your-client-id"
export ARM_CLIENT_SECRET="your-secret"
export ARM_SUBSCRIPTION_ID="your-subscription"
export ARM_TENANT_ID="your-tenant"

# GCP
export GOOGLE_APPLICATION_CREDENTIALS="/path/to/credentials.json"
```

## CI/CD

The GitHub Actions workflow automatically:

1. Validates Packer template on pull requests
2. Builds images on merge to main
3. Tags and stores image IDs as artifacts

## Customization

### Adding Provisioners

Edit `image.pkr.hcl` to add shell or Ansible provisioners:

```hcl
build {
  provisioner "shell" {
    scripts = [
      "scripts/base.sh",
      "scripts/security.sh",
      "scripts/cleanup.sh"
    ]
  }
  
  provisioner "ansible" {
    playbook_file = "ansible/playbook.yml"
  }
}
```

### Multi-Platform Builds

Add additional source blocks for different platforms:

```hcl
source "azure-arm" "ubuntu" {
  # Azure configuration
}

source "googlecompute" "ubuntu" {
  # GCP configuration
}
```

## Troubleshooting

### Debug Mode

```bash
PACKER_LOG=1 packer build image.pkr.hcl
```

### SSH Issues

```bash
# Increase SSH timeout
packer build -var 'ssh_timeout=10m' image.pkr.hcl
```

## Support

- **Owner**: ${{ values.owner }}
- **Repository**: [GitHub](${{ values.repoUrl }})
