# ZooKeeper Ensemble

Apache ZooKeeper distributed coordination service for configuration management, leader election, distributed locking, and service discovery.

## Quick Start

```bash
# Pull ZooKeeper image
docker pull zookeeper:3.9

# Run single node for development
docker run -d --name zookeeper \
  -p 2181:2181 \
  -p 2888:2888 \
  -p 3888:3888 \
  -e ZOO_MY_ID=1 \
  zookeeper:3.9

# Connect with zkCli
docker exec -it zookeeper zkCli.sh

# Basic operations
create /myapp "config data"
get /myapp
set /myapp "updated data"
delete /myapp
```

## Features

| Feature | Description | Use Case |
|---------|-------------|----------|
| **Configuration Management** | Centralized config storage with watch notifications | Dynamic app configuration |
| **Leader Election** | Automatic leader selection with failover | Master/worker patterns |
| **Distributed Locking** | Consistent locks across cluster nodes | Preventing race conditions |
| **Service Discovery** | Ephemeral nodes for service registration | Microservices routing |
| **Barrier Synchronization** | Coordinate distributed processes | Batch job coordination |
| **Queue Management** | FIFO ordering with sequential znodes | Distributed task queues |
| **Group Membership** | Track active cluster members | Health monitoring |

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     ZooKeeper Ensemble                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐         │
│  │  ZK Node 1  │◄──►│  ZK Node 2  │◄──►│  ZK Node 3  │         │
│  │  (Leader)   │    │  (Follower) │    │  (Follower) │         │
│  │  Port 2181  │    │  Port 2181  │    │  Port 2181  │         │
│  └──────┬──────┘    └──────┬──────┘    └──────┬──────┘         │
│         │                  │                  │                 │
│         └──────────────────┼──────────────────┘                 │
│                            │                                    │
│                    ZAB Protocol                                 │
│              (Atomic Broadcast)                                 │
│                                                                 │
├─────────────────────────────────────────────────────────────────┤
│                     Data Model (ZNodes)                         │
│                                                                 │
│                          /                                      │
│                    ┌─────┴─────┐                                │
│                    │           │                                │
│                 /kafka      /apps                               │
│                    │           │                                │
│            ┌───────┼───────┐   └──────┐                         │
│            │       │       │          │                         │
│        /brokers /topics /consumers  /myapp                      │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
        ┌─────────────────────────────────────────┐
        │              Clients                     │
        │  ┌───────┐  ┌───────┐  ┌───────────┐    │
        │  │ Kafka │  │ HBase │  │ Custom App│    │
        │  └───────┘  └───────┘  └───────────┘    │
        └─────────────────────────────────────────┘
```

## ZNode Types

| Type | Description | Use Case |
|------|-------------|----------|
| **Persistent** | Survives session disconnect | Configuration data |
| **Ephemeral** | Deleted when session ends | Service registration |
| **Sequential** | Auto-incrementing suffix | Leader election, queues |
| **Container** | Deleted when empty | Grouping ephemeral nodes |
| **TTL** | Expires after time limit | Temporary data (3.6+) |

## Version Information

| Component | Version | Release Date |
|-----------|---------|--------------|
| ZooKeeper | 3.9.2 | 2024 |
| Java | 11+ (17 recommended) | - |
| Curator Client | 5.6.0 | 2024 |
| kazoo (Python) | 2.10.0 | 2024 |

## Ports Reference

| Port | Protocol | Purpose |
|------|----------|---------|
| 2181 | TCP | Client connections |
| 2888 | TCP | Follower to leader |
| 3888 | TCP | Leader election |
| 8080 | HTTP | Admin server (3.5+) |
| 7000 | HTTP | Metrics endpoint |

## Related Documentation

- [Overview](overview.md) - Architecture, configuration, security, and monitoring
- [Usage](usage.md) - Deployment examples, recipes, and troubleshooting
