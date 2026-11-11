# Ansible Windows Management

Creates a playbook repository for managing Windows servers and workstations
with Ansible, over WinRM or OpenSSH: a security baseline, Windows features,
software from Chocolatey or winget, and Windows Update with controlled reboots.

## What you get

| Path                        | Purpose                                                                                           |
| --------------------------- | ------------------------------------------------------------------------------------------------- |
| `inventory/`                | The hosts entered in the form and the connection settings for the chosen transport                |
| `playbooks/site.yml`        | Baseline, features and packages                                                                   |
| `playbooks/updates.yml`     | Windows Update in batches, stopping at the first failed batch                                     |
| `roles/win_baseline/`       | Time zone, firewall, protocol and credential hardening, account and audit policy, event log sizes |
| `roles/win_features/`       | Server roles and features, and optional features on client editions                               |
| `roles/win_packages/`       | Chocolatey and winget packages, each with name, optional version and state                        |
| `roles/win_patching/`       | Windows Update by category, with an exclusion list and optional reboot                            |
| `.github/workflows/ci.yaml` | yamllint, ansible-lint (`production` profile), inventory and syntax checks                        |

## Parameters

| Parameter            | Description                                                  |
| -------------------- | ------------------------------------------------------------ |
| Hosts                | Windows machines to manage                                   |
| Connection           | WinRM over HTTPS, or OpenSSH with PowerShell as the shell    |
| WinRM authentication | Kerberos for domain accounts, NTLM for local accounts        |
| Time zone            | Windows time zone name set on every host                     |
| Chocolatey, winget   | Which package managers the packages role uses                |
| Allow reboots        | Whether features and updates may restart a host on their own |

## Connection security

- WinRM is used over HTTPS on port 5986 with certificate validation on; the plain HTTP listener is never used
- Kerberos needs no stored password when the operator has a ticket; NTLM credentials come from Ansible Vault
- With OpenSSH, authentication is by key and host keys are checked

The baseline opens the management port in Windows Firewall before it turns
the firewall on, so applying it cannot cut off the connection it runs over.

## After scaffolding

1. Prepare the hosts for the chosen connection (an HTTPS WinRM listener, or the OpenSSH server); the README lists the steps.
2. Create the vault with the account to connect as.
3. Review `inventory/group_vars/windows/main.yml`, then run `ansible-playbook playbooks/site.yml --check --diff`.
