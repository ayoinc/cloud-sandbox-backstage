# ${{ values.name }}

${{ values.description }}

| | |
| --- | --- |
| Hosts | ${{ values.hosts | join(', ') }} |
| Connection | ${{ 'WinRM over HTTPS, port 5986, ' + values.winrmTransport + ' authentication' if values.connection == 'winrm' else 'OpenSSH, port 22, key authentication' }} |
| Time zone | `${{ values.timezone }}` |
| Package managers | ${{ 'Chocolatey' if values.useChocolatey else '' }}${{ ', ' if values.useChocolatey and values.useWinget else '' }}${{ 'winget' if values.useWinget else '' }}${{ 'none' if not values.useChocolatey and not values.useWinget else '' }} |
| Automatic reboots | ${{ 'allowed' if values.allowReboot else 'not allowed' }} |
| Owner | `${{ values.owner }}` |

## Roles

| Role | Does |
| --- | --- |
| `win_baseline` | Time zone, firewall, protocol and credential hardening, account policy, audit policy, event logs, services |
| `win_features` | Server roles and features on Windows Server; optional features on client editions |
| `win_packages` | Chocolatey and winget packages |
| `win_patching` | Windows Update by classification, exclusion list, optional restart |

## Layout

```
ansible.cfg
inventory/
├── hosts.yml
└── group_vars/windows/
    ├── main.yml                 # connection and settings
    └── vault.yml                # the account, encrypted (you create it)
playbooks/
├── site.yml
└── updates.yml
roles/
├── win_baseline/
├── win_features/
├── win_packages/
└── win_patching/
```

## Patching model

`playbooks/updates.yml` works through the inventory a quarter of the hosts at
a time. If any host in a batch fails, the run stops before the next batch.
Patch a canary group first with `--limit`, then the rest.
