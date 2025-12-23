# MongoDB Cluster Usage Guide

## Prerequisites

- Docker and Docker Compose (for containerized deployment)
- MongoDB Shell (`mongosh`) for administration
- Network connectivity between all cluster nodes
- Sufficient disk space (SSD recommended)
- Minimum 4GB RAM per node (8GB+ recommended for production)

## Deployment with Docker Compose

### Replica Set Deployment

```yaml
# docker-compose.yml
version: '3.8'

services:
  mongo-primary:
    image: mongo:7.0
    container_name: mongo-primary
    hostname: mongo-primary
    command: ["--replSet", "rs0", "--bind_ip_all", "--keyFile", "/etc/mongodb/keyfile"]
    environment:
      MONGO_INITDB_ROOT_USERNAME: admin
      MONGO_INITDB_ROOT_PASSWORD: ${MONGO_ROOT_PASSWORD:-secretpassword}
    volumes:
      - mongo-primary-data:/data/db
      - ./keyfile:/etc/mongodb/keyfile:ro
    ports:
      - "27017:27017"
    networks:
      - mongodb-cluster
    healthcheck:
      test: ["CMD", "mongosh", "--eval", "db.adminCommand('ping')"]
      interval: 10s
      timeout: 5s
      retries: 5

  mongo-secondary1:
    image: mongo:7.0
    container_name: mongo-secondary1
    hostname: mongo-secondary1
    command: ["--replSet", "rs0", "--bind_ip_all", "--keyFile", "/etc/mongodb/keyfile"]
    environment:
      MONGO_INITDB_ROOT_USERNAME: admin
      MONGO_INITDB_ROOT_PASSWORD: ${MONGO_ROOT_PASSWORD:-secretpassword}
    volumes:
      - mongo-secondary1-data:/data/db
      - ./keyfile:/etc/mongodb/keyfile:ro
    networks:
      - mongodb-cluster
    depends_on:
      - mongo-primary

  mongo-secondary2:
    image: mongo:7.0
    container_name: mongo-secondary2
    hostname: mongo-secondary2
    command: ["--replSet", "rs0", "--bind_ip_all", "--keyFile", "/etc/mongodb/keyfile"]
    environment:
      MONGO_INITDB_ROOT_USERNAME: admin
      MONGO_INITDB_ROOT_PASSWORD: ${MONGO_ROOT_PASSWORD:-secretpassword}
    volumes:
      - mongo-secondary2-data:/data/db
      - ./keyfile:/etc/mongodb/keyfile:ro
    networks:
      - mongodb-cluster
    depends_on:
      - mongo-primary

  mongo-express:
    image: mongo-express:latest
    container_name: mongo-express
    environment:
      ME_CONFIG_MONGODB_ADMINUSERNAME: admin
      ME_CONFIG_MONGODB_ADMINPASSWORD: ${MONGO_ROOT_PASSWORD:-secretpassword}
      ME_CONFIG_MONGODB_URL: mongodb://admin:${MONGO_ROOT_PASSWORD:-secretpassword}@mongo-primary:27017/?replicaSet=rs0
    ports:
      - "8081:8081"
    networks:
      - mongodb-cluster
    depends_on:
      - mongo-primary

volumes:
  mongo-primary-data:
  mongo-secondary1-data:
  mongo-secondary2-data:

networks:
  mongodb-cluster:
    driver: bridge
```

### Initialize Replica Set

```bash
# Generate keyfile for internal authentication
openssl rand -base64 756 > keyfile
chmod 400 keyfile

# Start the cluster
docker-compose up -d

# Wait for nodes to start
sleep 10

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

# Verify status
docker exec -it mongo-primary mongosh -u admin -p secretpassword --eval 'rs.status()'
```

## Kubernetes Deployment

### MongoDB Community Operator

```yaml
# mongodb-operator.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: mongodb
---
apiVersion: mongodbcommunity.mongodb.com/v1
kind: MongoDBCommunity
metadata:
  name: mongodb-cluster
  namespace: mongodb
spec:
  members: 3
  type: ReplicaSet
  version: "7.0.5"
  security:
    authentication:
      modes: ["SCRAM"]
  users:
    - name: admin
      db: admin
      passwordSecretRef:
        name: mongodb-admin-password
      roles:
        - name: root
          db: admin
      scramCredentialsSecretName: mongodb-admin-scram
    - name: appuser
      db: admin
      passwordSecretRef:
        name: mongodb-app-password
      roles:
        - name: readWrite
          db: myapp
      scramCredentialsSecretName: mongodb-app-scram
  statefulSet:
    spec:
      template:
        spec:
          containers:
            - name: mongod
              resources:
                limits:
                  cpu: "2"
                  memory: 4Gi
                requests:
                  cpu: "1"
                  memory: 2Gi
      volumeClaimTemplates:
        - metadata:
            name: data-volume
          spec:
            accessModes: ["ReadWriteOnce"]
            storageClassName: fast-ssd
            resources:
              requests:
                storage: 100Gi
---
apiVersion: v1
kind: Secret
metadata:
  name: mongodb-admin-password
  namespace: mongodb
type: Opaque
stringData:
  password: "secureAdminPassword123!"
---
apiVersion: v1
kind: Secret
metadata:
  name: mongodb-app-password
  namespace: mongodb
type: Opaque
stringData:
  password: "secureAppPassword123!"
```

```bash
# Install MongoDB Community Operator
kubectl apply -f https://raw.githubusercontent.com/mongodb/mongodb-kubernetes-operator/master/config/crd/bases/mongodbcommunity.mongodb.com_mongodbcommunity.yaml

# Deploy the cluster
kubectl apply -f mongodb-operator.yaml

# Check status
kubectl get mongodbcommunity -n mongodb
kubectl get pods -n mongodb
```

## Common Operations

### CRUD Operations

```javascript
// Connect to MongoDB
mongosh "mongodb://admin:password@localhost:27017/?replicaSet=rs0"

// Switch to database
use myapp

// Insert documents
db.users.insertOne({
  name: "John Doe",
  email: "john@example.com",
  createdAt: new Date(),
  roles: ["user"]
})

db.users.insertMany([
  { name: "Jane Smith", email: "jane@example.com", roles: ["admin"] },
  { name: "Bob Wilson", email: "bob@example.com", roles: ["user"] }
])

// Find documents
db.users.find({ roles: "admin" })
db.users.findOne({ email: "john@example.com" })

// Update documents
db.users.updateOne(
  { email: "john@example.com" },
  { $set: { lastLogin: new Date() }, $push: { roles: "moderator" } }
)

db.users.updateMany(
  { roles: "user" },
  { $set: { verified: true } }
)

// Delete documents
db.users.deleteOne({ email: "bob@example.com" })
db.users.deleteMany({ verified: false })
```

### Aggregation Pipeline

```javascript
// Sales analytics example
db.orders.aggregate([
  // Stage 1: Filter by date range
  {
    $match: {
      orderDate: {
        $gte: ISODate("2024-01-01"),
        $lt: ISODate("2025-01-01")
      }
    }
  },
  // Stage 2: Lookup customer details
  {
    $lookup: {
      from: "customers",
      localField: "customerId",
      foreignField: "_id",
      as: "customer"
    }
  },
  // Stage 3: Unwind customer array
  { $unwind: "$customer" },
  // Stage 4: Group by month
  {
    $group: {
      _id: {
        year: { $year: "$orderDate" },
        month: { $month: "$orderDate" }
      },
      totalRevenue: { $sum: "$total" },
      orderCount: { $sum: 1 },
      avgOrderValue: { $avg: "$total" },
      uniqueCustomers: { $addToSet: "$customerId" }
    }
  },
  // Stage 5: Add computed fields
  {
    $addFields: {
      uniqueCustomerCount: { $size: "$uniqueCustomers" }
    }
  },
  // Stage 6: Sort by date
  { $sort: { "_id.year": 1, "_id.month": 1 } },
  // Stage 7: Format output
  {
    $project: {
      _id: 0,
      period: {
        $concat: [
          { $toString: "$_id.year" },
          "-",
          { $cond: [{ $lt: ["$_id.month", 10] }, "0", ""] },
          { $toString: "$_id.month" }
        ]
      },
      totalRevenue: { $round: ["$totalRevenue", 2] },
      orderCount: 1,
      avgOrderValue: { $round: ["$avgOrderValue", 2] },
      uniqueCustomerCount: 1
    }
  }
])
```

### Transactions

```javascript
// Multi-document transaction example
const session = db.getMongo().startSession()
session.startTransaction({
  readConcern: { level: "snapshot" },
  writeConcern: { w: "majority" }
})

try {
  const accounts = session.getDatabase("bank").accounts
  
  // Transfer $100 from account A to account B
  accounts.updateOne(
    { _id: "accountA" },
    { $inc: { balance: -100 } },
    { session }
  )
  
  accounts.updateOne(
    { _id: "accountB" },
    { $inc: { balance: 100 } },
    { session }
  )
  
  // Record the transaction
  session.getDatabase("bank").transactions.insertOne({
    from: "accountA",
    to: "accountB",
    amount: 100,
    timestamp: new Date()
  }, { session })
  
  session.commitTransaction()
  print("Transaction committed successfully")
} catch (error) {
  session.abortTransaction()
  print("Transaction aborted: " + error.message)
} finally {
  session.endSession()
}
```

### Change Streams

```javascript
// Watch for changes in a collection
const pipeline = [
  { $match: { "operationType": { $in: ["insert", "update", "delete"] } } },
  { $match: { "fullDocument.status": "pending" } }
]

const changeStream = db.orders.watch(pipeline, {
  fullDocument: "updateLookup"
})

changeStream.on("change", (change) => {
  console.log("Change detected:", JSON.stringify(change, null, 2))
  
  switch (change.operationType) {
    case "insert":
      console.log("New order:", change.fullDocument._id)
      break
    case "update":
      console.log("Order updated:", change.documentKey._id)
      break
    case "delete":
      console.log("Order deleted:", change.documentKey._id)
      break
  }
})
```

## Cluster Management

### Add/Remove Replica Set Members

```javascript
// Add a new secondary
rs.add({ host: "mongo-secondary3:27017", priority: 1 })

// Add an arbiter
rs.addArb("mongo-arbiter:27017")

// Remove a member
rs.remove("mongo-secondary3:27017")

// Reconfigure member settings
cfg = rs.conf()
cfg.members[1].priority = 0
cfg.members[1].hidden = true
cfg.members[1].votes = 0
rs.reconfig(cfg)

// Step down primary (force election)
rs.stepDown(60)  // 60 seconds
```

### Enable Sharding

```javascript
// Connect to mongos
mongosh "mongodb://admin:password@mongos:27017"

// Enable sharding on database
sh.enableSharding("myapp")

// Shard a collection with hashed key
sh.shardCollection("myapp.events", { _id: "hashed" })

// Shard with range-based key
sh.shardCollection("myapp.logs", { timestamp: 1, category: 1 })

// Check sharding status
sh.status()

// View chunk distribution
db.chunks.find({ ns: "myapp.events" }).count()
```

## Performance Tuning

### Query Optimization

```javascript
// Explain query execution
db.orders.find({ customerId: ObjectId("..."), status: "pending" })
  .explain("executionStats")

// Create optimal index based on explain output
db.orders.createIndex(
  { customerId: 1, status: 1, orderDate: -1 },
  { name: "customer_status_date_idx" }
)

// Profile slow queries
db.setProfilingLevel(1, { slowms: 100 })

// View slow query log
db.system.profile.find().sort({ ts: -1 }).limit(10)
```

### Connection Pool Settings

```javascript
// Node.js connection with pool settings
const { MongoClient } = require('mongodb')

const client = new MongoClient(uri, {
  maxPoolSize: 100,
  minPoolSize: 10,
  maxIdleTimeMS: 30000,
  waitQueueTimeoutMS: 5000,
  serverSelectionTimeoutMS: 5000,
  socketTimeoutMS: 45000,
  compressors: ['snappy', 'zstd'],
  readPreference: 'secondaryPreferred',
  retryWrites: true,
  w: 'majority'
})
```

## Troubleshooting

| Issue | Cause | Solution |
|-------|-------|----------|
| Replica set election loops | Network partitions | Check connectivity between all nodes, verify firewall rules |
| High replication lag | Slow secondary, large oplog operations | Check secondary disk I/O, increase oplog size, check network bandwidth |
| Connection refused | Auth failure, max connections | Verify credentials, check `maxIncomingConnections` setting |
| Slow queries | Missing indexes | Run `explain()`, create appropriate compound indexes |
| Out of memory | Large result sets, insufficient cache | Add `limit()`, increase WiredTiger cache, add RAM |
| Write concern timeout | Network issues, slow secondaries | Check replica set health, reduce write concern level |
| `NotPrimaryError` | Writing to secondary | Use replica set connection string, check read preference |
| Chunk migration failures | Balancer issues | Check balancer status with `sh.status()`, verify config servers |

### Diagnostic Commands

```bash
# Check replica set status
docker exec mongo-primary mongosh --eval 'rs.status()' -u admin -p password

# Check oplog size and window
docker exec mongo-primary mongosh --eval 'rs.printReplicationInfo()' -u admin -p password

# View current operations
docker exec mongo-primary mongosh --eval 'db.currentOp()' -u admin -p password

# Check server stats
docker exec mongo-primary mongosh --eval 'db.serverStatus()' -u admin -p password

# Validate collection
docker exec mongo-primary mongosh --eval 'db.collection.validate()' -u admin -p password
```

## Best Practices

### Schema Design

1. **Embed vs Reference**: Embed related data accessed together; reference data accessed separately
2. **Document Size**: Keep documents under 16MB limit; consider bucketing patterns
3. **Array Growth**: Avoid unbounded arrays; use bucketing for time-series data
4. **Schema Versioning**: Include `schemaVersion` field for migrations

### Operational Best Practices

1. **Always use replica sets** - Even for development, use at least 3 members
2. **Enable authentication** - Use SCRAM-SHA-256 or x.509 certificates
3. **Use TLS/SSL** - Encrypt all connections in transit
4. **Monitor proactively** - Set up alerts for lag, connections, and disk usage
5. **Regular backups** - Test restore procedures regularly
6. **Index maintenance** - Review unused indexes, rebuild fragmented indexes
7. **Capacity planning** - Monitor disk usage, plan for growth
8. **Rolling upgrades** - Upgrade secondaries first, then step down primary

### Security Checklist

- [ ] Enable authentication (`--auth`)
- [ ] Use keyFile or x.509 for replica set auth
- [ ] Create specific users per application
- [ ] Enable TLS for all connections
- [ ] Restrict network access (bind to private IPs)
- [ ] Enable audit logging
- [ ] Regular security patches
- [ ] Encrypt data at rest (Enterprise feature)
