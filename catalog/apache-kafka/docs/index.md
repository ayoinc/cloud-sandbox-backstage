# Apache Kafka

Apache Kafka is a distributed event streaming platform capable of handling trillions of events per day. Originally developed by LinkedIn, it's now maintained by the Apache Software Foundation.

## Quick Start

```bash
# Start Kafka with Docker Compose
docker run -d --name kafka \
  -p 9092:9092 \
  -e KAFKA_NODE_ID=1 \
  -e KAFKA_PROCESS_ROLES=broker,controller \
  -e KAFKA_LISTENERS=PLAINTEXT://:9092,CONTROLLER://:9093 \
  -e KAFKA_ADVERTISED_LISTENERS=PLAINTEXT://localhost:9092 \
  -e KAFKA_CONTROLLER_QUORUM_VOTERS=1@localhost:9093 \
  -e KAFKA_CONTROLLER_LISTENER_NAMES=CONTROLLER \
  -e CLUSTER_ID=$(kafka-storage random-uuid) \
  apache/kafka:3.7.0

# Create a topic
kafka-topics.sh --create \
  --topic my-topic \
  --bootstrap-server localhost:9092 \
  --partitions 3 \
  --replication-factor 1

# Produce messages
kafka-console-producer.sh \
  --topic my-topic \
  --bootstrap-server localhost:9092

# Consume messages
kafka-console-consumer.sh \
  --topic my-topic \
  --bootstrap-server localhost:9092 \
  --from-beginning
```

## Key Features

| Feature | Description |
|---------|-------------|
| **High Throughput** | Millions of messages per second with low latency |
| **Scalability** | Scale horizontally by adding brokers |
| **Durability** | Replicated, persistent log storage |
| **Fault Tolerance** | Automatic failover and replication |
| **Stream Processing** | Built-in Kafka Streams API |
| **Connectors** | 100+ pre-built Kafka Connect connectors |

## Core Concepts

- **Topics**: Categories for organizing messages
- **Partitions**: Ordered, immutable sequence of messages
- **Producers**: Applications that publish messages
- **Consumers**: Applications that subscribe to topics
- **Consumer Groups**: Group of consumers sharing topic consumption
- **Brokers**: Kafka servers that store and serve data

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                     Kafka Cluster                            │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │
│  │  Broker 1   │  │  Broker 2   │  │  Broker 3   │         │
│  │  (Leader)   │  │  (Follower) │  │  (Follower) │         │
│  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘         │
│         │                │                │                 │
│  ┌──────▼────────────────▼────────────────▼──────┐         │
│  │              Topic: orders                     │         │
│  │  ┌─────────┐  ┌─────────┐  ┌─────────┐       │         │
│  │  │ Part 0  │  │ Part 1  │  │ Part 2  │       │         │
│  │  └─────────┘  └─────────┘  └─────────┘       │         │
│  └───────────────────────────────────────────────┘         │
└─────────────────────────────────────────────────────────────┘
        ▲                                       │
        │                                       ▼
┌───────┴───────┐                     ┌─────────────────┐
│   Producers   │                     │    Consumers    │
│  (Microservices)                    │  (Consumer Group)
└───────────────┘                     └─────────────────┘
```

## Related Documentation

- [Overview](overview.md) - Architecture, components, and configuration
- [Usage](usage.md) - Practical examples and best practices
