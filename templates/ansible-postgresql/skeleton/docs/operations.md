# Operations

Commands run as the `postgres` user on the database host unless noted.

## Backups

```bash
pgbackrest --stanza=main info                 # what the repository holds
pgbackrest --stanza=main check                # archiving works end to end
systemctl list-timers 'pgbackrest-*'          # next scheduled runs
systemctl start pgbackrest-backup@diff        # a backup now (root)
journalctl -u 'pgbackrest-backup@*' --since today
```

Keep a copy of `postgresql_pgbackrest_cipher_pass` somewhere that survives the
loss of every database host. Without it the repository cannot be read.

## Restore

Restore to the latest archived WAL, on the same host:

```bash
systemctl stop <service>                      # root
pgbackrest --stanza=main --delta restore
systemctl start <service>                     # root
```

Point-in-time recovery:

```bash
pgbackrest --stanza=main --delta \
  --type=time --target='2026-01-31 09:30:00+00' --target-action=promote restore
```

Rehearse a restore on a scratch host regularly; a backup that has never been
restored is a hope, not a backup.

## Replication

Check lag on the primary:

```sql
SELECT application_name, state, sent_lsn, replay_lsn, replay_lag FROM pg_stat_replication;
```

### Promote a replica

```bash
pg_ctlcluster <version> main promote          # Debian, Ubuntu
/usr/pgsql-<version>/bin/pg_ctl promote -D /var/lib/pgsql/<version>/data   # Enterprise Linux
```

Then set `postgresql_replication_role: primary` for that host in inventory and
point the remaining replicas' `postgresql_replication_primary_host` at it.
The role does not fail over on its own.

### Rebuild a replica

The role seeds a replica only when it created the host's empty cluster, so
rebuilding is explicit. Stop PostgreSQL on the replica, move its data
directory aside, create the seed marker and run the playbook for that host:

```bash
systemctl stop <service>
mv <data directory> <data directory>.old
install -o postgres -g postgres -m 0600 /dev/null ~postgres/.replica_seed_pending_<version>
```

On Enterprise Linux the marker is created automatically once the data
directory is gone.

## Major version upgrades

Changing `postgresql_version` installs the new version next to the old one and
creates a new, empty cluster; it does not migrate data. Use `pg_upgrade` or
logical replication, then retire the old cluster.
