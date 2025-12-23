# Overview

## Architecture

PostgreSQL clusters provide high availability through streaming replication and automatic failover mechanisms.

### Replication Types

| Type | Description | Use Case |
|------|-------------|----------|
| **Streaming** | Real-time WAL streaming | HA, read replicas |
| **Logical** | Row-level changes | Cross-version, selective |
| **Synchronous** | Wait for replica ACK | Zero data loss |
| **Asynchronous** | Fire and forget | Performance priority |

### Cluster Topologies

```
# Single Primary, Multiple Replicas
Primary ──WAL──> Replica 1 (sync)
        └──WAL──> Replica 2 (async)
        └──WAL──> Replica 3 (async)

# Cascading Replication
Primary ──WAL──> Replica 1 ──WAL──> Replica 2
                           └──WAL──> Replica 3
```

## Components

### Patroni (HA Manager)

Patroni manages PostgreSQL high availability using a distributed consensus store.

```yaml
# patroni.yml
scope: postgres-cluster
name: node1

restapi:
  listen: 0.0.0.0:8008
  connect_address: node1:8008

etcd3:
  hosts:
    - etcd1:2379
    - etcd2:2379
    - etcd3:2379

bootstrap:
  dcs:
    ttl: 30
    loop_wait: 10
    retry_timeout: 10
    maximum_lag_on_failover: 1048576
    postgresql:
      use_pg_rewind: true
      use_slots: true
      parameters:
        max_connections: 200
        shared_buffers: 2GB
        effective_cache_size: 6GB
        work_mem: 64MB
        maintenance_work_mem: 512MB

postgresql:
  listen: 0.0.0.0:5432
  connect_address: node1:5432
  data_dir: /var/lib/postgresql/data
  authentication:
    superuser:
      username: postgres
      password: superuser_password
    replication:
      username: replicator
      password: replication_password
```

### PgBouncer (Connection Pooler)

PgBouncer reduces connection overhead and improves performance.

```ini
# pgbouncer.ini
[databases]
myapp = host=primary.postgres port=5432 dbname=myapp

[pgbouncer]
listen_addr = 0.0.0.0
listen_port = 6432
auth_type = scram-sha-256
auth_file = /etc/pgbouncer/userlist.txt
pool_mode = transaction
max_client_conn = 1000
default_pool_size = 20
min_pool_size = 5
reserve_pool_size = 5
```

## Configuration

### postgresql.conf (Key Settings)

```ini
# Memory
shared_buffers = 4GB                    # 25% of RAM
effective_cache_size = 12GB             # 75% of RAM
work_mem = 64MB                         # Per-operation memory
maintenance_work_mem = 1GB              # For VACUUM, CREATE INDEX

# WAL and Checkpoints
wal_level = replica                     # Required for replication
max_wal_senders = 10                    # Replication connections
max_replication_slots = 10              # Replication slots
wal_keep_size = 1GB                     # WAL retention
checkpoint_completion_target = 0.9

# Query Planner
random_page_cost = 1.1                  # SSD optimization
effective_io_concurrency = 200          # SSD parallel reads

# Connections
max_connections = 200
superuser_reserved_connections = 3

# Logging
log_destination = 'csvlog'
logging_collector = on
log_directory = 'pg_log'
log_filename = 'postgresql-%Y-%m-%d.log'
log_min_duration_statement = 1000       # Log queries > 1 second
log_checkpoints = on
log_connections = on
log_disconnections = on
log_lock_waits = on

# Replication
synchronous_commit = on                 # or 'remote_apply' for sync
synchronous_standby_names = 'replica1'
```

### pg_hba.conf (Authentication)

```
# TYPE  DATABASE        USER            ADDRESS                 METHOD
local   all             postgres                                peer
local   all             all                                     scram-sha-256
host    all             all             127.0.0.1/32            scram-sha-256
host    all             all             10.0.0.0/8              scram-sha-256
host    replication     replicator      10.0.0.0/8              scram-sha-256

# SSL connections
hostssl all             all             0.0.0.0/0               scram-sha-256
```

### Environment Variables

```bash
# PostgreSQL
export PGHOST=localhost
export PGPORT=5432
export PGDATABASE=myapp
export PGUSER=admin
export PGPASSWORD=secretpassword

# Or use connection string
export DATABASE_URL="postgresql://admin:secretpassword@localhost:5432/myapp?sslmode=require"
```

## Security

### SSL/TLS Configuration

```ini
# postgresql.conf
ssl = on
ssl_cert_file = '/etc/postgresql/server.crt'
ssl_key_file = '/etc/postgresql/server.key'
ssl_ca_file = '/etc/postgresql/ca.crt'
ssl_min_protocol_version = 'TLSv1.2'
```

### Role-Based Access Control

```sql
-- Create roles
CREATE ROLE readonly;
CREATE ROLE readwrite;
CREATE ROLE admin;

-- Grant permissions
GRANT CONNECT ON DATABASE myapp TO readonly;
GRANT USAGE ON SCHEMA public TO readonly;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO readonly;

GRANT CONNECT ON DATABASE myapp TO readwrite;
GRANT USAGE ON SCHEMA public TO readwrite;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO readwrite;

-- Create users with roles
CREATE USER app_reader WITH PASSWORD 'reader_password';
GRANT readonly TO app_reader;

CREATE USER app_writer WITH PASSWORD 'writer_password';
GRANT readwrite TO app_writer;
```

## Monitoring

### Key Metrics

| Metric | Query | Alert Threshold |
|--------|-------|-----------------|
| Active connections | `SELECT count(*) FROM pg_stat_activity` | > 80% max |
| Replication lag | `SELECT pg_wal_lsn_diff(...)` | > 1MB |
| Cache hit ratio | `pg_stat_database` | < 95% |
| Transaction rate | `pg_stat_database.xact_commit` | Monitor trend |
| Dead tuples | `pg_stat_user_tables.n_dead_tup` | > 10% of live |

### pg_stat_statements

```sql
-- Enable extension
CREATE EXTENSION pg_stat_statements;

-- Top queries by time
SELECT 
  calls,
  round(total_exec_time::numeric, 2) as total_ms,
  round(mean_exec_time::numeric, 2) as mean_ms,
  round((100 * total_exec_time / sum(total_exec_time) OVER())::numeric, 2) as pct,
  substring(query, 1, 100) as query
FROM pg_stat_statements
ORDER BY total_exec_time DESC
LIMIT 20;
```

### Prometheus Exporter

```yaml
# docker-compose.yml
postgres_exporter:
  image: prometheuscommunity/postgres-exporter
  environment:
    DATA_SOURCE_NAME: "postgresql://postgres:password@postgres:5432/postgres?sslmode=disable"
  ports:
    - "9187:9187"
```
