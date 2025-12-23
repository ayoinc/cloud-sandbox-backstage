# MongoDB Cluster Overview

## Architecture Deep Dive

### Replica Set Architecture

A MongoDB replica set provides high availability through automatic failover and data redundancy.

```
                    ┌─────────────────────────────────────────────────────┐
                    │                  Replica Set (rs0)                  │
                    └─────────────────────────────────────────────────────┘
                                            │
        ┌───────────────────────────────────┼───────────────────────────────────┐
        │                                   │                                   │
┌───────▼───────┐                   ┌───────▼───────┐                   ┌───────▼───────┐
│    PRIMARY    │                   │   SECONDARY   │                   │   SECONDARY   │
│   (Writable)  │   ──Replication──▶│  (Read-only)  │   ──Replication──▶│   (Read-only) │
├───────────────┤                   ├───────────────┤                   ├───────────────┤
│ Oplog: 50GB   │                   │ Oplog: 50GB   │                   │ Oplog: 50GB   │
│ Data: /data/db│                   │ Data: /data/db│                   │ Data: /data/db│
│ Priority: 2   │                   │ Priority: 1   │                   │ Priority: 1   │
└───────────────┘                   └───────────────┘                   └───────────────┘
        │                                   │                                   │
        │                           ┌───────▼───────┐                           │
        │                           │   ARBITER     │                           │
        │                           │  (Vote only)  │◀──────────────────────────┘
        │                           │  No data      │
        │                           └───────────────┘
        │
        ▼
  ┌─────────────┐
  │ Application │
  │   Writes    │
  └─────────────┘
```

### Election Process

When the primary becomes unavailable:

1. **Detection**: Secondaries detect primary failure via heartbeat (every 2 seconds)
2. **Election Timeout**: After 10 seconds (default), election begins
3. **Voting**: Members with votes participate in election
4. **Priority**: Higher priority members preferred as primary
5. **New Primary**: Winning member becomes primary, accepts writes

### Sharding Architecture

For datasets exceeding single-server capacity:

| Component | Role | Recommended Count |
|-----------|------|-------------------|
| **Mongos** | Query router, distributes operations | 2+ (behind load balancer) |
| **Config Servers** | Store metadata, chunk mappings | 3 (replica set) |
| **Shards** | Store data partitions | 2+ (each a replica set) |

## Component Configuration

### Replica Set Member Types

| Type | Votes | Priority | Data | Use Case |
|------|-------|----------|------|----------|
| **Primary** | 1 | > 0 | Yes | Accept writes |
| **Secondary** | 1 | >= 0 | Yes | Read scaling, failover |
| **Arbiter** | 1 | 0 | No | Tie-breaking votes |
| **Hidden** | 0 or 1 | 0 | Yes | Backup, reporting |
| **Delayed** | 0 or 1 | 0 | Yes | Point-in-time recovery |

### Storage Engines

```yaml
# mongod.conf - WiredTiger Configuration
storage:
  dbPath: /data/db
  engine: wiredTiger
  wiredTiger:
    engineConfig:
      cacheSizeGB: 8                    # 50% of RAM - 1GB
      journalCompressor: snappy
      directoryForIndexes: true
    collectionConfig:
      blockCompressor: snappy           # Options: none, snappy, zlib, zstd
    indexConfig:
      prefixCompression: true
```

### Replication Configuration

```yaml
# mongod.conf - Replication Settings
replication:
  replSetName: rs0
  oplogSizeMB: 51200                    # 50GB oplog
  enableMajorityReadConcern: true

# For sharding
sharding:
  clusterRole: shardsvr                 # or configsvr
```

## Network Configuration

### Connection String Formats

```bash
# Standard replica set connection
mongodb://user:pass@host1:27017,host2:27017,host3:27017/database?replicaSet=rs0

# With read preference
mongodb://user:pass@host1:27017,host2:27017,host3:27017/database?replicaSet=rs0&readPreference=secondaryPreferred

# Sharded cluster
mongodb://user:pass@mongos1:27017,mongos2:27017/database

# With TLS/SSL
mongodb://user:pass@host1:27017/database?tls=true&tlsCAFile=/path/to/ca.pem

# SRV record (DNS seedlist)
mongodb+srv://user:pass@cluster.example.com/database
```

### Read Preferences

| Preference | Description | Use Case |
|------------|-------------|----------|
| `primary` | All reads from primary | Strong consistency required |
| `primaryPreferred` | Primary, fallback to secondary | Prefer consistency |
| `secondary` | All reads from secondaries | Read scaling |
| `secondaryPreferred` | Secondary, fallback to primary | Read scaling with fallback |
| `nearest` | Lowest latency member | Geo-distributed reads |

### Write Concerns

```javascript
// Write concern examples
db.collection.insertOne(
  { name: "example" },
  { 
    writeConcern: { 
      w: "majority",        // Wait for majority acknowledgment
      j: true,              // Wait for journal commit
      wtimeout: 5000        // Timeout in milliseconds
    }
  }
)
```

| Write Concern | Durability | Performance |
|---------------|------------|-------------|
| `w: 1` | Primary acknowledged | Fastest |
| `w: "majority"` | Majority acknowledged | Recommended |
| `w: <n>` | n members acknowledged | Specific requirements |
| `j: true` | Journal committed | Most durable |

## Security Configuration

### Authentication Methods

```yaml
# mongod.conf - Security Settings
security:
  authorization: enabled
  keyFile: /etc/mongodb/keyfile          # For replica set auth
  # Or use x.509 certificates
  clusterAuthMode: x509
  
net:
  tls:
    mode: requireTLS
    certificateKeyFile: /etc/mongodb/server.pem
    CAFile: /etc/mongodb/ca.pem
    allowConnectionsWithoutCertificates: false
```

### Role-Based Access Control (RBAC)

```javascript
// Create admin user
db.createUser({
  user: "admin",
  pwd: "securePassword",
  roles: [
    { role: "root", db: "admin" }
  ]
})

// Create application user
db.createUser({
  user: "appuser",
  pwd: "appPassword",
  roles: [
    { role: "readWrite", db: "myapp" },
    { role: "read", db: "analytics" }
  ]
})

// Create read-only user
db.createUser({
  user: "reader",
  pwd: "readerPassword",
  roles: [
    { role: "read", db: "myapp" }
  ]
})
```

### Built-in Roles

| Role | Database | Permissions |
|------|----------|-------------|
| `read` | Specific DB | Read all collections |
| `readWrite` | Specific DB | Read/write all collections |
| `dbAdmin` | Specific DB | Schema management, indexing |
| `dbOwner` | Specific DB | Full control of database |
| `clusterAdmin` | admin | Cluster management |
| `root` | admin | Superuser access |

## Indexing Strategy

### Index Types

```javascript
// Single field index
db.users.createIndex({ email: 1 })

// Compound index
db.orders.createIndex({ customerId: 1, orderDate: -1 })

// Unique index
db.users.createIndex({ email: 1 }, { unique: true })

// TTL index (auto-expire documents)
db.sessions.createIndex({ createdAt: 1 }, { expireAfterSeconds: 3600 })

// Text index (full-text search)
db.articles.createIndex({ title: "text", content: "text" })

// Geospatial index
db.locations.createIndex({ coordinates: "2dsphere" })

// Partial index
db.orders.createIndex(
  { status: 1 },
  { partialFilterExpression: { status: "pending" } }
)

// Wildcard index
db.products.createIndex({ "attributes.$**": 1 })
```

### Index Best Practices

| Practice | Description |
|----------|-------------|
| **ESR Rule** | Equality, Sort, Range order in compound indexes |
| **Covered Queries** | Include all query/projection fields in index |
| **Index Intersection** | MongoDB can use multiple indexes |
| **Background Building** | Use `background: true` for production |
| **Index Size** | Keep indexes in RAM for best performance |

## Monitoring and Metrics

### Key Metrics to Monitor

```javascript
// Server status
db.serverStatus()

// Replica set status
rs.status()

// Current operations
db.currentOp()

// Collection statistics
db.collection.stats()

// Index usage
db.collection.aggregate([{ $indexStats: {} }])
```

### Important Metrics

| Metric | Healthy Range | Alert Threshold |
|--------|---------------|-----------------|
| Replication Lag | < 10 seconds | > 60 seconds |
| Connections | < 80% of max | > 90% of max |
| Cache Usage | < 80% | > 95% |
| Oplog Window | > 24 hours | < 1 hour |
| Lock Percentage | < 5% | > 20% |
| Page Faults | Low | Sudden increase |

### Prometheus Metrics

```yaml
# MongoDB Exporter for Prometheus
- job_name: 'mongodb'
  static_configs:
    - targets: ['mongodb-exporter:9216']
  metrics_path: /metrics
```

## Backup Strategies

### Backup Methods

| Method | Use Case | RTO | RPO |
|--------|----------|-----|-----|
| **mongodump** | Small databases | Hours | Point-in-time |
| **Filesystem Snapshots** | Large databases | Minutes | Point-in-time |
| **Ops Manager / Atlas** | Enterprise | Minutes | Continuous |
| **Delayed Secondary** | Accidental deletion | Minutes | Delay window |

### mongodump Commands

```bash
# Full backup
mongodump --uri="mongodb://admin:pass@localhost:27017" \
  --out=/backup/$(date +%Y%m%d) \
  --oplog

# Compressed backup
mongodump --uri="mongodb://admin:pass@localhost:27017" \
  --archive=/backup/backup.gz \
  --gzip

# Restore
mongorestore --uri="mongodb://admin:pass@localhost:27017" \
  --archive=/backup/backup.gz \
  --gzip \
  --oplogReplay
```
