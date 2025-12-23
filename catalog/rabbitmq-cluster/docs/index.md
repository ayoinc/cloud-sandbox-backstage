# RabbitMQ Cluster

Enterprise-grade message broker implementing AMQP, MQTT, and STOMP protocols with clustering, high availability, and advanced routing capabilities.

## Quick Start

### Start RabbitMQ with Docker

```bash
# Start single node with management UI
docker run -d --name rabbitmq \
  -p 5672:5672 -p 15672:15672 \
  -e RABBITMQ_DEFAULT_USER=admin \
  -e RABBITMQ_DEFAULT_PASS=password \
  rabbitmq:3.13-management

# Access Management UI
open http://localhost:15672
# Login: admin / password
```

### Start Cluster with Docker Compose

```bash
docker-compose up -d

# Check cluster status
docker exec rabbitmq1 rabbitmqctl cluster_status
```

## Features

| Feature | Description |
|---------|-------------|
| **Multiple Protocols** | AMQP 0-9-1, AMQP 1.0, MQTT, STOMP, HTTP/WebSockets |
| **Clustering** | Multiple nodes for high availability and throughput |
| **Quorum Queues** | Raft-based replicated queues for data safety |
| **Streams** | Append-only log with replay capability |
| **Exchange Types** | Direct, Topic, Fanout, Headers routing patterns |
| **Dead Letter Queues** | Automatic handling of failed messages |
| **Message TTL** | Per-message and per-queue expiration |
| **Federation/Shovel** | Cross-datacenter message routing |

## Architecture

```
                                    ┌──────────────────────────────────────────────┐
                                    │              RabbitMQ Cluster                 │
                                    └──────────────────────────────────────────────┘
                                                         │
        ┌────────────────────────────────────────────────┼────────────────────────────────────────────────┐
        │                                                │                                                │
┌───────▼───────┐                               ┌───────▼───────┐                               ┌───────▼───────┐
│   Node 1      │                               │   Node 2      │                               │   Node 3      │
│  (rabbit@n1)  │◀─────────────────────────────▶│  (rabbit@n2)  │◀─────────────────────────────▶│  (rabbit@n3)  │
├───────────────┤     Erlang Distribution       ├───────────────┤     Erlang Distribution       ├───────────────┤
│ • Exchanges   │                               │ • Exchanges   │                               │ • Exchanges   │
│ • Bindings    │                               │ • Bindings    │                               │ • Bindings    │
│ • Queues      │                               │ • Queues      │                               │ • Queues      │
│ • Connections │                               │ • Connections │                               │ • Connections │
└───────────────┘                               └───────────────┘                               └───────────────┘

                              ┌─────────────────────────────────────────┐
                              │            Quorum Queue                  │
                              │     (Replicated across nodes)            │
                              ├─────────────────────────────────────────┤
                              │  Leader: Node 1  │  Follower: Node 2,3  │
                              │  Raft consensus for replication          │
                              └─────────────────────────────────────────┘
```

## Queue Types

| Type | Durability | Replication | Use Case |
|------|------------|-------------|----------|
| **Classic** | Optional | Mirroring (deprecated) | Legacy, simple use cases |
| **Quorum** | Always | Raft-based | Production, data safety |
| **Stream** | Always | Raft-based | Log streaming, replay |

## Exchange Types

| Type | Routing | Use Case |
|------|---------|----------|
| **Direct** | Exact routing key match | Point-to-point, RPC |
| **Topic** | Pattern matching (*.logs.#) | Pub/sub with filtering |
| **Fanout** | Broadcast to all queues | Notifications, events |
| **Headers** | Header attribute matching | Complex routing logic |

## Version Information

- **RabbitMQ**: 3.13.x (current stable)
- **Erlang/OTP**: 26.x
- **Management Plugin**: Included

## Related Documentation

- [Overview](overview.md) - Architecture, configuration, and clustering
- [Usage](usage.md) - Messaging patterns, clients, and best practices
