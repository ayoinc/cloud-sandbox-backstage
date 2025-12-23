# Redis Cluster

High-performance, in-memory data store with clustering support for horizontal scaling, high availability, and sub-millisecond latency.

## Quick Start

### Start Redis Cluster with Docker

```bash
# Create a 6-node Redis Cluster (3 masters, 3 replicas)
docker network create redis-cluster

# Start Redis nodes
for port in $(seq 7000 7005); do
  docker run -d --name redis-$port --network redis-cluster \
    -p $port:$port -p 1$port:1$port \
    redis:7.2 redis-server \
    --port $port \
    --cluster-enabled yes \
    --cluster-config-file nodes.conf \
    --cluster-node-timeout 5000 \
    --appendonly yes \
    --protected-mode no
done

# Get container IPs
REDIS_IPS=""
for port in $(seq 7000 7005); do
  IP=$(docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' redis-$port)
  REDIS_IPS="$REDIS_IPS $IP:$port"
done

# Create the cluster
docker exec -it redis-7000 redis-cli --cluster create $REDIS_IPS --cluster-replicas 1 --cluster-yes
```

### Connect to Cluster

```bash
# Connect with cluster mode
redis-cli -c -h localhost -p 7000

# Check cluster status
redis-cli -c -p 7000 cluster info

# View cluster nodes
redis-cli -c -p 7000 cluster nodes
```

## Features

| Feature | Description |
|---------|-------------|
| **Clustering** | Automatic sharding across 16384 hash slots with data partitioning |
| **Replication** | Master-replica setup with automatic failover |
| **Persistence** | RDB snapshots and AOF (Append Only File) journaling |
| **Pub/Sub** | Real-time messaging with channels and patterns |
| **Lua Scripting** | Server-side scripting with atomic execution |
| **Streams** | Log-like data structure for event streaming |
| **Transactions** | MULTI/EXEC atomic command execution |
| **TTL Support** | Key expiration with millisecond precision |

## Architecture

```
                                 ┌──────────────────────────────────────────────────────────────┐
                                 │                        Redis Cluster                         │
                                 │                     (16384 Hash Slots)                       │
                                 └──────────────────────────────────────────────────────────────┘
                                                            │
        ┌───────────────────────────────────────────────────┼───────────────────────────────────────────────────┐
        │                                                   │                                                   │
┌───────▼───────┐                                   ┌───────▼───────┐                                   ┌───────▼───────┐
│   Master 1    │                                   │   Master 2    │                                   │   Master 3    │
│  Slots 0-5460 │                                   │ Slots 5461-   │                                   │ Slots 10923-  │
│   Port 7000   │                                   │  10922        │                                   │  16383        │
│               │                                   │  Port 7001    │                                   │  Port 7002    │
└───────┬───────┘                                   └───────┬───────┘                                   └───────┬───────┘
        │ Replication                                       │ Replication                                       │ Replication
        ▼                                                   ▼                                                   ▼
┌───────────────┐                                   ┌───────────────┐                                   ┌───────────────┐
│   Replica 1   │                                   │   Replica 2   │                                   │   Replica 3   │
│   Port 7003   │                                   │   Port 7004   │                                   │   Port 7005   │
└───────────────┘                                   └───────────────┘                                   └───────────────┘

                                           ┌─────────────────────────────┐
                                           │      Client Connection      │
                                           │    (Cluster-aware client)   │
                                           └─────────────────────────────┘
                                                          │
                                                          ▼
                                           ┌─────────────────────────────┐
                                           │   Key: "user:1234"          │
                                           │   CRC16("user:1234") % 16384│
                                           │   = Slot 6789 → Master 2    │
                                           └─────────────────────────────┘
```

## Deployment Modes

| Mode | Use Case | Nodes | HA |
|------|----------|-------|-----|
| **Standalone** | Development, caching | 1 | No |
| **Sentinel** | HA without sharding | 3+ Sentinels + 1 Master + Replicas | Yes |
| **Cluster** | Sharding + HA | 6+ (3 masters + 3 replicas minimum) | Yes |

## Data Types

| Type | Description | Example Use Case |
|------|-------------|------------------|
| **String** | Binary-safe strings, up to 512MB | Caching, counters, sessions |
| **List** | Linked list of strings | Message queues, activity feeds |
| **Set** | Unordered unique strings | Tags, unique visitors |
| **Sorted Set** | Ordered by score | Leaderboards, rate limiting |
| **Hash** | Field-value pairs | Objects, user profiles |
| **Stream** | Append-only log | Event sourcing, messaging |
| **Bitmap** | Bit operations | Feature flags, analytics |
| **HyperLogLog** | Cardinality estimation | Unique counts (probabilistic) |
| **Geospatial** | Location data | Nearby searches |

## Version Information

- **Redis Server**: 7.2.x (current stable)
- **Redis Stack**: 7.2.x (includes JSON, Search, TimeSeries)
- **Clients**: redis-py 5.x, ioredis 5.x, Jedis 5.x

## Related Documentation

- [Overview](overview.md) - Architecture, configuration, and security
- [Usage](usage.md) - Commands, patterns, and best practices
