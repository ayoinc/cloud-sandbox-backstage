# Redis Cluster Overview

## Redis Replication Architecture

```d2
direction: down

title: Redis Replication Model {
  shape: text
  near: top-center
  style.font-size: 24
  style.bold: true
}

# Master Node
master: Master Node {
  style.fill: "#e3f2fd"
  style.stroke: "#1565c2"
  style.stroke-width: 2

  server: Redis Server {
    shape: hexagon
    style.fill: "#1976d2"
    style.font-color: white
    icon: https://icons.terrastruct.com/essentials%2F112-server.svg
  }

  data: In-Memory Data {
    style.fill: "#bbdefb"

    strings: Strings {shape: cylinder; style.fill: "#64b5f6"}
    hashes: Hashes {shape: cylinder; style.fill: "#42a5f5"}
    lists: Lists {shape: cylinder; style.fill: "#2196f3"; style.font-color: white}
    sets: Sets {shape: cylinder; style.fill: "#1e88e5"; style.font-color: white}
  }

  aof: AOF Log {
    shape: document
    style.fill: "#90caf9"
  }

  rdb: RDB Snapshot {
    shape: document
    style.fill: "#64b5f6"
  }

  backlog: Replication Backlog {
    shape: queue
    style.fill: "#e3f2fd"
    style.stroke: "#1976d2"
  }
}

# Replication Stream
stream: Replication Stream {
  style.fill: "#fff3e0"
  style.stroke: "#ef6c00"

  sync: Sync Process {
    style.fill: "#ffe0b2"

    full: "1. Full Sync (RDB)" {shape: step; style.fill: "#ffb74d"}
    partial: "2. Partial Sync" {shape: step; style.fill: "#ffa726"}
    commands: "3. Command Stream" {shape: step; style.fill: "#ff9800"; style.font-color: white}

    full -> partial -> commands
  }
}

# Replica Nodes
replicas: Replica Nodes {
  style.fill: "#e8f5e9"
  style.stroke: "#2e7d32"

  r1: Replica 1 {
    style.fill: "#4caf50"
    style.font-color: white
    icon: https://icons.terrastruct.com/essentials%2F112-server.svg

    state: "Read-Only" {
      style.fill: "#81c784"
      style.font-size: 11
    }
    offset: "Offset: 12345678" {
      style.fill: "#a5d6a7"
      style.font-size: 10
    }
  }

  r2: Replica 2 {
    style.fill: "#43a047"
    style.font-color: white
    icon: https://icons.terrastruct.com/essentials%2F112-server.svg

    state: "Read-Only" {
      style.fill: "#81c784"
      style.font-size: 11
    }
    offset: "Offset: 12345670" {
      style.fill: "#a5d6a7"
      style.font-size: 10
    }
  }

  r3: Replica 3 {
    style.fill: "#388e3c"
    style.font-color: white
    icon: https://icons.terrastruct.com/essentials%2F112-server.svg

    state: "Read-Only" {
      style.fill: "#81c784"
      style.font-size: 11
    }
    offset: "Offset: 12345665" {
      style.fill: "#a5d6a7"
      style.font-size: 10
    }
  }
}

# Failover
failover: Automatic Failover {
  style.fill: "#fce4ec"
  style.stroke: "#c2185b"

  detect: "1. Detect Failure" {shape: diamond; style.fill: "#f48fb1"}
  elect: "2. Elect Leader" {shape: diamond; style.fill: "#ec407a"; style.font-color: white}
  promote: "3. Promote Replica" {shape: diamond; style.fill: "#e91e63"; style.font-color: white}

  detect -> elect -> promote
}

# Connections
master.server -> master.backlog: "Write to backlog"
master.backlog -> stream: "Replication"
stream -> replicas.r1: "Async" {style.stroke: "#4caf50"; style.stroke-width: 2}
stream -> replicas.r2: "Async" {style.stroke: "#43a047"; style.stroke-width: 2}
stream -> replicas.r3: "Async" {style.stroke: "#388e3c"; style.stroke-width: 2}

replicas -> failover: "On master failure" {style.stroke: "#c2185b"; style.stroke-dash: 3}
failover.promote -> master: "New Master" {style.stroke: "#c2185b"; style.stroke-dash: 5}
```

## Architecture Deep Dive

### Cluster Data Distribution

Redis Cluster uses hash slots for data partitioning:

```d2
direction: down

slots: Hash Slot Distribution (16384 slots) {
  master1: Master 1 - Slots 0-5460 {
    r1a: Replica 1a
    r1b: Replica 1b
  }

  master2: Master 2 - Slots 5461-10922 {
    r2a: Replica 2a
    r2b: Replica 2b
  }

  master3: Master 3 - Slots 10923-16383 {
    r3a: Replica 3a
    r3b: Replica 3b
  }
}

key_assignment: "Key Assignment: key='user:1234' → slot=CRC16(key) mod 16384 = 6789 → Routes to Master 2"
```

### Hash Tags for Co-location

```bash
# Keys with same hash tag are stored on same slot
SET {user:1000}.profile "..."
SET {user:1000}.settings "..."
SET {user:1000}.sessions "..."

# All three keys use hash tag {user:1000}
# CRC16 is calculated only on "user:1000"
# Enables multi-key operations like MGET
```

### Sentinel Architecture (HA without Sharding)

```d2
direction: down

sentinel_quorum: Sentinel Quorum (Monitors & Failover) {
  s1: Sentinel 1 (Port 26379) {
    shape: hexagon
  }
  s2: Sentinel 2 (Port 26380) {
    shape: hexagon
  }
  s3: Sentinel 3 (Port 26381) {
    shape: hexagon
  }
}

master: Master (Port 6379) {
  shape: cylinder
}

replicas: {
  r1: Replica 1 (Port 6380) {
    shape: cylinder
  }
  r2: Replica 2 (Port 6381) {
    shape: cylinder
  }
}

sentinel_quorum.s1 -> master: monitors
sentinel_quorum.s2 -> master: monitors
sentinel_quorum.s3 -> master: monitors
master -> replicas.r1: Replication
master -> replicas.r2: Replication
```

## Configuration

### Cluster Configuration

```bash
# redis.conf for cluster node
port 7000
cluster-enabled yes
cluster-config-file nodes-7000.conf
cluster-node-timeout 5000
cluster-replica-validity-factor 10
cluster-migration-barrier 1
cluster-require-full-coverage yes
cluster-replica-no-failover no

# Memory management
maxmemory 4gb
maxmemory-policy allkeys-lru

# Persistence
appendonly yes
appendfsync everysec
auto-aof-rewrite-percentage 100
auto-aof-rewrite-min-size 64mb

# RDB snapshots
save 900 1
save 300 10
save 60 10000

# Security
requirepass your-secure-password
masterauth your-secure-password

# Network
bind 0.0.0.0
protected-mode yes
tcp-backlog 511
timeout 0
tcp-keepalive 300
```

### Sentinel Configuration

```bash
# sentinel.conf
port 26379
sentinel monitor mymaster 127.0.0.1 6379 2
sentinel auth-pass mymaster your-secure-password
sentinel down-after-milliseconds mymaster 5000
sentinel failover-timeout mymaster 60000
sentinel parallel-syncs mymaster 1

# Notifications
sentinel notification-script mymaster /scripts/notify.sh
sentinel client-reconfig-script mymaster /scripts/reconfig.sh
```

### Memory Policies

| Policy            | Description                      | Use Case                   |
| ----------------- | -------------------------------- | -------------------------- |
| `noeviction`      | Return error on writes when full | Critical data              |
| `allkeys-lru`     | Evict least recently used        | General caching            |
| `allkeys-lfu`     | Evict least frequently used      | Hot/cold data              |
| `volatile-lru`    | LRU among keys with TTL          | Mixed data                 |
| `volatile-lfu`    | LFU among keys with TTL          | Mixed with access patterns |
| `allkeys-random`  | Random eviction                  | Uniform access             |
| `volatile-random` | Random among TTL keys            | Uniform TTL data           |
| `volatile-ttl`    | Evict shortest TTL first         | Time-sensitive data        |

## Security Configuration

### Authentication (Redis 6+)

```bash
# redis.conf - ACL configuration
user default off
user admin on >adminpassword ~* &* +@all
user appuser on >apppassword ~app:* &* +@read +@write -@admin
user readonly on >readpassword ~* &* +@read -@write

# Or use external ACL file
aclfile /etc/redis/users.acl
```

### ACL File Example

```bash
# /etc/redis/users.acl
user admin on >$2a$12$hashedpassword ~* &* +@all
user cache_writer on >$2a$12$hashedpassword ~cache:* +SET +GET +DEL +EXPIRE
user cache_reader on >$2a$12$hashedpassword ~cache:* +GET +MGET
user pubsub_user on >$2a$12$hashedpassword &notifications:* +SUBSCRIBE +PUBLISH
```

### TLS/SSL Configuration

```bash
# redis.conf - TLS settings
tls-port 6380
port 0  # Disable non-TLS port

tls-cert-file /etc/redis/tls/redis.crt
tls-key-file /etc/redis/tls/redis.key
tls-ca-cert-file /etc/redis/tls/ca.crt

tls-auth-clients yes
tls-protocols "TLSv1.2 TLSv1.3"
tls-ciphers "ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384"
tls-prefer-server-ciphers yes

# For cluster
tls-cluster yes
tls-replication yes
```

## Replication Configuration

### Master-Replica Setup

```bash
# On replica node
replicaof master-host 6379
masterauth your-master-password

# Replica settings
replica-serve-stale-data yes
replica-read-only yes
replica-priority 100

# Sync settings
repl-diskless-sync yes
repl-diskless-sync-delay 5
repl-ping-replica-period 10
repl-timeout 60
repl-backlog-size 1mb
repl-backlog-ttl 3600
```

## Persistence Options

### RDB vs AOF Comparison

| Feature            | RDB (Snapshots) | AOF (Append Only File) |
| ------------------ | --------------- | ---------------------- |
| **Durability**     | Point-in-time   | Every operation        |
| **Performance**    | Better          | Slight overhead        |
| **Recovery Speed** | Fast            | Slower (replay)        |
| **File Size**      | Compact         | Larger                 |
| **Data Loss Risk** | Minutes         | Seconds (configurable) |

### Recommended Persistence Strategy

```bash
# Production recommendation: Both RDB + AOF
appendonly yes
appendfsync everysec  # Balance durability/performance

# RDB as backup
save 900 1
save 300 10
save 60 10000

# AOF rewrite triggers
auto-aof-rewrite-percentage 100
auto-aof-rewrite-min-size 64mb

# Use RDB for faster restarts
aof-use-rdb-preamble yes
```

## Monitoring and Metrics

### Key Metrics

| Metric                      | Description         | Alert Threshold     |
| --------------------------- | ------------------- | ------------------- |
| `used_memory`               | Total memory used   | > 80% of maxmemory  |
| `connected_clients`         | Current connections | > 80% of maxclients |
| `blocked_clients`           | Clients waiting     | > 0 sustained       |
| `instantaneous_ops_per_sec` | Current throughput  | Sudden drops        |
| `hit_rate`                  | Cache hit ratio     | < 90%               |
| `evicted_keys`              | Keys evicted        | > 0 with LRU/LFU    |
| `rejected_connections`      | Connection failures | > 0                 |
| `replication_lag`           | Replica delay       | > 1 second          |
| `cluster_state`             | Cluster health      | != "ok"             |

### Redis INFO Command

```bash
# Get all stats
redis-cli INFO

# Specific sections
redis-cli INFO memory
redis-cli INFO replication
redis-cli INFO cluster
redis-cli INFO stats
redis-cli INFO clients
redis-cli INFO commandstats
```

### Prometheus Metrics

```yaml
# docker-compose.yml - Redis Exporter
redis-exporter:
  image: oliver006/redis_exporter:latest
  environment:
    REDIS_ADDR: 'redis://redis-cluster:7000'
    REDIS_PASSWORD: 'your-password'
  ports:
    - '9121:9121'

# Prometheus scrape config
scrape_configs:
  - job_name: 'redis'
    static_configs:
      - targets: ['redis-exporter:9121']
```

## Cluster Operations

### Resharding

```bash
# Move slots between nodes
redis-cli --cluster reshard redis-7000:7000 \
  --cluster-from <source-node-id> \
  --cluster-to <target-node-id> \
  --cluster-slots 1000 \
  --cluster-yes

# Rebalance cluster
redis-cli --cluster rebalance redis-7000:7000 \
  --cluster-use-empty-masters \
  --cluster-weight <node-id>=1
```

### Adding/Removing Nodes

```bash
# Add a new master
redis-cli --cluster add-node new-host:7006 existing-host:7000

# Add a new replica
redis-cli --cluster add-node new-host:7007 existing-host:7000 \
  --cluster-slave --cluster-master-id <master-node-id>

# Remove a node (after moving slots)
redis-cli --cluster del-node existing-host:7000 <node-id>
```

### Failover Operations

```bash
# Manual failover (on replica)
redis-cli -p 7003 CLUSTER FAILOVER

# Force failover (when master is down)
redis-cli -p 7003 CLUSTER FAILOVER FORCE

# Takeover (ignore master state)
redis-cli -p 7003 CLUSTER FAILOVER TAKEOVER
```

## Performance Tuning

### Latency Optimization

```bash
# Disable persistence for pure caching
appendonly no
save ""

# Disable transparent huge pages (Linux)
echo never > /sys/kernel/mm/transparent_hugepage/enabled

# Increase somaxconn
sysctl -w net.core.somaxconn=65535

# Redis config
tcp-backlog 65535
timeout 0
tcp-keepalive 300

# Disable slowlog in production testing
slowlog-log-slower-than -1
```

### Memory Optimization

```bash
# Use hash-max-ziplist for small hashes
hash-max-ziplist-entries 512
hash-max-ziplist-value 64

# Use list-max-ziplist for small lists
list-max-ziplist-size -2
list-compress-depth 0

# Use set-max-intset for integer sets
set-max-intset-entries 512

# Use zset-max-ziplist for small sorted sets
zset-max-ziplist-entries 128
zset-max-ziplist-value 64

# Active defragmentation (Redis 4+)
activedefrag yes
active-defrag-ignore-bytes 100mb
active-defrag-threshold-lower 10
active-defrag-threshold-upper 100
active-defrag-cycle-min 1
active-defrag-cycle-max 25
```
