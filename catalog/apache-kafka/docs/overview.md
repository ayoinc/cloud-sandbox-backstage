# Overview

## Architecture

Apache Kafka uses a distributed commit log architecture. Messages are persisted to disk and replicated across multiple brokers for fault tolerance.

### KRaft Mode (Kafka 3.x+)

Starting with Kafka 3.0, ZooKeeper is being replaced with KRaft (Kafka Raft) for metadata management:

```
┌─────────────────────────────────────────────────────────────┐
│                    KRaft Cluster                             │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │
│  │ Controller  │  │ Controller  │  │ Controller  │         │
│  │  + Broker   │  │  + Broker   │  │  + Broker   │         │
│  │   Node 1    │  │   Node 2    │  │   Node 3    │         │
│  └─────────────┘  └─────────────┘  └─────────────┘         │
│         │                │                │                 │
│         └────────────────┼────────────────┘                 │
│                          │                                  │
│              Raft Consensus Protocol                        │
│              (Metadata Replication)                         │
└─────────────────────────────────────────────────────────────┘
```

## Components

### Brokers

Kafka brokers are the servers that store data and serve clients.

| Setting | Default | Description |
|---------|---------|-------------|
| `broker.id` | - | Unique identifier for each broker |
| `listeners` | PLAINTEXT://:9092 | Network listeners |
| `log.dirs` | /var/kafka-logs | Data storage directories |
| `num.partitions` | 1 | Default partitions for new topics |
| `log.retention.hours` | 168 (7 days) | How long to retain messages |
| `log.segment.bytes` | 1GB | Size of log segment files |

### Topics and Partitions

Topics are divided into partitions for parallelism:

```
Topic: user-events (3 partitions, RF=2)
├── Partition 0: Broker 1 (leader), Broker 2 (replica)
├── Partition 1: Broker 2 (leader), Broker 3 (replica)
└── Partition 2: Broker 3 (leader), Broker 1 (replica)
```

**Partitioning Strategies:**

| Strategy | Use Case |
|----------|----------|
| Round-robin | No key, even distribution |
| Key-based hash | Messages with same key go to same partition |
| Custom partitioner | Business logic-based routing |

### Producers

Producer configuration options:

| Setting | Values | Description |
|---------|--------|-------------|
| `acks` | 0, 1, all | Acknowledgment level |
| `retries` | 0-N | Number of retry attempts |
| `batch.size` | 16384 | Batch size in bytes |
| `linger.ms` | 0-N | Time to wait for batch |
| `compression.type` | none, gzip, snappy, lz4, zstd | Compression algorithm |

### Consumers

Consumer configuration options:

| Setting | Default | Description |
|---------|---------|-------------|
| `group.id` | - | Consumer group identifier |
| `auto.offset.reset` | latest | Where to start if no offset |
| `enable.auto.commit` | true | Auto-commit offsets |
| `max.poll.records` | 500 | Max records per poll |

## Configuration

### Broker Configuration (server.properties)

```properties
# Broker settings
broker.id=1
listeners=PLAINTEXT://:9092,SSL://:9093
advertised.listeners=PLAINTEXT://kafka1.example.com:9092

# KRaft settings (Kafka 3.x+)
process.roles=broker,controller
node.id=1
controller.quorum.voters=1@kafka1:9093,2@kafka2:9093,3@kafka3:9093
controller.listener.names=CONTROLLER

# Log settings
log.dirs=/var/kafka-logs
num.partitions=6
default.replication.factor=3
min.insync.replicas=2

# Retention
log.retention.hours=168
log.retention.bytes=-1
log.segment.bytes=1073741824

# Performance
num.network.threads=8
num.io.threads=16
socket.send.buffer.bytes=102400
socket.receive.buffer.bytes=102400
socket.request.max.bytes=104857600
```

### Producer Configuration

```properties
# Producer settings
bootstrap.servers=kafka1:9092,kafka2:9092,kafka3:9092
acks=all
retries=3
retry.backoff.ms=100
batch.size=16384
linger.ms=5
buffer.memory=33554432
compression.type=snappy

# Idempotence (exactly-once semantics)
enable.idempotence=true
max.in.flight.requests.per.connection=5
```

### Consumer Configuration

```properties
# Consumer settings
bootstrap.servers=kafka1:9092,kafka2:9092,kafka3:9092
group.id=my-consumer-group
auto.offset.reset=earliest
enable.auto.commit=false
max.poll.records=500
max.poll.interval.ms=300000
session.timeout.ms=30000
heartbeat.interval.ms=10000
```

## Security

### SSL/TLS Encryption

```properties
# Broker SSL config
listeners=SSL://:9093
ssl.keystore.location=/var/ssl/kafka.keystore.jks
ssl.keystore.password=keystore-password
ssl.key.password=key-password
ssl.truststore.location=/var/ssl/kafka.truststore.jks
ssl.truststore.password=truststore-password
ssl.client.auth=required
```

### SASL Authentication

```properties
# SASL/SCRAM configuration
listeners=SASL_SSL://:9094
security.inter.broker.protocol=SASL_SSL
sasl.mechanism.inter.broker.protocol=SCRAM-SHA-512
sasl.enabled.mechanisms=SCRAM-SHA-512

# JAAS config
listener.name.sasl_ssl.scram-sha-512.sasl.jaas.config=\
  org.apache.kafka.common.security.scram.ScramLoginModule required \
  username="admin" password="admin-password";
```

### ACLs (Access Control Lists)

```bash
# Create ACL for producer
kafka-acls.sh --bootstrap-server localhost:9092 \
  --add --allow-principal User:producer \
  --operation Write --topic my-topic

# Create ACL for consumer
kafka-acls.sh --bootstrap-server localhost:9092 \
  --add --allow-principal User:consumer \
  --operation Read --topic my-topic \
  --group my-consumer-group
```

## Monitoring

### Key JMX Metrics

| Metric | Description | Alert Threshold |
|--------|-------------|-----------------|
| `UnderReplicatedPartitions` | Partitions below RF | > 0 |
| `OfflinePartitionsCount` | Unavailable partitions | > 0 |
| `ActiveControllerCount` | Active controllers | != 1 |
| `RequestHandlerAvgIdlePercent` | Handler utilization | < 30% |
| `NetworkProcessorAvgIdlePercent` | Network thread usage | < 30% |
| `MessagesInPerSec` | Incoming message rate | Monitor trend |
| `BytesInPerSec` | Incoming bytes rate | Monitor trend |

### Consumer Lag

```bash
# Check consumer group lag
kafka-consumer-groups.sh \
  --bootstrap-server localhost:9092 \
  --describe --group my-consumer-group
```

### Prometheus + Grafana

Use JMX Exporter for Prometheus metrics:

```yaml
# jmx_exporter config
lowercaseOutputName: true
rules:
  - pattern: kafka.server<type=(.+), name=(.+)><>Value
    name: kafka_server_$1_$2
  - pattern: kafka.server<type=(.+), name=(.+), topic=(.+)><>Value
    name: kafka_server_$1_$2
    labels:
      topic: $3
```
