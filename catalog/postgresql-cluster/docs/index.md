# PostgreSQL Cluster

PostgreSQL is a powerful, open-source object-relational database system with over 35 years of active development. This documentation covers high-availability cluster configurations for production environments.

## Quick Start

```bash
# Run PostgreSQL with Docker
docker run -d \
  --name postgres \
  -e POSTGRES_USER=admin \
  -e POSTGRES_PASSWORD=secretpassword \
  -e POSTGRES_DB=myapp \
  -p 5432:5432 \
  -v pgdata:/var/lib/postgresql/data \
  postgres:16-alpine

# Connect with psql
psql -h localhost -U admin -d myapp

# Or use connection string
psql "postgresql://admin:secretpassword@localhost:5432/myapp"
```

## Key Features

| Feature | Description |
|---------|-------------|
| **ACID Compliance** | Full transaction support with rollback |
| **JSON/JSONB** | Native JSON storage and querying |
| **Full-Text Search** | Built-in text search capabilities |
| **Partitioning** | Table partitioning for large datasets |
| **Replication** | Streaming and logical replication |
| **Extensions** | PostGIS, TimescaleDB, pg_stat_statements |

## High Availability Options

| Solution | Description | Use Case |
|----------|-------------|----------|
| **Patroni** | HA cluster with automatic failover | Production HA clusters |
| **PgBouncer** | Connection pooling | High-connection workloads |
| **Pgpool-II** | Load balancing + connection pooling | Read-heavy workloads |
| **Citus** | Distributed PostgreSQL | Horizontal scaling |

## Architecture Overview

```
                         ┌─────────────────┐
                         │    PgBouncer    │
                         │  (Connection    │
                         │    Pooler)      │
                         └────────┬────────┘
                                  │
              ┌───────────────────┼───────────────────┐
              │                   │                   │
     ┌────────▼────────┐ ┌────────▼────────┐ ┌────────▼────────┐
     │   PostgreSQL    │ │   PostgreSQL    │ │   PostgreSQL    │
     │    Primary      │ │   Replica 1     │ │   Replica 2     │
     │   (Read/Write)  │ │   (Read-only)   │ │   (Read-only)   │
     └────────┬────────┘ └────────┬────────┘ └────────┬────────┘
              │                   │                   │
              │      Streaming Replication            │
              └───────────────────┴───────────────────┘
                                  │
                         ┌────────▼────────┐
                         │     Patroni     │
                         │  (HA Manager)   │
                         └────────┬────────┘
                                  │
                         ┌────────▼────────┐
                         │   etcd/Consul   │
                         │  (DCS Store)    │
                         └─────────────────┘
```

## Related Documentation

- [Overview](overview.md) - Architecture, replication, and configuration
- [Usage](usage.md) - SQL examples, backup strategies, and monitoring
