# Redis Cluster Overview

## Architecture Deep Dive

### Cluster Data Distribution

Redis Cluster uses hash slots for data partitioning:

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                             Hash Slot Distribution                               │
│                                 (16384 slots)                                    │
├─────────────────────┬─────────────────────┬─────────────────────────────────────┤
│    Slots 0-5460     │   Slots 5461-10922  │         Slots 10923-16383           │
│     (Master 1)      │      (Master 2)     │            (Master 3)               │
├─────────────────────┼─────────────────────┼─────────────────────────────────────┤
│   Replica 1a        │    Replica 2a       │          Replica 3a                 │
│   Replica 1b        │    Replica 2b       │          Replica 3b                 │
└─────────────────────┴─────────────────────┴─────────────────────────────────────┘

Key Assignment:
  key = "user:1234"
  slot = CRC16(key) mod 16384
  slot = CRC16("user:1234") mod 16384 = 6789
  → Routes to Master 2 (handles slots 5461-10922)
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

```
                    ┌─────────────────────────────────────────┐
                    │            Sentinel Quorum              │
                    │         (Monitors & Failover)           │
                    └─────────────────────────────────────────┘
                                        │
            ┌───────────────────────────┼───────────────────────────┐
            │                           │                           │
    ┌───────▼───────┐           ┌───────▼───────┐           ┌───────▼───────┐
    │  Sentinel 1   │           │  Sentinel 2   │           │  Sentinel 3   │
    │  Port 26379   │           │  Port 26380   │           │  Port 26381   │
    └───────┬───────┘           └───────┬───────┘           └───────┬───────┘
            │                           │                           │
            └───────────────────────────┼───────────────────────────┘
                                        │ Monitors
                                        ▼
                              ┌─────────────────┐
                              │     Master      │
                              │   Port 6379     │
                              └────────┬────────┘
                                       │ Replication
                        ┌──────────────┴──────────────┐
                        ▼                              ▼
               ┌─────────────────┐            ┌─────────────────┐
               │    Replica 1    │            │    Replica 2    │
               │   Port 6380     │            │   Port 6381     │
               └─────────────────┘            └─────────────────┘
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

| Policy | Description | Use Case |
|--------|-------------|----------|
| `noeviction` | Return error on writes when full | Critical data |
| `allkeys-lru` | Evict least recently used | General caching |
| `allkeys-lfu` | Evict least frequently used | Hot/cold data |
| `volatile-lru` | LRU among keys with TTL | Mixed data |
| `volatile-lfu` | LFU among keys with TTL | Mixed with access patterns |
| `allkeys-random` | Random eviction | Uniform access |
| `volatile-random` | Random among TTL keys | Uniform TTL data |
| `volatile-ttl` | Evict shortest TTL first | Time-sensitive data |

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

| Feature | RDB (Snapshots) | AOF (Append Only File) |
|---------|-----------------|------------------------|
| **Durability** | Point-in-time | Every operation |
| **Performance** | Better | Slight overhead |
| **Recovery Speed** | Fast | Slower (replay) |
| **File Size** | Compact | Larger |
| **Data Loss Risk** | Minutes | Seconds (configurable) |

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

| Metric | Description | Alert Threshold |
|--------|-------------|-----------------|
| `used_memory` | Total memory used | > 80% of maxmemory |
| `connected_clients` | Current connections | > 80% of maxclients |
| `blocked_clients` | Clients waiting | > 0 sustained |
| `instantaneous_ops_per_sec` | Current throughput | Sudden drops |
| `hit_rate` | Cache hit ratio | < 90% |
| `evicted_keys` | Keys evicted | > 0 with LRU/LFU |
| `rejected_connections` | Connection failures | > 0 |
| `replication_lag` | Replica delay | > 1 second |
| `cluster_state` | Cluster health | != "ok" |

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
    REDIS_ADDR: "redis://redis-cluster:7000"
    REDIS_PASSWORD: "your-password"
  ports:
    - "9121:9121"

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
