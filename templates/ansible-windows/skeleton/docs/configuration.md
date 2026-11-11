# Configuration

Settings live in `inventory/group_vars/windows/main.yml`. Any variable below
can be set there, or per host in `inventory/host_vars/<host>.yml`. Each role's
`defaults/main.yml` shows the full default values.

## win_baseline

| Variable | Type | Description |
| --- | --- | --- |
| `win_baseline_timezone` | str | Windows time zone name. |
| `win_baseline_firewall_enabled` | bool | Manage Windows Firewall. |
| `win_baseline_firewall_profiles` | list of str | Firewall profiles to enable. |
| `win_baseline_management_port` | raw | Port Ansible connects on; opened before the firewall is enabled. |
| `win_baseline_management_sources` | list of str | Sources allowed to reach the management port; any, or addresses and subnets. |
| `win_baseline_registry` | list of dict | Registry values to set. Each entry has path, name, data and optionally type. |
| `win_baseline_registry_extra` | list of dict | Further registry values, same shape. |
| `win_baseline_account_policy_enabled` | bool | Manage the local password and lockout policy. |
| `win_baseline_account_policy` | dict | System Access policy keys and values. |
| `win_baseline_audit_policy` | dict | Audit subcategory to a list of success and failure. |
| `win_baseline_event_logs` | dict | Event log name to maximum size. |
| `win_baseline_disabled_services` | list of str | Services to stop and disable. |

What the default registry values do:

| Setting | Effect |
| --- | --- |
| `SMB1` under `Parameters` | SMB version 1 server off |
| `RequireSecuritySignature` under `Parameters` | SMB server signing required |
| `RequireSecuritySignature` under `Parameters` | SMB client signing required |
| `LmCompatibilityLevel` under `Lsa` | NTLMv2 only; LM and NTLMv1 refused |
| `NoLMHash` under `Lsa` | No LAN Manager password hashes stored |
| `RestrictAnonymous` under `Lsa` | No anonymous enumeration of accounts and shares |
| `UseLogonCredential` under `WDigest` | No clear-text credentials kept in memory by WDigest |
| `EnableMulticast` under `DNSClient` | LLMNR name resolution off |
| `UserAuthentication` under `RDP-Tcp` | Remote Desktop requires Network Level Authentication |
| `EnableLUA` under `System` | User Account Control on |
| `SchUseStrongCrypto` under `v4.0.30319` | .NET uses current TLS versions (64-bit) |
| `SchUseStrongCrypto` under `v4.0.30319` | .NET uses current TLS versions (32-bit) |
| `Enabled` under `SSL 3.0\Server` | SSL 3.0 off (server) |
| `Enabled` under `SSL 3.0\Client` | SSL 3.0 off (client) |
| `Enabled` under `TLS 1.0\Server` | TLS 1.0 off (server) |
| `Enabled` under `TLS 1.0\Client` | TLS 1.0 off (client) |
| `Enabled` under `TLS 1.1\Server` | TLS 1.1 off (server) |
| `Enabled` under `TLS 1.1\Client` | TLS 1.1 off (client) |

Protocol changes take effect after a restart. Before applying to a host that
serves old clients, confirm nothing still needs TLS 1.0 or 1.1, SMB 1 or NTLMv1.

## win_features

| Variable | Type | Description |
| --- | --- | --- |
| `win_features_server_present` | list of str | Server roles and features to install. |
| `win_features_server_absent` | list of str | Server roles and features to remove. |
| `win_features_optional_present` | list of str | Optional features to enable on client editions. |
| `win_features_optional_absent` | list of str | Optional features to disable on client editions. |
| `win_features_allow_reboot` | bool | Restart when a feature change requires it. |
| `win_features_reboot_timeout` | int | Seconds to wait for the host to come back. |

## win_packages

| Variable | Type | Description |
| --- | --- | --- |
| `win_packages_chocolatey_enabled` | bool | Manage Chocolatey and its package list. |
| `win_packages_chocolatey` | list of dict | Chocolatey packages. Each entry has name and optionally version, state and pinned. |
| `win_packages_chocolatey_source_url` | str | URL of an internal feed. When set, the community feed is disabled. |
| `win_packages_chocolatey_source_name` | str | Name the internal feed is registered under. |
| `win_packages_winget_enabled` | bool | Manage the winget package list. |
| `win_packages_winget` | list of dict | winget packages. Each entry has id and optionally version and state. |
| `win_packages_winget_source` | str | winget source packages come from. |

```yaml
win_packages_chocolatey:
  - name: git
    version: 2.47.1
    pinned: true
  - name: googlechrome
    state: latest
  - name: adobereader
    state: absent

win_packages_winget:
  - id: Microsoft.VisualStudioCode
  - id: Git.Git
    version: 2.47.1
```

winget needs Windows 11 or Windows Server 2025 or newer, and installs with
machine scope.

## win_patching

| Variable | Type | Description |
| --- | --- | --- |
| `win_patching_categories` | list of str | Update classifications to install. |
| `win_patching_reject_list` | list of str | Updates never installed, as regular expressions matching title or KB number. |
| `win_patching_reboot` | bool | Restart when updates require it. |
| `win_patching_reboot_timeout` | int | Seconds to wait for the host to come back. |
| `win_patching_log_path` | str | Log written on the host by the update run. |

`playbooks/updates.yml` also reads `win_patching_batch`, the number or
percentage of hosts patched at a time (default `25%`).
