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

| Feature              | Description                              |
| -------------------- | ---------------------------------------- |
| **ACID Compliance**  | Full transaction support with rollback   |
| **JSON/JSONB**       | Native JSON storage and querying         |
| **Full-Text Search** | Built-in text search capabilities        |
| **Partitioning**     | Table partitioning for large datasets    |
| **Replication**      | Streaming and logical replication        |
| **Extensions**       | PostGIS, TimescaleDB, pg_stat_statements |

## High Availability Options

| Solution      | Description                         | Use Case                  |
| ------------- | ----------------------------------- | ------------------------- |
| **Patroni**   | HA cluster with automatic failover  | Production HA clusters    |
| **PgBouncer** | Connection pooling                  | High-connection workloads |
| **Pgpool-II** | Load balancing + connection pooling | Read-heavy workloads      |
| **Citus**     | Distributed PostgreSQL              | Horizontal scaling        |

## Architecture Overview

```d2
direction: down

clients: Clients {
  shape: rectangle
  style.fill: "#e3f2fd"
}

pgbouncer: PgBouncer {
  shape: rectangle
  style.fill: "#fff3e0"
  label: "PgBouncer\n(Connection Pooler)"
}

cluster: PostgreSQL Cluster {
  style.fill: "#f3e5f5"

  primary: Primary {
    shape: cylinder
    style.fill: "#c8e6c9"
    label: "PostgreSQL Primary\n(Read/Write)"
  }

  replica1: Replica 1 {
    shape: cylinder
    style.fill: "#bbdefb"
    label: "PostgreSQL Replica 1\n(Read-only)"
  }

  replica2: Replica 2 {
    shape: cylinder
    style.fill: "#bbdefb"
    label: "PostgreSQL Replica 2\n(Read-only)"
  }

  primary -> replica1: WAL Stream {style.stroke-dash: 3}
  primary -> replica2: WAL Stream {style.stroke-dash: 3}
}

ha: HA Management {
  style.fill: "#fff8e1"

  patroni: Patroni {
    shape: hexagon
    style.fill: "#ffe0b2"
    label: "Patroni\n(HA Manager)"
  }

  etcd: etcd Cluster {
    shape: cylinder
    style.fill: "#ffccbc"
    label: "etcd\n(DCS Store)"
  }

  patroni -> etcd: Leader Election
}

clients -> pgbouncer: SQL Queries
pgbouncer -> cluster.primary: Write
pgbouncer -> cluster.replica1: Read
pgbouncer -> cluster.replica2: Read
ha.patroni -> cluster.primary: Manage {style.stroke-dash: 3}
ha.patroni -> cluster.replica1: Manage {style.stroke-dash: 3}
ha.patroni -> cluster.replica2: Manage {style.stroke-dash: 3}
```

## Related Documentation

- [Overview](overview.md) - Architecture, replication, and configuration
- [Usage](usage.md) - SQL examples, backup strategies, and monitoring
