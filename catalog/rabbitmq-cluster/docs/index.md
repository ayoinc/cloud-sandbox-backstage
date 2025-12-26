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

| Feature                | Description                                         |
| ---------------------- | --------------------------------------------------- |
| **Multiple Protocols** | AMQP 0-9-1, AMQP 1.0, MQTT, STOMP, HTTP/WebSockets  |
| **Clustering**         | Multiple nodes for high availability and throughput |
| **Quorum Queues**      | Raft-based replicated queues for data safety        |
| **Streams**            | Append-only log with replay capability              |
| **Exchange Types**     | Direct, Topic, Fanout, Headers routing patterns     |
| **Dead Letter Queues** | Automatic handling of failed messages               |
| **Message TTL**        | Per-message and per-queue expiration                |
| **Federation/Shovel**  | Cross-datacenter message routing                    |

## Architecture

```d2
direction: right

title: RabbitMQ Cluster Architecture {
  shape: text
  near: top-center
  style.font-size: 24
}

cluster: RabbitMQ Cluster {
  style.fill: "#E3F2FD"

  node1: Node 1\n(rabbit@n1) {
    style.fill: "#FF6F00"
    style.font-color: white

    exchanges: Exchanges {shape: rectangle}
    bindings: Bindings {shape: rectangle}
    queues: Queues {shape: cylinder}
    conns: Connections {shape: rectangle}
  }

  node2: Node 2\n(rabbit@n2) {
    style.fill: "#FF6F00"
    style.font-color: white

    exchanges: Exchanges {shape: rectangle}
    bindings: Bindings {shape: rectangle}
    queues: Queues {shape: cylinder}
    conns: Connections {shape: rectangle}
  }

  node3: Node 3\n(rabbit@n3) {
    style.fill: "#FF6F00"
    style.font-color: white

    exchanges: Exchanges {shape: rectangle}
    bindings: Bindings {shape: rectangle}
    queues: Queues {shape: cylinder}
    conns: Connections {shape: rectangle}
  }

  node1 <-> node2: Erlang Distribution
  node2 <-> node3: Erlang Distribution
  node1 <-> node3: Erlang Distribution {style.stroke-dash: 3}
}

quorum: Quorum Queue {
  style.fill: "#E8F5E9"

  leader: Leader: Node 1 {
    shape: hexagon
    style.fill: "#4CAF50"
    style.font-color: white
  }

  followers: Follower: Node 2, 3 {
    shape: hexagon
    style.fill: "#81C784"
    style.font-color: white
  }

  raft: Raft consensus\nfor replication {
    shape: text
    style.font-size: 12
  }

  leader -> followers: Replicate
}

cluster -> quorum: Quorum Queues
```

## Queue Types

| Type        | Durability | Replication            | Use Case                 |
| ----------- | ---------- | ---------------------- | ------------------------ |
| **Classic** | Optional   | Mirroring (deprecated) | Legacy, simple use cases |
| **Quorum**  | Always     | Raft-based             | Production, data safety  |
| **Stream**  | Always     | Raft-based             | Log streaming, replay    |

## Exchange Types

| Type        | Routing                      | Use Case               |
| ----------- | ---------------------------- | ---------------------- |
| **Direct**  | Exact routing key match      | Point-to-point, RPC    |
| **Topic**   | Pattern matching (\*.logs.#) | Pub/sub with filtering |
| **Fanout**  | Broadcast to all queues      | Notifications, events  |
| **Headers** | Header attribute matching    | Complex routing logic  |

## Version Information

- **RabbitMQ**: 3.13.x (current stable)
- **Erlang/OTP**: 26.x
- **Management Plugin**: Included

## Related Documentation

- [Overview](overview.md) - Architecture, configuration, and clustering
- [Usage](usage.md) - Messaging patterns, clients, and best practices
