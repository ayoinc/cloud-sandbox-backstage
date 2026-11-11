# ${{ values.name }}

${{ values.description }}

An Ansible role that installs PostgreSQL ${{ values.postgresVersion }} from the PGDG repositories
and manages its configuration, roles, databases{% if values.enableBackups %}, pgBackRest backups{% endif %} and
streaming replication.

## Requirements

- ansible-core 2.18 or newer on the controller, with the collections in `requirements.yml`
- Ubuntu 24.04 or 26.04, Debian 12 or 13, or Enterprise Linux 9 or 10 targets, with systemd
- Privilege escalation on the target (`become: true`)
- Outbound HTTPS from targets to `apt.postgresql.org` or `download.postgresql.org`, or a mirror of them

## Secure by default

- Listens on `localhost` only until `postgresql_listen_addresses` says otherwise
- Passwords are stored and verified with SCRAM-SHA-256; no `trust` rules
- New clusters have data checksums
- The backup repository is encrypted; the role stops if no passphrase is supplied
- No secret has a default. Supply them from Ansible Vault:

```bash
ansible-vault create group_vars/postgresql/vault.yml
```

```yaml
postgresql_pgbackrest_cipher_pass: "{{ vault_postgresql_pgbackrest_cipher_pass }}"
postgresql_replication_password: "{{ vault_postgresql_replication_password }}"
```

## Usage

```yaml
- name: PostgreSQL
  hosts: postgresql
  become: true
  roles:
    - role: ${{ values.name }}
      vars:
        postgresql_listen_addresses: ['localhost', '{{ ansible_facts.default_ipv4.address }}']
        postgresql_hba_entries:
          - {type: hostssl, database: appdb, user: app, address: 10.20.0.0/16}
        postgresql_ssl_enabled: true
        postgresql_ssl_cert_file: /etc/ssl/postgresql/server.crt
        postgresql_ssl_key_file: /etc/ssl/postgresql/server.key
        postgresql_users:
          - {name: app, password: "{{ vault_app_db_password }}"}
        postgresql_databases:
          - {name: appdb, owner: app}
```

### Tuning

With `postgresql_tuning_enabled`, memory, parallelism and WAL settings are
derived from the host's RAM and CPU count (see `vars/main.yml`). Override any
single setting through `postgresql_settings`:

```yaml
postgresql_settings:
  work_mem: 64MB
  max_wal_size: 16GB
```

Settings that need a restart are detected from `pg_settings.pending_restart`;
set `postgresql_restart_on_change: false` to reload only and restart in a
maintenance window.

### Streaming replication

```yaml
# group_vars/postgresql.yml
postgresql_replication_enabled: true
postgresql_replication_allowed_addresses: [10.20.0.0/24]
postgresql_replication_slots: [db2]
postgresql_listen_addresses: ['*']

# host_vars/db2.yml
postgresql_replication_role: replica
postgresql_replication_primary_host: db1.internal
postgresql_replication_slot_name: db2
```

Run the primary first. A replica is copied from the primary once, when the
role creates its empty cluster; a host that already holds data is never wiped.
`docs/operations.md` covers promotion and rebuilding a replica.

### Backups

pgBackRest archives WAL continuously and runs a full backup weekly and a
differential backup on the other days. `docs/operations.md` shows how to
inspect, back up on demand and restore.

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

The Molecule scenario converges one node, checks settings, the declared role,
database and extension, then takes and inspects an encrypted full backup.
Replication needs two hosts and is not part of the container scenario.

## License

MIT

## Author

${{ values.owner }}
