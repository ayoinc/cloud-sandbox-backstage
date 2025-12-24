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

```d2
direction: down

title: ZooKeeper Ensemble Architecture {
  shape: text
  near: top-center
  style.font-size: 24
}

ensemble: ZooKeeper Ensemble {
  style.fill: "#E3F2FD"
  
  nodes: Node Cluster {
    style.fill: "#BBDEFB"
    
    zk1: ZK Node 1\n(Leader)\nPort 2181 {
      shape: hexagon
      style.fill: "#4CAF50"
      style.font-color: white
    }
    
    zk2: ZK Node 2\n(Follower)\nPort 2181 {
      shape: hexagon
      style.fill: "#2196F3"
      style.font-color: white
    }
    
    zk3: ZK Node 3\n(Follower)\nPort 2181 {
      shape: hexagon
      style.fill: "#2196F3"
      style.font-color: white
    }
    
    zk1 <-> zk2: ZAB Protocol
    zk2 <-> zk3: ZAB Protocol
    zk1 <-> zk3: ZAB Protocol {style.stroke-dash: 3}
  }
  
  znodes: Data Model (ZNodes) {
    style.fill: "#E8F5E9"
    
    root: / {shape: circle}
    kafka: /kafka {shape: rectangle}
    apps: /apps {shape: rectangle}
    brokers: /brokers {shape: document}
    topics: /topics {shape: document}
    consumers: /consumers {shape: document}
    myapp: /myapp {shape: document}
    
    root -> kafka
    root -> apps
    kafka -> brokers
    kafka -> topics
    kafka -> consumers
    apps -> myapp
  }
}

clients: Clients {
  style.fill: "#FFF3E0"
  
  kafka_client: Kafka {
    shape: rectangle
    style.fill: "#FF9800"
    style.font-color: white
  }
  
  hbase: HBase {
    shape: rectangle
    style.fill: "#FF9800"
    style.font-color: white
  }
  
  custom: Custom App {
    shape: rectangle
    style.fill: "#FF9800"
    style.font-color: white
  }
}

ensemble -> clients: Client Connections (2181)
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
