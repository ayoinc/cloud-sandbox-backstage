# Controls

Each section names the CIS Benchmark area the control follows. Recommendation
numbers differ between distributions and benchmark versions, so areas are
named instead of numbered.

## SSH daemon

*Benchmark area: Configure SSH Server.*

A drop-in at `/etc/ssh/sshd_config.d/00-hardening.conf` is validated with
`sshd -t` before it replaces the previous version. sshd keeps the first value
it reads for a keyword, and the name sorts first, so the baseline wins over
cloud-init and distribution drop-ins.

- Root login and empty passwords are refused; password and keyboard-interactive logins are off
- `MaxAuthTries 4`, `LoginGraceTime 60`, `MaxStartups 10:30:60`, `MaxSessions 10`
- Idle sessions are probed every 300 seconds and closed after three missed replies
- TCP, agent and X11 forwarding are off
- Ciphers, MACs and key exchange are limited to AEAD or encrypt-then-MAC algorithms present in OpenSSH 8.7 and later
- `LogLevel VERBOSE` records the key fingerprint used for each login

The role does not change the port sshd listens on.

## Kernel parameters

*Benchmark areas: Configure Network Kernel Parameters; Configure Additional Process Hardening.*

Source routing, ICMP redirects and router advertisements are refused, reverse
path filtering and SYN cookies are on, martian packets are logged, address
space layout randomisation is full, core dumps of setuid programs are
disabled, and `ptrace`, `dmesg` and kernel pointers are restricted.

Exceptions go in `linux_hardening_sysctl_overrides`, per group or host.

## Audit daemon

*Benchmark area: Configure System Accounting (auditd).*

Rules record changes to time, identity files, hostname and network files,
sudoers, permissions and ownership, failed file access, mounts, deletions,
kernel module loading, privileged command execution, logins and sessions.
Rules are written for 64-bit and 32-bit system calls; system calls that do not
exist on the host's architecture are left out.

## Firewall

*Benchmark area: Configure a Host Based Firewall (nftables).*

One `inet` table: inbound and forwarded traffic is dropped by default;
loopback, established connections, essential ICMP, SSH and the listed ports are
accepted; outbound traffic is allowed. firewalld and ufw are stopped and
masked so that only one tool owns the ruleset.

## Unattended upgrades

*Benchmark area: Configure Package Updates.*

Security updates are downloaded and installed daily. Reboots stay manual
unless `linux_hardening_updates_automatic_reboot` is set.

## Deliberate deviations

| Setting | Benchmark | Default here | Why |
| --- | --- | --- | --- |
| `max_log_file_action` | `keep_logs` | `rotate` | Unbounded audit logs fill the disk; ship logs to a central store, then raise retention |
| `admin_space_left_action` | `single` or `halt` | `suspend` | Halting a production host on a full audit volume is a decision for the service owner |
| Immutable audit rules (`-e 2`) | Required | Off | With it on, every rule change needs a reboot; switch on once the rule set has settled |
| Outbound firewall policy | Default deny | Accept | Outbound allow-lists are specific to each workload |
| Automatic reboot | Not specified | Off | Reboots are scheduled by the service owner |

Each of these is a variable; set the benchmark value where policy requires it.
