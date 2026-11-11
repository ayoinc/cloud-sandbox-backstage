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
- Memory: ${{ values.memory }} MB
- Disk: ${{ values.disk_size }} GB
- Private IP: `${{ values.private_network }}`
- Provisioner: `${{ values.provisioner }}`

## Provisioning

{% if values.provisioner == "shell" -%}
`scripts/provision.sh` runs as root inside the VM.
{%- elif values.provisioner == "ansible" -%}
`ansible/playbook.yml` is run from the host, which needs Ansible installed.
{%- elif values.provisioner == "ansible_local" -%}
`ansible/playbook.yml` is run inside the VM; Vagrant installs Ansible there.
{%- elif values.provisioner == "puppet" -%}
`puppet/manifests/default.pp` is applied inside the VM after
`puppet/install-agent.sh` has installed the Puppet agent.
{%- elif values.provisioner == "chef" -%}
The `environment` cookbook in `chef/cookbooks` is converged inside the VM with
Chef Solo.
{%- endif %}

## Commands

| Command             | Description         |
| ------------------- | ------------------- |
| `vagrant up`        | Start VM            |
| `vagrant ssh`       | SSH into VM         |
| `vagrant halt`      | Stop VM             |
| `vagrant destroy`   | Delete VM           |
| `vagrant provision` | Re-run provisioning |

## CI

`.github/workflows/ci.yaml` runs on every push and pull request. It checks the
Vagrantfile (`ruby -wc`, `vagrant validate --ignore-provider`) and lints the
provisioning files. It does not boot the VM: hosted runners have no hypervisor.
