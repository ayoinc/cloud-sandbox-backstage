# ${{ values.name }}

${{ values.description }}

## Overview

The role brings a server to a known security baseline and keeps it there. Run
it from the playbook that builds a host, and again on a schedule: every task
is idempotent, so a scheduled run reports exactly the drift it corrected.

| Control | Files written | Service |
| --- | --- | --- |
| SSH daemon | `/etc/ssh/sshd_config.d/00-hardening.conf`, `/etc/issue.net` | `ssh` / `sshd` reloaded |
| Kernel parameters | `/etc/sysctl.d/60-hardening.conf` | `sysctl --system` |
| Audit daemon | `/etc/audit/auditd.conf`, `/etc/audit/rules.d/50-hardening.rules` | `auditd` |
| Firewall | `/etc/nftables.conf` or `/etc/sysconfig/nftables.conf` | `nftables` |
| Unattended upgrades | `/etc/apt/apt.conf.d/20auto-upgrades`, `52unattended-upgrades-hardening`, or `/etc/dnf/automatic.conf` | apt timers / `dnf-automatic.timer` |

## Rollout

1. Confirm key-based SSH access for every operator.
2. Apply to one host with `--check --diff` and read the diff.
3. Apply to a canary group; keep a console session open while sshd reloads.
4. Apply everywhere, then schedule the playbook.

## Layout

```
${{ values.name }}/
├── defaults/main.yml           # Toggles and settings
├── vars/                       # Service and package names per family
├── tasks/                      # One file per control
├── handlers/main.yml           # Reloads, skipped when a control is not applied
├── templates/                  # sshd, sysctl, audit, nftables, update policy
├── meta/argument_specs.yml     # Typed role arguments
└── molecule/default/           # Converge and verify
```

## Owner

`${{ values.owner }}`
