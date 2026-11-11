# ${{ values.name }}

${{ values.description }}

Ansible playbooks for ${{ values.hosts | length }} Windows host(s), connecting over
${{ 'WinRM (HTTPS, ' + values.winrmTransport + ')' if values.connection == 'winrm' else 'OpenSSH' }}.

| Playbook | Purpose |
| --- | --- |
| `playbooks/site.yml` | Security baseline, Windows features and packages |
| `playbooks/updates.yml` | Windows Update, a batch of hosts at a time |

## Requirements

- A Linux or macOS control machine with Python 3.13 or newer (Ansible does not run on Windows itself; WSL works)
- Windows Server 2019 or newer, or Windows 10 or 11, with PowerShell 5.1 and .NET Framework 4.8
{%- if values.connection == 'winrm' %}
- An HTTPS WinRM listener on port 5986 on every host, with a certificate the control machine trusts
{%- if values.winrmTransport == 'kerberos' %}
- A domain account that is a local administrator on the hosts, and Kerberos client libraries on the control machine
{%- else %}
- A local administrator account on the hosts
{%- endif %}
{%- else %}
- The OpenSSH server on every host, with PowerShell as the default shell and your public key authorised
{%- endif %}

`docs/connecting.md` has the host-side setup.

## First run

```bash
python -m venv .venv && . .venv/bin/activate
pip install -r requirements-dev.txt
{%- if values.connection == 'winrm' and values.winrmTransport == 'kerberos' %}
pip install "pywinrm[kerberos]==0.5.0"
{%- endif %}
ansible-galaxy collection install -r requirements.yml

# The account to connect as, stored encrypted
ansible-vault create inventory/group_vars/windows/vault.yml
```

Put this in the vault:

```yaml
{%- if values.connection == 'winrm' and values.winrmTransport == 'kerberos' %}
vault_windows_user: svc-ansible@CORP.INTERNAL
# Leave out to use a ticket obtained with kinit instead of a stored password.
vault_windows_password: "..."
{%- elif values.connection == 'winrm' %}
vault_windows_user: ansible
vault_windows_password: "..."
{%- else %}
vault_windows_user: ansible
{%- endif %}
```

Then:

```bash
ansible windows -m ansible.windows.win_ping --ask-vault-pass
ansible-playbook playbooks/site.yml --check --diff --ask-vault-pass
ansible-playbook playbooks/site.yml --ask-vault-pass
```

## Day to day

| To | Do |
| --- | --- |
| Add a host | Add it to `inventory/hosts.yml` and run `site.yml --limit <host>` |
| Change a setting for all hosts | Edit `inventory/group_vars/windows/main.yml` |
| Change a setting for one host | Create `inventory/host_vars/<host>.yml` |
| Add or pin software | Edit the package lists in `inventory/group_vars/windows/main.yml` |
| Apply one area only | `--tags baseline`, `--tags features` or `--tags packages` |
| Patch | `ansible-playbook playbooks/updates.yml` |
| Patch and restart one host | `ansible-playbook playbooks/updates.yml --limit <host> -e win_patching_reboot=true` |

Automatic reboots are ${{ 'on' if values.allowReboot else 'off' }} by default
(`win_features_allow_reboot`, `win_patching_reboot`). When off, the playbooks
report which hosts still need a restart.

## What the baseline changes

- Enables Windows Firewall on all profiles with inbound traffic blocked, after allowing Ansible's own port
- Turns off SSL 3.0, TLS 1.0, TLS 1.1, SMB 1, LLMNR, WDigest credential caching and LM/NTLMv1
- Requires SMB signing and Network Level Authentication for Remote Desktop
- Sets the local password and lockout policy, the advanced audit policy and event log sizes
- Sets the time zone to `${{ values.timezone }}`

Every one of these is a variable; `docs/configuration.md` lists them. Check
with `--check --diff` before applying to hosts that serve legacy clients.

## Continuous integration

`.github/workflows/ci.yaml` runs yamllint, ansible-lint with the `production`
profile, an inventory check, a syntax check of every playbook and
PSScriptAnalyzer on each push to `main`. It never connects to the hosts.

## Owner

${{ values.owner }}
