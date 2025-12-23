# Overview

## Architecture

Packer Image Builder provides automated, repeatable machine image creation across multiple cloud providers. Images are built from a common template with provider-specific configurations, ensuring consistency across environments.

```
+------------------------------------------------------------------+
|                    PACKER ARCHITECTURE                            |
+------------------------------------------------------------------+
|                                                                   |
|  +-------------------+         +-------------------+              |
|  |   Template        |         |   Variables       |              |
|  |   sources { }     |-------->|   pkrvars.hcl     |              |
|  |   build { }       |         |   env vars        |              |
|  +-------------------+         +-------------------+              |
|           |                            |                          |
|           v                            v                          |
|  +--------------------------------------------------+            |
|  |              PACKER CORE                          |            |
|  |  +------------+  +------------+  +------------+  |            |
|  |  | Plugins    |  | Builders   |  | Comm       |  |            |
|  |  | Registry   |  | AMI/Image  |  | SSH/WinRM  |  |            |
|  |  +------------+  +------------+  +------------+  |            |
|  +--------------------------------------------------+            |
|                          |                                        |
|                          v                                        |
|  +--------------------------------------------------+            |
|  |              BUILD PROCESS                        |            |
|  |  +------------+  +------------+  +------------+  |            |
|  |  | Launch     |  | Provision  |  | Snapshot   |  |            |
|  |  | Instance   |  | Configure  |  | Create     |  |            |
|  |  +------------+  +------------+  +------------+  |            |
|  +--------------------------------------------------+            |
|                                                                   |
+------------------------------------------------------------------+
```

## HCL2 Template Structure

### Plugin Requirements

```hcl
# plugins.pkr.hcl
packer {
  required_version = ">= 1.10.0"

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
    ansible = {
      version = ">= 1.1.0"
      source  = "github.com/hashicorp/ansible"
    }
  }
}
```

### Variables Definition

```hcl
# variables.pkr.hcl
variable "version" {
  type        = string
  description = "Image version"
  default     = "1.0.0"
}

variable "environment" {
  type        = string
  description = "Target environment"
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "aws_region" {
  type        = string
  description = "AWS region for AMI"
  default     = "us-west-2"
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type for building"
  default     = "t3.medium"
}

variable "ssh_username" {
  type        = string
  description = "SSH username for provisioning"
  default     = "ubuntu"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID for building"
  default     = ""
}

variable "subnet_id" {
  type        = string
  description = "Subnet ID for building"
  default     = ""
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to resources"
  default = {
    ManagedBy = "packer"
    Project   = "infrastructure"
  }
}

# Sensitive variables
variable "ansible_vault_password" {
  type        = string
  description = "Ansible vault password"
  sensitive   = true
  default     = ""
}
```

### AWS AMI Source

```hcl
# aws-ubuntu.pkr.hcl
locals {
  timestamp = formatdate("YYYYMMDD-hhmmss", timestamp())
  
  common_tags = merge(var.tags, {
    Environment = var.environment
    Version     = var.version
    BuildTime   = local.timestamp
  })
}

data "amazon-ami" "ubuntu" {
  filters = {
    name                = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"
    root-device-type    = "ebs"
    virtualization-type = "hvm"
  }
  most_recent = true
  owners      = ["099720109477"] # Canonical
}

source "amazon-ebs" "ubuntu" {
  ami_name        = "company-ubuntu-${var.version}-${local.timestamp}"
  ami_description = "Company Ubuntu 22.04 base image v${var.version}"
  instance_type   = var.instance_type
  region          = var.aws_region
  source_ami      = data.amazon-ami.ubuntu.id
  ssh_username    = var.ssh_username

  # VPC configuration
  vpc_id                      = var.vpc_id != "" ? var.vpc_id : null
  subnet_id                   = var.subnet_id != "" ? var.subnet_id : null
  associate_public_ip_address = true

  # AMI configuration
  ami_virtualization_type = "hvm"
  ena_support             = true
  sriov_support           = true

  # Encryption
  encrypt_boot = true
  kms_key_id   = "alias/packer-images"

  # AMI sharing
  ami_users = var.environment == "prod" ? ["123456789012", "234567890123"] : []

  # Copy to multiple regions
  ami_regions = var.environment == "prod" ? ["us-east-1", "eu-west-1"] : []

  # Block device mapping
  launch_block_device_mappings {
    device_name           = "/dev/sda1"
    volume_size           = 50
    volume_type           = "gp3"
    iops                  = 3000
    throughput            = 125
    delete_on_termination = true
    encrypted             = true
  }

  # Tags
  tags          = local.common_tags
  run_tags      = local.common_tags
  snapshot_tags = local.common_tags

  # Timeouts
  ssh_timeout         = "10m"
  aws_polling {
    delay_seconds = 30
    max_attempts  = 50
  }
}
```

### Azure Image Source

```hcl
# azure-ubuntu.pkr.hcl
variable "azure_subscription_id" {
  type    = string
  default = env("ARM_SUBSCRIPTION_ID")
}

variable "azure_resource_group" {
  type    = string
  default = "packer-images-rg"
}

variable "azure_location" {
  type    = string
  default = "westus2"
}

source "azure-arm" "ubuntu" {
  subscription_id = var.azure_subscription_id
  
  # Use service principal or managed identity
  use_azure_cli_auth = true

  # Shared Image Gallery destination
  shared_image_gallery_destination {
    subscription         = var.azure_subscription_id
    resource_group       = var.azure_resource_group
    gallery_name         = "company_images"
    image_name           = "ubuntu-22.04"
    image_version        = var.version
    replication_regions  = ["westus2", "eastus"]
    storage_account_type = "Standard_LRS"
  }

  # Source image
  os_type         = "Linux"
  image_publisher = "Canonical"
  image_offer     = "0001-com-ubuntu-server-jammy"
  image_sku       = "22_04-lts-gen2"

  # Build VM configuration
  location = var.azure_location
  vm_size  = "Standard_D2s_v3"

  # OS disk
  os_disk_size_gb = 50

  # Network
  virtual_network_name                = "packer-vnet"
  virtual_network_subnet_name         = "packer-subnet"
  virtual_network_resource_group_name = var.azure_resource_group

  # Authentication
  ssh_username = var.ssh_username

  # Tags
  azure_tags = local.common_tags
}
```

### GCP Image Source

```hcl
# gcp-ubuntu.pkr.hcl
variable "gcp_project_id" {
  type    = string
  default = env("GOOGLE_PROJECT")
}

variable "gcp_zone" {
  type    = string
  default = "us-central1-a"
}

source "googlecompute" "ubuntu" {
  project_id = var.gcp_project_id
  
  # Source image
  source_image_family = "ubuntu-2204-lts"
  
  # Build configuration
  zone         = var.gcp_zone
  machine_type = "e2-medium"
  
  # Network
  network    = "default"
  subnetwork = "default"
  
  # Disk configuration
  disk_size = 50
  disk_type = "pd-ssd"
  
  # Image destination
  image_name        = "company-ubuntu-${replace(var.version, ".", "-")}-${local.timestamp}"
  image_description = "Company Ubuntu 22.04 base image v${var.version}"
  image_family      = "company-ubuntu"
  
  # Image storage locations
  image_storage_locations = ["us"]
  
  # Authentication
  ssh_username = var.ssh_username
  
  # Labels
  image_labels = {
    environment = var.environment
    version     = replace(var.version, ".", "-")
    managed_by  = "packer"
  }
}
```

## Build Block

```hcl
# build.pkr.hcl
build {
  name = "company-base-image"

  sources = [
    "source.amazon-ebs.ubuntu",
    "source.azure-arm.ubuntu",
    "source.googlecompute.ubuntu"
  ]

  # Wait for cloud-init
  provisioner "shell" {
    inline = [
      "cloud-init status --wait",
      "echo 'Cloud-init complete'"
    ]
  }

  # Update system packages
  provisioner "shell" {
    inline = [
      "sudo apt-get update",
      "sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y",
      "sudo DEBIAN_FRONTEND=noninteractive apt-get dist-upgrade -y"
    ]
  }

  # Copy scripts
  provisioner "file" {
    source      = "scripts/"
    destination = "/tmp/scripts"
  }

  # Run base configuration
  provisioner "shell" {
    scripts = [
      "scripts/common/base.sh",
      "scripts/common/security.sh",
      "scripts/app/docker.sh",
      "scripts/app/monitoring.sh"
    ]
    environment_vars = [
      "ENVIRONMENT=${var.environment}",
      "VERSION=${var.version}"
    ]
    execute_command = "chmod +x {{ .Path }}; sudo -E {{ .Path }}"
  }

  # Ansible provisioning
  provisioner "ansible" {
    playbook_file = "ansible/playbook.yml"
    user          = var.ssh_username
    use_proxy     = false
    
    extra_arguments = [
      "--extra-vars", "environment=${var.environment}",
      "--extra-vars", "version=${var.version}",
      "-vv"
    ]
    
    ansible_env_vars = [
      "ANSIBLE_HOST_KEY_CHECKING=False"
    ]
  }

  # Cleanup
  provisioner "shell" {
    scripts = [
      "scripts/common/cleanup.sh"
    ]
    execute_command = "chmod +x {{ .Path }}; sudo {{ .Path }}"
  }

  # Generate manifest
  post-processor "manifest" {
    output     = "manifest.json"
    strip_path = true
    custom_data = {
      version     = var.version
      environment = var.environment
      build_time  = local.timestamp
    }
  }

  # Checksum
  post-processor "checksum" {
    checksum_types = ["sha256"]
    output         = "checksums.txt"
  }
}
```

## Provisioner Scripts

### Base Configuration

```bash
#!/bin/bash
# scripts/common/base.sh
set -euxo pipefail

echo "==> Installing base packages"
apt-get update
apt-get install -y --no-install-recommends \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    software-properties-common \
    jq \
    unzip \
    htop \
    vim \
    git \
    wget

echo "==> Configuring time synchronization"
timedatectl set-ntp on

echo "==> Setting timezone"
timedatectl set-timezone UTC

echo "==> Configuring sysctl"
cat > /etc/sysctl.d/99-custom.conf << 'EOF'
# Network performance
net.core.somaxconn = 65535
net.core.netdev_max_backlog = 65535
net.ipv4.tcp_max_syn_backlog = 65535
net.ipv4.tcp_fin_timeout = 15
net.ipv4.tcp_keepalive_time = 300
net.ipv4.tcp_keepalive_probes = 5
net.ipv4.tcp_keepalive_intvl = 15

# File handles
fs.file-max = 2097152
fs.nr_open = 2097152

# Virtual memory
vm.swappiness = 10
vm.dirty_ratio = 60
vm.dirty_background_ratio = 2
EOF

sysctl -p /etc/sysctl.d/99-custom.conf

echo "==> Configuring limits"
cat > /etc/security/limits.d/99-custom.conf << 'EOF'
* soft nofile 1048576
* hard nofile 1048576
* soft nproc 65535
* hard nproc 65535
EOF

echo "==> Base configuration complete"
```

### Security Hardening

```bash
#!/bin/bash
# scripts/common/security.sh
set -euxo pipefail

echo "==> Configuring SSH hardening"
cat > /etc/ssh/sshd_config.d/99-hardening.conf << 'EOF'
# Disable password authentication
PasswordAuthentication no
PermitEmptyPasswords no
ChallengeResponseAuthentication no

# Disable root login
PermitRootLogin no

# Use only protocol 2
Protocol 2

# Limit authentication attempts
MaxAuthTries 3
MaxSessions 10
LoginGraceTime 30

# Disable X11 forwarding
X11Forwarding no

# Disconnect idle sessions
ClientAliveInterval 300
ClientAliveCountMax 2

# Use strong ciphers
Ciphers aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr
MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com
KexAlgorithms curve25519-sha256,curve25519-sha256@libssh.org

# Logging
LogLevel VERBOSE
EOF

echo "==> Installing and configuring fail2ban"
apt-get install -y fail2ban

cat > /etc/fail2ban/jail.local << 'EOF'
[DEFAULT]
bantime = 1h
findtime = 10m
maxretry = 5
backend = systemd

[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 24h
EOF

systemctl enable fail2ban

echo "==> Configuring automatic security updates"
apt-get install -y unattended-upgrades

cat > /etc/apt/apt.conf.d/50unattended-upgrades << 'EOF'
Unattended-Upgrade::Allowed-Origins {
    "${distro_id}:${distro_codename}";
    "${distro_id}:${distro_codename}-security";
    "${distro_id}ESMApps:${distro_codename}-apps-security";
    "${distro_id}ESM:${distro_codename}-infra-security";
};
Unattended-Upgrade::Remove-Unused-Dependencies "true";
Unattended-Upgrade::Automatic-Reboot "false";
EOF

echo "==> Security hardening complete"
```

### Docker Installation

```bash
#!/bin/bash
# scripts/app/docker.sh
set -euxo pipefail

echo "==> Installing Docker"

# Add Docker GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Add Docker repository
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Configure Docker daemon
mkdir -p /etc/docker
cat > /etc/docker/daemon.json << 'EOF'
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m",
    "max-file": "3"
  },
  "storage-driver": "overlay2",
  "live-restore": true,
  "default-ulimits": {
    "nofile": {
      "Name": "nofile",
      "Hard": 65536,
      "Soft": 65536
    }
  },
  "features": {
    "buildkit": true
  }
}
EOF

# Enable and start Docker
systemctl enable docker
systemctl start docker

echo "==> Docker installation complete"
docker --version
```

### Cleanup Script

```bash
#!/bin/bash
# scripts/common/cleanup.sh
set -euxo pipefail

echo "==> Cleaning up temporary files"

# Clear apt cache
apt-get clean
apt-get autoremove -y
rm -rf /var/lib/apt/lists/*

# Clear logs
find /var/log -type f -name "*.log" -delete
find /var/log -type f -name "*.gz" -delete
journalctl --vacuum-time=1d

# Clear temporary files
rm -rf /tmp/*
rm -rf /var/tmp/*

# Clear SSH host keys (regenerated on first boot)
rm -f /etc/ssh/ssh_host_*

# Clear machine ID (regenerated on first boot)
echo "" > /etc/machine-id

# Clear command history
rm -f /root/.bash_history
rm -f /home/*/.bash_history
unset HISTFILE

# Cloud-init cleanup
if command -v cloud-init &> /dev/null; then
    cloud-init clean --logs --seed
fi

# Zero out free space for better compression (optional)
if [ "${ZERO_FREE_SPACE:-false}" = "true" ]; then
    dd if=/dev/zero of=/EMPTY bs=1M || true
    rm -f /EMPTY
fi

# Sync filesystem
sync

echo "==> Cleanup complete"
```

## Ansible Provisioning

```yaml
# ansible/playbook.yml
---
- name: Configure base image
  hosts: all
  become: true
  
  vars:
    environment: "{{ lookup('env', 'ENVIRONMENT') | default('dev') }}"
    version: "{{ lookup('env', 'VERSION') | default('1.0.0') }}"
  
  tasks:
    - name: Set hostname pattern
      ansible.builtin.hostname:
        name: "{{ environment }}-instance"
    
    - name: Install monitoring agents
      ansible.builtin.include_role:
        name: monitoring
      vars:
        datadog_enabled: "{{ environment == 'prod' }}"
    
    - name: Configure log shipping
      ansible.builtin.include_role:
        name: logging
    
    - name: Apply CIS benchmarks
      ansible.builtin.include_role:
        name: cis_hardening
      when: environment == 'prod'
    
    - name: Add version file
      ansible.builtin.copy:
        dest: /etc/image-version
        content: |
          VERSION={{ version }}
          ENVIRONMENT={{ environment }}
          BUILD_DATE={{ ansible_date_time.iso8601 }}
        mode: '0644'
```

## Related Resources

- [Packer Documentation](https://developer.hashicorp.com/packer/docs)
- [Packer Plugins](https://developer.hashicorp.com/packer/plugins)
- [HCL2 Reference](https://developer.hashicorp.com/packer/docs/templates/hcl_templates)
- [Packer Examples](https://github.com/hashicorp/packer/tree/main/examples)
