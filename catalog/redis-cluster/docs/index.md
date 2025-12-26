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

| Feature           | Description                                                       |
| ----------------- | ----------------------------------------------------------------- |
| **Clustering**    | Automatic sharding across 16384 hash slots with data partitioning |
| **Replication**   | Master-replica setup with automatic failover                      |
| **Persistence**   | RDB snapshots and AOF (Append Only File) journaling               |
| **Pub/Sub**       | Real-time messaging with channels and patterns                    |
| **Lua Scripting** | Server-side scripting with atomic execution                       |
| **Streams**       | Log-like data structure for event streaming                       |
| **Transactions**  | MULTI/EXEC atomic command execution                               |
| **TTL Support**   | Key expiration with millisecond precision                         |

## Architecture

```d2
direction: down

title: Redis Cluster Topology {
  shape: text
  near: top-center
  style.font-size: 24
  style.bold: true
}

cluster: Redis Cluster (16384 Hash Slots) {
  style.fill: "#ffebee"
  style.stroke: "#c62828"
  style.stroke-width: 2

  masters: Master Nodes {
    style.fill: "#ffffff"

    m1: Master 1 {
      style.fill: "#d32f2f"
      style.font-color: "#ffffff"
      icon: https://icons.terrastruct.com/essentials%2F112-server.svg

      slots: "Slots 0-5460" {
        style.fill: "#ffcdd2"
        style.font-size: 12
      }
      port: "Port 7000" {
        style.fill: "#ef9a9a"
        style.font-size: 11
      }
    }

    m2: Master 2 {
      style.fill: "#1976d2"
      style.font-color: "#ffffff"
      icon: https://icons.terrastruct.com/essentials%2F112-server.svg

      slots: "Slots 5461-10922" {
        style.fill: "#bbdefb"
        style.font-size: 12
      }
      port: "Port 7001" {
        style.fill: "#90caf9"
        style.font-size: 11
      }
    }

    m3: Master 3 {
      style.fill: "#388e3c"
      style.font-color: "#ffffff"
      icon: https://icons.terrastruct.com/essentials%2F112-server.svg

      slots: "Slots 10923-16383" {
        style.fill: "#c8e6c9"
        style.font-size: 12
      }
      port: "Port 7002" {
        style.fill: "#a5d6a7"
        style.font-size: 11
      }
    }
  }

  replicas: Replica Nodes {
    style.fill: "#f5f5f5"

    r1: Replica 1 {
      style.fill: "#ef5350"
      style.font-color: white
      port: "Port 7003" {style.font-size: 11}
    }
    r2: Replica 2 {
      style.fill: "#42a5f5"
      style.font-color: white
      port: "Port 7004" {style.font-size: 11}
    }
    r3: Replica 3 {
      style.fill: "#66bb6a"
      style.font-color: white
      port: "Port 7005" {style.font-size: 11}
    }
  }

  masters.m1 -> replicas.r1: "Replication" {style.stroke: "#d32f2f"; style.stroke-dash: 3}
  masters.m2 -> replicas.r2: "Replication" {style.stroke: "#1976d2"; style.stroke-dash: 3}
  masters.m3 -> replicas.r3: "Replication" {style.stroke: "#388e3c"; style.stroke-dash: 3}

  masters.m1 <-> masters.m2: "Gossip" {style.stroke: "#9e9e9e"; style.stroke-dash: 5}
  masters.m2 <-> masters.m3: "Gossip" {style.stroke: "#9e9e9e"; style.stroke-dash: 5}
  masters.m1 <-> masters.m3: "Gossip" {style.stroke: "#9e9e9e"; style.stroke-dash: 5}
}

client: Cluster-Aware Client {
  style.fill: "#fff8e1"
  style.stroke: "#f57c00"
  shape: rectangle

  routing: Key Routing {
    style.fill: "#ffe0b2"

    key: 'Key: "user:1234"' {shape: text; style.font-size: 12}
    hash: 'CRC16("user:1234") % 16384' {shape: text; style.font-size: 11}
    result: "= Slot 6789 → Master 2" {shape: text; style.font-size: 11; style.bold: true}
  }
}

client -> cluster.masters.m2: "Routed Request" {style.stroke: "#1976d2"; style.stroke-width: 2}
client -> cluster.masters.m1: "MOVED redirect" {style.stroke: "#9e9e9e"; style.stroke-dash: 3}
client -> cluster.masters.m3: "MOVED redirect" {style.stroke: "#9e9e9e"; style.stroke-dash: 3}
```

## Deployment Modes

| Mode           | Use Case             | Nodes                               | HA  |
| -------------- | -------------------- | ----------------------------------- | --- |
| **Standalone** | Development, caching | 1                                   | No  |
| **Sentinel**   | HA without sharding  | 3+ Sentinels + 1 Master + Replicas  | Yes |
| **Cluster**    | Sharding + HA        | 6+ (3 masters + 3 replicas minimum) | Yes |

## Data Types

| Type            | Description                      | Example Use Case               |
| --------------- | -------------------------------- | ------------------------------ |
| **String**      | Binary-safe strings, up to 512MB | Caching, counters, sessions    |
| **List**        | Linked list of strings           | Message queues, activity feeds |
| **Set**         | Unordered unique strings         | Tags, unique visitors          |
| **Sorted Set**  | Ordered by score                 | Leaderboards, rate limiting    |
| **Hash**        | Field-value pairs                | Objects, user profiles         |
| **Stream**      | Append-only log                  | Event sourcing, messaging      |
| **Bitmap**      | Bit operations                   | Feature flags, analytics       |
| **HyperLogLog** | Cardinality estimation           | Unique counts (probabilistic)  |
| **Geospatial**  | Location data                    | Nearby searches                |

## Version Information

- **Redis Server**: 7.2.x (current stable)
- **Redis Stack**: 7.2.x (includes JSON, Search, TimeSeries)
- **Clients**: redis-py 5.x, ioredis 5.x, Jedis 5.x

## Related Documentation

- [Overview](overview.md) - Architecture, configuration, and security
- [Usage](usage.md) - Commands, patterns, and best practices
