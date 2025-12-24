# Usage Guide

## Getting Started

### Prerequisites

- PostgreSQL 15+ installed
- psql client
- Sufficient disk space for data and WAL

### Docker Compose Setup

```yaml
version: '3.8'
services:
  postgres:
    image: postgres:16-alpine
    container_name: postgres
    environment:
      POSTGRES_USER: admin
      POSTGRES_PASSWORD: secretpassword
      POSTGRES_DB: myapp
    ports:
      - "5432:5432"
    volumes:
      - pgdata:/var/lib/postgresql/data
      - ./init.sql:/docker-entrypoint-initdb.d/init.sql
    command:
      - "postgres"
      - "-c"
      - "shared_buffers=256MB"
      - "-c"
      - "max_connections=200"

volumes:
  pgdata:
```

## Examples

### Database Management

```sql
-- Create database
CREATE DATABASE myapp
  WITH OWNER = admin
       ENCODING = 'UTF8'
       LC_COLLATE = 'en_US.UTF-8'
       LC_CTYPE = 'en_US.UTF-8';

-- Create schema
CREATE SCHEMA IF NOT EXISTS app;

-- Grant privileges
GRANT ALL PRIVILEGES ON DATABASE myapp TO admin;
GRANT USAGE ON SCHEMA app TO readonly;
GRANT SELECT ON ALL TABLES IN SCHEMA app TO readonly;

-- Set search path
ALTER DATABASE myapp SET search_path TO app, public;
```

### Table Operations

```sql
-- Create table with best practices
CREATE TABLE app.users (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  email VARCHAR(255) NOT NULL UNIQUE,
  name VARCHAR(100) NOT NULL,
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes
CREATE INDEX idx_users_email ON app.users(email);
CREATE INDEX idx_users_metadata ON app.users USING GIN(metadata);
CREATE INDEX idx_users_created_at ON app.users(created_at DESC);

-- Partial index
CREATE INDEX idx_users_active ON app.users(email) 
  WHERE metadata->>'status' = 'active';

-- Add trigger for updated_at
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER users_updated_at
  BEFORE UPDATE ON app.users
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
```

### JSONB Operations

```sql
-- Insert with JSONB
INSERT INTO app.users (email, name, metadata)
VALUES (
  'john@example.com',
  'John Doe',
  '{"role": "admin", "preferences": {"theme": "dark"}}'
);

-- Query JSONB
SELECT * FROM app.users
WHERE metadata->>'role' = 'admin';

-- Update JSONB field
UPDATE app.users
SET metadata = jsonb_set(metadata, '{preferences,notifications}', 'true')
WHERE email = 'john@example.com';

-- JSONB containment
SELECT * FROM app.users
WHERE metadata @> '{"role": "admin"}';
```

### Partitioning

```sql
-- Create partitioned table
CREATE TABLE app.events (
  id BIGINT GENERATED ALWAYS AS IDENTITY,
  event_type VARCHAR(50) NOT NULL,
  payload JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
) PARTITION BY RANGE (created_at);

-- Create monthly partitions
CREATE TABLE app.events_2024_01 PARTITION OF app.events
  FOR VALUES FROM ('2024-01-01') TO ('2024-02-01');
CREATE TABLE app.events_2024_02 PARTITION OF app.events
  FOR VALUES FROM ('2024-02-01') TO ('2024-03-01');

-- Create default partition for unmatched data
CREATE TABLE app.events_default PARTITION OF app.events DEFAULT;

-- Create indexes on partitioned table
CREATE INDEX idx_events_created_at ON app.events(created_at);
CREATE INDEX idx_events_type ON app.events(event_type);
```

### Replication Setup

```bash
# On primary: Create replication user
psql -c "CREATE USER replicator WITH REPLICATION ENCRYPTED PASSWORD 'replication_password';"

# On primary: Add to pg_hba.conf
echo "host replication replicator 10.0.0.0/8 scram-sha-256" >> pg_hba.conf

# On replica: Create base backup
pg_basebackup -h primary -U replicator -D /var/lib/postgresql/data -Fp -Xs -P

# On replica: Configure recovery
cat > /var/lib/postgresql/data/postgresql.auto.conf << EOF
primary_conninfo = 'host=primary port=5432 user=replicator password=replication_password'
EOF

touch /var/lib/postgresql/data/standby.signal

# Start replica
pg_ctl start -D /var/lib/postgresql/data
```

### Backup and Recovery

#### Backup/Restore Workflow

```d2
direction: down

production: Production Database {
  style.fill: "#e8f5e9"
  
  primary: PostgreSQL Primary {
    shape: cylinder
    style.fill: "#c8e6c9"
  }
  
  wal: WAL Files {
    shape: document
    style.fill: "#fff9c4"
  }
  
  primary -> wal: Generate
}

backup_methods: Backup Methods {
  style.fill: "#e3f2fd"
  
  pg_dump: pg_dump {
    shape: rectangle
    style.fill: "#bbdefb"
    label: "pg_dump\n(Logical Backup)"
  }
  
  pg_basebackup: pg_basebackup {
    shape: rectangle
    style.fill: "#b3e5fc"
    label: "pg_basebackup\n(Physical Backup)"
  }
  
  wal_archive: WAL Archiving {
    shape: rectangle
    style.fill: "#b2ebf2"
    label: "WAL Archive\n(Continuous)"
  }
}

storage: Backup Storage {
  style.fill: "#fff3e0"
  
  dump_files: Dump Files {
    shape: document
    style.fill: "#ffe0b2"
    label: ".dump / .sql"
  }
  
  base_backup: Base Backup {
    shape: folder
    style.fill: "#ffccbc"
    label: "Data Directory\nSnapshot"
  }
  
  wal_files: Archived WAL {
    shape: document
    style.fill: "#d7ccc8"
    label: "WAL Segments"
  }
}

restore: Restore Options {
  style.fill: "#fce4ec"
  
  pg_restore: pg_restore {
    shape: rectangle
    style.fill: "#f8bbd9"
    label: "pg_restore\n(From Dump)"
  }
  
  pitr: PITR {
    shape: rectangle
    style.fill: "#f48fb1"
    label: "Point-in-Time\nRecovery"
  }
}

target: Target Database {
  style.fill: "#f3e5f5"
  
  restored_db: Restored DB {
    shape: cylinder
    style.fill: "#ce93d8"
  }
}

production.primary -> backup_methods.pg_dump: Logical
production.primary -> backup_methods.pg_basebackup: Physical
production.wal -> backup_methods.wal_archive: Archive

backup_methods.pg_dump -> storage.dump_files
backup_methods.pg_basebackup -> storage.base_backup
backup_methods.wal_archive -> storage.wal_files

storage.dump_files -> restore.pg_restore
storage.base_backup -> restore.pitr
storage.wal_files -> restore.pitr: Replay

restore.pg_restore -> target.restored_db
restore.pitr -> target.restored_db
```

```bash
# pg_dump - Logical backup
pg_dump -h localhost -U admin -d myapp -F c -f myapp.dump

# pg_dump specific tables
pg_dump -h localhost -U admin -d myapp -t 'app.users' -F c -f users.dump

# pg_dumpall - All databases
pg_dumpall -h localhost -U admin -f all_databases.sql

# Restore from dump
pg_restore -h localhost -U admin -d myapp -c myapp.dump

# pg_basebackup - Physical backup
pg_basebackup -h localhost -U admin -D /backup/base -Fp -Xs -P

# Point-in-time recovery
# 1. Stop PostgreSQL
# 2. Restore base backup
# 3. Configure recovery
cat > recovery.signal << EOF
EOF
cat >> postgresql.auto.conf << EOF
restore_command = 'cp /wal_archive/%f %p'
recovery_target_time = '2024-01-15 10:30:00'
recovery_target_action = 'promote'
EOF
# 4. Start PostgreSQL
```

### Performance Tuning

```sql
-- Analyze query plan
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT * FROM app.users WHERE email = 'john@example.com';

-- Force index scan
SET enable_seqscan = off;
EXPLAIN SELECT * FROM app.users WHERE email = 'john@example.com';
SET enable_seqscan = on;

-- Update statistics
ANALYZE app.users;

-- Vacuum
VACUUM (VERBOSE, ANALYZE) app.users;

-- Check bloat
SELECT 
  schemaname, tablename,
  pg_size_pretty(pg_total_relation_size(schemaname || '.' || tablename)) as total_size,
  n_dead_tup,
  n_live_tup,
  round(100.0 * n_dead_tup / NULLIF(n_live_tup + n_dead_tup, 0), 2) as dead_pct
FROM pg_stat_user_tables
ORDER BY n_dead_tup DESC;
```

### Connection Pooling with PgBouncer

```bash
# Start PgBouncer
docker run -d \
  --name pgbouncer \
  -e DATABASE_URL="postgresql://admin:secretpassword@postgres:5432/myapp" \
  -e POOL_MODE=transaction \
  -e MAX_CLIENT_CONN=1000 \
  -e DEFAULT_POOL_SIZE=20 \
  -p 6432:6432 \
  edoburu/pgbouncer

# Connect through PgBouncer
psql -h localhost -p 6432 -U admin -d myapp
```

## Troubleshooting

### Common Issues

| Issue | Cause | Solution |
|-------|-------|----------|
| Connection refused | PostgreSQL not running | Check `pg_ctl status` |
| Too many connections | Max connections exceeded | Use connection pooler |
| Slow queries | Missing indexes | Analyze with EXPLAIN |
| Disk full | WAL or data growth | Archive WAL, add space |
| Replication lag | Network or load issues | Check pg_stat_replication |

### Diagnostic Queries

```sql
-- Active connections
SELECT pid, usename, application_name, client_addr, state, query
FROM pg_stat_activity
WHERE state = 'active';

-- Blocking queries
SELECT blocked_locks.pid AS blocked_pid,
       blocked_activity.usename AS blocked_user,
       blocking_locks.pid AS blocking_pid,
       blocking_activity.usename AS blocking_user,
       blocked_activity.query AS blocked_statement
FROM pg_catalog.pg_locks blocked_locks
JOIN pg_catalog.pg_stat_activity blocked_activity ON blocked_activity.pid = blocked_locks.pid
JOIN pg_catalog.pg_locks blocking_locks ON blocking_locks.locktype = blocked_locks.locktype
JOIN pg_catalog.pg_stat_activity blocking_activity ON blocking_activity.pid = blocking_locks.pid
WHERE NOT blocked_locks.granted;

-- Replication status
SELECT client_addr, state, sent_lsn, write_lsn, flush_lsn, replay_lsn,
       pg_wal_lsn_diff(sent_lsn, replay_lsn) AS replication_lag
FROM pg_stat_replication;

-- Table sizes
SELECT schemaname, tablename,
       pg_size_pretty(pg_total_relation_size(schemaname || '.' || tablename)) as size
FROM pg_tables
WHERE schemaname NOT IN ('pg_catalog', 'information_schema')
ORDER BY pg_total_relation_size(schemaname || '.' || tablename) DESC
LIMIT 20;
```

### Kill Long-Running Queries

```sql
-- Cancel query (graceful)
SELECT pg_cancel_backend(pid);

-- Terminate connection (forceful)
SELECT pg_terminate_backend(pid);

-- Kill all idle connections
SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE state = 'idle'
  AND state_change < CURRENT_TIMESTAMP - INTERVAL '1 hour';
```
