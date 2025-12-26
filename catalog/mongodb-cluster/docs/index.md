# MongoDB Cluster

Production-ready MongoDB replica set and sharded cluster configuration for high availability and horizontal scalability.

## Quick Start

### Start a Replica Set with Docker

```bash
# Create a Docker network
docker network create mongodb-cluster

# Start primary node
docker run -d --name mongo-primary --network mongodb-cluster \
  -e MONGO_INITDB_ROOT_USERNAME=admin \
  -e MONGO_INITDB_ROOT_PASSWORD=secretpassword \
  -p 27017:27017 \
  mongo:7.0 --replSet rs0 --bind_ip_all

# Start secondary nodes
docker run -d --name mongo-secondary1 --network mongodb-cluster \
  -e MONGO_INITDB_ROOT_USERNAME=admin \
  -e MONGO_INITDB_ROOT_PASSWORD=secretpassword \
  mongo:7.0 --replSet rs0 --bind_ip_all

docker run -d --name mongo-secondary2 --network mongodb-cluster \
  -e MONGO_INITDB_ROOT_USERNAME=admin \
  -e MONGO_INITDB_ROOT_PASSWORD=secretpassword \
  mongo:7.0 --replSet rs0 --bind_ip_all

# Initialize replica set
docker exec -it mongo-primary mongosh -u admin -p secretpassword --eval '
rs.initiate({
  _id: "rs0",
  members: [
    { _id: 0, host: "mongo-primary:27017", priority: 2 },
    { _id: 1, host: "mongo-secondary1:27017", priority: 1 },
    { _id: 2, host: "mongo-secondary2:27017", priority: 1 }
  ]
})'
```

### Connect to Cluster

```bash
# Connection string for replica set
mongosh "mongodb://admin:secretpassword@mongo-primary:27017,mongo-secondary1:27017,mongo-secondary2:27017/?replicaSet=rs0&authSource=admin"

# Check replica set status
rs.status()
```

## Features

| Feature                     | Description                                                            |
| --------------------------- | ---------------------------------------------------------------------- |
| **Replica Sets**            | Automatic failover with primary election, data redundancy across nodes |
| **Sharding**                | Horizontal scaling across multiple shards for large datasets           |
| **Change Streams**          | Real-time data change notifications for event-driven architectures     |
| **Aggregation Pipeline**    | Powerful data processing and analytics framework                       |
| **ACID Transactions**       | Multi-document transactions with snapshot isolation                    |
| **Time Series Collections** | Optimized storage for time-series data (IoT, metrics)                  |
| **Atlas Search**            | Full-text search with Lucene-based indexing                            |
| **Queryable Encryption**    | Client-side field-level encryption with query support                  |

## Architecture

```d2
direction: down

title: MongoDB Sharded Cluster {
  style.fill: transparent
  style.font-size: 24
}

routers: Query Routers {
  direction: right
  style.fill: "#E3F2FD"

  mongos1: Mongos Router {
    style.fill: "#BBDEFB"
  }
  mongos2: Mongos Router {
    style.fill: "#BBDEFB"
  }
  mongos3: Mongos Router {
    style.fill: "#BBDEFB"
  }
}

shards: Shards {
  direction: right
  style.fill: "#E8F5E9"

  shard1: Shard 1 (Replica Set) {
    style.fill: "#C8E6C9"
    p1: Primary {
      style.fill: "#4CAF50"
    }
    s1a: Secondary {
      style.fill: "#81C784"
    }
    s1b: Secondary {
      style.fill: "#81C784"
    }
    p1 -> s1a: replication
    p1 -> s1b: replication
  }

  shard2: Shard 2 (Replica Set) {
    style.fill: "#C8E6C9"
    p2: Primary {
      style.fill: "#4CAF50"
    }
    s2a: Secondary {
      style.fill: "#81C784"
    }
    s2b: Secondary {
      style.fill: "#81C784"
    }
    p2 -> s2a: replication
    p2 -> s2b: replication
  }

  shard3: Shard 3 (Replica Set) {
    style.fill: "#C8E6C9"
    p3: Primary {
      style.fill: "#4CAF50"
    }
    s3a: Secondary {
      style.fill: "#81C784"
    }
    s3b: Secondary {
      style.fill: "#81C784"
    }
    p3 -> s3a: replication
    p3 -> s3b: replication
  }
}

config: Config Server Replica Set {
  style.fill: "#FFF3E0"
  desc: Cluster Metadata

  nodes: {
    direction: right
    cp: Primary {
      style.fill: "#FF9800"
    }
    cs1: Secondary {
      style.fill: "#FFB74D"
    }
    cs2: Secondary {
      style.fill: "#FFB74D"
    }
  }
}

routers.mongos1 -> shards: route queries
routers.mongos2 -> shards: route queries
routers.mongos3 -> shards: route queries
routers -> config: read metadata
```

**Legend:** P = Primary, S = Secondary

## Deployment Options

| Option              | Use Case                           | Nodes       |
| ------------------- | ---------------------------------- | ----------- |
| **Replica Set**     | High availability, read scaling    | 3-7 members |
| **Sharded Cluster** | Horizontal scaling, large datasets | 2+ shards   |
| **Standalone**      | Development only                   | 1 node      |

## Version Information

- **MongoDB Server**: 7.0.x (current LTS)
- **MongoDB Shell**: mongosh 2.x
- **Drivers**: Node.js 6.x, Python 4.x, Java 5.x

## Related Documentation

- [Overview](overview.md) - Architecture, components, and configuration
- [Usage](usage.md) - Operations, queries, and best practices
