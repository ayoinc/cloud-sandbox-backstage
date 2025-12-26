# Redis Cluster Usage Guide

## Caching Patterns

```d2
direction: right

title: Redis Caching Patterns {
  shape: text
  near: top-center
  style.font-size: 24
  style.bold: true
}

# Cache-Aside Pattern
cache_aside: Cache-Aside Pattern {
  style.fill: "#e3f2fd"
  style.stroke: "#1565c2"
  style.stroke-width: 2

  app: Application {
    shape: rectangle
    style.fill: "#1976d2"
    style.font-color: white
  }

  cache: Redis Cache {
    shape: cylinder
    style.fill: "#42a5f5"
    style.font-color: white
  }

  db: Database {
    shape: cylinder
    style.fill: "#0d47a1"
    style.font-color: white
  }

  flow: Flow {
    style.fill: "#bbdefb"
    s1: "1. Check Cache" {shape: step; style.fill: "#64b5f6"}
    s2: "2. Cache Miss → Query DB" {shape: step; style.fill: "#42a5f5"; style.font-color: white}
    s3: "3. Store in Cache" {shape: step; style.fill: "#1e88e5"; style.font-color: white}
    s4: "4. Return Data" {shape: step; style.fill: "#1565c2"; style.font-color: white}

    s1 -> s2 -> s3 -> s4
  }

  app -> cache: "GET key" {style.stroke: "#4caf50"}
  cache -> app: "Cache Hit" {style.stroke: "#4caf50"; style.stroke-dash: 3}
  app -> db: "SELECT ..." {style.stroke: "#f44336"}
  app -> cache: "SETEX key TTL" {style.stroke: "#ff9800"}
}

# Write-Through Pattern
write_through: Write-Through Pattern {
  style.fill: "#fff3e0"
  style.stroke: "#ef6c00"
  style.stroke-width: 2

  app: Application {
    shape: rectangle
    style.fill: "#ff9800"
    style.font-color: white
  }

  cache: Redis Cache {
    shape: cylinder
    style.fill: "#ffb74d"
  }

  db: Database {
    shape: cylinder
    style.fill: "#e65100"
    style.font-color: white
  }

  flow: Flow {
    style.fill: "#ffe0b2"
    s1: "1. Write to Cache" {shape: step; style.fill: "#ffcc80"}
    s2: "2. Sync Write to DB" {shape: step; style.fill: "#ffb74d"}
    s3: "3. Confirm Write" {shape: step; style.fill: "#ffa726"}

    s1 -> s2 -> s3
  }

  app -> cache: "SET key value" {style.stroke: "#4caf50"; style.stroke-width: 2}
  cache -> db: "INSERT/UPDATE" {style.stroke: "#1976d2"; style.stroke-width: 2}
}

# Read-Through with TTL
read_through: Read-Through + TTL {
  style.fill: "#e8f5e9"
  style.stroke: "#2e7d32"
  style.stroke-width: 2

  client: Client {
    shape: rectangle
    style.fill: "#4caf50"
    style.font-color: white
  }

  service: Cache Service {
    shape: hexagon
    style.fill: "#66bb6a"
    style.font-color: white
  }

  redis: Redis {
    shape: cylinder
    style.fill: "#81c784"
  }

  source: Data Source {
    shape: cylinder
    style.fill: "#2e7d32"
    style.font-color: white
  }

  ttl: TTL Strategy {
    style.fill: "#c8e6c9"

    active: "Active: 1 hour" {shape: text; style.font-size: 11}
    stale: "Stale-while-revalidate" {shape: text; style.font-size: 11}
    refresh: "Background refresh" {shape: text; style.font-size: 11}
  }

  client -> service: "Request"
  service -> redis: "GET"
  redis -> service: "Hit/Miss"
  service -> source: "Fetch on miss"
  service -> redis: "SET with TTL"
}

# Distributed Lock
lock: Distributed Lock (Redlock) {
  style.fill: "#fce4ec"
  style.stroke: "#c2185b"
  style.stroke-width: 2

  worker: Worker Process {
    shape: rectangle
    style.fill: "#e91e63"
    style.font-color: white
  }

  nodes: Redis Nodes {
    style.fill: "#f8bbd9"

    n1: Node 1 {shape: cylinder; style.fill: "#f48fb1"}
    n2: Node 2 {shape: cylinder; style.fill: "#f48fb1"}
    n3: Node 3 {shape: cylinder; style.fill: "#f48fb1"}
  }

  lock_flow: Lock Flow {
    style.fill: "#fce4ec"

    acquire: "SET lock:resource NX PX 30000" {shape: step; style.fill: "#ec407a"; style.font-color: white}
    work: "Do Critical Work" {shape: step; style.fill: "#e91e63"; style.font-color: white}
    release: "DEL lock:resource (Lua)" {shape: step; style.fill: "#c2185b"; style.font-color: white}

    acquire -> work -> release
  }

  worker -> nodes.n1: "Lock" {style.stroke: "#c2185b"}
  worker -> nodes.n2: "Lock" {style.stroke: "#c2185b"}
  worker -> nodes.n3: "Lock" {style.stroke: "#c2185b"}
}
```

## Prerequisites

- Docker and Docker Compose (for containerized deployment)
- Redis CLI (`redis-cli`) for administration
- Network connectivity between all cluster nodes
- Minimum 1GB RAM per node (4GB+ recommended for production)

## Deployment with Docker Compose

### Redis Cluster (6 nodes)

```yaml
# docker-compose.yml
version: '3.8'

services:
  redis-node-1:
    image: redis:7.2
    container_name: redis-node-1
    command: redis-server /usr/local/etc/redis/redis.conf
    ports:
      - '7000:7000'
      - '17000:17000'
    volumes:
      - redis-node-1-data:/data
      - ./redis-cluster.conf:/usr/local/etc/redis/redis.conf
    environment:
      - REDIS_PORT=7000
    networks:
      - redis-cluster

  redis-node-2:
    image: redis:7.2
    container_name: redis-node-2
    command: redis-server /usr/local/etc/redis/redis.conf
    ports:
      - '7001:7001'
      - '17001:17001'
    volumes:
      - redis-node-2-data:/data
      - ./redis-cluster-7001.conf:/usr/local/etc/redis/redis.conf
    networks:
      - redis-cluster

  redis-node-3:
    image: redis:7.2
    container_name: redis-node-3
    command: redis-server /usr/local/etc/redis/redis.conf
    ports:
      - '7002:7002'
      - '17002:17002'
    volumes:
      - redis-node-3-data:/data
      - ./redis-cluster-7002.conf:/usr/local/etc/redis/redis.conf
    networks:
      - redis-cluster

  redis-node-4:
    image: redis:7.2
    container_name: redis-node-4
    command: redis-server /usr/local/etc/redis/redis.conf
    ports:
      - '7003:7003'
      - '17003:17003'
    volumes:
      - redis-node-4-data:/data
      - ./redis-cluster-7003.conf:/usr/local/etc/redis/redis.conf
    networks:
      - redis-cluster

  redis-node-5:
    image: redis:7.2
    container_name: redis-node-5
    command: redis-server /usr/local/etc/redis/redis.conf
    ports:
      - '7004:7004'
      - '17004:17004'
    volumes:
      - redis-node-5-data:/data
      - ./redis-cluster-7004.conf:/usr/local/etc/redis/redis.conf
    networks:
      - redis-cluster

  redis-node-6:
    image: redis:7.2
    container_name: redis-node-6
    command: redis-server /usr/local/etc/redis/redis.conf
    ports:
      - '7005:7005'
      - '17005:17005'
    volumes:
      - redis-node-6-data:/data
      - ./redis-cluster-7005.conf:/usr/local/etc/redis/redis.conf
    networks:
      - redis-cluster

  redis-cluster-init:
    image: redis:7.2
    container_name: redis-cluster-init
    depends_on:
      - redis-node-1
      - redis-node-2
      - redis-node-3
      - redis-node-4
      - redis-node-5
      - redis-node-6
    command: >
      bash -c "sleep 5 && redis-cli --cluster create 
      redis-node-1:7000 redis-node-2:7001 redis-node-3:7002 
      redis-node-4:7003 redis-node-5:7004 redis-node-6:7005 
      --cluster-replicas 1 --cluster-yes"
    networks:
      - redis-cluster

volumes:
  redis-node-1-data:
  redis-node-2-data:
  redis-node-3-data:
  redis-node-4-data:
  redis-node-5-data:
  redis-node-6-data:

networks:
  redis-cluster:
    driver: bridge
```

### Cluster Node Configuration

```bash
# redis-cluster.conf (template - adjust port per node)
port 7000
cluster-enabled yes
cluster-config-file nodes.conf
cluster-node-timeout 5000
appendonly yes
appendfsync everysec
protected-mode no
bind 0.0.0.0
maxmemory 1gb
maxmemory-policy allkeys-lru
```

## Kubernetes Deployment

### Redis Cluster with Bitnami Helm Chart

```bash
# Add Bitnami repo
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

# Install Redis Cluster
helm install redis-cluster bitnami/redis-cluster \
  --namespace redis \
  --create-namespace \
  --set cluster.nodes=6 \
  --set cluster.replicas=1 \
  --set password=your-secure-password \
  --set persistence.size=10Gi \
  --set redis.resources.requests.memory=1Gi \
  --set redis.resources.requests.cpu=500m
```

### Custom Kubernetes Manifests

```yaml
# redis-cluster-statefulset.yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: redis-cluster
  namespace: redis
spec:
  serviceName: redis-cluster
  replicas: 6
  selector:
    matchLabels:
      app: redis-cluster
  template:
    metadata:
      labels:
        app: redis-cluster
    spec:
      containers:
        - name: redis
          image: redis:7.2
          ports:
            - containerPort: 6379
              name: client
            - containerPort: 16379
              name: gossip
          command:
            - redis-server
          args:
            - --port 6379
            - --cluster-enabled yes
            - --cluster-config-file nodes.conf
            - --cluster-node-timeout 5000
            - --appendonly yes
            - --requirepass $(REDIS_PASSWORD)
            - --masterauth $(REDIS_PASSWORD)
          env:
            - name: REDIS_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: redis-cluster-secret
                  key: password
          volumeMounts:
            - name: data
              mountPath: /data
          resources:
            requests:
              cpu: 500m
              memory: 1Gi
            limits:
              cpu: 1000m
              memory: 2Gi
  volumeClaimTemplates:
    - metadata:
        name: data
      spec:
        accessModes: ['ReadWriteOnce']
        storageClassName: fast-ssd
        resources:
          requests:
            storage: 10Gi
---
apiVersion: v1
kind: Service
metadata:
  name: redis-cluster
  namespace: redis
spec:
  clusterIP: None
  ports:
    - port: 6379
      targetPort: 6379
      name: client
    - port: 16379
      targetPort: 16379
      name: gossip
  selector:
    app: redis-cluster
```

## Common Operations

### Basic Commands

```bash
# Connect to cluster
redis-cli -c -h localhost -p 7000 -a your-password

# String operations
SET user:1000:name "John Doe"
GET user:1000:name
SETEX session:abc123 3600 "session-data"  # Expires in 1 hour
INCR page:views
INCRBY counter:hits 10

# Hash operations
HSET user:1000 name "John" email "john@example.com" age 30
HGET user:1000 name
HGETALL user:1000
HINCRBY user:1000 age 1

# List operations
LPUSH notifications:user:1000 "New message"
RPUSH queue:jobs '{"type":"email","to":"user@example.com"}'
LPOP queue:jobs
LRANGE notifications:user:1000 0 -1
BRPOP queue:jobs 30  # Blocking pop with timeout

# Set operations
SADD tags:article:123 "redis" "database" "caching"
SMEMBERS tags:article:123
SISMEMBER tags:article:123 "redis"
SINTER tags:article:123 tags:article:456  # Intersection

# Sorted Set operations
ZADD leaderboard 100 "player1" 85 "player2" 95 "player3"
ZRANGE leaderboard 0 -1 WITHSCORES  # Ascending
ZREVRANGE leaderboard 0 2 WITHSCORES  # Top 3
ZINCRBY leaderboard 5 "player2"
ZRANK leaderboard "player1"
```

### Pub/Sub Messaging

```bash
# Subscriber (Terminal 1)
redis-cli -c -p 7000
SUBSCRIBE notifications:user:1000
PSUBSCRIBE notifications:*  # Pattern subscribe

# Publisher (Terminal 2)
redis-cli -c -p 7000
PUBLISH notifications:user:1000 '{"type":"message","content":"Hello!"}'
```

### Redis Streams

```bash
# Add events to stream
XADD events:orders * action "created" order_id "12345" customer "john"
XADD events:orders * action "paid" order_id "12345" amount "99.99"

# Read events
XRANGE events:orders - +  # All events
XRANGE events:orders - + COUNT 10  # Last 10

# Consumer groups
XGROUP CREATE events:orders order-processors $ MKSTREAM
XREADGROUP GROUP order-processors processor-1 COUNT 1 BLOCK 5000 STREAMS events:orders >

# Acknowledge processed event
XACK events:orders order-processors <message-id>

# Check pending messages
XPENDING events:orders order-processors
```

### Transactions

```bash
# Basic transaction
MULTI
SET account:1000:balance 100
SET account:1001:balance 200
EXEC

# Watch for optimistic locking
WATCH account:1000:balance
balance=$(redis-cli GET account:1000:balance)
MULTI
SET account:1000:balance $((balance - 50))
EXEC
# Returns nil if key changed between WATCH and EXEC
```

### Lua Scripting

```bash
# Atomic rate limiter script
redis-cli EVAL "
local key = KEYS[1]
local limit = tonumber(ARGV[1])
local window = tonumber(ARGV[2])
local current = redis.call('GET', key)
if current and tonumber(current) >= limit then
    return 0
end
current = redis.call('INCR', key)
if tonumber(current) == 1 then
    redis.call('EXPIRE', key, window)
end
return 1
" 1 "ratelimit:api:user:1000" 100 60

# Load script for reuse
redis-cli SCRIPT LOAD "return redis.call('GET', KEYS[1])"
# Returns SHA1 hash
redis-cli EVALSHA <sha1-hash> 1 mykey
```

## Client Code Examples

### Python (redis-py)

```python
import redis
from redis.cluster import RedisCluster

# Connect to cluster
rc = RedisCluster(
    host='localhost',
    port=7000,
    password='your-password',
    decode_responses=True
)

# Basic operations
rc.set('user:1000:name', 'John Doe')
name = rc.get('user:1000:name')

# Pipeline for batching
pipe = rc.pipeline()
for i in range(100):
    pipe.set(f'key:{i}', f'value:{i}')
pipe.execute()

# Hash operations
rc.hset('user:1000', mapping={
    'name': 'John Doe',
    'email': 'john@example.com',
    'age': 30
})
user = rc.hgetall('user:1000')

# Pub/Sub
pubsub = rc.pubsub()
pubsub.subscribe('notifications')
for message in pubsub.listen():
    print(message)
```

### Node.js (ioredis)

```javascript
const Redis = require('ioredis');

// Connect to cluster
const cluster = new Redis.Cluster(
  [
    { port: 7000, host: 'localhost' },
    { port: 7001, host: 'localhost' },
    { port: 7002, host: 'localhost' },
  ],
  {
    redisOptions: {
      password: 'your-password',
    },
  },
);

// Basic operations
await cluster.set('user:1000:name', 'John Doe');
const name = await cluster.get('user:1000:name');

// Pipeline
const pipeline = cluster.pipeline();
for (let i = 0; i < 100; i++) {
  pipeline.set(`key:${i}`, `value:${i}`);
}
await pipeline.exec();

// Streams
await cluster.xadd('events', '*', 'action', 'click', 'user', '1000');
const events = await cluster.xrange('events', '-', '+', 'COUNT', 10);

// Pub/Sub
const subscriber = cluster.duplicate();
subscriber.subscribe('notifications', (err, count) => {
  console.log(`Subscribed to ${count} channels`);
});
subscriber.on('message', (channel, message) => {
  console.log(`Received: ${message}`);
});
```

## Caching Patterns

### Cache-Aside Pattern

```python
def get_user(user_id):
    # Try cache first
    cached = redis.get(f'user:{user_id}')
    if cached:
        return json.loads(cached)

    # Cache miss - fetch from database
    user = db.query(f"SELECT * FROM users WHERE id = {user_id}")

    # Store in cache with TTL
    redis.setex(f'user:{user_id}', 3600, json.dumps(user))

    return user

def update_user(user_id, data):
    # Update database
    db.execute(f"UPDATE users SET ... WHERE id = {user_id}")

    # Invalidate cache
    redis.delete(f'user:{user_id}')
```

### Write-Through Pattern

```python
def update_user(user_id, data):
    # Update cache first
    redis.hset(f'user:{user_id}', mapping=data)
    redis.expire(f'user:{user_id}', 3600)

    # Then update database
    db.execute(f"UPDATE users SET ... WHERE id = {user_id}")
```

### Distributed Locking

```python
import redis
import uuid
import time

def acquire_lock(lock_name, timeout=10):
    identifier = str(uuid.uuid4())
    lock_key = f'lock:{lock_name}'

    if redis.set(lock_key, identifier, nx=True, ex=timeout):
        return identifier
    return None

def release_lock(lock_name, identifier):
    lock_key = f'lock:{lock_name}'

    # Lua script for atomic check-and-delete
    script = """
    if redis.call('get', KEYS[1]) == ARGV[1] then
        return redis.call('del', KEYS[1])
    else
        return 0
    end
    """
    return redis.eval(script, 1, lock_key, identifier)

# Usage
lock_id = acquire_lock('process-orders')
if lock_id:
    try:
        # Do work
        process_orders()
    finally:
        release_lock('process-orders', lock_id)
```

## Troubleshooting

| Issue                               | Cause                                | Solution                                              |
| ----------------------------------- | ------------------------------------ | ----------------------------------------------------- |
| `CLUSTERDOWN` error                 | Not enough masters available         | Ensure quorum of masters (N/2 + 1), check node health |
| `MOVED` error in non-cluster client | Using single-node client for cluster | Use cluster-aware client (`redis-cli -c`)             |
| High latency                        | Slow commands, persistence           | Check `SLOWLOG`, disable AOF fsync, use pipeline      |
| `OOM` errors                        | Memory limit reached                 | Increase `maxmemory`, set eviction policy             |
| Replication lag                     | Slow replica, network issues         | Check replica resources, increase `repl-backlog-size` |
| Connection refused                  | Max connections reached              | Increase `maxclients`, check connection leaks         |
| Cluster slot gaps                   | Incomplete resharding                | Run `redis-cli --cluster fix`                         |
| Split brain                         | Network partition                    | Ensure proper `cluster-node-timeout`, check network   |

### Diagnostic Commands

```bash
# Cluster health
redis-cli -c -p 7000 CLUSTER INFO
redis-cli -c -p 7000 CLUSTER NODES

# Memory analysis
redis-cli -c -p 7000 MEMORY DOCTOR
redis-cli -c -p 7000 MEMORY STATS
redis-cli --bigkeys -p 7000  # Find large keys

# Slow operations
redis-cli -p 7000 SLOWLOG GET 10
redis-cli -p 7000 SLOWLOG RESET

# Client connections
redis-cli -p 7000 CLIENT LIST
redis-cli -p 7000 CLIENT KILL TYPE normal

# Debug latency
redis-cli --latency -p 7000
redis-cli --latency-history -p 7000
redis-cli --intrinsic-latency 5 -p 7000
```

## Best Practices

### Key Design

1. **Use colons for namespacing**: `user:1000:profile`, `cache:api:response:xyz`
2. **Keep keys short but meaningful**: Balance readability and memory
3. **Use hash tags for multi-key operations**: `{user:1000}:profile`, `{user:1000}:sessions`
4. **Set TTL on cache keys**: Prevent unbounded memory growth

### Performance

1. **Use pipelining**: Batch commands to reduce round trips
2. **Prefer hashes over strings**: Store objects as hashes, not JSON strings
3. **Use appropriate data structures**: Sorted sets for leaderboards, HyperLogLog for counts
4. **Avoid large keys**: Break up large lists/sets
5. **Use SCAN instead of KEYS**: Non-blocking iteration

### Operations

1. **Enable persistence**: Use both RDB and AOF for durability
2. **Monitor memory**: Set up alerts for memory usage
3. **Use connection pooling**: Reuse connections in applications
4. **Regular backups**: Automate RDB snapshots to object storage
5. **Test failover**: Regularly simulate node failures

### Security Checklist

- [ ] Set strong passwords with `requirepass`
- [ ] Enable TLS for all connections
- [ ] Use ACLs for fine-grained access control
- [ ] Disable `KEYS`, `FLUSHALL`, `FLUSHDB` for non-admin users
- [ ] Bind to private interfaces only
- [ ] Enable protected mode in production
- [ ] Regular security updates
