# RabbitMQ Cluster Overview

## Architecture Deep Dive

### Message Flow

```d2
direction: right

producer: Producer {
  shape: rectangle
  style.fill: "#E3F2FD"

  publish: "Publish"
  confirm: "Confirm"
}

exchange: Exchange {
  shape: hexagon
  style.fill: "#FFF8E1"

  routing: "Routing"
  bindings: "Bindings"
}

queue: Queue {
  shape: cylinder
  style.fill: "#E8F5E9"

  storage: "Storage"
  ordering: "Ordering"
}

consumer: Consumer {
  shape: rectangle
  style.fill: "#F3E5F5"

  consume: "Consume"
  ack: "Ack/Nack"
}

bindings_detail: Bindings {
  shape: rectangle
  style.fill: "#FFF3E0"
  label: "Exchange ──(routing_key)──► Queue"
}

producer -> exchange: message
exchange -> queue: routing key match
queue -> consumer: deliver
exchange -> bindings_detail: route via
```

### Clustering Architecture

```d2
direction: down

lb: Load Balancer (HAProxy) {
  shape: cloud
  style.fill: "#E3F2FD"
  label: ":5672 (AMQP), :15672 (HTTP)"
}

cluster: RabbitMQ Cluster {
  style: {
    fill: "#F5F5F5"
    stroke: "#9E9E9E"
  }

  rmq1: RabbitMQ 1 {
    shape: rectangle
    style.fill: "#E8F5E9"

    type1: "(Disk Node)"
    mnesia1: "Mnesia DB (metadata)"
    queue1: "Queue Leader (orders)"
  }

  rmq2: RabbitMQ 2 {
    shape: rectangle
    style.fill: "#E8F5E9"

    type2: "(Disk Node)"
    mnesia2: "Mnesia DB (metadata)"
    queue2: "Queue Follower (orders)"
  }

  rmq3: RabbitMQ 3 {
    shape: rectangle
    style.fill: "#FFF8E1"

    type3: "(RAM Node)"
    mnesia3: "Mnesia DB (in-memory)"
    queue3: "Queue Follower (orders)"
  }

  rmq1 <-> rmq2: Erlang Distribution
  rmq2 <-> rmq3: Erlang Distribution
  rmq1 <-> rmq3: Erlang Distribution
}

erlang: "Erlang Distribution (Port 25672)" {
  shape: text
  style.font-size: 12
}

lb -> cluster.rmq1
lb -> cluster.rmq2
lb -> cluster.rmq3
```

### Quorum Queues

Quorum queues use Raft consensus for replication:

```d2
direction: down

title: "Quorum Queue: orders" {
  shape: text
  near: top-center
  style: {
    font-size: 20
    bold: true
  }
}

quorum: Quorum Queue {
  style: {
    fill: "#E3F2FD"
    stroke: "#1976D2"
    stroke-width: 2
  }

  leader: Leader (Node 1) {
    shape: hexagon
    style.fill: "#C8E6C9"
    log1: "Log: [...]"
  }

  follower1: Follower (Node 2) {
    shape: hexagon
    style.fill: "#DCEDC8"
    log2: "Log: [...]"
  }

  follower2: Follower (Node 3) {
    shape: hexagon
    style.fill: "#DCEDC8"
    log3: "Log: [...]"
  }

  leader -> follower1: replicate
  leader -> follower2: replicate
}

write_path: Write Path {
  style.fill: "#FFF8E1"

  step1: "1. Producer sends message to leader"
  step2: "2. Leader appends to local log"
  step3: "3. Leader replicates to followers"
  step4: "4. Majority confirms → message committed"
  step5: "5. Leader acknowledges to producer"

  step1 -> step2 -> step3 -> step4 -> step5
}
```

## Configuration

### rabbitmq.conf

```ini
# Clustering
cluster_formation.peer_discovery_backend = rabbit_peer_discovery_k8s
cluster_formation.k8s.host = kubernetes.default.svc.cluster.local
cluster_formation.k8s.address_type = hostname
cluster_formation.node_cleanup.interval = 30
cluster_formation.node_cleanup.only_log_warning = true

# Queue defaults
default_queue_type = quorum

# Resource limits
vm_memory_high_watermark.relative = 0.7
disk_free_limit.relative = 2.0

# Connections
tcp_listen_options.backlog = 4096
tcp_listen_options.nodelay = true
tcp_listen_options.linger.on = true
tcp_listen_options.linger.timeout = 0

# Channels
channel_max = 2047

# Consumer prefetch
consumer_timeout = 1800000

# Management
management.tcp.port = 15672
management.load_definitions = /etc/rabbitmq/definitions.json

# Logging
log.console = true
log.console.level = info
log.file = false

# Prometheus metrics
prometheus.return_per_object_metrics = true
prometheus.tcp.port = 15692
```

### advanced.config (Erlang)

```erlang
[
  {rabbit, [
    {collect_statistics_interval, 10000},
    {queue_master_locator, <<"min-masters">>},
    {consumer_timeout, 3600000},
    {default_consumer_prefetch, {false, 100}}
  ]},
  {rabbitmq_management, [
    {rates_mode, detailed}
  ]},
  {rabbitmq_prometheus, [
    {return_per_object_metrics, true}
  ]}
].
```

### Environment Variables

```bash
# Node configuration
RABBITMQ_NODENAME=rabbit@hostname
RABBITMQ_USE_LONGNAME=true
RABBITMQ_ERLANG_COOKIE=shared-secret-cookie

# Clustering
RABBITMQ_CLUSTER_FORMATION_PEER_DISCOVERY_BACKEND=rabbit_peer_discovery_k8s

# Memory and disk
RABBITMQ_VM_MEMORY_HIGH_WATERMARK=0.7
RABBITMQ_DISK_FREE_LIMIT=2GB

# Default user
RABBITMQ_DEFAULT_USER=admin
RABBITMQ_DEFAULT_PASS=secure-password
RABBITMQ_DEFAULT_VHOST=/
```

## Exchange and Queue Configuration

### Declare Exchange

```bash
# Via Management API
curl -u admin:password -X PUT \
  http://localhost:15672/api/exchanges/%2F/orders \
  -H "content-type:application/json" \
  -d '{
    "type": "topic",
    "durable": true,
    "auto_delete": false,
    "arguments": {}
  }'
```

### Declare Quorum Queue

```bash
# Via Management API
curl -u admin:password -X PUT \
  http://localhost:15672/api/queues/%2F/orders.created \
  -H "content-type:application/json" \
  -d '{
    "durable": true,
    "arguments": {
      "x-queue-type": "quorum",
      "x-quorum-initial-group-size": 3,
      "x-delivery-limit": 5,
      "x-dead-letter-exchange": "dlx",
      "x-dead-letter-routing-key": "orders.failed"
    }
  }'
```

### Policies

```bash
# Set policy via CLI
rabbitmqctl set_policy ha-quorum "^orders\." \
  '{"queue-type":"quorum","delivery-limit":5}' \
  --apply-to queues

# High availability for classic queues (deprecated)
rabbitmqctl set_policy ha-all "^ha\." \
  '{"ha-mode":"all","ha-sync-mode":"automatic"}' \
  --apply-to queues
```

## Security

### TLS Configuration

```ini
# rabbitmq.conf
listeners.ssl.default = 5671
ssl_options.cacertfile = /etc/rabbitmq/certs/ca.pem
ssl_options.certfile = /etc/rabbitmq/certs/server.pem
ssl_options.keyfile = /etc/rabbitmq/certs/server-key.pem
ssl_options.verify = verify_peer
ssl_options.fail_if_no_peer_cert = true
ssl_options.versions.1 = tlsv1.3
ssl_options.versions.2 = tlsv1.2

# Management SSL
management.ssl.port = 15671
management.ssl.cacertfile = /etc/rabbitmq/certs/ca.pem
management.ssl.certfile = /etc/rabbitmq/certs/server.pem
management.ssl.keyfile = /etc/rabbitmq/certs/server-key.pem
```

### User and Permissions

```bash
# Create user
rabbitmqctl add_user app_user secure_password

# Set permissions (configure, write, read)
rabbitmqctl set_permissions -p / app_user "^app\..*" "^app\..*" "^app\..*"

# Set topic permissions
rabbitmqctl set_topic_permissions -p / app_user orders "^orders\..*" "^orders\..*"

# Create vhost
rabbitmqctl add_vhost production
rabbitmqctl set_permissions -p production app_user ".*" ".*" ".*"

# List users and permissions
rabbitmqctl list_users
rabbitmqctl list_permissions -p /
```

## Monitoring

### Key Metrics

| Metric                   | Description                   | Alert Threshold        |
| ------------------------ | ----------------------------- | ---------------------- |
| `queue_messages_ready`   | Messages waiting for consumer | > 10000 sustained      |
| `queue_messages_unacked` | Messages delivered, not acked | > 1000                 |
| `node_mem_used`          | Memory usage                  | > 70% of limit         |
| `node_disk_free`         | Free disk space               | < disk limit           |
| `channels`               | Open channels                 | > 2000                 |
| `connections`            | Open connections              | > 1000                 |
| `queue_consumer_count`   | Consumers per queue           | 0 for important queues |
| `message_publish_rate`   | Messages published/sec        | Sudden drops           |

### Prometheus Metrics

```yaml
# Scrape config
scrape_configs:
  - job_name: 'rabbitmq'
    static_configs:
      - targets: ['rabbitmq:15692']
    metrics_path: /metrics
```

### Health Checks

```bash
# Node health
curl -u admin:password http://localhost:15672/api/health/checks/alarms
curl -u admin:password http://localhost:15672/api/health/checks/local-alarms
curl -u admin:password http://localhost:15672/api/health/checks/node-is-quorum-critical

# Cluster health
rabbitmqctl cluster_status
rabbitmqctl node_health_check

# Queue health
rabbitmqctl list_queues name messages consumers state
```

## High Availability

### Quorum Queue Sizing

| Cluster Size | Quorum Size | Fault Tolerance |
| ------------ | ----------- | --------------- |
| 3 nodes      | 3           | 1 node failure  |
| 5 nodes      | 5           | 2 node failures |
| 7 nodes      | 5           | 2 node failures |

### Network Partitions

```ini
# rabbitmq.conf
# Partition handling strategy
cluster_partition_handling = pause_minority

# Other options:
# cluster_partition_handling = autoheal
# cluster_partition_handling = ignore (not recommended)
```
