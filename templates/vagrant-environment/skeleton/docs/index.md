# ${{ values.name }}

${{ values.description }}

## Overview

This Vagrant environment provides a reproducible, portable local development environment using virtualization technology. It enables consistent development experiences across team members by codifying infrastructure configuration.

Key features:

- Reproducible VM provisioning with version-controlled configuration
- Multi-provider support (VirtualBox, VMware, Hyper-V)
- Automated provisioning with shell scripts or Ansible
- Private networking for isolated development
- Port forwarding for service access from host
- Synced folders for seamless code sharing

```d2
direction: right

title: {
  label: Vagrant Environment Architecture
  near: top-center
  shape: text
  style.font-size: 24
  style.bold: true
}

host: Host Machine {
  style.fill: "#E3F2FD"
  style.stroke: "#1976D2"

  vagrant: Vagrant CLI {
    shape: hexagon
    style.fill: "#E8F5E9"
    style.stroke: "#388E3C"
  }

  vagrantfile: Vagrantfile {
    shape: document
    style.fill: "#FFF3E0"
    style.stroke: "#FF9800"
  }

  synced: Synced Folder {
    shape: cylinder
    style.fill: "#FCE4EC"
    style.stroke: "#C2185B"
  }
}

provider: ${{ values.provider }} Provider {
  style.fill: "#E8F5E9"
  style.stroke: "#388E3C"
  shape: hexagon
}

vm: Virtual Machine {
  style.fill: "#FCE4EC"
  style.stroke: "#C2185B"

  box: ${{ values.box }} {
    shape: package
    style.fill: "#FFECB3"
    style.stroke: "#FFA000"
  }

  network: Private Network {
    style.fill: "#E3F2FD"
    style.stroke: "#1976D2"
    label: "${{ values.private_network }}"
  }

  provision: Provisioner {
    style.fill: "#E8F5E9"
    style.stroke: "#388E3C"
    label: "${{ values.provisioner }}"
  }

  services: Services {
    style.fill: "#FFF3E0"
    style.stroke: "#FF9800"
  }

  box -> provision: configures
  provision -> services: installs
}

host.vagrant -> host.vagrantfile: reads
host.vagrantfile -> provider: configures
provider -> vm: creates
host.synced <-> vm: shares files
```

---

## Configuration Summary

| Setting          | Value                            |
| ---------------- | -------------------------------- |
| Environment Name | `${{ values.name }}`             |
| Base Box         | `${{ values.box }}`              |
| Provider         | `${{ values.provider }}`         |
| Memory           | ${{ values.memory }} MB          |
| CPUs             | ${{ values.cpus }}               |
| Private Network  | `${{ values.private_network }}`  |
| Provisioner      | `${{ values.provisioner }}`      |
| Owner            | ${{ values.owner }}              |

---

## Environment Structure

```
${{ values.name }}/
├── Vagrantfile              # Main Vagrant configuration
├── catalog-info.yaml        # Backstage catalog entry
├── docs/                    # Documentation (TechDocs)
│   └── index.md
├── mkdocs.yml               # MkDocs configuration
├── README.md                # Project readme
├── scripts/                 # Provisioning scripts
│   └── provision.sh         # Shell provisioner script
{%- if values.provisioner == "ansible" or values.provisioner == "ansible_local" %}
├── ansible/                 # Ansible configuration
│   ├── playbook.yml         # Main playbook
│   └── roles/               # Ansible roles
{%- endif %}
└── .gitignore               # Git ignore rules
```

### Key Files

| File                   | Purpose                                          |
| ---------------------- | ------------------------------------------------ |
| `Vagrantfile`          | Defines VM configuration, networking, provisioning |
| `scripts/provision.sh` | Shell script for software installation           |
| `catalog-info.yaml`    | Registers environment in Backstage catalog       |

---

## CI/CD Pipeline

This environment includes GitHub Actions workflows for validation, testing, and documentation.

### Pipeline Features

- **Syntax Validation**: Vagrantfile Ruby syntax checking
- **Linting**: Rubocop for Vagrantfile style consistency
- **Security Scanning**: Detect secrets and vulnerabilities
- **Box Verification**: Ensure base box exists and is accessible
- **Documentation**: Automatic TechDocs generation

### Pipeline Workflow

```d2
direction: right

commit: Code Commit {
  shape: oval
  style.fill: "#E3F2FD"
  style.stroke: "#1976D2"
}

validate: Validate {
  style.fill: "#E8F5E9"
  style.stroke: "#388E3C"
  label: "Syntax Check\nRubocop Lint\nYAML Validate"
}

security: Security {
  style.fill: "#FFCDD2"
  style.stroke: "#D32F2F"
  label: "Secret Scan\nBox Verify"
}

test: Test {
  style.fill: "#E3F2FD"
  style.stroke: "#1976D2"
  label: "vagrant validate\nProvisioner Check"
}

docs: Documentation {
  style.fill: "#FFECB3"
  style.stroke: "#FFA000"
  label: "TechDocs Build\nPublish"
}

deploy: Ready {
  shape: oval
  style.fill: "#E8F5E9"
  style.stroke: "#388E3C"
}

commit -> validate -> security -> test -> docs -> deploy
```

### Workflow Triggers

| Trigger      | Actions                                    |
| ------------ | ------------------------------------------ |
| Pull Request | Validate, Lint, Security Scan              |
| Push to main | Full validation, Documentation publish     |
| Manual       | On-demand validation and box verification  |

---

## Prerequisites

### 1. Vagrant Installation

Install Vagrant from [vagrantup.com](https://www.vagrantup.com/downloads):

**macOS (Homebrew):**
```bash
brew install --cask vagrant
```

**Ubuntu/Debian:**
```bash
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install vagrant
```

**Windows (Chocolatey):**
```powershell
choco install vagrant
```

**Verify installation:**
```bash
vagrant --version
# Expected: Vagrant 2.3.x or later
```

### 2. Virtualization Provider

Install your chosen provider:

#### VirtualBox (Free, Recommended)

```bash
# macOS
brew install --cask virtualbox

# Ubuntu/Debian
sudo apt install virtualbox

# Windows
choco install virtualbox
```

#### VMware Workstation/Fusion (Commercial)

1. Install VMware Workstation (Windows/Linux) or VMware Fusion (macOS)
2. Install Vagrant VMware Utility: [Install Guide](https://www.vagrantup.com/docs/providers/vmware/installation)
3. Install Vagrant VMware plugin:
   ```bash
   vagrant plugin install vagrant-vmware-desktop
   ```

#### Hyper-V (Windows)

```powershell
# Enable Hyper-V (requires admin privileges)
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All
```

### 3. System Requirements

| Requirement      | Minimum              | Recommended          |
| ---------------- | -------------------- | -------------------- |
| RAM              | ${{ values.memory }}MB + 2GB | ${{ values.memory }}MB + 4GB |
| CPU Cores        | ${{ values.cpus }} + 2 | ${{ values.cpus }} + 4 |
| Disk Space       | 10GB                 | 20GB                 |
| Virtualization   | VT-x/AMD-V enabled   | VT-x/AMD-V enabled   |

**Enable virtualization in BIOS/UEFI if not already enabled.**

---

## Usage

### Starting the Environment

```bash
# Navigate to project directory
cd ${{ values.name }}

# Start and provision the VM
vagrant up

# Start without re-provisioning (subsequent runs)
vagrant up --no-provision

# Start with specific provider
vagrant up --provider=${{ values.provider }}
```

### Accessing the VM

```bash
# SSH into the VM
vagrant ssh

# Run command without entering shell
vagrant ssh -c "hostname"

# Get SSH configuration for external clients
vagrant ssh-config
```

### Managing VM State

```bash
# Check VM status
vagrant status

# Suspend (save state to disk)
vagrant suspend

# Resume from suspended state
vagrant resume

# Halt (graceful shutdown)
vagrant halt

# Restart VM
vagrant reload

# Restart with re-provisioning
vagrant reload --provision
```

### Provisioning

```bash
# Run provisioners on running VM
vagrant provision

# Run specific provisioner
vagrant provision --provision-with shell

# Debug provisioning issues
vagrant provision --debug
```

### Destroying the Environment

```bash
# Destroy VM (confirmation required)
vagrant destroy

# Force destroy without confirmation
vagrant destroy -f

# Destroy and recreate fresh
vagrant destroy -f && vagrant up
```

---

## Customization Options

### Memory and CPU

Edit `Vagrantfile` to adjust resources:

```ruby
config.vm.provider "${{ values.provider }}" do |v|
  v.memory = 4096  # Increase to 4GB RAM
  v.cpus = 4       # Increase to 4 CPUs
end
```

### Network Configuration

#### Additional Port Forwarding

```ruby
# Add more port forwards
config.vm.network "forwarded_port", guest: 3000, host: 3000  # Node.js
config.vm.network "forwarded_port", guest: 5432, host: 5432  # PostgreSQL
config.vm.network "forwarded_port", guest: 6379, host: 6379  # Redis
```

#### Public Network (Bridged)

```ruby
# Expose VM on local network
config.vm.network "public_network", bridge: "en0: Wi-Fi"
```

### Synced Folders

```ruby
# Additional synced folders
config.vm.synced_folder "../shared", "/shared"

# NFS mount (better performance on macOS/Linux)
config.vm.synced_folder ".", "/vagrant", type: "nfs"

# rsync (no host dependencies)
config.vm.synced_folder ".", "/vagrant", type: "rsync",
  rsync__exclude: [".git/", "node_modules/"]
```

### Base Box

Change the base operating system:

```ruby
# Ubuntu options
config.vm.box = "ubuntu/jammy64"    # Ubuntu 22.04
config.vm.box = "ubuntu/focal64"    # Ubuntu 20.04

# CentOS/Rocky options
config.vm.box = "rockylinux/9"      # Rocky Linux 9
config.vm.box = "centos/7"          # CentOS 7

# Debian
config.vm.box = "debian/bookworm64" # Debian 12
```

### Environment Variables

```ruby
# Set environment variables in VM
config.vm.provision "shell", inline: <<-SHELL
  echo 'export APP_ENV=development' >> /home/vagrant/.bashrc
  echo 'export DATABASE_URL=postgres://localhost/app' >> /home/vagrant/.bashrc
SHELL
```

---

## Multi-Machine Setup

For complex environments requiring multiple VMs:

```ruby
Vagrant.configure("2") do |config|
  # Web Server
  config.vm.define "web" do |web|
    web.vm.box = "${{ values.box }}"
    web.vm.hostname = "web"
    web.vm.network "private_network", ip: "192.168.56.10"
    web.vm.provider "${{ values.provider }}" do |v|
      v.memory = 1024
      v.cpus = 1
    end
    web.vm.provision "shell", inline: <<-SHELL
      apt-get update && apt-get install -y nginx
    SHELL
  end

  # Database Server
  config.vm.define "db" do |db|
    db.vm.box = "${{ values.box }}"
    db.vm.hostname = "db"
    db.vm.network "private_network", ip: "192.168.56.11"
    db.vm.provider "${{ values.provider }}" do |v|
      v.memory = 2048
      v.cpus = 2
    end
    db.vm.provision "shell", inline: <<-SHELL
      apt-get update && apt-get install -y postgresql postgresql-contrib
    SHELL
  end

  # Application Server
  config.vm.define "app", primary: true do |app|
    app.vm.box = "${{ values.box }}"
    app.vm.hostname = "app"
    app.vm.network "private_network", ip: "192.168.56.12"
    app.vm.network "forwarded_port", guest: 3000, host: 3000
    app.vm.provider "${{ values.provider }}" do |v|
      v.memory = ${{ values.memory }}
      v.cpus = ${{ values.cpus }}
    end
    app.vm.provision "shell", path: "scripts/provision.sh"
  end
end
```

### Multi-Machine Commands

```bash
# Start all VMs
vagrant up

# Start specific VM
vagrant up web
vagrant up db

# SSH to specific VM
vagrant ssh web
vagrant ssh db

# Destroy specific VM
vagrant destroy db -f

# Status of all VMs
vagrant status
```

---

## Provisioner Options

### Shell Provisioner

Basic shell script provisioning:

```ruby
config.vm.provision "shell", path: "scripts/provision.sh"

# Inline script
config.vm.provision "shell", inline: <<-SHELL
  apt-get update
  apt-get install -y nginx docker.io
SHELL

# Run as specific user
config.vm.provision "shell", path: "scripts/setup.sh", privileged: false
```

### Ansible Provisioner

For complex configuration management:

```ruby
# Ansible on host machine
config.vm.provision "ansible" do |ansible|
  ansible.playbook = "ansible/playbook.yml"
  ansible.inventory_path = "ansible/inventory"
  ansible.verbose = "v"
end

# Ansible installed in VM (ansible_local)
config.vm.provision "ansible_local" do |ansible|
  ansible.playbook = "ansible/playbook.yml"
  ansible.install_mode = "pip"
end
```

### Docker Provisioner

```ruby
config.vm.provision "docker" do |d|
  d.pull_images "nginx"
  d.run "nginx",
    args: "-p 80:80 -v /vagrant/html:/usr/share/nginx/html"
end
```

---

## Troubleshooting

### VM Won't Start

**Error: VT-x is not available**

```bash
# Check if virtualization is enabled
# Linux
egrep -c '(vmx|svm)' /proc/cpuinfo

# macOS
sysctl -a | grep machdep.cpu.features | grep VMX
```

**Resolution:** Enable VT-x/AMD-V in BIOS/UEFI settings.

---

**Error: The box 'xxx' could not be found**

```bash
# Search for available boxes
vagrant box list

# Add box manually
vagrant box add ${{ values.box }}

# Update box
vagrant box update
```

---

**Error: Port 8080 is already in use**

```bash
# Find process using port
lsof -i :8080

# Kill process or change port in Vagrantfile
config.vm.network "forwarded_port", guest: 80, host: 8081
```

### Provisioning Failures

**Error: E: Could not get lock /var/lib/dpkg/lock**

```bash
# Wait for apt to finish or kill the process in VM
vagrant ssh -c "sudo killall apt apt-get"
vagrant provision
```

---

**Error: Ansible not found**

```bash
# Install Ansible on host
pip install ansible

# Or use ansible_local provisioner
```

---

**Debug provisioning:**

```bash
# Verbose output
vagrant provision --debug

# Check provisioner output
vagrant ssh -c "cat /var/log/cloud-init-output.log"
```

### Network Issues

**Cannot access forwarded port from host**

```bash
# Verify port forwarding
vagrant port

# Check firewall in VM
vagrant ssh -c "sudo ufw status"
vagrant ssh -c "sudo ufw allow 80"
```

---

**Private network not working**

```bash
# Verify network in VM
vagrant ssh -c "ip addr show"

# Check host-only network (VirtualBox)
VBoxManage list hostonlyifs
```

### Synced Folder Issues

**Error: mount.nfs: access denied**

```bash
# Install NFS on host (Linux)
sudo apt install nfs-kernel-server

# Or use rsync instead
config.vm.synced_folder ".", "/vagrant", type: "rsync"
```

---

**Error: vboxsf mount failed**

```bash
# Install VirtualBox Guest Additions plugin
vagrant plugin install vagrant-vbguest

# Rebuild VM
vagrant destroy -f && vagrant up
```

### Performance Optimization

```ruby
# VirtualBox optimizations
config.vm.provider "virtualbox" do |vb|
  vb.memory = ${{ values.memory }}
  vb.cpus = ${{ values.cpus }}
  
  # Enable nested virtualization
  vb.customize ["modifyvm", :id, "--nested-hw-virt", "on"]
  
  # Use paravirtualized network adapter
  vb.customize ["modifyvm", :id, "--nictype1", "virtio"]
  
  # Enable I/O APIC
  vb.customize ["modifyvm", :id, "--ioapic", "on"]
end
```

---

## Related Templates

| Template                                                          | Description                              |
| ----------------------------------------------------------------- | ---------------------------------------- |
| [docker-compose](/docs/default/template/docker-compose)           | Docker Compose multi-container setup     |
| [kubernetes-local](/docs/default/template/kubernetes-local)       | Local Kubernetes with Kind/Minikube      |
| [ansible-playbook](/docs/default/template/ansible-playbook)       | Ansible playbook for configuration mgmt  |
| [packer-image](/docs/default/template/packer-image)               | Packer image builds for cloud/VM         |
| [terraform-local](/docs/default/template/terraform-local)         | Terraform local provider setup           |

---

## References

- [Vagrant Documentation](https://www.vagrantup.com/docs)
- [Vagrant Cloud Box Catalog](https://app.vagrantup.com/boxes/search)
- [VirtualBox Manual](https://www.virtualbox.org/manual/)
- [VMware Vagrant Provider](https://www.vagrantup.com/docs/providers/vmware)
- [Ansible Provisioner](https://www.vagrantup.com/docs/provisioning/ansible)
- [Vagrant Multi-Machine](https://www.vagrantup.com/docs/multi-machine)
- [HashiCorp Learn - Vagrant](https://learn.hashicorp.com/vagrant)
