# Variables

`meta/argument_specs.yml` is the authoritative reference; defaults are in
`defaults/main.yml`.

| Variable | Type | Description |
| --- | --- | --- |
| `linux_hardening_sshd_enabled` | bool | Apply the SSH daemon control. |
| `linux_hardening_sysctl_enabled` | bool | Apply the kernel parameter control. |
| `linux_hardening_auditd_enabled` | bool | Apply the audit daemon control. |
| `linux_hardening_firewall_enabled` | bool | Apply the firewall control. |
| `linux_hardening_updates_enabled` | bool | Apply the unattended upgrades control. |
| `linux_hardening_ssh_port` | int | Port sshd already listens on. Kept open by the firewall; the role does not move sshd. |
| `linux_hardening_ssh_permit_root_login` | str | Value of PermitRootLogin. |
| `linux_hardening_ssh_password_authentication` | bool | Allow password logins. |
| `linux_hardening_ssh_max_auth_tries` | int | Authentication attempts per connection. |
| `linux_hardening_ssh_max_sessions` | int | Sessions per network connection. |
| `linux_hardening_ssh_max_startups` | str | Limit on concurrent unauthenticated connections, as start:rate:full. |
| `linux_hardening_ssh_login_grace_time` | int | Seconds allowed to complete authentication. |
| `linux_hardening_ssh_client_alive_interval` | int | Seconds of silence before sshd probes the client. |
| `linux_hardening_ssh_client_alive_count_max` | int | Unanswered probes before the session is closed. |
| `linux_hardening_ssh_allow_tcp_forwarding` | bool | Allow TCP port forwarding. |
| `linux_hardening_ssh_allow_agent_forwarding` | bool | Allow agent forwarding. |
| `linux_hardening_ssh_x11_forwarding` | bool | Allow X11 forwarding. |
| `linux_hardening_ssh_log_level` | str | sshd log level. |
| `linux_hardening_ssh_allow_groups` | list of str | Groups allowed to log in. Empty leaves group membership unrestricted. |
| `linux_hardening_ssh_ciphers` | list of str | Accepted ciphers, in order of preference. |
| `linux_hardening_ssh_macs` | list of str | Accepted message authentication codes. |
| `linux_hardening_ssh_kex_algorithms` | list of str | Accepted key exchange algorithms. |
| `linux_hardening_ssh_banner` | str | Text shown before authentication. Empty disables the banner. |
| `linux_hardening_sysctl_apply` | bool | Load the settings into the running kernel as well as writing them. |
| `linux_hardening_sysctl_settings` | dict | Baseline kernel parameters, name to value. |
| `linux_hardening_sysctl_overrides` | dict | Merged over the baseline; the place for per-group exceptions. |
| `linux_hardening_auditd_apply` | bool | Start auditd and load the rules as well as writing them. |
| `linux_hardening_auditd_conf` | dict | Settings written to /etc/audit/auditd.conf. |
| `linux_hardening_auditd_backlog_limit` | int | Kernel audit backlog size. |
| `linux_hardening_auditd_immutable` | bool | Lock the rules until the next reboot. |
| `linux_hardening_auditd_extra_rules` | list of str | Extra rule lines in auditctl syntax. |
| `linux_hardening_firewall_apply` | bool | Load the ruleset and enable nftables as well as writing the file. |
| `linux_hardening_firewall_ssh_sources_ipv4` | list of str | IPv4 networks allowed to reach sshd. With both source lists empty, any source is allowed. |
| `linux_hardening_firewall_ssh_sources_ipv6` | list of str | IPv6 networks allowed to reach sshd. |
| `linux_hardening_firewall_allowed_tcp_ports` | list of int | Further inbound TCP ports to accept. |
| `linux_hardening_firewall_allowed_udp_ports` | list of int | Further inbound UDP ports to accept. |
| `linux_hardening_firewall_log_dropped` | bool | Log dropped inbound packets, rate limited. |
| `linux_hardening_updates_automatic_reboot` | bool | Reboot automatically when an update requires it. |
| `linux_hardening_updates_reboot_time` | str | Time of day for the automatic reboot, HH:MM (Debian and Ubuntu). |
| `linux_hardening_updates_remove_unused` | bool | Remove unused dependencies and old kernels (Debian and Ubuntu). |
