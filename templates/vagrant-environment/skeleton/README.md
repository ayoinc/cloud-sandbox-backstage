# ${{ values.name }}

${{ values.description }}

## Quick Start

```bash
vagrant up
vagrant ssh
```

## Configuration

- Box: `${{ values.box }}`
- Provider: `${{ values.provider }}`
- CPUs: ${{ values.cpus }}
- Memory: ${{ values.memory }}MB
- Private IP: `${{ values.private_network }}`

## Commands

| Command | Description |
|---------|-------------|
| `vagrant up` | Start VM |
| `vagrant ssh` | SSH into VM |
| `vagrant halt` | Stop VM |
| `vagrant destroy` | Delete VM |
| `vagrant provision` | Re-run provisioning |
