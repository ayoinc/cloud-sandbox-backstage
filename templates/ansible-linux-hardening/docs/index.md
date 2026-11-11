# Ansible Linux Hardening Baseline

Creates an Ansible role that applies a CIS-aligned security baseline to
Debian-family and Enterprise Linux servers. Each control area is a separate
task file behind its own toggle, so a team can adopt the baseline one control
at a time.

## Controls

| Control             | What the role manages                                                                                                                    |
| ------------------- | ---------------------------------------------------------------------------------------------------------------------------------------- |
| SSH daemon          | A validated drop-in in `/etc/ssh/sshd_config.d/`: no root login, no passwords, modern ciphers, idle timeouts, login banner               |
| Kernel parameters   | `/etc/sysctl.d/60-hardening.conf`: network stack and kernel self-protection settings                                                     |
| Audit daemon        | `auditd`, its retention settings and a rule set covering identity, time, permissions, access, mounts, deletions, sudo and kernel modules |
| Firewall            | A default-deny nftables ruleset that keeps SSH and the ports you list open                                                               |
| Unattended upgrades | `unattended-upgrades` on Debian and Ubuntu, `dnf-automatic` on Enterprise Linux, security updates only                                   |

The form's toggles set the defaults written to `defaults/main.yml`; every one
can still be overridden per host or group from inventory.

## What you get

- The role, with typed arguments in `meta/argument_specs.yml`
- A Molecule scenario with a verify playbook that asserts each enabled control
- A workflow running yamllint, ansible-lint (`production` profile) and Molecule on Ubuntu 24.04 and 26.04, Debian 13 and Rocky Linux 9 and 10
- TechDocs describing each control, the variables and the documented deviations from the benchmark

## Before applying to real hosts

- Password authentication is disabled. Make sure key-based access works first.
- The firewall replaces the whole nftables ruleset. Hosts running a container engine or another firewall manager need the firewall control switched off or the ruleset extended.
- Run with `--check --diff` against one host and read the diff.

"CIS-aligned" means the settings follow the published recommendations; the role
is not a certified benchmark implementation and does not replace an audit.
