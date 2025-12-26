# ${{ values.name }}

${{ values.description }}

## Overview

This Vagrant environment provides a reproducible local development environment using virtualization.

## Prerequisites

- Vagrant 2.3 or later
- VirtualBox 7.0+ or VMware Workstation/Fusion
- At least 4GB RAM available for VMs

## Quick Start

### Start Environment

```bash
# Start all VMs
vagrant up

# Start specific VM
vagrant up web
```

### Access VMs

```bash
# SSH into default VM
vagrant ssh

# SSH into specific VM
vagrant ssh web
```

### Stop Environment

```bash
# Suspend (save state)
vagrant suspend

# Halt (shutdown)
vagrant halt

# Destroy (delete VMs)
vagrant destroy
```

## Project Structure

```
.
├── catalog-info.yaml     # Backstage catalog entry
├── docs/                 # Documentation
├── README.md
├── scripts/              # Provisioning scripts
│   └── bootstrap.sh
└── Vagrantfile           # Vagrant configuration
```

## Configuration

### VM Settings

Edit `Vagrantfile` to customize VMs:

```ruby
Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/jammy64"
  
  config.vm.provider "virtualbox" do |vb|
    vb.memory = "2048"
    vb.cpus = 2
  end
  
  config.vm.network "private_network", ip: "192.168.56.10"
  config.vm.synced_folder ".", "/vagrant"
end
```

### Multi-Machine Setup

```ruby
Vagrant.configure("2") do |config|
  config.vm.define "web" do |web|
    web.vm.box = "ubuntu/jammy64"
    web.vm.network "private_network", ip: "192.168.56.10"
  end
  
  config.vm.define "db" do |db|
    db.vm.box = "ubuntu/jammy64"
    db.vm.network "private_network", ip: "192.168.56.11"
  end
end
```

## Common Commands

| Command | Description |
|---------|-------------|
| `vagrant up` | Start and provision VMs |
| `vagrant ssh` | SSH into VM |
| `vagrant halt` | Stop VMs |
| `vagrant destroy` | Delete VMs |
| `vagrant reload` | Restart VMs |
| `vagrant provision` | Re-run provisioners |
| `vagrant status` | Show VM status |

## Provisioning

### Shell Scripts

Add scripts to `scripts/` directory:

```bash
# scripts/bootstrap.sh
#!/bin/bash
apt-get update
apt-get install -y nginx
```

### Ansible Integration

```ruby
config.vm.provision "ansible" do |ansible|
  ansible.playbook = "ansible/playbook.yml"
end
```

## Networking

### Port Forwarding

```ruby
config.vm.network "forwarded_port", guest: 80, host: 8080
config.vm.network "forwarded_port", guest: 443, host: 8443
```

### Private Network

```ruby
config.vm.network "private_network", ip: "192.168.56.10"
```

## Troubleshooting

### VM Won't Start

```bash
# Check VirtualBox status
VBoxManage list vms

# Rebuild from scratch
vagrant destroy -f && vagrant up
```

### Provisioning Fails

```bash
# Re-run provisioning
vagrant provision --debug
```

### Shared Folder Issues

```bash
# Install guest additions
vagrant plugin install vagrant-vbguest
```

## Support

- **Owner**: ${{ values.owner }}
- **Repository**: [GitHub](${{ values.repoUrl }})
