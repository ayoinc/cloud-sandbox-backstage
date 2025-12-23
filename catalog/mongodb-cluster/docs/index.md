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

| Feature | Description |
|---------|-------------|
| **Replica Sets** | Automatic failover with primary election, data redundancy across nodes |
| **Sharding** | Horizontal scaling across multiple shards for large datasets |
| **Change Streams** | Real-time data change notifications for event-driven architectures |
| **Aggregation Pipeline** | Powerful data processing and analytics framework |
| **ACID Transactions** | Multi-document transactions with snapshot isolation |
| **Time Series Collections** | Optimized storage for time-series data (IoT, metrics) |
| **Atlas Search** | Full-text search with Lucene-based indexing |
| **Queryable Encryption** | Client-side field-level encryption with query support |

## Architecture

```
                                    ┌─────────────────────────────────────┐
                                    │           MongoDB Cluster           │
                                    └─────────────────────────────────────┘
                                                      │
                    ┌─────────────────────────────────┼─────────────────────────────────┐
                    │                                 │                                 │
            ┌───────▼───────┐                 ┌───────▼───────┐                 ┌───────▼───────┐
            │   Mongos      │                 │   Mongos      │                 │   Mongos      │
            │   Router      │                 │   Router      │                 │   Router      │
            └───────┬───────┘                 └───────┬───────┘                 └───────┬───────┘
                    │                                 │                                 │
                    └─────────────────────────────────┼─────────────────────────────────┘
                                                      │
            ┌─────────────────────────────────────────┼─────────────────────────────────────────┐
            │                                         │                                         │
    ┌───────▼───────┐                         ┌───────▼───────┐                         ┌───────▼───────┐
    │   Shard 1     │                         │   Shard 2     │                         │   Shard 3     │
    │  Replica Set  │                         │  Replica Set  │                         │  Replica Set  │
    ├───────────────┤                         ├───────────────┤                         ├───────────────┤
    │ P │ S │ S     │                         │ P │ S │ S     │                         │ P │ S │ S     │
    └───────────────┘                         └───────────────┘                         └───────────────┘

                              ┌─────────────────────────────────────┐
                              │      Config Server Replica Set      │
                              │         (Cluster Metadata)          │
                              ├─────────────────────────────────────┤
                              │       P    │    S    │    S         │
                              └─────────────────────────────────────┘

    P = Primary    S = Secondary
```

## Deployment Options

| Option | Use Case | Nodes |
|--------|----------|-------|
| **Replica Set** | High availability, read scaling | 3-7 members |
| **Sharded Cluster** | Horizontal scaling, large datasets | 2+ shards |
| **Standalone** | Development only | 1 node |

## Version Information

- **MongoDB Server**: 7.0.x (current LTS)
- **MongoDB Shell**: mongosh 2.x
- **Drivers**: Node.js 6.x, Python 4.x, Java 5.x

## Related Documentation

- [Overview](overview.md) - Architecture, components, and configuration
- [Usage](usage.md) - Operations, queries, and best practices
