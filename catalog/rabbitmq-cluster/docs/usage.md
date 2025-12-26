# RabbitMQ Cluster Usage Guide

## Deployment Architecture

```d2
direction: down

title: RabbitMQ Cluster Deployment {
  shape: text
  near: top-center
  style.font-size: 24
}

lb: HAProxy Load Balancer {
  style.fill: "#E3F2FD"

  amqp: AMQP (5673) {
    shape: hexagon
    style.fill: "#2196F3"
    style.font-color: white
  }

  mgmt: Management (15673) {
    shape: hexagon
    style.fill: "#2196F3"
    style.font-color: white
  }

  stats: Stats (8404) {
    shape: rectangle
    style.fill: "#64B5F6"
    style.font-color: white
  }
}

cluster: RabbitMQ Cluster {
  style.fill: "#FFF3E0"

  rmq1: rabbitmq1\n:5672 :15672 {
    shape: hexagon
    style.fill: "#FF6F00"
    style.font-color: white
  }

  rmq2: rabbitmq2\n:5672 :15672 {
    shape: hexagon
    style.fill: "#FF6F00"
    style.font-color: white
  }

  rmq3: rabbitmq3\n:5672 :15672 {
    shape: hexagon
    style.fill: "#FF6F00"
    style.font-color: white
  }

  rmq1 <-> rmq2: Cluster
  rmq2 <-> rmq3: Cluster
  rmq1 <-> rmq3: Cluster {style.stroke-dash: 3}
}

storage: Persistent Storage {
  style.fill: "#E8F5E9"

  vol1: rabbitmq1-data {shape: cylinder; style.fill: "#4CAF50"; style.font-color: white}
  vol2: rabbitmq2-data {shape: cylinder; style.fill: "#4CAF50"; style.font-color: white}
  vol3: rabbitmq3-data {shape: cylinder; style.fill: "#4CAF50"; style.font-color: white}
}

lb -> cluster: Load Balance
cluster.rmq1 -> storage.vol1
cluster.rmq2 -> storage.vol2
cluster.rmq3 -> storage.vol3
```

## Prerequisites

- Docker and Docker Compose
- 2GB+ RAM per node
- Network connectivity between nodes (ports 4369, 5672, 15672, 25672)

## Deployment with Docker Compose

### 3-Node Cluster

```yaml
# docker-compose.yml
version: '3.8'

services:
  rabbitmq1:
    image: rabbitmq:3.13-management
    hostname: rabbitmq1
    environment:
      - RABBITMQ_ERLANG_COOKIE=secret_cookie
      - RABBITMQ_DEFAULT_USER=admin
      - RABBITMQ_DEFAULT_PASS=password
      - RABBITMQ_NODENAME=rabbit@rabbitmq1
    volumes:
      - rabbitmq1-data:/var/lib/rabbitmq
      - ./rabbitmq.conf:/etc/rabbitmq/rabbitmq.conf:ro
      - ./definitions.json:/etc/rabbitmq/definitions.json:ro
    ports:
      - '5672:5672'
      - '15672:15672'
      - '15692:15692'
    networks:
      - rabbitmq-cluster
    healthcheck:
      test: rabbitmq-diagnostics -q ping
      interval: 30s
      timeout: 10s
      retries: 5

  rabbitmq2:
    image: rabbitmq:3.13-management
    hostname: rabbitmq2
    environment:
      - RABBITMQ_ERLANG_COOKIE=secret_cookie
      - RABBITMQ_DEFAULT_USER=admin
      - RABBITMQ_DEFAULT_PASS=password
      - RABBITMQ_NODENAME=rabbit@rabbitmq2
    volumes:
      - rabbitmq2-data:/var/lib/rabbitmq
      - ./rabbitmq.conf:/etc/rabbitmq/rabbitmq.conf:ro
    depends_on:
      - rabbitmq1
    networks:
      - rabbitmq-cluster

  rabbitmq3:
    image: rabbitmq:3.13-management
    hostname: rabbitmq3
    environment:
      - RABBITMQ_ERLANG_COOKIE=secret_cookie
      - RABBITMQ_DEFAULT_USER=admin
      - RABBITMQ_DEFAULT_PASS=password
      - RABBITMQ_NODENAME=rabbit@rabbitmq3
    volumes:
      - rabbitmq3-data:/var/lib/rabbitmq
      - ./rabbitmq.conf:/etc/rabbitmq/rabbitmq.conf:ro
    depends_on:
      - rabbitmq1
    networks:
      - rabbitmq-cluster

  haproxy:
    image: haproxy:2.8
    ports:
      - '5673:5672'
      - '15673:15672'
      - '8404:8404'
    volumes:
      - ./haproxy.cfg:/usr/local/etc/haproxy/haproxy.cfg:ro
    depends_on:
      - rabbitmq1
      - rabbitmq2
      - rabbitmq3
    networks:
      - rabbitmq-cluster

volumes:
  rabbitmq1-data:
  rabbitmq2-data:
  rabbitmq3-data:

networks:
  rabbitmq-cluster:
    driver: bridge
```

### Cluster Initialization

```bash
# Start the cluster
docker-compose up -d

# Join nodes to cluster
docker exec rabbitmq2 rabbitmqctl stop_app
docker exec rabbitmq2 rabbitmqctl reset
docker exec rabbitmq2 rabbitmqctl join_cluster rabbit@rabbitmq1
docker exec rabbitmq2 rabbitmqctl start_app

docker exec rabbitmq3 rabbitmqctl stop_app
docker exec rabbitmq3 rabbitmqctl reset
docker exec rabbitmq3 rabbitmqctl join_cluster rabbit@rabbitmq1
docker exec rabbitmq3 rabbitmqctl start_app

# Verify cluster
docker exec rabbitmq1 rabbitmqctl cluster_status
```

## Client Examples

### Python (pika)

```python
import pika
import json
from pika.exchange_type import ExchangeType

# Connection parameters
credentials = pika.PlainCredentials('admin', 'password')
parameters = pika.ConnectionParameters(
    host='localhost',
    port=5672,
    virtual_host='/',
    credentials=credentials,
    heartbeat=600,
    blocked_connection_timeout=300
)

# Producer
def publish_message(exchange, routing_key, message):
    connection = pika.BlockingConnection(parameters)
    channel = connection.channel()

    # Declare exchange
    channel.exchange_declare(
        exchange=exchange,
        exchange_type=ExchangeType.topic,
        durable=True
    )

    # Publish with confirms
    channel.confirm_delivery()

    try:
        channel.basic_publish(
            exchange=exchange,
            routing_key=routing_key,
            body=json.dumps(message),
            properties=pika.BasicProperties(
                delivery_mode=pika.DeliveryMode.Persistent,
                content_type='application/json',
                headers={'version': '1.0'}
            ),
            mandatory=True
        )
        print(f"Message published: {routing_key}")
    except pika.exceptions.UnroutableError:
        print("Message could not be routed")
    finally:
        connection.close()

# Consumer
def consume_messages(queue, callback):
    connection = pika.BlockingConnection(parameters)
    channel = connection.channel()

    # Declare quorum queue
    channel.queue_declare(
        queue=queue,
        durable=True,
        arguments={
            'x-queue-type': 'quorum',
            'x-delivery-limit': 5,
            'x-dead-letter-exchange': 'dlx'
        }
    )

    # Bind to exchange
    channel.queue_bind(
        queue=queue,
        exchange='orders',
        routing_key='orders.created'
    )

    # Set prefetch
    channel.basic_qos(prefetch_count=10)

    def on_message(ch, method, properties, body):
        try:
            message = json.loads(body)
            callback(message)
            ch.basic_ack(delivery_tag=method.delivery_tag)
        except Exception as e:
            print(f"Error processing message: {e}")
            ch.basic_nack(delivery_tag=method.delivery_tag, requeue=False)

    channel.basic_consume(queue=queue, on_message_callback=on_message)

    print(f"Waiting for messages on {queue}")
    channel.start_consuming()

# Usage
publish_message('orders', 'orders.created', {'order_id': '12345', 'amount': 99.99})
consume_messages('orders.created.queue', lambda msg: print(f"Received: {msg}"))
```

### Node.js (amqplib)

```javascript
const amqp = require('amqplib');

const AMQP_URL = 'amqp://admin:password@localhost:5672';

// Publisher
async function publishMessage(exchange, routingKey, message) {
  const connection = await amqp.connect(AMQP_URL);
  const channel = await connection.createConfirmChannel();

  await channel.assertExchange(exchange, 'topic', { durable: true });

  const content = Buffer.from(JSON.stringify(message));

  channel.publish(
    exchange,
    routingKey,
    content,
    {
      persistent: true,
      contentType: 'application/json',
      headers: { version: '1.0' },
    },
    err => {
      if (err) {
        console.error('Message nacked:', err);
      } else {
        console.log('Message confirmed');
      }
    },
  );

  await channel.waitForConfirms();
  await connection.close();
}

// Consumer
async function consumeMessages(queue, handler) {
  const connection = await amqp.connect(AMQP_URL);
  const channel = await connection.createChannel();

  await channel.assertQueue(queue, {
    durable: true,
    arguments: {
      'x-queue-type': 'quorum',
      'x-delivery-limit': 5,
      'x-dead-letter-exchange': 'dlx',
    },
  });

  await channel.bindQueue(queue, 'orders', 'orders.created');

  channel.prefetch(10);

  channel.consume(queue, async msg => {
    if (msg) {
      try {
        const content = JSON.parse(msg.content.toString());
        await handler(content);
        channel.ack(msg);
      } catch (err) {
        console.error('Processing error:', err);
        channel.nack(msg, false, false); // Don't requeue
      }
    }
  });

  console.log(`Consuming from ${queue}`);
}

// Usage
publishMessage('orders', 'orders.created', { orderId: '12345' });
consumeMessages('orders.created.queue', msg => console.log('Received:', msg));
```

### Go (amqp091-go)

```go
package main

import (
    "encoding/json"
    "log"

    amqp "github.com/rabbitmq/amqp091-go"
)

func main() {
    conn, err := amqp.Dial("amqp://admin:password@localhost:5672/")
    if err != nil {
        log.Fatal(err)
    }
    defer conn.Close()

    ch, err := conn.Channel()
    if err != nil {
        log.Fatal(err)
    }
    defer ch.Close()

    // Declare exchange
    err = ch.ExchangeDeclare(
        "orders",  // name
        "topic",   // type
        true,      // durable
        false,     // auto-deleted
        false,     // internal
        false,     // no-wait
        nil,       // arguments
    )
    if err != nil {
        log.Fatal(err)
    }

    // Declare quorum queue
    args := amqp.Table{
        "x-queue-type":          "quorum",
        "x-delivery-limit":      int32(5),
        "x-dead-letter-exchange": "dlx",
    }

    q, err := ch.QueueDeclare(
        "orders.created.queue",
        true,   // durable
        false,  // delete when unused
        false,  // exclusive
        false,  // no-wait
        args,   // arguments
    )
    if err != nil {
        log.Fatal(err)
    }

    // Bind queue
    err = ch.QueueBind(
        q.Name,
        "orders.created",
        "orders",
        false,
        nil,
    )
    if err != nil {
        log.Fatal(err)
    }

    // Publish
    message := map[string]interface{}{"order_id": "12345"}
    body, _ := json.Marshal(message)

    err = ch.Publish(
        "orders",
        "orders.created",
        false,
        false,
        amqp.Publishing{
            DeliveryMode: amqp.Persistent,
            ContentType:  "application/json",
            Body:         body,
        },
    )
    if err != nil {
        log.Fatal(err)
    }

    log.Println("Message published")
}
```

## Messaging Patterns

### Work Queue (Competing Consumers)

```python
# Multiple consumers share work from one queue
# Each message is processed by exactly one consumer

# Consumer 1
consume_messages('task_queue', process_task)

# Consumer 2
consume_messages('task_queue', process_task)

# Messages are distributed round-robin
```

### Pub/Sub (Fanout)

```python
# All subscribers receive all messages
channel.exchange_declare(exchange='logs', exchange_type='fanout')

# Each subscriber creates exclusive queue
result = channel.queue_declare(queue='', exclusive=True)
queue_name = result.method.queue
channel.queue_bind(exchange='logs', queue=queue_name)
```

### Topic Routing

```python
# Pattern-based routing
# orders.* matches orders.created, orders.updated
# orders.# matches orders.created, orders.payment.processed

channel.exchange_declare(exchange='events', exchange_type='topic')
channel.queue_bind(
    queue='email_notifications',
    exchange='events',
    routing_key='orders.created'
)
channel.queue_bind(
    queue='audit_log',
    exchange='events',
    routing_key='#'  # All messages
)
```

### Request-Reply (RPC)

```python
import uuid

def rpc_call(request):
    connection = pika.BlockingConnection(parameters)
    channel = connection.channel()

    # Create callback queue
    result = channel.queue_declare(queue='', exclusive=True)
    callback_queue = result.method.queue

    correlation_id = str(uuid.uuid4())
    response = None

    def on_response(ch, method, props, body):
        nonlocal response
        if props.correlation_id == correlation_id:
            response = body

    channel.basic_consume(
        queue=callback_queue,
        on_message_callback=on_response,
        auto_ack=True
    )

    channel.basic_publish(
        exchange='',
        routing_key='rpc_queue',
        properties=pika.BasicProperties(
            reply_to=callback_queue,
            correlation_id=correlation_id,
        ),
        body=request
    )

    while response is None:
        connection.process_data_events()

    return response
```

## CLI Commands

```bash
# Cluster management
rabbitmqctl cluster_status
rabbitmqctl set_cluster_name my_cluster
rabbitmqctl forget_cluster_node rabbit@deadnode

# Queue management
rabbitmqctl list_queues name messages consumers state
rabbitmqctl purge_queue queue_name
rabbitmqctl delete_queue queue_name

# Exchange management
rabbitmqctl list_exchanges name type
rabbitmqctl delete_exchange exchange_name

# Connection management
rabbitmqctl list_connections name state
rabbitmqctl close_connection <connection_pid> "reason"

# Consumer management
rabbitmqctl list_consumers
rabbitmqctl list_channels

# User management
rabbitmqctl add_user username password
rabbitmqctl set_user_tags username administrator
rabbitmqctl set_permissions -p / username ".*" ".*" ".*"

# Policy management
rabbitmqctl list_policies
rabbitmqctl set_policy name "^pattern" '{"definition":"value"}' --apply-to queues

# Metrics
rabbitmqctl list_queues name messages_ready messages_unacknowledged
rabbitmqctl report  # Full diagnostic report
```

## Troubleshooting

| Issue                    | Cause                             | Solution                                  |
| ------------------------ | --------------------------------- | ----------------------------------------- |
| Messages stuck in queue  | No consumers, consumer too slow   | Add consumers, increase prefetch          |
| High memory usage        | Too many messages, large messages | Add consumers, set message TTL, scale out |
| Network partition        | Network issues between nodes      | Check connectivity, use pause_minority    |
| Connection refused       | Port blocked, node down           | Check firewall, verify node status        |
| Unacked messages growing | Consumer not acknowledging        | Fix consumer logic, set consumer timeout  |
| Disk alarm               | Disk space low                    | Free disk space, increase limit           |
| Memory alarm             | Memory limit reached              | Add RAM, reduce queue backlog             |

### Diagnostic Commands

```bash
# Check alarms
rabbitmqctl list_alarms

# Check node health
rabbitmq-diagnostics check_running
rabbitmq-diagnostics check_port_connectivity
rabbitmq-diagnostics check_virtual_hosts

# Memory breakdown
rabbitmq-diagnostics memory_breakdown

# Network diagnostics
rabbitmq-diagnostics check_port_listener 5672

# Cluster diagnostics
rabbitmq-diagnostics cluster_status
```

## Best Practices

### Producer

1. **Enable publisher confirms** - Know when messages are persisted
2. **Set message persistence** - Survive broker restarts
3. **Use mandatory flag** - Detect unroutable messages
4. **Handle connection failures** - Implement reconnection logic

### Consumer

1. **Use manual acknowledgments** - Control message lifecycle
2. **Set appropriate prefetch** - Balance throughput and fairness
3. **Handle redeliveries** - Check `redelivered` flag
4. **Use dead letter queues** - Handle poison messages

### Operations

1. **Use quorum queues** - Better durability and availability
2. **Monitor queue depths** - Prevent unbounded growth
3. **Set message TTL** - Prevent stale messages
4. **Use policies** - Consistent queue configuration
5. **Regular backups** - Export definitions regularly

### Security Checklist

- [ ] Change default credentials
- [ ] Enable TLS for all connections
- [ ] Use vhosts for isolation
- [ ] Apply least-privilege permissions
- [ ] Enable management API authentication
- [ ] Restrict network access
- [ ] Enable audit logging
