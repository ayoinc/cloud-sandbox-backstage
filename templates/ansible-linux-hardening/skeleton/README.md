# ${{ values.name }}

${{ values.description }}

An Ansible role that applies a CIS-aligned security baseline to Debian-family
and Enterprise Linux servers. Each control is independent:

| Control | Toggle | Default here |
| --- | --- | --- |
| SSH daemon | `linux_hardening_sshd_enabled` | `${{ 'true' if values.manageSshd else 'false' }}` |
| Kernel parameters | `linux_hardening_sysctl_enabled` | `${{ 'true' if values.manageSysctl else 'false' }}` |
| Audit daemon | `linux_hardening_auditd_enabled` | `${{ 'true' if values.manageAuditd else 'false' }}` |
| Firewall (nftables) | `linux_hardening_firewall_enabled` | `${{ 'true' if values.manageFirewall else 'false' }}` |
| Unattended upgrades | `linux_hardening_updates_enabled` | `${{ 'true' if values.manageUpdates else 'false' }}` |

## Requirements

- ansible-core 2.18 or newer on the controller
- Ubuntu 24.04 or 26.04, Debian 12 or 13, or Enterprise Linux 9 or 10 targets, with systemd
- Privilege escalation on the target (`become: true`)

## Read this before the first run

- **Key-based SSH access must already work.** Password logins are switched off.
- **The firewall replaces the complete nftables ruleset** and masks firewalld
  and ufw. On container hosts, or where another tool owns the firewall, set
  `linux_hardening_firewall_enabled: false`.
- **`net.ipv4.ip_forward` is set to 0.** Routers, VPN gateways and container
  hosts need `linux_hardening_sysctl_overrides: {net.ipv4.ip_forward: 1}`.
- Try it on one host first: `ansible-playbook site.yml --limit host1 --check --diff`.

## Usage

```yaml
- name: Apply the hardening baseline
  hosts: all
  become: true
  roles:
    - role: ${{ values.name }}
      vars:
        linux_hardening_ssh_allow_groups:
          - ssh-users
        linux_hardening_firewall_ssh_sources_ipv4:
          - 10.0.0.0/8
        linux_hardening_firewall_allowed_tcp_ports:
          - 443
```

Apply a single control with its tag: `--tags hardening_sshd`,
`hardening_sysctl`, `hardening_auditd`, `hardening_firewall` or
`hardening_updates`.

`docs/controls.md` describes each control and where the defaults deliberately
differ from the benchmark; `docs/variables.md` lists every variable.

## Development

```bash
python -m venv .venv && . .venv/bin/activate
pip install -r requirements-dev.txt
ansible-galaxy collection install -r requirements.yml

yamllint .
ansible-lint
molecule test
MOLECULE_DISTRO=rockylinux10 molecule test
```

The Molecule scenario applies the role in a systemd container and asserts the
result of each enabled control. Kernel parameters and audit rules are written
but not loaded there, because a container shares its kernel with the machine
running the tests.

## Scope

The role follows published CIS Benchmark recommendations for the areas above.
It is not a complete or certified benchmark implementation; use a scanner such
as OpenSCAP to measure a host against a full profile.

## License

MIT

## Author

${{ values.owner }}
