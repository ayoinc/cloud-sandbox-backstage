# Variables

`meta/argument_specs.yml` is the authoritative reference; defaults are in
`defaults/main.yml`.

| Variable | Type | Description |
| --- | --- | --- |
| `postgresql_version` | str | PostgreSQL major version installed from PGDG. |
| `postgresql_locale` | str | Locale of a newly created cluster. |
| `postgresql_encoding` | str | Encoding of a newly created cluster. |
| `postgresql_epel_enabled` | bool | Install epel-release on Enterprise Linux when pgBackRest is enabled. |
| `postgresql_listen_addresses` | list of str | Addresses to listen on. Only localhost by default. |
| `postgresql_port` | int | TCP port. |
| `postgresql_max_connections` | int | Maximum concurrent connections; also sizes work_mem. |
| `postgresql_tuning_enabled` | bool | Derive memory, parallelism and WAL settings from RAM and CPU count. |
| `postgresql_storage_type` | str | Kind of disk under the data directory. |
| `postgresql_settings` | dict | Settings merged last, over everything the role computes. |
| `postgresql_restart_on_change` | bool | Restart when a changed setting only takes effect at restart. |
| `postgresql_ssl_enabled` | bool | Enable TLS for client connections. |
| `postgresql_ssl_cert_file` | str | Path of the server certificate on the host. |
| `postgresql_ssl_key_file` | str | Path of the private key on the host. |
| `postgresql_hba_entries` | list of dict | Client authentication rules. Each entry has `database`, `user` and optionally `type` (default `hostssl`), `address` and `method` (default `scram-sha-256`). |
| `postgresql_users` | list of dict | Roles. Each entry has name and optionally password, role_attr_flags and state. |
| `postgresql_databases` | list of dict | Databases. Each entry has name and optionally owner, encoding, lc_collate, lc_ctype and state. |
| `postgresql_extensions` | list of dict | Extensions. Each entry has name, database and optionally schema and state. |
| `postgresql_replication_enabled` | bool | Prepare the primary for streaming replicas and allow replicas to be seeded. |
| `postgresql_replication_role` | str | Role of this host. |
| `postgresql_replication_user` | str | Name of the replication role. |
| `postgresql_replication_password` | str | Password of the replication role. Required when replication is enabled. |
| `postgresql_replication_allowed_addresses` | list of str | Networks replicas connect from, in CIDR notation. |
| `postgresql_replication_slots` | list of str | Physical replication slots kept on the primary. |
| `postgresql_replication_primary_host` | str | Address of the primary. Required on a replica. |
| `postgresql_replication_primary_port` | int | Port of the primary. |
| `postgresql_replication_slot_name` | str | Slot this replica streams from. Empty for none. |
| `postgresql_pgbackrest_enabled` | bool | Install pgBackRest, archive WAL and schedule backups. |
| `postgresql_pgbackrest_stanza` | str | Name of the backup stanza. |
| `postgresql_pgbackrest_repo_type` | str | Repository type. |
| `postgresql_pgbackrest_repo_path` | str | Directory or object prefix of the repository. |
| `postgresql_pgbackrest_repo_options` | dict | Further repository options written to the global section. |
| `postgresql_pgbackrest_encryption` | bool | Encrypt the repository with AES-256. |
| `postgresql_pgbackrest_cipher_pass` | str | Repository passphrase. Required when encryption is on. |
| `postgresql_pgbackrest_retention_full` | int | Full backups to keep. |
| `postgresql_pgbackrest_retention_diff` | int | Differential backups to keep. |
| `postgresql_pgbackrest_process_max` | int | Parallel processes for backup and restore. |
| `postgresql_pgbackrest_full_schedule` | str | systemd calendar expression for full backups. |
| `postgresql_pgbackrest_diff_schedule` | str | systemd calendar expression for differential backups. |
| `postgresql_pgbackrest_initial_backup` | bool | Start a full backup in the background when the stanza is first created. |
