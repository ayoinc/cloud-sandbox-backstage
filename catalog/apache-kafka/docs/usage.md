# Usage Guide

## Producer/Consumer Flow

```d2
direction: right

producer: Producer Application {
  style.fill: "#FF9800"
  serialize: Serialize Message
  partition: Select Partition
  batch: Batch Messages
  
  serialize -> partition -> batch
}

kafka: Kafka Cluster {
  style.fill: "#f5f5f5"
  
  topic: Topic {
    p0: Partition 0 {
      style.fill: "#4CAF50"
      leader: Leader
      replica: Replica
    }
    p1: Partition 1 {
      style.fill: "#4CAF50"
      leader: Leader
      replica: Replica
    }
    p2: Partition 2 {
      style.fill: "#4CAF50"
      leader: Leader
      replica: Replica
    }
  }
}

consumer_group: Consumer Group {
  style.fill: "#9C27B0"
  
  c1: Consumer 1 {
    style.fill: "#E1BEE7"
  }
  c2: Consumer 2 {
    style.fill: "#E1BEE7"
  }
  c3: Consumer 3 {
    style.fill: "#E1BEE7"
  }
}

producer -> kafka.topic: "1. Send (acks=all)"
kafka.topic.p0 -> consumer_group.c1: "2. Fetch"
kafka.topic.p1 -> consumer_group.c2: "2. Fetch"
kafka.topic.p2 -> consumer_group.c3: "2. Fetch"
consumer_group -> kafka: "3. Commit Offset"
```

## Getting Started

### Prerequisites

- Java 11+ (for Kafka binaries)
- Docker (for containerized deployment)
- Sufficient disk space for log storage

### Installation

#### Docker Compose (Recommended for Development)

```yaml
version: '3.8'
services:
  kafka:
    image: apache/kafka:3.7.0
    container_name: kafka
    ports:
      - "9092:9092"
    environment:
      KAFKA_NODE_ID: 1
      KAFKA_PROCESS_ROLES: broker,controller
      KAFKA_LISTENERS: PLAINTEXT://:9092,CONTROLLER://:9093
      KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://localhost:9092
      KAFKA_CONTROLLER_LISTENER_NAMES: CONTROLLER
      KAFKA_CONTROLLER_QUORUM_VOTERS: 1@kafka:9093
      KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR: 1
      KAFKA_TRANSACTION_STATE_LOG_REPLICATION_FACTOR: 1
      KAFKA_TRANSACTION_STATE_LOG_MIN_ISR: 1
      CLUSTER_ID: MkU3OEVBNTcwNTJENDM2Qk
    volumes:
      - kafka_data:/var/lib/kafka/data

volumes:
  kafka_data:
```

#### Kubernetes with Strimzi Operator

```yaml
apiVersion: kafka.strimzi.io/v1beta2
kind: Kafka
metadata:
  name: my-cluster
spec:
  kafka:
    version: 3.7.0
    replicas: 3
    listeners:
      - name: plain
        port: 9092
        type: internal
        tls: false
      - name: tls
        port: 9093
        type: internal
        tls: true
    config:
      offsets.topic.replication.factor: 3
      transaction.state.log.replication.factor: 3
      transaction.state.log.min.isr: 2
      default.replication.factor: 3
      min.insync.replicas: 2
    storage:
      type: jbod
      volumes:
        - id: 0
          type: persistent-claim
          size: 100Gi
          deleteClaim: false
  zookeeper:
    replicas: 3
    storage:
      type: persistent-claim
      size: 10Gi
      deleteClaim: false
```

## Examples

### Topic Management

```bash
# Create topic
kafka-topics.sh --create \
  --bootstrap-server localhost:9092 \
  --topic orders \
  --partitions 6 \
  --replication-factor 3 \
  --config retention.ms=604800000 \
  --config cleanup.policy=delete

# List topics
kafka-topics.sh --list --bootstrap-server localhost:9092

# Describe topic
kafka-topics.sh --describe \
  --bootstrap-server localhost:9092 \
  --topic orders

# Alter topic partitions
kafka-topics.sh --alter \
  --bootstrap-server localhost:9092 \
  --topic orders \
  --partitions 12

# Delete topic
kafka-topics.sh --delete \
  --bootstrap-server localhost:9092 \
  --topic orders
```

### Producer Examples

#### Command Line Producer

```bash
# Simple producer
kafka-console-producer.sh \
  --bootstrap-server localhost:9092 \
  --topic orders

# Producer with key
kafka-console-producer.sh \
  --bootstrap-server localhost:9092 \
  --topic orders \
  --property "key.separator=:" \
  --property "parse.key=true"
# Input: order-123:{"status":"created"}
```

#### Python Producer

```python
from kafka import KafkaProducer
import json

producer = KafkaProducer(
    bootstrap_servers=['localhost:9092'],
    value_serializer=lambda v: json.dumps(v).encode('utf-8'),
    key_serializer=lambda k: k.encode('utf-8') if k else None,
    acks='all',
    retries=3,
    compression_type='snappy'
)

# Send message
future = producer.send(
    'orders',
    key='order-123',
    value={'status': 'created', 'amount': 99.99}
)
result = future.get(timeout=10)
print(f"Sent to partition {result.partition} at offset {result.offset}")

producer.flush()
producer.close()
```

#### Java Producer

```java
Properties props = new Properties();
props.put("bootstrap.servers", "localhost:9092");
props.put("key.serializer", "org.apache.kafka.common.serialization.StringSerializer");
props.put("value.serializer", "org.apache.kafka.common.serialization.StringSerializer");
props.put("acks", "all");
props.put("retries", 3);

KafkaProducer<String, String> producer = new KafkaProducer<>(props);

ProducerRecord<String, String> record = new ProducerRecord<>(
    "orders", "order-123", "{\"status\":\"created\"}"
);

producer.send(record, (metadata, exception) -> {
    if (exception == null) {
        System.out.printf("Sent to partition %d at offset %d%n",
            metadata.partition(), metadata.offset());
    } else {
        exception.printStackTrace();
    }
});

producer.close();
```

### Consumer Examples

#### Command Line Consumer

```bash
# Simple consumer
kafka-console-consumer.sh \
  --bootstrap-server localhost:9092 \
  --topic orders \
  --from-beginning

# Consumer with group
kafka-console-consumer.sh \
  --bootstrap-server localhost:9092 \
  --topic orders \
  --group my-consumer-group

# Show keys and timestamps
kafka-console-consumer.sh \
  --bootstrap-server localhost:9092 \
  --topic orders \
  --property print.key=true \
  --property print.timestamp=true
```

#### Python Consumer

```python
from kafka import KafkaConsumer
import json

consumer = KafkaConsumer(
    'orders',
    bootstrap_servers=['localhost:9092'],
    group_id='order-processor',
    auto_offset_reset='earliest',
    enable_auto_commit=False,
    value_deserializer=lambda v: json.loads(v.decode('utf-8'))
)

try:
    for message in consumer:
        print(f"Partition: {message.partition}, Offset: {message.offset}")
        print(f"Key: {message.key}, Value: {message.value}")
        
        # Process message...
        
        # Manual commit
        consumer.commit()
except KeyboardInterrupt:
    pass
finally:
    consumer.close()
```

### Kafka Connect

#### File Source Connector

```json
{
  "name": "file-source",
  "config": {
    "connector.class": "org.apache.kafka.connect.file.FileStreamSourceConnector",
    "tasks.max": "1",
    "file": "/var/log/app.log",
    "topic": "app-logs"
  }
}
```

#### JDBC Sink Connector

```json
{
  "name": "postgres-sink",
  "config": {
    "connector.class": "io.confluent.connect.jdbc.JdbcSinkConnector",
    "tasks.max": "1",
    "topics": "orders",
    "connection.url": "jdbc:postgresql://localhost:5432/mydb",
    "connection.user": "postgres",
    "connection.password": "password",
    "auto.create": "true",
    "insert.mode": "upsert",
    "pk.mode": "record_key",
    "pk.fields": "order_id"
  }
}
```

### Kafka Streams

```java
Properties props = new Properties();
props.put(StreamsConfig.APPLICATION_ID_CONFIG, "order-processor");
props.put(StreamsConfig.BOOTSTRAP_SERVERS_CONFIG, "localhost:9092");

StreamsBuilder builder = new StreamsBuilder();

KStream<String, String> orders = builder.stream("orders");

// Filter and transform
orders
    .filter((key, value) -> value.contains("\"status\":\"pending\""))
    .mapValues(value -> value.replace("pending", "processing"))
    .to("processed-orders");

// Aggregation
orders
    .groupBy((key, value) -> extractCustomerId(value))
    .count()
    .toStream()
    .to("customer-order-counts");

KafkaStreams streams = new KafkaStreams(builder.build(), props);
streams.start();
```

## Best Practices

### Partition Strategy

| Partitions | Use Case |
|------------|----------|
| 1 | Strict ordering required |
| 3-6 | Low-volume topics |
| 12-30 | Medium-volume topics |
| 50+ | High-volume, many consumers |

### Replication Factor

- **Production**: RF=3, min.insync.replicas=2
- **Development**: RF=1 (single broker)

### Message Design

```json
{
  "eventId": "uuid",
  "eventType": "OrderCreated",
  "timestamp": "2024-01-01T12:00:00Z",
  "version": "1.0",
  "data": {
    "orderId": "order-123",
    "customerId": "cust-456",
    "amount": 99.99
  }
}
```

## Troubleshooting

### Common Issues

| Issue | Cause | Solution |
|-------|-------|----------|
| Consumer lag increasing | Slow processing | Scale consumers, optimize processing |
| UnderReplicatedPartitions | Broker issues | Check broker health, disk space |
| Producer timeout | Network/broker issues | Check connectivity, increase timeout |
| Out of memory | Large messages | Increase heap, check message size |

### Diagnostic Commands

```bash
# Check cluster health
kafka-metadata.sh --snapshot /var/kafka-logs/__cluster_metadata-0/00000000000000000000.log --command describe

# Consumer group details
kafka-consumer-groups.sh \
  --bootstrap-server localhost:9092 \
  --describe --group my-group

# Reset consumer offsets
kafka-consumer-groups.sh \
  --bootstrap-server localhost:9092 \
  --group my-group \
  --topic orders \
  --reset-offsets --to-earliest --execute

# Check log segments
kafka-dump-log.sh \
  --files /var/kafka-logs/orders-0/00000000000000000000.log \
  --print-data-log
```
