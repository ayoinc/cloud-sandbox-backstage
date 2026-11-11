# Ansible PostgreSQL Role

Creates an Ansible role that installs PostgreSQL from the PostgreSQL Global
Development Group (PGDG) repositories and runs it the way a production
database should be run: memory-aware tuning, SCRAM authentication, declared
roles and databases, encrypted pgBackRest backups with WAL archiving, and an
optional streaming replica.

## What the role manages

| Area                | Detail                                                                                                                                     |
| ------------------- | ------------------------------------------------------------------------------------------------------------------------------------------ |
| Installation        | PGDG apt or dnf repository with a pinned signing key, the selected major version, a cluster with data checksums                            |
| Configuration       | `conf.d/00-ansible.conf` computed from the host's memory and CPU count, overridable setting by setting; `pg_hba.conf` rendered from a list |
| Roles and databases | Declared in inventory, created over the local socket; passwords never logged                                                               |
| Backups             | pgBackRest: encrypted repository (local, S3, Azure or GCS), WAL archiving, weekly full and daily differential backups from systemd timers  |
| Replication         | Replication role and `pg_hba.conf` entries on the primary; replicas seeded once with `pg_basebackup` and never wiped again                 |

By default PostgreSQL listens on localhost only. Nothing is reachable from the
network until inventory says so.

## Parameters

| Parameter             | Description                                                                        |
| --------------------- | ---------------------------------------------------------------------------------- |
| PostgreSQL version    | Major version installed from PGDG                                                  |
| Storage               | Solid-state or spinning disks; sets planner cost and I/O concurrency               |
| pgBackRest backups    | Install and schedule backups, and archive WAL                                      |
| Backup repository     | Where backups are stored; object stores use the instance's own identity by default |
| Streaming replication | Prepare the primary for replicas and allow hosts to be seeded as replicas          |

## Secrets

The generated repository contains no secrets. The backup passphrase, the
replication password and role passwords are inventory variables with empty
defaults; the role refuses to run when one it needs is missing. Keep them in
Ansible Vault or a secrets manager lookup.

## Testing

The workflow lints with the ansible-lint `production` profile and runs Molecule
on Ubuntu 24.04, Debian 13 and Rocky Linux 9 and 10. The scenario converges a
single node with backups enabled, then checks settings, the database, the role
and the backup stanza. Replication needs two hosts and is not covered by the
container scenario; rehearse it in a staging environment.
