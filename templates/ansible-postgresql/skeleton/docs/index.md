# ${{ values.name }}

${{ values.description }}

## Overview

| Setting | Value |
| --- | --- |
| PostgreSQL version | ${{ values.postgresVersion }} |
| Storage profile | `${{ values.storageType }}` |
| pgBackRest backups | ${{ 'enabled' if values.enableBackups else 'disabled' }} by default, `${{ values.backupRepoType }}` repository |
| Streaming replication | ${{ 'enabled' if values.enableReplication else 'disabled' }} by default |
| Owner | `${{ values.owner }}` |

## What happens on a run

1. The PGDG repository is added and the packages installed.
2. A cluster with data checksums is created if there is none. A new replica is copied from its primary instead.
3. pgBackRest is configured, when enabled.
4. `conf.d/00-ansible.conf` and `pg_hba.conf` are rendered; PostgreSQL is reloaded, and restarted only if a changed setting requires it.
5. On a primary: roles, replication slots, databases and extensions are brought to the declared state.
6. On a primary with backups: the stanza is created, archiving is checked and the backup timers are enabled.

## Where things are

| | Debian, Ubuntu | Enterprise Linux |
| --- | --- | --- |
| Data | `/var/lib/postgresql/<version>/main` | `/var/lib/pgsql/<version>/data` |
| Configuration | `/etc/postgresql/<version>/main` | the data directory |
| Service | `postgresql@<version>-main` | `postgresql-<version>` |
| pgBackRest configuration | `/etc/pgbackrest/pgbackrest.conf` | same |
| pgBackRest logs | `/var/log/pgbackrest` | same |

## Tags

`postgresql_install`, `postgresql_configure`, `postgresql_objects`,
`postgresql_backup`, `postgresql_replication`; `postgresql` selects all.
